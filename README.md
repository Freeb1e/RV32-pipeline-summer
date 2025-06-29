## RV32I CPU 设计和验证

This project runs at `Ubuntu 22.04`.

RTL designs are located at `core/vsrc`.

### Initialization
**run initialzation script**

First, switch to folder `RV32-CPU` and run:
```
bash init.sh
source ~/.bashrc
```
Then try

```
$CPU_HOME
$NPC_HOME
$AM_HOME
```
to check whether env variables are right.

Install necessary files before simulation:

**install verilator**

[check verilator manual](https://verilator.org/guide/latest/install.html)

Noticed that your verilator version must be `v5.008` or later.

**install dependant libraries**

```
sudo apt install -y libreadline-dev g++-riscv64-linux-gnu binutils-riscv64-linux-gnu python3 python3-pip python-is-python3
```

**run example program**
```
cd $CPU_HOME/core
make sim
```

### Run tests

Before running tests, some modification must be done.

```
--- /usr/riscv64-linux-gnu/include/gnu/stubs.h
+++ /usr/riscv64-linux-gnu/include/gnu/stubs.h
@@ -5,5 +5,5 @@
 #include <bits/wordsize.h>

 #if __WORDSIZE == 32 && defined __riscv_float_abi_soft
-# include <gnu/stubs-ilp32.h>
+//# include <gnu/stubs-ilp32.h>
 #endif
```

Above is a [diff format](https://ruanyifeng.com/blog/2012/08/how_to_read_diff.html) text. You need to modify the text by yourself. The row location of codes may be not accurate. In this case, `find` might be very useful.

> A simple way to modify the file:
> type `sudo nano /usr/riscv64-linux-gnu/include/gnu/stubs.h`
> 

We prepared some tests program in `tests/tests`.

If you want to run any of them, run commands below:
```
cd $CPU_HOME/tests
make run ARCH=riscv32e-npc ALL=<your_tests_name>
```

If `ALL` is not specified, the program defaults to test all the C files in `tests/`

also, you can run your own testfile by adding it into `tests/`:

For example, you create a testfile called `mytest.c`. After adding it to `tests/` directory, you can run
```
make run ARCH=riscv32e-npc ALL=mytest
```
to run your own test.

If using simple debugger while testing is intended, you can modify file `$CPU_HOME/abstract-machine/scripts/platform/npc.mk` by removing the `-b` arg in line 15.

### Setup CPU Configuration

There are some optional configs in CPU simulations. If you want to activate or deactivate any, check out `core/csrc/include/config.h`.
