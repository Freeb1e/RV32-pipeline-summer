.PHONY: all run gdb clean latest $(ALL)

RESULT = .result
ARCH = riscv32e-npc
$(shell > $(RESULT))

COLOR_RED   = \033[1;31m
COLOR_GREEN = \033[1;32m
COLOR_NONE  = \033[0m

ALL = $(basename $(notdir $(shell find tests/. -name "*.c")))

all: $(addprefix Makefile., $(ALL))
	@echo "test list [$(words $(ALL)) item(s)]:" $(ALL)

$(ALL): %: Makefile.%

Makefile.%: tests/%.c latest
	@/bin/echo -e "NAME = $*\nSRCS = $<\ninclude $${CPU_HOME}/abstract-machine/Makefile" > $@
	cat $@
	@if make -s -f $@ ARCH=$(ARCH) $(MAKECMDGOALS); then \
		printf "[%14s] $(COLOR_GREEN)PASS$(COLOR_NONE)\n" $* >> $(RESULT); \
	else \
		printf "[%14s] $(COLOR_RED)***FAIL***$(COLOR_NONE)\n" $* >> $(RESULT); \
	fi
	-@rm -f Makefile.$*

run: all
	@cat $(RESULT)
	@rm $(RESULT)

gdb: 
	@echo "正在启动GDB调试模式..."
	@if [ -z "$(TEST)" ]; then \
		echo "请指定要调试的测试，例如: make gdb TEST=add"; \
		exit 1; \
	fi
	@/bin/echo -e "NAME = $(TEST)\nSRCS = tests/$(TEST).c\ninclude $${CPU_HOME}/abstract-machine/Makefile" > Makefile.$(TEST)
	@make -s -f Makefile.$(TEST) ARCH=$(ARCH) gdb
	-@rm -f Makefile.$(TEST)

clean:
	rm -rf Makefile.* build/ $(CPU_HOME)/core/build

latest:
