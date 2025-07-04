TOPNAME = npc
BUILD_DIR = ./build
SIM_DIR = $(abspath ./sim)
OBJ_DIR = $(BUILD_DIR)/obj_dir
SIM_OBJ_DIR = $(SIM_DIR)/obj_dir
BIN = $(BUILD_DIR)/V$(TOPNAME)
DEBUG_BIN = $(BUILD_DIR)/V$(TOPNAME)_debug
INC_PATH += $(abspath ./csrc/include) $(abspath ./tools/capstone/repo/include)

$(shell mkdir -p $(BUILD_DIR))
$(shell mkdir -p $(SIM_DIR) $(SIM_OBJ_DIR))

# Project source
VSRCS=$(shell find $(abspath ./vsrc) -name "*.v" -or -name "*.sv")
CSRCS = $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")
HSRCS = $(shell find $(abspath ./csrc/include) -name "*.h")

LOCAL_ARGS += -d $(CPU_HOME)/core/tools/riscv32-nemu-interpreter-so #-i $(CPU_HOME)/core/image.bin

# Compiler and flags
VERILATOR = verilator
VERILATOR_FLAGS = --cc -D --exe --trace --build -j 4 --x-assign fast --x-initial fast --noassert -I$(CPU_HOME)/core/vsrc/
VERILATOR_FLAGS_RELEASE = $(VERILATOR_FLAGS) -O3
VERILATOR_FLAGS_DEBUG = $(VERILATOR_FLAGS) --debug -O0

INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS_BASE = $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""
CXXFLAGS_RELEASE = $(CXXFLAGS_BASE) -O3
CXXFLAGS_DEBUG = $(CXXFLAGS_BASE) -g -O0
LDFLAGS += -lreadline -ltinfo -ldl -pie

all: run

$(BIN): $(VSRCS) $(CSRCS) $(HSRCS)
	@rm -rf $(OBJ_DIR)
	@echo "Verilating sources for release..."
	@$(VERILATOR) $(VERILATOR_FLAGS_RELEASE) \
		--top-module $(TOPNAME) $(VSRCS) $(CSRCS) \
		$(addprefix -CFLAGS , $(CXXFLAGS_RELEASE)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))

$(DEBUG_BIN): $(VSRCS) $(CSRCS) $(HSRCS)
	@rm -rf $(OBJ_DIR)
	@echo "Verilating sources for debug..."
	@$(VERILATOR) $(VERILATOR_FLAGS_DEBUG) \
		--top-module $(TOPNAME) $(VSRCS) $(CSRCS) \
		$(addprefix -CFLAGS , $(CXXFLAGS_DEBUG)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(DEBUG_BIN))

run: $(BIN)
	@$^ $(ARGS) $(LOCAL_ARGS)

gdb: $(DEBUG_BIN)
	@echo "Starting GDB debugging for Verilator simulator..."
	@gdb --args $^ $(ARGS) $(LOCAL_ARGS)

clean:
	rm -rf $(BUILD_DIR) 

.PHONY: all sim run gdb clean
