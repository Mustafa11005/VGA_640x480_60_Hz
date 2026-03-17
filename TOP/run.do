vlib work

vlog -f src_files.list

vsim -voptargs=+acc work.vga_640x480_tb

add wave *

add wave -position insertpoint  \
sim:/vga_640x480_tb/DUT/pixel_x \
sim:/vga_640x480_tb/DUT/pixel_y

add wave -position insertpoint  \
sim:/vga_640x480_tb/DUT/genblk2/RGB_GEN/img_mem

run -all
#quit -sim
