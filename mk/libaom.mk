

# NOTE: This file is generated by m4! Make sure you're editing the .m4 version,
# not the generated version!

# 3.11.0
LIBAOM_VERSION=7cbb7eb5f

build/inst/%/lib/pkgconfig/aom.pc: build/libaom-$(LIBAOM_VERSION)/build-%/Makefile
	cd build/libaom-$(LIBAOM_VERSION)/build-$* && \
		$(MAKE) install

# General build rule for any target
# Use: buildrule(target name, cmake flags)


# Non-threaded

build/libaom-$(LIBAOM_VERSION)/build-base/Makefile: build/libaom-$(LIBAOM_VERSION)/PATCHED | build/inst/base/cflags.txt
	mkdir -p build/libaom-$(LIBAOM_VERSION)/build-base
	cd build/libaom-$(LIBAOM_VERSION)/build-base && \
		emcmake cmake ../../libaom-$(LIBAOM_VERSION) \
		-DCMAKE_INSTALL_PREFIX="$(PWD)/build/inst/base" \
		-DCMAKE_C_FLAGS="-Oz `cat $(PWD)/build/inst/base/cflags.txt`" \
		-DCMAKE_CXX_FLAGS="-Oz `cat $(PWD)/build/inst/base/cflags.txt`" \
		-DAOM_TARGET_CPU=generic \
		-DCMAKE_BUILD_TYPE=Release \
		-DENABLE_DOCS=0 \
		-DENABLE_TESTS=0 \
		-DENABLE_EXAMPLES=0 \
		-DCONFIG_RUNTIME_CPU_DETECT=0 \
		-DCONFIG_WEBM_IO=0 \
                -DCONFIG_MULTITHREAD=0
	touch $(@)

# Threaded

build/libaom-$(LIBAOM_VERSION)/build-thr/Makefile: build/libaom-$(LIBAOM_VERSION)/PATCHED | build/inst/thr/cflags.txt
	mkdir -p build/libaom-$(LIBAOM_VERSION)/build-thr
	cd build/libaom-$(LIBAOM_VERSION)/build-thr && \
		emcmake cmake ../../libaom-$(LIBAOM_VERSION) \
		-DCMAKE_INSTALL_PREFIX="$(PWD)/build/inst/thr" \
		-DCMAKE_C_FLAGS="-Oz `cat $(PWD)/build/inst/thr/cflags.txt`" \
		-DCMAKE_CXX_FLAGS="-Oz `cat $(PWD)/build/inst/thr/cflags.txt`" \
		-DAOM_TARGET_CPU=generic \
		-DCMAKE_BUILD_TYPE=Release \
		-DENABLE_DOCS=0 \
		-DENABLE_TESTS=0 \
		-DENABLE_EXAMPLES=0 \
		-DCONFIG_RUNTIME_CPU_DETECT=0 \
		-DCONFIG_WEBM_IO=0 \
                
	touch $(@)


extract: build/libaom-$(LIBAOM_VERSION)/PATCHED

build/libaom-$(LIBAOM_VERSION)/PATCHED: build/libaom-$(LIBAOM_VERSION)/CMakeLists.txt
	cd build/libaom-$(LIBAOM_VERSION) && ( test -e PATCHED || patch -p1 -i ../../patches/libaom.diff )
	touch $@

build/libaom-$(LIBAOM_VERSION)/CMakeLists.txt: build/libaom-$(LIBAOM_VERSION).tar.gz
	mkdir -p build/libaom-$(LIBAOM_VERSION)
	cd build/libaom-$(LIBAOM_VERSION) && \
		tar zxf ../libaom-$(LIBAOM_VERSION).tar.gz
	touch $@

build/libaom-$(LIBAOM_VERSION).tar.gz:
	mkdir -p build
	curl https://aomedia.googlesource.com/aom/+archive/$(LIBAOM_VERSION).tar.gz -L -o $@

libaom-release:
	cp build/libaom-$(LIBAOM_VERSION).tar.gz dist/release/libav.js-$(LIBAVJS_VERSION)/sources/

.PRECIOUS: \
	build/inst/%/lib/pkgconfig/aom.pc \
	build/libaom-$(LIBAOM_VERSION)/build-%/Makefile \
	build/libaom-$(LIBAOM_VERSION)/PATCHED \
	build/libaom-$(LIBAOM_VERSION)/CMakeLists.txt
