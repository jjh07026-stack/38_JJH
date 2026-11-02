# 정준혁 소개 페이지

## 소개
- 이름 : 정준혁  
- 출생 : 2002.07.26  
- 메일 : jjh07026@gmail.com
- 관심분야 : Verilog HDL, ON-Device AI

## 경력
2026.09.01 ~ 2027.03.31 : 대한상공회의소 AI 시스템 반도체 설계 2기  

## 프로젝트

### [저전력 온디바이스 AI 영유아 위험 알림 시스템](https://github.com/kcci-AI-campus/Team10)
- 설명 : 아기가 칼·콘센트의 위험 반경 안에 머물면 라즈베리파이 5가 스스로 판단해 보호자 휴대폰으로 알리는 시스템
- 사용 기술 : Python, Raspberry Pi 5, YOLO11n, TFLite, Flask, ntfy
- 주요 기능 : 위험 거리에 따른 4상태 전력 관리, 휴대폰 경보 알림과 클립 저장, 웹 관제 대시보드

### [Basys-3 기반 WATCH, STOPWATCH, DHT11·SR04 센서 통합 및 UART 제어 시스템](DHT%20%26%20SR04%20Sensor/)
- 설명 : 미니 프로젝트로 구현한 Watch·Stopwatch와 UART·FIFO를 합치고 DHT11 온습도 센서와 HC-SR04 초음파 센서를 추가해, 버튼·스위치와 PC UART 명령으로 제어하는 시스템
- 사용 기술 : Verilog HDL, Vivado, Basys-3 (Artix-7 XC7A35T), UART, FIFO
- 주요 기능 : 4개 모드(스톱워치·시계·거리·온습도) 전환 및 FND 표시, ASCII 명령 수신과 측정값 PC 송신, 센서 무응답·checksum 오류 처리
- 담당 역할 : 전체 모듈 통합, 컨트롤 유닛 구현, 전체 검증

## 미니 프로젝트

### [RPS GAME](RPS_GAME/)
- 설명 : 카메라와 AI 손동작 인식을 활용한 2인용 가위바위보 게임
- 사용 기술 : Python, OpenCV, YOLO, NumPy, Google AI Edge LiteRT
- 주요 기능 : 카메라 영상에서 두 플레이어의 손 모양을 인식해 가위바위보 결과와 점수를 표시

### [Basys-3 기반 Digital Watch & Stopwatch 통합 시스템](Watch%20%26%20Stopwatch/)
- 설명 : Basys-3 FPGA 보드에서 디지털 시계와 스톱워치를 설계하고 FND로 통합 제어하는 시스템
- 사용 기술 : Verilog HDL, Vivado, Basys-3 (Artix-7 XC7A35T)
- 주요 기능 : 버튼 디바운스와 FSM으로 시계 시각 설정, 스톱워치 RUN/STOP·CLEAR 제어 및 4자리 FND 표시 모드 전환

### [UART FIFO Loopback](UART%20FIFO%20Loopback/)
- 설명 : UART 수신·송신 경로에 FIFO 버퍼 2개를 두어 PC에서 보낸 데이터를 그대로 되돌려 보내는 루프백 시스템
- 사용 기술 : Verilog HDL, Vivado, XSim, Basys-3 (Artix-7 XC7A35T), UART (9600 bps, 8N1), FIFO
- 주요 기능 : 16배 오버샘플링 UART 수신, 4-depth FIFO 버퍼링, 랜덤 16 byte 루프백 검증 및 ComPort Master 보드 에코 확인
