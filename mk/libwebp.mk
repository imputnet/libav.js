LIBWEBP_VERSION=1.4.0

build/inst/%/lib/pkgconfig/libwebp.pc: build/libwebp-$(LIBWEBP_VERSION)/build-%/config.h
	cd build/libwebp-$(LIBWEBP_VERSION)/build-$* && \
		$(MAKE) install

build/libwebp-$(LIBWEBP_VERSION)/build-%/config.h: build/libwebp-$(LIBWEBP_VERSION)/configure | build/inst/%/cflags.txt
	mkdir -p build/libwebp-$(LIBWEBP_VERSION)/build-$*
	cd build/libwebp-$(LIBWEBP_VERSION)/build-$* && \
		emconfigure ../../libwebp-$(LIBWEBP_VERSION)/configure \
			--prefix="$(PWD)/build/inst/$*" --host=mipsel-sysv \
			--disable-shared --disable-png --disable-jpeg \
			--disable-tiff --disable-gif --disable-wic \
			CFLAGS="$(OPTFLAGS) `cat $(PWD)/build/inst/$*/cflags.txt`"
	touch $@

extract: build/libwebp-$(LIBWEBP_VERSION)/configure

build/libwebp-$(LIBWEBP_VERSION)/configure: build/libwebp-$(LIBWEBP_VERSION).tar.gz
	cd build && tar zxf libwebp-$(LIBWEBP_VERSION).tar.gz
	touch $@

build/libwebp-$(LIBWEBP_VERSION).tar.gz:
	mkdir -p build
	curl https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-$(LIBWEBP_VERSION).tar.gz -L -o $@

libwebp-release:
	cp build/libwebp-$(LIBWEBP_VERSION).tar.gz dist/release/libav.js-$(LIBAVJS_VERSION)/sources/

.PRECIOUS: \
	build/inst/%/lib/pkgconfig/libwebp.pc \
	build/libwebp-$(LIBWEBP_VERSION)/build-%/config.h \
	build/libwebp-$(LIBWEBP_VERSION)/configure
