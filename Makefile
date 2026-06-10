DEVICE    = up5k
PACKAGE   = uwg30
BUILD_DIR = build
SRCS      = $(wildcard ./src/*.v) $(wildcard ./src/*/*.v)
PCF       = ./src/constraints.pcf

BINS = $(BUILD_DIR)/xnor_popcount_unmasked.bin $(BUILD_DIR)/xnor_popcount_masked_xnor.bin $(BUILD_DIR)/xnor_popcount_all_masked.bin

.PHONY: all sim clean

all: $(BINS)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/xnor_popcount_unmasked.json: $(SRCS) | $(BUILD_DIR)
	yosys -p "synth_ice40 -top top_unmasked -json $@" $(SRCS)

$(BUILD_DIR)/xnor_popcount_unmasked.asc: $(BUILD_DIR)/xnor_popcount_unmasked.json $(PCF)
	nextpnr-ice40 --$(DEVICE) --package $(PACKAGE) \
	    --json $< --pcf $(PCF) --asc $@

$(BUILD_DIR)/xnor_popcount_unmasked.bin: $(BUILD_DIR)/xnor_popcount_unmasked.asc
	icepack $< $@

# Masked version
$(BUILD_DIR)/xnor_popcount_masked_xnor.json: $(SRCS) | $(BUILD_DIR)
	yosys -p "synth_ice40 -top top_xnor_masked -json $@" $(SRCS)

$(BUILD_DIR)/xnor_popcount_masked_xnor.asc: $(BUILD_DIR)/xnor_popcount_masked_xnor.json $(PCF)
	nextpnr-ice40 --$(DEVICE) --package $(PACKAGE) \
	    --json $< --pcf $(PCF) --asc $@

$(BUILD_DIR)/xnor_popcount_masked_xnor.bin: $(BUILD_DIR)/xnor_popcount_masked_xnor.asc
	icepack $< $@

# All masked version (with dynamic TRNG masks)
$(BUILD_DIR)/xnor_popcount_all_masked.json: $(SRCS) | $(BUILD_DIR)
	yosys -p "synth_ice40 -top top_all_masked -json $@" $(SRCS)

$(BUILD_DIR)/xnor_popcount_all_masked.asc: $(BUILD_DIR)/xnor_popcount_all_masked.json $(PCF)
	nextpnr-ice40 --$(DEVICE) --package $(PACKAGE) \
	    --json $< --pcf $(PCF) --asc $@

$(BUILD_DIR)/xnor_popcount_all_masked.bin: $(BUILD_DIR)/xnor_popcount_all_masked.asc
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
