
COMPONENT_DIR = $(abspath $(dir $(abspath $(lastword $(MAKEFILE_LIST))))..)
REPO_DIR = $(abspath $(COMPONENT_DIR)/..)

OUT_DIR_DEFAULT = $(COMPONENT_DIR)/out
OUT_DIR ?= $(OUT_DIR_DEFAULT)

LIBRARY_NAME = lib_common

SOURCES_VHDL = \
	$(COMPONENT_DIR)/src/common_pkg.vhd

SOURCES_TB = \
	$(COMPONENT_DIR)/src/random_2008_pkg.vhd

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
