#
# vars.mk
#

HOST = $(shell echo $$MACHTYPE | sed "s/$$(echo $$MACHTYPE | cut -d- -f2)/cross/")
TARGET = arm-crux-linux-gnueabi

PWD  = $(shell pwd)
CLFS = $(PWD)/clfs
CROSSTOOLS = $(PWD)/crosstools
WORK = $(PWD)/work

KERNEL_HEADERS_VERSION = 2.6.35.6
LIBGMP_VERSION = 5.0.1
LIBMPFR_VERSION = 3.0.0
LIBMPC_VERSION = 0.8.2
BINUTILS_VERSION = 2.20.1
GCC_VERSION = 4.5.2
GLIBC_VERSION = 2.12.1

# End of file
