COMPONENT_DIR = $(abspath $(dir $(abspath $(lastword $(MAKEFILE_LIST))))..)
REPO_DIR = $(abspath $(COMPONENT_DIR)/../..)

OUT_DIR_DEFAULT = $(COMPONENT_DIR)/out
OUT_DIR ?= $(OUT_DIR_DEFAULT)

LIBRARY_NAME = lib_bus_testbench

COMPONENTS = \
	$(REPO_DIR)/common

SOURCES_TB = \
	$(COMPONENT_DIR)/src/axis_pkg.vhd

compile: outdir
	$(foreach COMPONENT, $(COMPONENTS), $(MAKE) -f $(COMPONENT)/build/Makefile compile OUT_DIR=$(OUT_DIR))
	(cd $(OUT_DIR) && xvhdl --2008 --work $(LIBRARY_NAME) $(SOURCES_TB))

outdir:
ifeq ($(OUT_DIR), $(OUT_DIR_DEFAULT))
	(cd $(COMPONENT_DIR) && mkdir -p out)
endif

clean:
ifeq ($(OUT_DIR), $(OUT_DIR_DEFAULT))
	rm -rf $(COMPONENT_DIR)/out
endif

