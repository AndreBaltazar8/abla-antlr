ABLAC ?= $(HOME)/.abla/bin/ablac
BUILD_DIR ?= build

.PHONY: all check unit tools g4 conformance fuzz clean

all: check

check: unit tools g4

unit:
	mkdir -p $(BUILD_DIR)
	$(ABLAC) build tests/unit_test.ab -o $(BUILD_DIR)/unit-test
	$(BUILD_DIR)/unit-test

tools:
	mkdir -p $(BUILD_DIR)
	$(ABLAC) build tests/parse_dump.ab -o $(BUILD_DIR)/parse-dump
	$(ABLAC) build tests/atn_dump.ab -o $(BUILD_DIR)/atn-dump
	$(ABLAC) build tests/g4_interp.ab -o $(BUILD_DIR)/g4-interp

g4: tools
	tools/g4_check.sh $(BUILD_DIR)/g4-interp $(BUILD_DIR)/g4

# make conformance LEXER=… PARSER=… LEXER_JS=… PARSER_JS=… RULE=… INPUTS="…"
conformance: tools
	tools/conformance.sh $(LEXER) $(PARSER) $(LEXER_JS) $(PARSER_JS) $(RULE) $(BUILD_DIR)/conformance $(INPUTS)

# make fuzz … SEED=1 COUNT=1000: mutated inputs, compared the same way
fuzz: tools
	rm -rf $(BUILD_DIR)/fuzz-inputs
	bun tools/fuzz.mjs $(PARSER) $(or $(SEED),1) $(or $(COUNT),1000) $(BUILD_DIR)/fuzz-inputs $(INPUTS)
	tools/conformance.sh $(LEXER) $(PARSER) $(LEXER_JS) $(PARSER_JS) $(RULE) $(BUILD_DIR)/fuzz $(BUILD_DIR)/fuzz-inputs/*

clean:
	@if [ -d "$(BUILD_DIR)" ]; then rm -rf "$(BUILD_DIR)"; fi
