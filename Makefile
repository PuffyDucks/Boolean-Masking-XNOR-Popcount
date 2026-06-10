PROJ      = module
TOP       = top_unmasked
DEVICE    = up5k
PACKAGE   = uwg30

BUILD_DIR = build

SRCS      = $(wildcard ./src/*.v) $(wildcard ./src/*/*.v)
PCF       = ./src/constraints.pcf

JSON      = $(BUILD_DIR)/$(PROJ).json
ASC       = $(BUILD_DIR)/$(PROJ).asc
BIN       = $(BUILD_DIR)/$(PROJ).bin

.PHONY: all sim clean

all: $(BIN)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(JSON): $(SRCS) | $(BUILD_DIR)
	yosys -p "synth_ice40 -top $(TOP) -json $@" $(SRCS)

$(ASC): $(JSON) $(PCF)
	nextpnr-ice40 --$(DEVICE) --package $(PACKAGE) \
	    --json $(JSON) --pcf $(PCF) --asc $@

$(BIN): $(ASC)
	icepack $< $@

clean:
	rm -rf $(BUILD_DIR)

# SIMULATION
SIM_DIR = sim
SIM_VVP = $(SIM_DIR)/tb_top.vvp
SIM_FST = $(SIM_DIR)/tb_top.fst

sim: $(SIM_FST)

$(SIM_VVP): $(SIM_DIR)/tb_top.v $(SRCS) | $(SIM_DIR)
	iverilog -g2012 -Wall -o $@ $^

$(SIM_FST): $(SIM_VVP)
	cd $(SIM_DIR) && vvp tb_top.vvp -fst

$(SIM_DIR):
	mkdir -p $(SIM_DIR)
