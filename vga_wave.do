onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /vga/clk_i
add wave -noupdate -format Logic /vga/rst_i
add wave -noupdate -format Logic /vga/inta_o
add wave -noupdate -format Logic /vga/nreset
add wave -noupdate -divider {wishbone slave}
add wave -noupdate -format Logic /vga/cyc_i
add wave -noupdate -format Logic /vga/we_i
add wave -noupdate -format Logic /vga/stb_i
add wave -noupdate -format Literal /vga/adr_i
add wave -noupdate -format Literal /vga/sel_i
add wave -noupdate -format Literal -radix hexadecimal /vga/sdat_i
add wave -noupdate -format Literal -radix hexadecimal /vga/sdat_o
add wave -noupdate -format Logic /vga/ack_o
add wave -noupdate -format Logic /vga/err_o
add wave -noupdate -divider {wishbone master}
add wave -noupdate -format Logic /vga/u2/dvmem_acc
add wave -noupdate -format Logic /vga/u2/dclut_acc
add wave -noupdate -format Logic /vga/cyc_o
add wave -noupdate -format Logic /vga/cab_o
add wave -noupdate -format Logic /vga/we_o
add wave -noupdate -format Logic /vga/stb_o
add wave -noupdate -format Literal -radix hexadecimal /vga/u2/wb_block/vmema
add wave -noupdate -format Literal -radix hexadecimal /vga/u2/wb_block/cluta
add wave -noupdate -format Literal -radix hexadecimal /vga/adr_o
add wave -noupdate -format Literal /vga/sel_o
add wave -noupdate -format Literal -radix hexadecimal /vga/mdat_i
add wave -noupdate -format Logic /vga/ack_i
add wave -noupdate -format Logic /vga/err_i
add wave -noupdate -divider vga
add wave -noupdate -format Logic /vga/pclk
add wave -noupdate -format Logic /vga/hsync
add wave -noupdate -format Logic /vga/vsync
add wave -noupdate -format Logic /vga/csync
add wave -noupdate -format Logic /vga/blank
add wave -noupdate -format Literal -radix hexadecimal /vga/r
add wave -noupdate -format Literal -radix hexadecimal /vga/g
add wave -noupdate -format Literal -radix hexadecimal /vga/b
add wave -noupdate -divider registers
add wave -noupdate -format Logic /vga/u1/acc
add wave -noupdate -format Logic /vga/u1/acc32
add wave -noupdate -format Logic /vga/u1/reg_acc
add wave -noupdate -format Literal -radix hexadecimal /vga/u1/ctrl
add wave -noupdate -format Literal -radix hexadecimal /vga/u1/stat
add wave -noupdate -format Literal -radix hexadecimal /vga/u1/vbara
add wave -noupdate -format Literal -radix hexadecimal /vga/u1/vbarb
add wave -noupdate -format Literal -radix hexadecimal /vga/u1/cbar
add wave -noupdate -format Literal -radix hexadecimal /vga/u1/htim
add wave -noupdate -format Literal -radix unsigned /vga/u1/thsync
add wave -noupdate -format Literal -radix unsigned /vga/u1/thgdel
add wave -noupdate -format Literal -radix unsigned /vga/u1/thgate
add wave -noupdate -format Literal -radix hexadecimal /vga/u1/vtim
add wave -noupdate -format Literal -radix unsigned /vga/u1/tvsync
add wave -noupdate -format Literal -radix unsigned /vga/u1/tvgdel
add wave -noupdate -format Literal -radix unsigned /vga/u1/tvgate
add wave -noupdate -format Literal -radix hexadecimal /vga/u1/hvlen
add wave -noupdate -format Literal -radix unsigned /vga/u1/thlen
add wave -noupdate -format Literal -radix unsigned /vga/u1/tvlen
add wave -noupdate -divider {pixel buffer}
add wave -noupdate -format Literal -radix hexadecimal /vga/u2/pixel_buf/d
add wave -noupdate -format Logic /vga/u2/pixel_buf/wreq
add wave -noupdate -format Logic /vga/u2/pixel_buf/empty
add wave -noupdate -format Logic /vga/u2/pixel_buf/hfull
add wave -noupdate -format Logic /vga/u2/pixel_buf/full
add wave -noupdate -format Literal -radix hexadecimal /vga/u2/pixel_buf/q
add wave -noupdate -format Logic -radix hexadecimal /vga/u2/pixel_buf/rreq
add wave -noupdate -divider {color processor}
add wave -noupdate -format Literal /vga/u2/color_proc/statemachine/c_state
add wave -noupdate -format Literal -radix hexadecimal /vga/u2/color_proc/databuffer
add wave -noupdate -format Literal -radix hexadecimal /vga/u2/color_proc/dwb_di
add wave -noupdate -format Literal /vga/u2/color_proc/colcnt
add wave -noupdate -format Literal -radix hexadecimal /vga/u2/color_proc/clut_offs
add wave -noupdate -format Logic /vga/u2/color_proc/clut_req
add wave -noupdate -format Logic /vga/u2/color_proc/clut_ack
add wave -noupdate -format Literal -radix hexadecimal /vga/u2/color_proc/r
add wave -noupdate -format Literal -radix hexadecimal /vga/u2/color_proc/g
add wave -noupdate -format Literal -radix hexadecimal /vga/u2/color_proc/b
add wave -noupdate -divider {rgb buffer}
add wave -noupdate -format Literal -radix hexadecimal /vga/u2/rgb_buf/d
add wave -noupdate -format Logic /vga/u2/rgb_buf/wreq
add wave -noupdate -format Logic /vga/u2/rgb_buf/empty
add wave -noupdate -format Logic /vga/u2/rgb_buf/hfull
add wave -noupdate -format Logic /vga/u2/rgb_buf/full
add wave -noupdate -format Literal -radix hexadecimal /vga/u2/rgb_buf/q
add wave -noupdate -format Logic /vga/u2/rgb_buf/rreq
add wave -noupdate -divider {line fifo}
add wave -noupdate -format Literal -radix hexadecimal -expand /vga/u4/mem
add wave -noupdate -format Literal -radix unsigned /vga/u4/rptr
add wave -noupdate -format Literal -radix unsigned /vga/u4/wptr
add wave -noupdate -format Logic /vga/u4/wclk
add wave -noupdate -format Literal -radix hexadecimal /vga/u4/d
add wave -noupdate -format Logic /vga/u4/wreq
add wave -noupdate -format Logic /vga/u4/ifull
add wave -noupdate -format Logic /vga/u4/iempty
add wave -noupdate -format Logic /vga/u4/wr_empty
add wave -noupdate -format Logic /vga/u4/wr_full
add wave -noupdate -format Logic /vga/u4/rclk
add wave -noupdate -format Literal -radix hexadecimal /vga/u4/q
add wave -noupdate -format Logic /vga/u4/rreq
add wave -noupdate -format Logic /vga/u4/rd_empty
add wave -noupdate -format Logic /vga/u4/rd_full
add wave -noupdate -divider {video timing}
add wave -noupdate -format Logic /vga/u3/tblk/vtgen/hor_gen/dsync
add wave -noupdate -format Logic /vga/u3/tblk/vtgen/hor_gen/dgdel
add wave -noupdate -format Logic /vga/u3/tblk/vtgen/hor_gen/dgate
add wave -noupdate -format Logic /vga/u3/tblk/vtgen/hor_gen/dlen
add wave -noupdate -format Logic /vga/u3/tblk/vtgen/ver_gen/dsync
add wave -noupdate -format Logic /vga/u3/tblk/vtgen/ver_gen/dgdel
add wave -noupdate -format Logic /vga/u3/tblk/vtgen/ver_gen/dgate
add wave -noupdate -format Logic /vga/u3/tblk/vtgen/ver_gen/dlen
add wave -noupdate -divider {image cnt}
add wave -noupdate -format Literal /vga/u2/wb_block/burst_cnt
add wave -noupdate -format Logic /vga/u2/wb_block/burst_done
add wave -noupdate -format Logic /vga/u2/wb_block/imdone
add wave -noupdate -format Literal -radix unsigned /vga/u2/wb_block/hpix
add wave -noupdate -format Literal -radix unsigned /vga/u2/wb_block/totpix
add wave -noupdate -format Literal -radix unsigned /vga/u2/wb_block/pixcnt
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {1862 ns}
WaveRestoreZoom {1697 ns} {2073 ns}
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
