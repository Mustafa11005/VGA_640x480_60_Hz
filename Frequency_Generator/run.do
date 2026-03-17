vlib work

vlog -f src_files.list

vsim -voptargs=+acc work.clk_gen_tb

add wave *

run -all
#quit -sim
