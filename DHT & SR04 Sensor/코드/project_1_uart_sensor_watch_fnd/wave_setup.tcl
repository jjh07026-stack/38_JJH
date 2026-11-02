# 시뮬레이션 파형 세팅 (tb_project_top / tb_system_exception 공용)
# 사용법 : Run Simulation 후 Tcl Console 에 아래 한 줄 입력
#   source C:/work/AI_CAMP_26/project_1_uart_sensor_watch_fnd/wave_setup.tcl

set top ""
foreach s [get_scopes /*] {
    if {[string match "/tb_*" $s]} { set top $s }
}
set rx_path $top/dut/U_UART/U_UART_FIFO_LOOPBACK/U_UART_RX

log_wave -recursive $top
foreach w [get_wave_configs] { close_wave_config -force $w }
create_wave_config

add_wave $top/clk
add_wave $top/rst

add_wave_divider "INPUT"
add_wave -radix bin $top/sw
add_wave $top/btnR
add_wave $top/rx
add_wave -radix ascii $rx_path/rx_data
add_wave $rx_path/rx_done

add_wave_divider "MODE"
add_wave -radix unsigned $top/dut/w_displaymode

add_wave_divider "SENSOR"
add_wave $top/trig
add_wave $top/echo
add_wave $top/dht11_io

add_wave_divider "UART OUT"
add_wave $top/dut/w_sender_start
add_wave $top/tx
add_wave -radix ascii $top/pc_rx_data
add_wave $top/pc_rx_done

add_wave_divider "FND"
add_wave -radix unsigned $top/dut/fnd_data

run all
