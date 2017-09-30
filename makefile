XILINX=/opt/Xilinx/14.7/ISE_DS/ISE/
XILINX_PLATFORM=lin64
XILINX_BIN=$(XILINX)/bin/$(XILINX_PLATFORM)
XST=$(XILINX_BIN)/xst
NGDBUILD=$(XILINX_BIN)/ngdbuild
MAP=$(XILINX_BIN)/map
PAR=$(XILINX_BIN)/par
TRCE=$(XILINX_BIN)/trce
BITGEN=$(XILINX_BIN)/bitgen
ISE=$(XILINX_BIN)/ise
SIM=$(XILINX_BIN)/fuse

MAIN_FILE=serial_memory
FILES=$(MAIN_FILE).vhdl avr_interface.vhdl cclk_detector.vhdl spi_slave.vhdl serial_rx.vhdl serial_tx.vhdl single_port_ram.vhdl
FILE_TYPE=vhdl
TEST_BENCH=test_bench

OUTPUT=$(MAIN_FILE).bit

PROCESSOR=xc6slx9-tqg144-2

TMP_DIR=syn

XST_TMPDIR=xst
XST_PRJ=xst_in.prj
XST_OUT=xst_out
XST_OUT_MAIN=$(XST_OUT).ngc
XST_OPTIONS=-ifn $(XST_PRJ) -ofn $(XST_OUT) -ofmt NGC -p $(PROCESSOR) -top $(MAIN_FILE) -opt_mode Speed -opt_level 1 -power NO -iuc NO -keep_hierarchy No -netlist_hierarchy As_Optimized -rtlview Yes -glob_opt AllClockNets -read_cores YES -write_timing_constraints NO -cross_clock_analysis NO -hierarchy_separator / -bus_delimiter \<\> -case Maintain -slice_utilization_ratio 100 -bram_utilization_ratio 100 -dsp_utilization_ratio 100 -lc Auto -reduce_control_sets Auto -fsm_extract YES -fsm_encoding Auto -safe_implementation No -fsm_style LUT -ram_extract Yes -ram_style Auto -rom_extract Yes -shreg_extract YES -rom_style Auto -auto_bram_packing NO -resource_sharing YES -async_to_sync NO -shreg_min_size 2 -use_dsp48 Auto -iobuf YES -max_fanout 100000 -bufg 16 -register_duplication YES -register_balancing No -optimize_primitives NO -use_clock_enable Auto -use_sync_set Auto -use_sync_reset Auto -iob Auto -equivalent_register_removal YES -slice_utilization_ratio_maxmargin 5
XST_SETTINGS=xst_settings.xst
XST_LOG=xst_log.syr

NGD_CONSTRAINTS=-uc mojo.ucf
NGD_OPTIONS=-dd _ngo -sd ipcore_dir -nt timestamp $(NGD_CONSTRAINTS) -p $(PROCESSOR)
NGD_OUT=ngd_out
NGD_OUT_MAIN=$(NGD_OUT).ngd

MAP_OPTIONS=-p $(PROCESSOR) -w -logic_opt off -ol high -t 1 -xt 0 -register_duplication off -r 4 -global_opt off -mt off -ir off -pr off -lc off -power off
MAP_OUT=map_out
MAP_OUT_MAIN=$(MAP_OUT)_map.ncd
MAP_CONSTRAINTS=$(MAP_OUT).pcf

PAR_OPTIONS=-w -ol high -mt off
PAR_OUT=par_out
PAR_OUT_MAIN=$(PAR_OUT).ncd
PAR_CONSTRAINTS=$(MAP_CONSTRAINTS)

TRCE_OUT=trace_out.twr
TRCE_REPORT=trace_report.twx
TRCE_OPTIONS=-v 3 -s 2 -n 3 -fastpaths -xml $(TRCE_REPORT)

BITGEN_OPTIONS=-w -g Binary:yes -g Compress -g CRC:Enable -g Reset_on_err:No -g ConfigRate:2 -g ProgPin:PullUp -g TckPin:PullUp -g TdiPin:PullUp -g TdoPin:PullUp -g TmsPin:PullUp -g UnusedPin:PullDown -g UserID:0xFFFFFFFF -g ExtMasterCclk_en:No -g SPI_buswidth:1 -g TIMER_CFG:0xFFFF -g multipin_wakeup:No -g StartUpClk:CClk -g DONE_cycle:4 -g GTS_cycle:5 -g GWE_cycle:6 -g LCK_cycle:NoWait -g Security:None -g DonePipe:Yes -g DriveDone:No -g en_sw_gsr:No -g drive_awake:No -g sw_clk:Startupclk -g sw_gwe_cycle:5 -g sw_gts_cycle:4

SIM_PRJ=sim_in.prj
SIM_FILES=$(TEST_BENCH).$(FILE_TYPE) $(FILES)

all: xst ngd map par trce bitgen clean_partial
xst: $(XST_OUT_MAIN)
$(XST_OUT_MAIN):
	-rm $(XST_SETTINGS)
	-rm $(XST_PRJ)
	echo "set -tmpdir \""$(XST_TMPDIR)"\"" >> $(XST_SETTINGS)
	echo "set -xsthdpdir \"xst\"" >> $(XST_SETTINGS)
	echo "run" >> $(XST_SETTINGS)
	echo $(XST_OPTIONS) >> $(XST_SETTINGS)
	$(foreach file,$(FILES), echo $(FILE_TYPE) "work" $(file) >> $(XST_PRJ);)
	mkdir -p $(XST_TMPDIR)
	$(XST) -ifn $(XST_SETTINGS) -ofn $(XST_LOG)
.PHONY: xst_clean
xst_clean:
	-rm $(XST_SETTINGS)
	-rm $(XST_LOG)
	-rm $(XST_PRJ)
	-rm $(MAIN_FILE).lso
	-rm -r _xmsgs
	-rm -r xst
	-rm $(XST_OUT).ngc
	-rm $(XST_OUT).ngr
	-rm $(XST_OUT)_xst.xrpt
ngd: $(NGD_OUT_MAIN)
$(NGD_OUT_MAIN): $(XST_OUT_MAIN)
	$(NGDBUILD) $(NGD_OPTIONS) $(XST_OUT_MAIN) $(NGD_OUT).ngd
.PHONY: ngd_clean
ngd_clean:
	-rm -r _xmsgs
	-rm $(NGD_OUT).bld
	-rm $(NGD_OUT).ngd
	-rm $(NGD_OUT)_ngdbuild.xrpt
	-rm $(NGD_OUT)_usage.xml
	-rm $(NGD_OUT)_summary.xml
	-rm -r _ngo
	-rm -r xlnx_auto_0_xdb
map: $(MAP_OUT_MAIN)
$(MAP_OUT_MAIN): $(NGD_OUT_MAIN)
	$(MAP) $(MAP_OPTIONS) -o $(MAP_OUT_MAIN) $(NGD_OUT_MAIN) $(MAP_CONSTRAINTS)
.PHONY: map_clean
map_clean:
	-rm -r _xmsgs
	-rm $(MAP_OUT)_map.ncd
	-rm $(MAP_OUT)_map.map
	-rm $(MAP_OUT)_map.mrp
	-rm $(MAP_OUT)_map.ngm
	-rm $(MAP_OUT).pcf
	-rm $(MAIN_FILE)_map.xrpt
par: $(PAR_OUT_MAIN)
$(PAR_OUT_MAIN): $(MAP_OUT_MAIN)
	$(PAR) $(PAR_OPTIONS) $(MAP_OUT_MAIN) $(PAR_OUT_MAIN) $(PAR_CONSTRAINTS)
.PHONY: par_clean
par_clean:
	-rm -r _xmsgs
	-rm par_usage_statistics.html
	-rm $(MAIN_FILE)_par.xrpt
	-rm $(PAR_OUT).ncd
	-rm $(PAR_OUT).pad
	-rm $(PAR_OUT)_pad.csv
	-rm $(PAR_OUT)_pad.txt
	-rm $(PAR_OUT).par
	-rm $(PAR_OUT).ptwx
	-rm $(PAR_OUT).unroutes
	-rm $(PAR_OUT).xpi
trce: $(TRCE_OUT)
$(TRCE_OUT): $(PAR_OUT_MAIN)
	$(TRCE) $(TRCE_OPTIONS) $(PAR_OUT_MAIN) -o $(TRCE_OUT) $(PAR_CONSTRAINTS)
.PHONY: trce_clean
trce_clean:
	-rm $(TRCE_OUT)
	-rm $(TRCE_REPORT)
	-rm -r _xmsgs
bitgen: $(OUTPUT)
$(OUTPUT): $(PAR_OUT_MAIN)
	$(BITGEN) $(BITGEN_OPTIONS) $(PAR_OUT_MAIN) $(OUTPUT)
.PHONY: bitgen_clean
bitgen_clean:
	-rm -r _xmsgs
	-rm xilinx_device_details.xml
	-rm $(MAIN_FILE).bit
	-rm $(MAIN_FILE).bgn
	-rm $(MAIN_FILE).drc
	-rm $(MAIN_FILE)_bitgen.xwbt
	-rm usage_statistics_webtalk.html
	-rm webtalk.log

.PHONY: sim
sim:
	-rm $(SIM_PRJ)
	-rm run_sim.sh
	$(foreach file,$(SIM_FILES), echo $(FILE_TYPE) "work" $(file) >> $(SIM_PRJ);)
	$(SIM) -prj $(SIM_PRJ) -o $(MAIN_FILE).sim $(TEST_BENCH)
	echo "export XILINX=$(XILINX)" >> run_sim.sh
	echo "export PLATFORM=$(XILINX_PLATFORM)" >> run_sim.sh
	echo "export PATH=$PATH:$(XILINX_BIN)" >> run_sim.sh
	echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$(XILINX)/lib/$(XILINX_PLATFORM)" >> run_sim.sh
	echo "./$(MAIN_FILE).sim -gui" >> run_sim.sh
	chmod +x run_sim.sh
.PHONY: sim_clean
sim_clean:
	-rm $(SIM_PRJ)
	-rm $(MAIN_FILE).sim
	-rm fuse.log
	-rm fuseRelaunch.cmd
	-rm fuse.xmsgs
	-rm -r isim
	-rm isim.log
	-rm isim.wdb
	-rm run_sim.sh
.PHONY: ise
ise:
	$(ISE)

.PHONY: clean_partial
clean_partial: xst_clean ngd_clean map_clean par_clean trce_clean bitgen_clean sim_clean
.PHONY: clean
clean: clean_partial
	-rm $(MAIN_FILE).bin

