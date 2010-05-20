#
# Makefile
#

include vars.mk

.PHONY: all clean distclean

all: linux-headers libgmp libmpfr binutils gcc-static glibc gcc-final test

clean: linux-headers-clean libgmp-clean libmpfr-clean binutils-clean gcc-static-clean glibc-clean gcc-final-clean test-clean

distclean: clean linux-headers-distclean libgmp-distclean libmpfr-distclean binutils-distclean gcc-static-distclean glibc-distclean gcc-final-distclean test-distclean


# LINUX HEADERS
$(WORK)/linux-$(KERNEL_HEADERS_VERSION).tar.bz2:
	wget -P $(WORK) -c ftp://ftp.kernel.org/pub/linux/kernel/v2.6/linux-$(KERNEL_HEADERS_VERSION).tar.bz2

$(WORK)/linux-$(KERNEL_HEADERS_VERSION): $(WORK)/linux-$(KERNEL_HEADERS_VERSION).tar.bz2
	tar -C $(WORK) -xvjf $(WORK)/linux-$(KERNEL_HEADERS_VERSION).tar.bz2
	touch $(WORK)/linux-$(KERNEL_HEADERS_VERSION)

$(CLFS)/usr/include/asm: $(WORK)/linux-$(KERNEL_HEADERS_VERSION)
	mkdir -p $(CLFS)/usr/include
	cd $(WORK)/linux-$(KERNEL_HEADERS_VERSION) && \
		make mrproper && \
		make ARCH=arm headers_check && \
		make ARCH=arm INSTALL_HDR_PATH=$(CLFS)/usr headers_install
	touch $(CLFS)/usr/include/asm

linux-headers: $(CLFS)/usr/include/asm

linux-headers-clean:
	rm -vrf $(WORK)/linux-$(KERNEL_HEADERS_VERSION)

linux-headers-distclean: linux-headers-clean
	rm -vf $(WORK)/linux-$(KERNEL_HEADERS_VERSION).tar.bz2


# LIBGMP
$(WORK)/gmp-$(LIBGMP_VERSION).tar.bz2:
	wget -P $(WORK) -c ftp://ftp.gnu.org/gnu/gmp/gmp-$(LIBGMP_VERSION).tar.bz2

$(WORK)/gmp-$(LIBGMP_VERSION): $(WORK)/gmp-$(LIBGMP_VERSION).tar.bz2
	tar -C $(WORK) -xvjf $(WORK)/gmp-$(LIBGMP_VERSION).tar.bz2
	touch $(WORK)/gmp-$(LIBGMP_VERSION)

$(WORK)/build-libgmp: $(WORK)/gmp-$(LIBGMP_VERSION)
	mkdir -p $(WORK)/build-libgmp
	touch $(WORK)/build-libgmp

$(CROSSTOOLS)/lib/libgmp.so: $(WORK)/build-libgmp
	cd $(WORK)/build-libgmp && \
		unset CFLAGS && unset CXXFLAGS && \
		CPPFLAGS=-fexceptions \
		$(WORK)/gmp-$(LIBGMP_VERSION)/configure --prefix=$(CROSSTOOLS) --enable-cxx && \
		make && make install || exit 1
	touch $(CROSSTOOLS)/lib/libgmp.so

libgmp: $(CROSSTOOLS)/lib/libgmp.so

libgmp-clean:
	rm -vrf $(WORK)/build-libgmp $(WORK)/gmp-$(LIBGMP_VERSION)

libgmp-distclean: libgmp-clean
	rm -vrf $(WORK)/gmp-$(LIBGMP_VERSION).tar.bz2


# LIBMPFR
$(WORK)/mpfr-$(LIBMPFR_VERSION).tar.bz2:
	wget -P $(WORK) -c http://www.mpfr.org/mpfr-current/mpfr-$(LIBMPFR_VERSION).tar.bz2

$(WORK)/mpfr-$(LIBMPFR_VERSION): $(WORK)/mpfr-$(LIBMPFR_VERSION).tar.bz2
	tar -C $(WORK) -xvjf $(WORK)/mpfr-$(LIBMPFR_VERSION).tar.bz2
	touch $(WORK)/mpfr-$(LIBMPFR_VERSION)

$(WORK)/build-libmpfr: $(WORK)/mpfr-$(LIBMPFR_VERSION)
	mkdir -p $(WORK)/build-libmpfr
	touch $(WORK)/build-libmpfr

$(CROSSTOOLS)/lib/libmpfr.so: $(WORK)/build-libmpfr
	cd $(WORK)/build-libmpfr && \
		unset CFLAGS && unset CXXFLAGS && \
		LDFLAGS="-Wl,-rpath,$(CROSSTOOLS)/lib" && \
		$(WORK)/mpfr-$(LIBMPFR_VERSION)/configure --prefix=$(CROSSTOOLS) --enable-shared --with-gmp=$(CROSSTOOLS) && \
		make && make install || exit 1
	touch $(CROSSTOOLS)/lib/libmpfr.so

libmpfr: $(CROSSTOOLS)/lib/libmpfr.so

libmpfr-clean:
	rm -vrf $(WORK)/build-libmpfr $(WORK)/mpfr-$(LIBMPFR_VERSION)

libmpfr-distclean: libmpfr-clean
	rm -vrf $(WORK)/mpfr-$(LIBMPFR_VERSION).tar.bz2


# BINUTILS
$(WORK)/binutils-$(BINUTILS_VERSION).tar.bz2:
	wget -P $(WORK) -c ftp://ftp.gnu.org/gnu/binutils/binutils-$(BINUTILS_VERSION).tar.bz2

$(WORK)/binutils-$(BINUTILS_VERSION): $(WORK)/binutils-$(BINUTILS_VERSION).tar.bz2 $(WORK)/binutils-$(BINUTILS_VERSION)-branch_update-5.patch
	tar -C $(WORK) -xvjf $(WORK)/binutils-$(BINUTILS_VERSION).tar.bz2
	cd $(WORK)/binutils-$(BINUTILS_VERSION) && \
		patch -p1 -i $(WORK)/binutils-$(BINUTILS_VERSION)-branch_update-5.patch
	sed -i '/^SUBDIRS/s/doc//' $(WORK)/binutils-$(BINUTILS_VERSION)/*/Makefile.in
	touch $(WORK)/binutils-$(BINUTILS_VERSION)

$(WORK)/build-binutils: $(WORK)/binutils-$(BINUTILS_VERSION)
	mkdir -p $(WORK)/build-binutils
	touch $(WORK)/build-binutils-build

$(CLFS)/usr/include/libiberty.h: $(WORK)/build-binutils
	cd $(WORK)/build-binutils && \
		unset CFLAGS && unset CXXFLAGS && \
		AR=ar AS=as \
		$(WORK)/binutils-$(BINUTILS_VERSION)/configure --prefix=$(CROSSTOOLS) \
		--host=$(HOST) --target=$(TARGET) --with-sysroot=$(CLFS) \
		--disable-nls --enable-shared --disable-multilib --nfp && \
		make configure-host && make && make install || exit 1
	cp -va $(WORK)/binutils-$(BINUTILS_VERSION)/include/libiberty.h $(CLFS)/usr/include
	touch $(CLFS)/usr/include/libiberty.h
		
binutils: linux-headers $(CLFS)/usr/include/libiberty.h

binutils-clean:
	rm -vrf $(WORK)/build-binutils $(WORK)/binutils-$(BINUTILS_VERSION)

binutils-distclean: binutils-clean
	rm -f $(WORK)/binutils-$(BINUTILS_VERSION).tar.bz2


# GCC-STATIC
$(WORK)/gcc-$(GCC_VERSION).tar.bz2:
	wget -P $(WORK) -c ftp://sources.redhat.com/pub/gcc/releases/gcc-$(GCC_VERSION)/gcc-$(GCC_VERSION).tar.bz2

$(WORK)/gcc-$(GCC_VERSION): $(WORK)/gcc-$(GCC_VERSION).tar.bz2
	tar -C $(WORK) -xvjf $(WORK)/gcc-$(GCC_VERSION).tar.bz2
	touch $(WORK)/gcc-$(GCC_VERSION)

$(WORK)/build-gcc-static: $(WORK)/gcc-$(GCC_VERSION)
	mkdir -p $(WORK)/build-gcc-static
	touch $(WORK)/build-gcc-static

$(CROSSTOOLS)/lib/gcc: $(WORK)/build-gcc-static $(WORK)/gcc-$(GCC_VERSION)
	cd $(WORK)/build-gcc-static && \
		unset CFLAGS && unset CXXFLAGS && \
		AR=ar LDFLAGS="-Wl,-rpath,$(CROSSTOOLS)/lib" \
		$(WORK)/gcc-$(GCC_VERSION)/configure --prefix=$(CROSSTOOLS) \
		--build=$(HOST) --host=$(HOST) --target=$(TARGET) \
		--disable-multilib --disable-nls \
		--without-headers --enable-__cxa_atexit --enable-symvers=gnu --disable-decimal-float \
		--nfp --without-fp --with-softfloat-support=internal \
		--disable-libgomp --disable-libmudflap --disable-libssp \
		--with-mpfr=$(CROSSTOOLS) --with-gmp=$(CROSSTOOLS) \
		--disable-shared --disable-threads --enable-languages=c && \
		make && make install || exit 1
	touch $(CROSSTOOLS)/lib/gcc

gcc-static: linux-headers libgmp libmpfr binutils $(CROSSTOOLS)/lib/gcc

gcc-static-clean:
	rm -vrf $(WORK)/build-gcc-static $(WORK)/gcc-$(GCC_VERSION)

gcc-static-distclean: gcc-static-clean
	rm -vf $(WORK)/gcc-$(GCC_VERSION).tar.bz2


# GLIBC
$(WORK)/glibc-$(GLIBC_VERSION).tar.bz2:
	wget -P $(WORK) -c ftp://ftp.gnu.org/gnu/glibc/glibc-$(GLIBC_VERSION).tar.bz2

$(WORK)/glibc-ports-$(GLIBC_VERSION).tar.bz2:
	wget -P $(WORK) -c ftp://ftp.gnu.org/gnu/glibc/glibc-ports-$(GLIBC_VERSION).tar.bz2
$(WORK)/glibc-$(GLIBC_VERSION): $(WORK)/glibc-$(GLIBC_VERSION).tar.bz2 $(WORK)/glibc-ports-$(GLIBC_VERSION).tar.bz2

	tar -C $(WORK) -xvjf $(WORK)/glibc-$(GLIBC_VERSION).tar.bz2
	cd $(WORK)/glibc-$(GLIBC_VERSION) && \
		tar xvjf $(WORK)/glibc-ports-$(GLIBC_VERSION).tar.bz2 && \
		mv glibc-ports-$(GLIBC_VERSION) ports && \
		sed -e 's/-lgcc_eh//g' -i Makeconfig
	touch $(WORK)/glibc-$(GLIBC_VERSION)

$(WORK)/build-glibc: $(WORK)/glibc-$(GLIBC_VERSION)
	mkdir -p $(WORK)/build-glibc
	touch $(WORK)/build-glibc
	
$(CLFS)/usr/lib/libc.so: $(WORK)/build-glibc $(WORK)/glibc-$(GLIBC_VERSION)
	cd $(WORK)/build-glibc && \
		export PATH=$(CROSSTOOLS)/bin:$$PATH && \
		echo "libc_cv_forced_unwind=yes" > config.cache && \
		echo "libc_cv_c_cleanup=yes" >> config.cache && \
		echo "libc_cv_gnu89_inline=yes" >> config.cache && \
		echo "install_root=$(CLFS)" > configparms && \
		unset CFLAGS && unset CXXFLAGS && \
		BUILD_CC="gcc" CC="$(TARGET)-gcc" AR="$(TARGET)-ar" \
		RANLIB="$(TARGET)-ranlib" \
		$(WORK)/glibc-$(GLIBC_VERSION)/configure --prefix=/usr \
		--libexecdir=/usr/lib/glibc --host=$(TARGET) --build=$(HOST) \
		--disable-profile --enable-add-ons --with-tls --enable-kernel=2.6.0 \
		--with-__thread --with-binutils=$(CROSSTOOLS)/bin --with-fp=no \
		--with-headers=$(CLFS)/usr/include --cache-file=config.cache && \
		make && make install || exit 1
	touch $(CLFS)/usr/lib/libc.so

glibc: binutils gcc-static $(CLFS)/usr/lib/libc.so

glibc-clean:
	rm -vrf $(WORK)/build-glibc $(WORK)/glibc-$(GLIBC_VERSION)

glibc-distclean: glibc-clean
	rm -vf $(WORK)/glibc-$(GLIBC_VERSION).tar.bz2 $(WORK)/glibc-ports-$(GLIBC_VERSION).tar.bz2


# GCC-FINAL
$(WORK)/build-gcc-final: $(WORK)/gcc-$(GCC_VERSION)
	mkdir -p $(WORK)/build-gcc-final
	touch $(WORK)/build-gcc-final

$(CLFS)/lib/gcc: $(WORK)/build-gcc-final $(WORK)/gcc-$(GCC_VERSION)
	cd $(WORK)/build-gcc-final && \
		export PATH=$$PATH:$(CROSSTOOLS)/bin && \
		unset CFLAGS && unset CXXFLAGS && unset CC && \
		AR=ar LDFLAGS="-Wl,-rpath,$(CROSSTOOLS)/lib" \
		$(WORK)/gcc-$(GCC_VERSION)/configure --prefix=$(CROSSTOOLS) \
		--build=$(HOST) --host=$(HOST) --target=$(TARGET) \
		-with-fp=no --with-headers=$(CLFS)/usr/include \
		--disable-multilib --with-sysroot=$(CLFS) --disable-nls \
		--enable-languages=c,c++ --enable-__cxa_atexit \
		--with-mpfr=$(CROSSTOOLS) --with-gmp=$(CROSSTOOLS) \
		--enable-c99 --enable-long-long --enable-threads=posix && \
		make AS_FOR_TARGET="$(TARGET)-as" LD_FOR_TARGET="$(TARGET)-ld" && \
		make install || exit 1
	touch $(CLFS)/lib/gcc
		
gcc-final: libgmp libmpfr glibc $(CLFS)/lib/gcc

gcc-final-clean:
	rm -vrf $(WORK)/build-gcc-final $(WORK)/gcc-$(GCC_VERSION)

gcc-final-distclean: gcc-final-clean
	rm -vf $(WORK)/gcc-$(GCC_VERSION).tar.bz2


# TEST THE TOOLCHAIN
$(WORK)/test: $(WORK)/test.c
	export PATH=$$PATH:$(CROSSTOOLS)/bin && \
	unset CFLAGS && unset CXXFLAGS && unset CC && \
	AR=ar LDFLAGS="-Wl,-rpath,$(CROSSTOOLS)/lib" \
	$(TARGET)-gcc -Wall -o $(WORK)/test $(WORK)/test.c
	[ "`file -b $(WORK)/test | cut -d',' -f2 | sed 's| ||g'`" = "ARM"  ] || exit 1
	touch $(WORK)/test

test: gcc-final $(WORK)/test

test-clean:
	rm -vrf $(WORK)/test

test-distclean: test-clean

# End of file
