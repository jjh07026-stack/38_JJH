# 모듈 로딩
#import tflite_runtime.interpreter as tflite
import ai_edge_litert.interpreter as tflite
from collections import Counter
import numpy as np
import time
import cv2

# LiteRT 모델 선택
modelPath = "best.tflite"
#modelPath = "best_int8.tflite"
#modelPath = "best_w8a32.tflite"
print('model path:', modelPath)

# LiteRT 모델 로딩
interpreter = tflite.Interpreter(model_path = modelPath) # 모델 로딩
interpreter.allocate_tensors() # tensor 할당

# 모델 정보 얻기 
input_details = interpreter.get_input_details()  # input tensor 정보 얻기
output_details = interpreter.get_output_details() # output tensor 정보 얻기
print(input_details)
print(output_details)
input_index = input_details[0]['index']
output_index = output_details[0]['index']
input_dtype = input_details[0]['dtype']
output_dtype = output_details[0]['dtype']
height = input_details[0]['shape'][2]
width = input_details[0]['shape'][3]
print('model input shape:', (height, width))

# BB 텍스트 및 색상 정의
ansToText = {0:'scissors', 1:'rock', 2:'paper'}
colorList = [(255,0,0),(0,255,0),(0,0,255)]

# 모델 입력 크기
IMG_SIZE = 320

# Threshold 설정
CONF_TH = 0.4
IOU_TH  = 0.45
COUNTDOWN_SEC = 3
VOTE_WINDOW_SEC = 0.5

# 4단계 타이밍 제어용 상태
countdown_state = {
    'start_time': None,
    'freeze_until': 0.0,
    'result': '',
    'last_round': None,
    'is_frozen': False,
    'waiting_for_key': False,
    'votes_p1': [],
    'votes_p2': []
}

# 스코어 보드 상태
score_state = {
    'p1': 0,
    'draw': 0,
    'p2': 0
}

freeze_frame = None
freeze_mode = False

# 가위바위보 판정 함수
# class id: 0=scissors, 1=rock, 2=paper
# P1가 이기면 True, P2가 이기면 False, 무승부면 None

def rpsWinner(p1Class, p2Class):
    if p1Class == p2Class:
        return 'Draw'

    winMap = {
        0: 2,  # scissors > paper
        1: 0,  # rock > scissors
        2: 1   # paper > rock
    }

    if winMap[p1Class] == p2Class:
        return 'P1 Win'
    return 'P2 Win'


def resetCountdown():
    countdown_state['start_time'] = None
    countdown_state['freeze_until'] = 0.0
    countdown_state['result'] = ''
    countdown_state['last_round'] = None
    countdown_state['is_frozen'] = False
    countdown_state['waiting_for_key'] = False
    countdown_state['votes_p1'].clear()
    countdown_state['votes_p2'].clear()

    global freeze_frame, freeze_mode
    freeze_frame = None
    freeze_mode = False


def resetScore():
    score_state['p1'] = 0
    score_state['draw'] = 0
    score_state['p2'] = 0
    resetCountdown()


def drawScoreBoard(frame):
    bar_h = 38
    cv2.rectangle(frame, (0, 0), (frame.shape[1], bar_h), (20, 20, 20), -1)
    cv2.putText(frame, f'P1: {score_state["p1"]}', (12, 27), cv2.FONT_HERSHEY_PLAIN, 1.2, (0,255,0), 2)
    cv2.putText(frame, f'DRAW: {score_state["draw"]}', (frame.shape[1]//2 - 48, 27), cv2.FONT_HERSHEY_PLAIN, 1.2, (0,255,255), 2)
    cv2.putText(frame, f'P2: {score_state["p2"]}', (frame.shape[1]-95, 27), cv2.FONT_HERSHEY_PLAIN, 1.2, (0,165,255), 2)


def drawKeyGuide(frame):
    cv2.putText(frame, 'r: reset score   q: quit', (8, frame.shape[0]-15), cv2.FONT_HERSHEY_PLAIN, 1.0, (255,255,255), 1)


def letterbox(img, new_shape=(320,320), color=(114,114,114)):
    h, w = img.shape[:2]    
    nh, nw = new_shape
    r = min(nw / w, nh / h)

    new_w, new_h = int(w * r), int(h * r)
    resized = cv2.resize(img, (new_w, new_h))

    pad_w = nw - new_w
    pad_h = nh - new_h
    pad_x = pad_w // 2
    pad_y = pad_h // 2

    padded = cv2.copyMakeBorder(
        resized,
        pad_y, pad_y,
        pad_x, pad_x,
        cv2.BORDER_CONSTANT,
        value=color
    )

    return padded, r, pad_x, pad_y

def processImage(frame):

    # BGR을 RGB로 변경
    img_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

    # letterbox 적용
    img_lb, r, pad_x, pad_y = letterbox(img_rgb, (IMG_SIZE, IMG_SIZE))

    # 0 ~ 1 사이 값으로 변경
    img = img_lb.astype(np.float32) / 255.0

    # 모델의 입력 형태로 수정: (1,3,320,320)
    #   최상위 차원 증가: (320,320,3) -> (1,320,320,3)
    img = np.expand_dims(img, axis=0)
    #   축 위치 변경: (1,320,320,3) -> (1,3,320,320)
    img = np.transpose(img, (0, 3, 1, 2))

    # 모델에 입력하여 결과 얻기
    #   input tensor 설정
    interpreter.set_tensor(input_index, img)
    #   모델 실행
    interpreter.invoke()
    #   output tensor 얻기: (1,7,2100) -> (7,2100) -> (2100,7)
    raw = interpreter.get_tensor(output_index)[0].transpose()

    # raw에서 각 Object 별로 confidence score의 최대값과 해당 클래스의 id를 추출
    class_scores = raw[:, 4:]                      # confidence score: (2100, 3)
    confidences = np.max(class_scores, axis=1)     # confidence score의 최대값: (2100,)
    class_ids = np.argmax(class_scores, axis=1)    # 해당 클래스의 id: (2100,)

    # confidence score가 설정한 임계값(CONF_TH)보다 높은 Object만 필터링
    keep_mask = confidences > CONF_TH
    filtered_raw = raw[keep_mask] # (N,7)
    scores = confidences[keep_mask] # (N,)
    classes = class_ids[keep_mask]  # (N,)

    # 중심점 좌표 [cx, cy, w, h]를 추출하고 좌상단 좌표 [x, y, w, h]로 변환
    cx, cy, w, h = filtered_raw[:, 0], filtered_raw[:, 1], filtered_raw[:, 2], filtered_raw[:, 3]
    x = cx - (w / 2)
    y = cy - (h / 2)
    boxes = np.stack([x, y, w, h], axis=-1) # (N,4)

    # Batched NMS 처리
    keep = cv2.dnn.NMSBoxesBatched(
            boxes, 
            scores, 
            classes, 
            score_threshold=CONF_TH, 
            nms_threshold=IOU_TH
    )

    if keep is None or len(keep) == 0:
        return

    # 최종 BB 정보만 저장
    draw_boxes = []
    for i in keep:
        if isinstance(i, tuple):
            i = i[0]

        x, y, w, h = boxes[i]
        sc = float(scores[i])
        cid = int(classes[i])

        x *= IMG_SIZE; y *= IMG_SIZE
        w *= IMG_SIZE; h *= IMG_SIZE

        x1 = (x - pad_x) / r
        y1 = (y - pad_y) / r
        x2 = (x + w - pad_x) / r
        y2 = (y + h - pad_y) / r

        x1 = int(np.clip(x1,0,frame.shape[1]))
        y1 = int(np.clip(y1,0,frame.shape[0]))
        x2 = int(np.clip(x2,0,frame.shape[1]))
        y2 = int(np.clip(y2,0,frame.shape[0]))

        draw_boxes.append({
            'x1': x1,
            'y1': y1,
            'x2': x2,
            'y2': y2,
            'cid': cid,
            'score': sc,
            'cx': (x1 + x2) / 2
        })

    # 왼쪽/오른쪽 플레이어 분리 (P1, P2)
    left_boxes = []
    right_boxes = []
    for box in draw_boxes:
        if box['cx'] < frame.shape[1] / 2:
            left_boxes.append(box)
        else:
            right_boxes.append(box)

    # 3단계: 손이 2개가 아니면 판정 불가
    if len(left_boxes) != 1 or len(right_boxes) != 1:
        resetCountdown()
        cv2.putText(frame, 'Need 2 hands detected', (20, 100), cv2.FONT_HERSHEY_PLAIN, 1.2, (0,0,255), 2)
        # 감지된 박스는 표시하되, 게임 판정은 보류
        for box in draw_boxes:
            cv2.rectangle(frame, (box['x1'], box['y1']), (box['x2'], box['y2']), colorList[box['cid']], 2)
            cv2.putText(frame, f'{ansToText[box["cid"]]} {int(box["score"]*100)}%', (box['x1'], box['y1']-7), cv2.FONT_HERSHEY_PLAIN, 1, colorList[box['cid']], 2)
        return

    p1 = left_boxes[0]
    p2 = right_boxes[0]

    for box in draw_boxes:
        cv2.rectangle(frame, (box['x1'], box['y1']), (box['x2'], box['y2']), colorList[box['cid']], 2)
        cv2.putText(frame, f'{ansToText[box["cid"]]} {int(box["score"]*100)}%', (box['x1'], box['y1']-7), cv2.FONT_HERSHEY_PLAIN, 1, colorList[box['cid']], 2)

    # 4단계: 결과 시점의 프레임을 고정하고, 키 입력 전까지는 정지
    current_round = (p1['cid'], p2['cid'])

    if countdown_state['is_frozen']:
        if countdown_state['last_round'] != current_round:
            countdown_state['is_frozen'] = False
            countdown_state['result'] = ''
            countdown_state['waiting_for_key'] = False
            countdown_state['start_time'] = None
            countdown_state['last_round'] = None
        else:
            cv2.putText(frame, f'P1: {ansToText[p1["cid"]]}', (20, 70), cv2.FONT_HERSHEY_PLAIN, 1.2, (255,255,255), 2)
            cv2.putText(frame, f'P2: {ansToText[p2["cid"]]}', (frame.shape[1]-150, 70), cv2.FONT_HERSHEY_PLAIN, 1.2, (255,255,255), 2)
            cv2.putText(frame, countdown_state['result'], (frame.shape[1]//2 - 45, 100), cv2.FONT_HERSHEY_PLAIN, 1.5, (0,255,255), 2)
            cv2.putText(frame, 'Press any key to continue', (frame.shape[1]//2 - 100, frame.shape[0]-30), cv2.FONT_HERSHEY_PLAIN, 1.0, (255,255,255), 2)
            return

    if countdown_state['start_time'] is None:
        countdown_state['start_time'] = time.time()

    elapsed = time.time() - countdown_state['start_time']
    remaining = max(0, COUNTDOWN_SEC - int(elapsed))

    if elapsed >= COUNTDOWN_SEC - VOTE_WINDOW_SEC:
        countdown_state['votes_p1'].append(p1['cid'])
        countdown_state['votes_p2'].append(p2['cid'])

    if remaining > 0:
        cv2.putText(frame, f'P1: {ansToText[p1["cid"]]}', (20, 70), cv2.FONT_HERSHEY_PLAIN, 1.2, (255,255,255), 2)
        cv2.putText(frame, f'P2: {ansToText[p2["cid"]]}', (frame.shape[1]-150, 70), cv2.FONT_HERSHEY_PLAIN, 1.2, (255,255,255), 2)
        cv2.putText(frame, f'Countdown: {remaining}', (frame.shape[1]//2 - 55, 100), cv2.FONT_HERSHEY_PLAIN, 1.5, (0,255,255), 2)
        return

    # 1단계/2단계: 마지막 0.5초의 최빈값으로 P1/P2 비교
    final_p1 = Counter(countdown_state['votes_p1']).most_common(1)[0][0] if countdown_state['votes_p1'] else p1['cid']
    final_p2 = Counter(countdown_state['votes_p2']).most_common(1)[0][0] if countdown_state['votes_p2'] else p2['cid']
    result = rpsWinner(final_p1, final_p2)
    if result == 'P1 Win':
        score_state['p1'] += 1
    elif result == 'P2 Win':
        score_state['p2'] += 1
    else:
        score_state['draw'] += 1

    countdown_state['result'] = result
    countdown_state['last_round'] = (final_p1, final_p2)
    countdown_state['is_frozen'] = True
    countdown_state['waiting_for_key'] = True
    countdown_state['start_time'] = None

    cv2.putText(frame, f'P1: {ansToText[final_p1]}', (20, 70), cv2.FONT_HERSHEY_PLAIN, 1.2, (255,255,255), 2)
    cv2.putText(frame, f'P2: {ansToText[final_p2]}', (frame.shape[1]-150, 70), cv2.FONT_HERSHEY_PLAIN, 1.2, (255,255,255), 2)
    cv2.putText(frame, result, (frame.shape[1]//2 - 45, 100), cv2.FONT_HERSHEY_PLAIN, 1.5, (0,255,255), 2)
    cv2.putText(frame, 'Press any key to continue', (frame.shape[1]//2 - 100, frame.shape[0]-30), cv2.FONT_HERSHEY_PLAIN, 1.0, (255,255,255), 2)
    global freeze_frame, freeze_mode
    freeze_frame = frame.copy()
    freeze_mode = True

# 카메라 설정
cap = cv2.VideoCapture(0) # 0번 카메라 열기
cap.set(cv2.CAP_PROP_FRAME_WIDTH,320)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT,240)
cap.set(cv2.CAP_PROP_BUFFERSIZE,1)

# 윈도우 설정
cv2.namedWindow('cam', cv2.WINDOW_NORMAL)
cv2.resizeWindow('cam', 320+40, 240+60)

startTime = time.time()
while(cap.isOpened()):
    if freeze_mode and freeze_frame is not None:
        cv2.imshow('cam', freeze_frame)
        key = cv2.waitKey(0) & 0xFF
        if key == ord('q'):
            break
        if key != 255:
            freeze_mode = False
            freeze_frame = None
            resetCountdown()
        continue

    ret,frame=cap.read() # 사진 찍기 -> (240,320,3)
    if not ret: break

    # 이미지 처리
    drawKeyGuide(frame)
    processImage(frame)
    drawScoreBoard(frame)

    # FPS 표시
    curTime = time.time()
    fps = 1/(curTime - startTime)
    startTime = curTime
    cv2.putText(frame,f'FPS: {fps:.1f}',(frame.shape[1]-110, frame.shape[0]-15),cv2.FONT_HERSHEY_PLAIN,1.0,(0,255,255),2)

    # 이미지 출력
    cv2.imshow('cam',frame)

     # 10ms 동안 키 입력 대기
    key = cv2.waitKey(10) & 0xFF
    if key == ord('r'):
        resetScore()
        continue
    if key == ord('q'): break
    if countdown_state['is_frozen'] and key != 255:
        countdown_state['is_frozen'] = False
        countdown_state['result'] = ''
        countdown_state['last_round'] = None
        countdown_state['waiting_for_key'] = False
        countdown_state['start_time'] = None

cap.release() # 카메라 닫기
cv2.destroyAllWindows() # 모든 창 닫기
