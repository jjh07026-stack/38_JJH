# 시스템검증_정상 2번 (DHT11 모드 전환) 재캡처용 파형 세팅 - tb_project_top
# 사용법 : Run Simulation 후 Tcl Console 에
#   source C:/work/AI_CAMP_26/project_1_uart_sensor_watch_fnd/wave_dht.tcl
# -> restart 후 전체 실행 (약 1분), START(34ms) ~ END(82ms) 마커 사이를 드래그해서 확대

set T /tb_project_top
set RXP $T/dut/U_UART/U_UART_FIFO_LOOPBACK/U_UART_RX

# 실행 중인 TB 확인
if {[lsearch [get_scopes /*] $T] < 0} {
    error "Current sim top is [get_scopes /*]. Set top to tb_project_top, close simulation, then Run Simulation again."
}

restart
log_wave -recursive $T
foreach w [get_wave_configs] { close_wave_config -force $w }
create_wave_config

add_wave -name clk $T/clk
add_wave -name rst $T/rst
add_wave -name sw -radix bin $T/sw
add_wave -name btnR $T/btnR
add_wave -name rx $T/rx
add_wave -name rx_data -radix ascii $RXP/rx_data
add_wave -name rx_done $RXP/rx_done
add_wave -name w_displaymode -radix unsigned $T/dut/w_displaymode
add_wave -name trig $T/trig
add_wave -name echo $T/echo
add_wave -name dht11_io $T/dht11_io
add_wave -name w_sender_start -color yellow $T/dut/w_sender_start
add_wave -name tx $T/tx
add_wave -name pc_rx_data -radix ascii -color cyan $T/pc_rx_data
add_wave -name pc_rx_done $T/pc_rx_done
add_wave -name fnd_data -radix unsigned $T/dut/fnd_data

add_wave_marker -name START 34 ms
add_wave_marker -name END 82 ms

run all
