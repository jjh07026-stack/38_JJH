# 정준혁 소개 페이지

## 소개
- 이름 : 정준혁  
- 출생 : 2002.07.26  
- 메일 : jjh07026@gmail.com
- 관심분야 : Verilog HDL, ON-Device AI

## 경력
2026.09.01 ~ 2027.03.31 : 대한상공회의소 AI 시스템 반도체 설계 2기  

## 프로젝트

### [Project 1. RPS GAME](RPS_GAME/)  
- 설명 : 카메라와 AI 손동작 인식을 활용한 2인용 가위바위보 게임
- 사용 기술 : Python, OpenCV, YOLO, NumPy, Google AI Edge LiteRT
- 주요 기능 : 카메라 영상에서 두 플레이어의 손 모양을 인식해 가위바위보 결과와 점수를 표시

### [Project 2 : 온디바이스 AI 기반 위험구역 침입 감지 시스템](https://github.com/kcci-AI-campus/Team10)
- 카메라 영상과 온디바이스 AI를 활용해 위험구역 내 침입을 감지하고 알림을 제공하는 시스템

### [Project 3. Basys-3 기반 Digital Watch & Stopwatch 통합 시스템](Watch%20%26%20Stopwatch/)
- 설명 : Basys-3 FPGA 보드에서 디지털 시계와 스톱워치를 설계하고 FND로 통합 제어하는 시스템
- 사용 기술 : Verilog HDL, Vivado, Basys-3 (Artix-7 XC7A35T)
- 주요 기능 : 버튼 디바운스와 FSM으로 시계 시각 설정, 스톱워치 RUN/STOP·CLEAR 제어 및 4자리 FND 표시 모드 전환

### [Project 4. UART FIFO Loopback](UART%20FIFO%20Loopback/)
- 설명 : UART 수신·송신 경로에 FIFO 버퍼 2개를 두어 PC에서 보낸 데이터를 그대로 되돌려 보내는 루프백 시스템
- 사용 기술 : Verilog HDL, Vivado, XSim, Basys-3 (Artix-7 XC7A35T), UART (9600 bps, 8N1), FIFO
- 주요 기능 : 16배 오버샘플링 UART 수신, 4-depth FIFO 버퍼링, 랜덤 16 byte 루프백 검증 및 ComPort Master 보드 에코 확인

### [Project 5. Basys-3 기반 DHT11·SR04 센서 통합 및 UART 제어 시스템](DHT%20%26%20SR04%20Sensor/)
- 설명 : Project 3의 Watch·Stopwatch와 Project 4의 UART·FIFO를 합치고 DHT11 온습도 센서와 HC-SR04 초음파 센서를 추가해, 버튼·스위치와 PC UART 명령으로 제어하는 시스템
- 사용 기술 : Verilog HDL, Vivado, Basys-3 (Artix-7 XC7A35T), UART, FIFO
- 주요 기능 : 4개 모드(스톱워치·시계·거리·온습도) 전환 및 FND 표시, ASCII 명령 수신과 측정값 PC 송신, 센서 무응답·checksum 오류 처리
- 담당 역할 : 전체 모듈 통합, 컨트롤 유닛 구현, 전체 검증
