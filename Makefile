PROJ      = module
TOP       = top
DEVICE    = up5k
PACKAGE   = uwg30

SRC_DIR   = src
BUILD_DIR = build

SOURCES   = $(wildcard $(SRC_DIR)/*.v)
PCF       = $(SRC_DIR)/constraints.pcf

JSON      = $(BUILD_DIR)/$(PROJ).json
ASC       = $(BUILD_DIR)/$(PROJ).asc
BIN       = $(BUILD_DIR)/$(PROJ).bin

.PHONY: all sim clean

all: $(BIN)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(JSON): $(SOURCES) | $(BUILD_DIR)
	yosys -p "synth_ice40 -top $(TOP) -json $@" $(SOURCES)

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

$(SIM_VVP): $(SIM_DIR)/tb_top.v $(SOURCES) | $(SIM_DIR)
	iverilog -g2012 -Wall -o $@ $^

$(SIM_FST): $(SIM_VVP)
	cd $(SIM_DIR) && vvp tb_top.vvp -fst

$(SIM_DIR):
	mkdir -p $(SIM_DIR)
