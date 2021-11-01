# test case description file generator
# 'descgen.py' is in repository 'minic-grader'
DESC_GEN ?= descgen.py

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
LIB_DIR := $(TOP_DIR)/sysy-runtime-lib
FUNC_TEST_DIR := $(TOP_DIR)/functional
PERF_TEST_DIR := $(TOP_DIR)/performance

# files
SYSY_LIB := $(BUILD_DIR)/sylib.o
TEST_SRC := $(wildcard $(FUNC_TEST_DIR)/*.c) $(wildcard $(PERF_TEST_DIR)/*.c)
TEST_SRC_COPY := $(patsubst $(TOP_DIR)/%.c, $(BUILD_DIR)/%.c, $(TEST_SRC))
TEST_IN := $(wildcard $(FUNC_TEST_DIR)/*.in) $(wildcard $(PERF_TEST_DIR)/*.in)
TEST_IN_COPY := $(patsubst $(TOP_DIR)/%.in, $(BUILD_DIR)/%.in, $(TEST_IN))
TEST_EXEC := $(patsubst $(TOP_DIR)/%.c, $(BUILD_DIR)/%, $(TEST_SRC))
TEST_OUT := $(patsubst $(TOP_DIR)/%.c, $(BUILD_DIR)/%.out, $(TEST_SRC))
DESC_FILE := $(BUILD_DIR)/testcases.json
TEST_CASE_FILES := $(patsubst $(TOP_DIR)/%.c, %.c, $(TEST_SRC))
TEST_CASE_FILES += $(patsubst $(TOP_DIR)/%.in, %.in, $(TEST_IN))
TEST_CASE_FILES += $(patsubst $(TOP_DIR)/%.c, %.out, $(TEST_SRC))
TEST_CASE_FILES += testcases.json
TEST_CASES := $(BUILD_DIR)/testcases.tar.gz


.PHONY: all clean

all: $(BUILD_DIR) $(TEST_CASES)

clean:
	-rm $(SYSY_LIB) $(TEST_SRC_COPY) $(TEST_IN_COPY) $(TEST_OUT) $(DESC_FILE) $(TEST_CASES)

$(BUILD_DIR):
	-mkdir $@

$(TEST_CASES): $(TEST_SRC_COPY) $(TEST_IN_COPY) $(TEST_OUT) $(DESC_FILE)
	tar -czf $@ -C $(BUILD_DIR) $(TEST_CASE_FILES)

$(DESC_FILE): $(TEST_SRC_COPY) $(TEST_IN_COPY) $(TEST_OUT)
	$(DESC_GEN) -d $(BUILD_DIR) -f functional -p performance -ce ".c" -o $@

$(BUILD_DIR)/%.c: $(TOP_DIR)/%.c
	-mkdir -p $(dir $@)
	cp $^ $@

$(BUILD_DIR)/%.in: $(TOP_DIR)/%.in
	-mkdir -p $(dir $@)
	cp $^ $@

$(BUILD_DIR)/%: $(TOP_DIR)/%.c $(SYSY_LIB)
	-mkdir -p $(dir $@)
	$(CC) $^ -o $@

$(BUILD_DIR)/%.o: $(LIB_DIR)/%.c
	clang $^ -o $@ -c

$(BUILD_DIR)/%.out: $(BUILD_DIR)/% $(TOP_DIR)/%.in
	-mkdir -p $(dir $@)
	$< < $(word 2, $^) > $@; ret=$$?; if [ -z "$$(tail -c 1 "$@")" ]; then echo "$$ret" >> "$@"; else printf "\n$$ret\n" >> "$@"; fi

$(BUILD_DIR)/%.out: $(BUILD_DIR)/%
	-mkdir -p $(dir $@)
	$^ > $@; ret=$$?; if [ -z "$$(tail -c 1 "$@")" ]; then echo "$$ret" >> "$@"; else printf "\n$$ret\n" >> "$@"; fi
