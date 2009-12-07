#
# vars.mk
#

HOST = $(shell echo $$MACHTYPE | sed "s/$$(echo $$MACHTYPE | cut -d- -f2)/cross/")
TARGET = arm-unknown-linux-gnu

PWD  = $(shell pwd)
CLFS = $(PWD)/clfs
CROSSTOOLS = $(PWD)/crosstools
WORK = $(PWD)/work

KERNEL_HEADERS_VERSION = 2.6.30.1
LIBGMP_VERSION = 4.3.1
LIBMPFR_VERSION = 2.4.2
BINUTILS_VERSION = 2.19.1
GCC_VERSION = 4.4.2
GLIBC_VERSION = 2.10.1

# End of file
