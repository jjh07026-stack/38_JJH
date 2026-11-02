# 트러블슈팅 비교용 파형 세팅 (해결 전 / 후 프로젝트 공용, tb_trouble)
# 사용법 (Run Simulation 후 Tcl Console)
#   1) source C:/work/AI_CAMP_26/project_1_uart_sensor_watch_fnd/wave_trouble.tcl
#      -> restart 후 모든 신호 기록하며 전체 실행 (약 1분) + 장면 1 표시
#   2) tw 1 ~ tw 5 : 장면 전환 (다시 실행 안 함, source 는 한 번만)
#      tw 1z, tw 2z : 1클록 확대용 장면

set T /tb_trouble
set RXP $T/dut/U_UART/U_UART_FIFO_LOOPBACK/U_UART_RX

proc new_wave {} {
    foreach w [get_wave_configs] { close_wave_config -force $w }
    create_wave_config
}

proc mark {a b unit} {
    add_wave_marker -name START $a $unit
    add_wave_marker -name END $b $unit
}

proc tw {n} {
    global T RXP
    new_wave
    switch $n {
        1 {
            add_wave -name rx $T/rx
            add_wave -name rx_data -radix ascii $RXP/rx_data
            add_wave -name rx_done $RXP/rx_done
            add_wave -name w_displaymode -radix unsigned $T/dut/w_displaymode
            add_wave -name w_sender_start -color yellow $T/dut/w_sender_start
            add_wave -name tx $T/tx
            add_wave -name pc_rx_data -radix ascii -color cyan $T/pc_rx_data
            add_wave -name pc_rx_done $T/pc_rx_done
            mark 0.5 15.5 ms
        }
        1z {
            add_wave -name clk $T/clk
            add_wave -name rx_done $RXP/rx_done
            add_wave -name w_sender_start -color yellow $T/dut/w_sender_start
            add_wave -name w_displaymode -radix unsigned $T/dut/w_displaymode
            mark 996120 996190 ns
        }
        2 {
            add_wave -name sw -radix bin $T/sw
            add_wave -name w_displaymode -radix unsigned $T/dut/w_displaymode
            add_wave -name trig $T/trig
            add_wave -name echo $T/echo
            add_wave -name w_sender_start -color yellow $T/dut/w_sender_start
            add_wave -name w_distance -radix unsigned $T/dut/w_distance
            add_wave -name pc_rx_data -radix ascii -color cyan $T/pc_rx_data
            add_wave -name pc_rx_done $T/pc_rx_done
            mark 15.5 26.5 ms
        }
        2z {
            add_wave -name clk $T/clk
            add_wave -name sr04_done $T/dut/w_sr04_done
            add_wave -name w_sender_start -color yellow $T/dut/w_sender_start
            add_wave -name w_distance -radix unsigned $T/dut/w_distance
            mark 16683770 16683840 ns
        }
        3 {
            add_wave -name rx $T/rx
            add_wave -name rx_data -radix ascii $RXP/rx_data
            add_wave -name w_displaymode -radix unsigned $T/dut/w_displaymode
            add_wave -name w_sender_start -color yellow $T/dut/w_sender_start
            add_wave -name tx $T/tx
            add_wave -name pc_rx_data -radix ascii -color cyan $T/pc_rx_data
            add_wave -name pc_rx_done $T/pc_rx_done
            mark 30.5 60 ms
        }
        4 {
            add_wave -name sw -radix bin $T/sw
            add_wave -name w_displaymode -radix unsigned $T/dut/w_displaymode
            add_wave -name dht11_io $T/dht11_io
            add_wave -name w_sender_start -color yellow $T/dut/w_sender_start
            add_wave -name tx $T/tx
            add_wave -name pc_rx_data -radix ascii -color cyan $T/pc_rx_data
            add_wave -name pc_rx_done $T/pc_rx_done
            mark 61.5 90.5 ms
        }
        5 {
            add_wave -name w_sender_start -color yellow $T/dut/w_sender_start
            add_wave -name tx $T/tx
            add_wave -name pc_rx_data -radix ascii -color cyan $T/pc_rx_data
            add_wave -name pc_rx_done $T/pc_rx_done
            mark 118.5 142.5 ms
        }
    }
}

# 처음부터 다시 시작 -> 모든 신호 기록 -> 끝까지 실행 (약 1분)
# (Relaunch 직후 자동 실행된 1us 동안은 일부 신호만 기록되므로 restart 필요)
restart
log_wave -recursive $T
tw 1
run all
