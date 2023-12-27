#
# vars.mk
#

HOST = $(shell echo $$MACHTYPE | sed "s/$$(echo $$MACHTYPE | cut -d- -f2)/cross/")
TARGET = arm-crux-linux-gnueabi

PWD  = $(shell pwd)
CLFS = $(PWD)/clfs
CROSSTOOLS = $(PWD)/crosstools
WORK = $(PWD)/work

KERNEL_HEADERS_VERSION = 3.5.4
LIBGMP_VERSION = 5.0.5
LIBMPFR_VERSION = 3.1.1
LIBMPC_VERSION = 1.0.1
BINUTILS_VERSION = 2.22
GCC_VERSION = 4.7.2
GLIBC_VERSION = 2.16.0

# End of file
