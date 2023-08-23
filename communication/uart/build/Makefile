
COMPONENT_DIR = $(abspath $(dir $(abspath $(lastword $(MAKEFILE_LIST))))..)
REPO_DIR = $(abspath $(COMPONENT_DIR)/../..)

OUT_DIR_DEFAULT = $(COMPONENT_DIR)/out
OUT_DIR ?= $(OUT_DIR_DEFAULT)

LIBRARY_NAME = lib_uart

COMPONENTS = \

SOURCES_VHDL = \
	$(COMPONENT_DIR)/src/uart_baud_gen_rtl.vhd \
	$(COMPONENT_DIR)/src/uart_rx_rtl.vhd \
	$(COMPONENT_DIR)/src/uart_tx_rtl.vhd \
	$(COMPONENT_DIR)/src/uart_rtl.vhd

SOURCES_TB = \
	$(COMPONENT_DIR)/test/uart_tb.vhd

TB_TOP = uart_tb

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
