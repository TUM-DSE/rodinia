CUDA_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
include $(CUDA_DIR)/../common.mk


#
# Auxiliary
#

DUMMY=
SPACE=$(DUMMY) $(DUMMY)
COMMA=$(DUMMY),$(DUMMY)

define join-list
$(subst $(SPACE),$(2),$(1))
endef


#
# CUDA detection
#

CUDA_ROOT ?= /usr

MACHINE := $(shell uname -m)
#ifeq ($(MACHINE), x86_64)
#LDFLAGS += -L$(CUDA_ROOT)/lib64
#endif
#ifeq ($(MACHINE), i686)
#LDFLAGS += -L$(CUDA_ROOT)/lib
#endif

LDFLAGS = -L/nix/store/513wmrnwa8lmc3ay44plqp6i2jysd50g-system-path/lib

CPPFLAGS += -isystem $(CUDA_ROOT)/include -isystem $(CUDA_DIR)/../common/cuda

#NVCC=$(CUDA_ROOT)/bin/nvcc
NVCC = nvcc
#NVCC_FLAGS = -I$(CUDA_DIR)/include 
NVCCFLAGS = -I/nix/store/rdhnkz8djgv74ms6iajm694byw236i11-cudatoolkit/include -L/nix/store/513wmrnwa8lmc3ay44plqp6i2jysd50g-system-path/lib -L/nix/store/rdhnkz8djgv74ms6iajm694byw236i11-cudatoolkit/lib

LDLIBS   += -lcudart -lnvToolsExt -lcuda


#
# NVCC compilation
#

# NOTE: passing -lcuda to nvcc is redundant, and shouldn't happen via -Xcompiler
# TODO: pass all CXXFLAGS to nvcc using -Xcompiler (i.e. -O3, -g, etc.)
NONCUDA_LDLIBS = $(filter-out -lcuda -lcudart,$(LDLIBS))

ifneq ($(strip $(NONCUDA_LDLIBS)),)
NVCC_LDLIBS += -Xcompiler $(call join-list,$(NONCUDA_LDLIBS),$(COMMA))
endif
NVCC_LDLIBS += -lcuda -lnvToolsExt

#NVCCFLAGS += --generate-line-info
#ifdef DEBUG
#NVCCFLAGS += -g --device-debug
#endif

%: %.cu
	$(NVCC) $(CPPFLAGS) $(NVCCFLAGS) $(NVCC_LDLIBS) -o $@ $^

%.o: %.cu
	$(NVCC) $(CPPFLAGS) $(NVCCFLAGS) -c -o $@ $<

%.ptx: %.cu
	$(NVCC) $(CPPFLAGS) $(NVCCFLAGS) -ptx -o $@ $<
