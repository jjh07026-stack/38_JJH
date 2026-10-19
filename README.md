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

### [Project 3. Basys-3 기반 Digital Watch & Stopwatch 통합 시스템]
- 설명 : Basys-3 FPGA 보드를 활용해 독립 동작하는 디지털 시계와 스톱워치를 설계하고 FND로 통합 제어하는 시스템

- 사용 기술 : Verilog HDL, Vivado, Basys-3 (Artix-7 XC7A35T)

- 주요 기능 :

-- 100MHz 클록 분주 기반 100Hz tick 생성으로 Watch(시각 설정)와 Stopwatch(시간 측정) 독립 구동

-- 버튼 디바운스 및 2-bit 4-state FSM을 활용한 RUN/STOP, CLEAR, MODE 전환 제어

-- MUX를 통한 표시 모드(hour.min / sec.msec) 전환 및 4자리 동적 스캔 FND 출력

-- 시 단위 수동 설정 시 24시간 범위 초과 오동작 예외 처리(-10 보정 로직) 구현
