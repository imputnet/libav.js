changequote(`[[[', `]]]')

# NOTE: This file is generated by m4! Make sure you're editing the .m4 version,
# not the generated version!

FFMPEG_VERSION_MAJOR=7
FFMPEG_VERSION_MINREV=0.2
FFMPEG_VERSION=$(FFMPEG_VERSION_MAJOR).$(FFMPEG_VERSION_MINREV)
LIBAVJS_VERSION_SUFFIX=
LIBAVJS_VERSION_BASE=5.4
LIBAVJS_VERSION=$(LIBAVJS_VERSION_BASE).$(FFMPEG_VERSION)$(LIBAVJS_VERSION_SUFFIX)
LIBAVJS_VERSION_SHORT=$(LIBAVJS_VERSION_BASE).$(FFMPEG_VERSION_MAJOR)
EMCC=emcc
MINIFIER=node_modules/.bin/uglifyjs -m
OPTFLAGS=-Oz
NOTHRFLAGS=build/inst/base/lib/libemfiberthreads.a
THRFLAGS=-pthread
ES6FLAGS=-sEXPORT_ES6=1 -sUSE_ES6_IMPORT_META=1
EFLAGS=\
	`tools/memory-init-file-emcc.sh` \
	--pre-js pre.js \
	--post-js build/post.js --extern-post-js extern-post.js \
	-s "EXPORT_NAME='LibAVFactory'" \
	-s "EXPORTED_FUNCTIONS=@build/exports.json" \
	-s "EXPORTED_RUNTIME_METHODS=['ccall', 'cwrap', 'PThread']" \
	-s MODULARIZE=1 \
	-s STACK_SIZE=1048576 \
	-s ASYNCIFY \
	-s "ASYNCIFY_IMPORTS=['libavjs_wait_reader']" \
	-s INITIAL_MEMORY=25165824 \
	-s ALLOW_MEMORY_GROWTH=1

# For debugging:
#EFLAGS+=\
#	-s ASSERTIONS=2 \
#	-s STACK_OVERFLOW_CHECK=2 \
#	-s MALLOC=emmalloc-memvalidate \
#	-s SAFE_HEAP=1

all: build-default

include mk/*.mk


build-%: \
	dist/libav-$(LIBAVJS_VERSION)-%.js \
	dist/libav-%.js \
	dist/libav-$(LIBAVJS_VERSION)-%.mjs \
	dist/libav-%.mjs \
	dist/libav-$(LIBAVJS_VERSION)-%.dbg.js \
	dist/libav-%.dbg.js \
	dist/libav-$(LIBAVJS_VERSION)-%.dbg.mjs \
	dist/libav-%.dbg.mjs \
	dist/libav-$(LIBAVJS_VERSION)-%.asm.js \
	dist/libav-$(LIBAVJS_VERSION)-%.asm.mjs \
	dist/libav-$(LIBAVJS_VERSION)-%.dbg.asm.js \
	dist/libav-$(LIBAVJS_VERSION)-%.dbg.asm.mjs \
	dist/libav-$(LIBAVJS_VERSION)-%.wasm.js \
	dist/libav-$(LIBAVJS_VERSION)-%.wasm.mjs \
	dist/libav-$(LIBAVJS_VERSION)-%.dbg.wasm.js \
	dist/libav-$(LIBAVJS_VERSION)-%.dbg.wasm.mjs \
	dist/libav-$(LIBAVJS_VERSION)-%.thr.js \
	dist/libav-$(LIBAVJS_VERSION)-%.thr.mjs \
	dist/libav-$(LIBAVJS_VERSION)-%.dbg.thr.js \
	dist/libav-$(LIBAVJS_VERSION)-%.dbg.thr.mjs \
	dist/libav.types.d.ts
	true

# Generic rule for frontend builds
# Use: febuildrule(debug infix, target extension, minifier)
define([[[febuildrule]]], [[[
dist/libav-$(LIBAVJS_VERSION)-%$1.$2: build/libav-$(LIBAVJS_VERSION).$2 \
	dist/libav-$(LIBAVJS_VERSION)-%$1.wasm.$2 \
	node_modules/.bin/uglifyjs
	mkdir -p dist
	sed "s/@CONFIG/$(*)/g ; s/@DBG/$1/g" < $< | $3 > $(@)

dist/libav-%$1.$2: dist/libav-$(LIBAVJS_VERSION)-%$1.$2
	cp $(<) $(@)
]]])

febuildrule([[[]]], js, [[[$(MINIFIER)]]])
febuildrule([[[]]], mjs, [[[$(MINIFIER)]]])
febuildrule(.dbg, js, cat)
febuildrule(.dbg, mjs, cat)

dist/libav.types.d.ts: build/libav.types.d.ts
	mkdir -p dist
	cp $< $@

# General build rule for any target
# Use: buildrule(target file name, debug infix, target inst name, CFLAGS, target file suffix)
define([[[buildrule]]], [[[
dist/libav-$(LIBAVJS_VERSION)-%.$2$1.$5: build/ffmpeg-$(FFMPEG_VERSION)/build-$3-%/libavformat/libavformat.a \
	build/exports.json pre.js build/post.js extern-post.js bindings.c
	mkdir -p $(@).d
	$(EMCC) $(OPTFLAGS) $(EFLAGS) $4 \
		-Ibuild/ffmpeg-$(FFMPEG_VERSION) -Ibuild/ffmpeg-$(FFMPEG_VERSION)/build-$3-$(*) \
		`test ! -e configs/configs/$(*)/link-flags.txt || cat configs/configs/$(*)/link-flags.txt` \
		bindings.c \
		`grep LIBAVJS_WITH_CLI configs/configs/$(*)/link-flags.txt > /dev/null 2>&1 && echo ' \
		build/ffmpeg-$(FFMPEG_VERSION)/build-$3-$(*)/fftools/*.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-$3-$(*)/libavdevice/libavdevice.a \
		'` \
		build/ffmpeg-$(FFMPEG_VERSION)/build-$3-$(*)/*/lib*.a \
		`test ! -e configs/configs/$(*)/libs.txt || sed 's/@TARGET/$3/' configs/configs/$(*)/libs.txt` -o $(@).d/libav-$(LIBAVJS_VERSION)-$(*).$2$1.$5
	if [ -e $(@).d/libav-$(LIBAVJS_VERSION)-$(*).$2$1.wasm.map ] ; then \
		./tools/adjust-sourcemap.js $(@).d/libav-$(LIBAVJS_VERSION)-$(*).$2$1.wasm.map \
			ffmpeg $(FFMPEG_VERSION) \
			libvpx $(LIBVPX_VERSION) \
			libaom $(LIBAOM_VERSION); \
	fi || ( rm -f $(@) ; false )
	sed " \
		s/^\/\/.*include:.*// ; \
		s/@VER/$(LIBAVJS_VERSION)/g ; \
		s/@VARIANT/$(*)/g ; \
		s/@TARGET/$1/g ; \
		s/@DBG/$2/g ; \
		s/@JS/$5/g \
	" $(@).d/libav-$(LIBAVJS_VERSION)-$(*).$2$1.$5 | cat configs/configs/$(*)/license.js - > $(@)
	rm -f $(@).d/libav-$(LIBAVJS_VERSION)-$(*).$2$1.$5
	-chmod a-x $(@).d/*.wasm
	-mv $(@).d/* dist/
	rmdir $(@).d
]]])

# asm.js version
buildrule(asm, [[[]]], base, [[[$(NOTHRFLAGS) -s WASM=0]]], js)
buildrule(asm, [[[]]], base, [[[$(NOTHRFLAGS) $(ES6FLAGS) -s WASM=0]]], mjs)
buildrule(asm, dbg., base, [[[$(NOTHRFLAGS) -g2 -s WASM=0]]], js)
buildrule(asm, dbg., base, [[[$(NOTHRFLAGS) -g2 $(ES6FLAGS) -s WASM=0]]], mjs)
# wasm version with no added features
buildrule(wasm, [[[]]], base, [[[$(NOTHRFLAGS)]]], js)
buildrule(wasm, [[[]]], base, [[[$(NOTHRFLAGS) $(ES6FLAGS)]]], mjs)
buildrule(wasm, dbg., base, [[[$(NOTHRFLAGS) -gsource-map]]], js)
buildrule(wasm, dbg., base, [[[$(NOTHRFLAGS) -gsource-map $(ES6FLAGS)]]], mjs)
# wasm + threads
buildrule(thr, [[[]]], thr, [[[$(THRFLAGS) -sPTHREAD_POOL_SIZE=navigator.hardwareConcurrency]]], js)
buildrule(thr, [[[]]], thr, [[[$(ES6FLAGS) $(THRFLAGS) -sPTHREAD_POOL_SIZE=navigator.hardwareConcurrency]]], mjs)
buildrule(thr, dbg., thr, [[[-gsource-map $(THRFLAGS) -sPTHREAD_POOL_SIZE=navigator.hardwareConcurrency]]], js)
buildrule(thr, dbg., thr, [[[-gsource-map $(ES6FLAGS) $(THRFLAGS) -sPTHREAD_POOL_SIZE=navigator.hardwareConcurrency]]], mjs)

build/libav-$(LIBAVJS_VERSION).js: libav.in.js post.in.js funcs.json tools/apply-funcs.js
	mkdir -p build dist
	./tools/apply-funcs.js $(LIBAVJS_VERSION)

build/libav.types.d.ts build/libav-$(LIBAVJS_VERSION).mjs build/exports.json build/post.js: build/libav-$(LIBAVJS_VERSION).js
	touch $@

node_modules/.bin/uglifyjs:
	npm install

# Targets
build/inst/base/cflags.txt:
	mkdir -p build/inst/base
	echo -gsource-map > $@

build/inst/thr/cflags.txt:
	mkdir -p build/inst/thr
	echo $(THRFLAGS) -gsource-map > $@

RELEASE_VARIANTS=\
	default default-cli opus opus-af flac flac-af wav wav-af obsolete webm \
	webm-cli webm-vp9 webm-vp9-cli vp8-opus vp8-opus-avf vp9-opus \
	vp9-opus-avf av1-opus av1-opus-avf webcodecs webcodecs-avf

release: extract
	mkdir -p dist/release
	mkdir dist/release/libav.js-$(LIBAVJS_VERSION)
	cp -a README.md docs dist/release/libav.js-$(LIBAVJS_VERSION)/
	mkdir dist/release/libav.js-$(LIBAVJS_VERSION)/dist
	for v in $(RELEASE_VARIANTS); \
	do \
		$(MAKE) build-$$v; \
		$(MAKE) release-$$v; \
		cp dist/libav-$(LIBAVJS_VERSION)-$$v.* \
			dist/libav-$$v.* \
			dist/release/libav.js-$(LIBAVJS_VERSION)/dist; \
	done
	cp dist/libav.types.d.ts dist/release/libav.js-$(LIBAVJS_VERSION)/dist/
	mkdir dist/release/libav.js-$(LIBAVJS_VERSION)/sources
	for t in ffmpeg emfiberthreads lame libaom libogg libvorbis libvpx opus zlib; \
	do \
		$(MAKE) $$t-release; \
	done
	git archive HEAD -o dist/release/libav.js-$(LIBAVJS_VERSION)/sources/libav.js.tar
	xz dist/release/libav.js-$(LIBAVJS_VERSION)/sources/libav.js.tar
	cd dist/release && zip -r libav.js-$(LIBAVJS_VERSION).zip libav.js-$(LIBAVJS_VERSION)
	rm -rf dist/release/libav.js-$(LIBAVJS_VERSION)

release-%: dist/release/libav.js-$(LIBAVJS_VERSION)-%
	true

dist/release/libav.js-$(LIBAVJS_VERSION)-%: build-%
	mkdir -p $(@)/dist
	cp dist/libav-$(LIBAVJS_VERSION)-$(*).* \
		dist/libav-$(*).* \
		dist/libav.types.d.ts \
		$(@)/dist
	rm -f $(@)/dist/*.dbg.*
	sed 's/@VARIANT/$(*)/g ; s/@VERSION/$(LIBAVJS_VERSION)/g ; s/@VER/$(LIBAVJS_VERSION_SHORT)/g' \
		package-one-variant.json > $(@)/package.json

npm-publish:
	cd dist/release && unzip libav.js-$(LIBAVJS_VERSION).zip
	cd dist/release/libav.js-$(LIBAVJS_VERSION) && \
	  cp ../../../package.json . && \
	  rm -f dist/*.dbg.* dist/*-av1* dist/*-vp9* dist/*.asm.mjs && \
	  npm publish
	rm -rf dist/release/libav.js-$(LIBAVJS_VERSION)
	for v in $(RELEASE_VARIANTS); \
	do \
		( cd dist/release/libav.js-$(LIBAVJS_VERSION)-$$v && npm publish --access=public ) \
	done

halfclean:
	-rm -rf dist/
	-rm -f build/exports.json build/libav-$(LIBAVJS_VERSION).js build/post.js

clean: halfclean
	-rm -rf build/inst
	-rm -rf build/emfiberthreads-$(EMFT_VERSION)
	-rm -rf build/opus-$(OPUS_VERSION)
	-rm -rf build/libaom-$(LIBAOM_VERSION)
	-rm -rf build/libvorbis-$(LIBVORBIS_VERSION)
	-rm -rf build/libogg-$(LIBOGG_VERSION)
	-rm -rf build/libvpx-$(LIBVPX_VERSION)
	-rm -rf build/lame-$(LAME_VERSION)
	-rm -rf build/openh264-$(OPENH264_VERSION)
	-rm -rf build/ffmpeg-$(FFMPEG_VERSION)
	-rm -rf build/zlib-$(ZLIB_VERSION)

distclean: clean
	-rm -rf build/

print-version:
	@printf '%s\n' "$(LIBAVJS_VERSION)"

.PRECIOUS: \
	build/ffmpeg-$(FFMPEG_VERSION)/build-%/libavformat/libavformat.a \
	dist/libav.types.d.ts \
	dist/libav-$(LIBAVJS_VERSION)-%.js \
	dist/libav-%.js \
	dist/libav-$(LIBAVJS_VERSION)-%.mjs \
	dist/libav-%.mjs \
	dist/libav-$(LIBAVJS_VERSION)-%.dbg.js \
	dist/libav-%.dbg.js \
	dist/libav-$(LIBAVJS_VERSION)-%.dbg.mjs \
	dist/libav-%.dbg.mjs \
	dist/libav-$(LIBAVJS_VERSION)-%.asm.js \
	dist/libav-$(LIBAVJS_VERSION)-%.asm.mjs \
	dist/libav-$(LIBAVJS_VERSION)-%.dbg.asm.js \
	dist/libav-$(LIBAVJS_VERSION)-%.dbg.asm.mjs \
	dist/libav-$(LIBAVJS_VERSION)-%.wasm.js \
	dist/libav-$(LIBAVJS_VERSION)-%.wasm.mjs \
	dist/libav-$(LIBAVJS_VERSION)-%.dbg.wasm.js \
	dist/libav-$(LIBAVJS_VERSION)-%.dbg.wasm.mjs \
	dist/libav-$(LIBAVJS_VERSION)-%.thr.js \
	dist/libav-$(LIBAVJS_VERSION)-%.thr.mjs \
	dist/libav-$(LIBAVJS_VERSION)-%.dbg.thr.js \
	dist/libav-$(LIBAVJS_VERSION)-%.dbg.thr.mjs
