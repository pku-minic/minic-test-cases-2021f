# test case description file generator
# 'descgen.py' is in repository 'minic-grader'
DESC_GEN ?= descgen.py

# Eeyore/Tigger file generator
ET_GEN ?= compiler

# make build targets
# params: prefix, extension
define make_targets
	$(eval $(strip $1)_TEST_SRC := $(patsubst $(TOP_DIR)/%.c, $($(strip $1)_BUILD_DIR)/%.$(strip $2), $(TEST_SRC)));
	$(eval $(strip $1)_TEST_IN := $(patsubst $(TOP_DIR)/%.in, $($(strip $1)_BUILD_DIR)/%.in, $(TEST_IN)));
	$(eval $(strip $1)_TEST_OUT := $(patsubst $(TOP_DIR)/%.c, $($(strip $1)_BUILD_DIR)/%.out, $(TEST_SRC)));
	$(eval $(strip $1)_DESC_FILE := $($(strip $1)_BUILD_DIR)/testcases.json);
	$(eval $(strip $1)_TEST_CASE_FILES := $(patsubst $(TOP_DIR)/%.c, %.$(strip $2), $(TEST_SRC)));
	$(eval $(strip $1)_TEST_CASE_FILES += $(patsubst $(TOP_DIR)/%.in, %.in, $(TEST_IN)));
	$(eval $(strip $1)_TEST_CASE_FILES += $(patsubst $(TOP_DIR)/%.c, %.out, $(TEST_SRC)));
	$(eval $(strip $1)_TEST_CASE_FILES += testcases.json);
	$(eval $(strip $1)_TEST_CASES := $($(strip $1)_BUILD_DIR)/testcases.tar.gz);
endef

# make build rules
# params: prefix, extension
define make_rules
$$($(strip $1)_TEST_CASES): $$($(strip $1)_TEST_SRC) $$($(strip $1)_TEST_IN) $$($(strip $1)_TEST_OUT) $$($(strip $1)_DESC_FILE)
	-mkdir -p $$(dir $$@)
	tar -czf $$@ -C $$($(strip $1)_BUILD_DIR) $$($(strip $1)_TEST_CASE_FILES)
$$($(strip $1)_DESC_FILE): $$($(strip $1)_TEST_SRC) $$($(strip $1)_TEST_IN) $$($(strip $1)_TEST_OUT)
	-mkdir -p $$(dir $$@)
	$$(DESC_GEN) -d $$($(strip $1)_BUILD_DIR) -f functional -p performance -ce ".$(strip $2)" -o $$@
$$($(strip $1)_BUILD_DIR)/%.in: $$(TOP_DIR)/%.in
	-mkdir -p $$(dir $$@)
	cp $$^ $$@
endef

# C compiler
CFLAGS := -Wall -Werror -Wno-implicit-function-declaration -Wno-unused-variable
CFLAGS += -Wno-unused-value -Wno-dangling-else -Wno-logical-op-parentheses
CFLAGS += -Wno-empty-body -Wno-tautological-compare -Wno-missing-braces
CFLAGS += -Wno-constant-logical-operand
CFLAGS += -Dstarttime=_sysy_starttime -Dstoptime=_sysy_stoptime -O2
CFLAGS += -fsanitize=address -fsanitize=undefined
CC := clang $(CFLAGS)

# directories
TOP_DIR := $(shell pwd)
BUILD_DIR := $(TOP_DIR)/build
C_BUILD_DIR := $(BUILD_DIR)/c
EEYORE_BUILD_DIR := $(BUILD_DIR)/eeyore
TIGGER_BUILD_DIR := $(BUILD_DIR)/tigger
LIB_DIR := $(TOP_DIR)/sysy-runtime-lib
FUNC_TEST_DIR := $(TOP_DIR)/functional
PERF_TEST_DIR := $(TOP_DIR)/performance

# files
SYSY_LIB := $(BUILD_DIR)/sylib.o
TEST_SRC := $(wildcard $(FUNC_TEST_DIR)/*.c) $(wildcard $(PERF_TEST_DIR)/*.c)
TEST_IN := $(wildcard $(FUNC_TEST_DIR)/*.in) $(wildcard $(PERF_TEST_DIR)/*.in)

# targets
$(call make_targets, C, c)
$(call make_targets, EEYORE, eeyore)
$(call make_targets, TIGGER, tigger)


.PHONY: all clean

all: $(C_TEST_CASES) $(EEYORE_TEST_CASES) $(TIGGER_TEST_CASES)

clean:
	-rm $(SYSY_LIB)
	-rm -rf $(C_BUILD_DIR) $(EEYORE_BUILD_DIR) $(TIGGER_BUILD_DIR)

$(eval $(call make_rules, C, c))
$(eval $(call make_rules, EEYORE, eeyore))
$(eval $(call make_rules, TIGGER, tigger))

$(C_BUILD_DIR)/%.c: $(TOP_DIR)/%.c
	-mkdir -p $(dir $@)
	cp $^ $@

$(C_BUILD_DIR)/%.out: $(C_BUILD_DIR)/% $(TOP_DIR)/%.in
	-mkdir -p $(dir $@)
	$< < $(word 2, $^) > $@; ret=$$?; if [ -z "$$(tail -c 1 "$@")" ]; then echo "$$ret" >> "$@"; else printf "\n$$ret\n" >> "$@"; fi

$(C_BUILD_DIR)/%.out: $(C_BUILD_DIR)/%
	-mkdir -p $(dir $@)
	$^ > $@; ret=$$?; if [ -z "$$(tail -c 1 "$@")" ]; then echo "$$ret" >> "$@"; else printf "\n$$ret\n" >> "$@"; fi

$(C_BUILD_DIR)/%: $(TOP_DIR)/%.c $(SYSY_LIB)
	-mkdir -p $(dir $@)
	$(CC) $^ -o $@

$(BUILD_DIR)/%.o: $(LIB_DIR)/%.c
	-mkdir -p $(dir $@)
	clang $^ -o $@ -c

$(EEYORE_BUILD_DIR)/%.eeyore: $(TOP_DIR)/%.c
	-mkdir -p $(dir $@)
	$(ET_GEN) -S -e $^ -o $@

$(EEYORE_BUILD_DIR)/%.out: $(C_BUILD_DIR)/%.out
	-mkdir -p $(dir $@)
	cp $^ $@

$(TIGGER_BUILD_DIR)/%.tigger: $(TOP_DIR)/%.c
	-mkdir -p $(dir $@)
	$(ET_GEN) -S -t $^ -o $@

$(TIGGER_BUILD_DIR)/%.out: $(C_BUILD_DIR)/%.out
	-mkdir -p $(dir $@)
	cp $^ $@
