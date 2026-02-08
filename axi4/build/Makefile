
COMPONENT_DIR = $(abspath $(dir $(abspath $(lastword $(MAKEFILE_LIST))))..)
REPO_DIR = $(abspath $(COMPONENT_DIR)/..)

OUT_DIR_DEFAULT = $(COMPONENT_DIR)/out
OUT_DIR ?= $(OUT_DIR_DEFAULT)

LIBRARY_NAME = lib_axi4

COMPONENTS = \
	$(REPO_DIR)/common

SOURCES_VHDL = \
	$(COMPONENT_DIR)/src/axi4_pkg.vhd \
	$(COMPONENT_DIR)/src/axi4_slice_rtl.vhd \
	$(COMPONENT_DIR)/src/axi4_demux_rtl.vhd \
	$(COMPONENT_DIR)/src/axi4_mux_rtl.vhd \

SOURCES_TB = \
	$(COMPONENT_DIR)/test/axi4_tb.vhd \

TB_TOP = axi4_tb

vcom: outdir
	$(foreach COMPONENT, $(COMPONENTS), $(MAKE) -f $(COMPONENT)/build/Makefile vcom OUT_DIR=$(OUT_DIR))
	(cd $(OUT_DIR) && vcom -2008 -work $(LIBRARY_NAME) $(SOURCES_VHDL) $(SOURCES_TB))

vsim: vcom
	(cd $(OUT_DIR) && vsim -L $(LIBRARY_NAME) $(LIBRARY_NAME).$(TB_TOP))

simulate: elab
	(cd $(OUT_DIR) && xsim -g sim_snapshot)

elab: compile
	(cd $(OUT_DIR) && xelab -debug typical --snapshot sim_snapshot $(LIBRARY_NAME).$(TB_TOP))

compile: outdir
	$(foreach COMPONENT, $(COMPONENTS), $(MAKE) -f $(COMPONENT)/build/Makefile compile OUT_DIR=$(OUT_DIR))
	(cd $(OUT_DIR) && xvhdl --2008 --work $(LIBRARY_NAME) $(SOURCES_VHDL) $(SOURCES_TB))

outdir:
ifeq ($(OUT_DIR), $(OUT_DIR_DEFAULT))
	(cd $(COMPONENT_DIR) && mkdir -p out)
endif

clean:
ifeq ($(OUT_DIR), $(OUT_DIR_DEFAULT))
	rm -rf $(COMPONENT_DIR)/out
endif
