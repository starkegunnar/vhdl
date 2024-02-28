
COMPONENT_DIR = $(abspath $(dir $(abspath $(lastword $(MAKEFILE_LIST))))..)
REPO_DIR = $(abspath $(COMPONENT_DIR)/..)

OUT_DIR_DEFAULT = $(COMPONENT_DIR)/out
OUT_DIR ?= $(OUT_DIR_DEFAULT)

LIBRARY_NAME = lib_common

SOURCES_VHDL = \
	$(COMPONENT_DIR)/src/common_pkg.vhd \
	$(COMPONENT_DIR)/src/reg_slice_full_rtl.vhd \
	$(COMPONENT_DIR)/src/reg_slice_fallthrough_rtl.vhd \
	$(COMPONENT_DIR)/src/srl_fifo_rtl.vhd \
	$(COMPONENT_DIR)/src/reg_slice_input_rtl.vhd \
	$(COMPONENT_DIR)/src/fifo_rtl.vhd \
	$(COMPONENT_DIR)/src/cdc_2phase_rtl.vhd \
	$(COMPONENT_DIR)/src/cdc_gray_rtl.vhd \
	$(COMPONENT_DIR)/src/cdc_fifo_2phase_rtl.vhd \
	$(COMPONENT_DIR)/src/cdc_fifo_gray_rtl.vhd \
	$(COMPONENT_DIR)/src/arbiter_tree_rtl.vhd

SOURCES_TB = \
	$(COMPONENT_DIR)/test/random_2008_pkg.vhd \
	$(COMPONENT_DIR)/test/generic_stream_tb_pkg.vhd \
	$(COMPONENT_DIR)/test/stream_tb.vhd

TB_TOP = stream_tb

simulate: elab
	(cd $(OUT_DIR) && xsim -g sim_snapshot)

elab: compile
	(cd $(OUT_DIR) && xelab -debug typical --snapshot sim_snapshot $(LIBRARY_NAME).$(TB_TOP))

compile: outdir
	(cd $(OUT_DIR) && xvhdl --2008 --work $(LIBRARY_NAME) $(SOURCES_VHDL) $(SOURCES_TB))

outdir:
ifeq ($(OUT_DIR), $(OUT_DIR_DEFAULT))
	(cd $(COMPONENT_DIR) && mkdir -p out)
endif

clean:
ifeq ($(OUT_DIR), $(OUT_DIR_DEFAULT))
	rm -rf $(COMPONENT_DIR)/out
endif
