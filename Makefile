.PHONY:all

SRC_DIR = ./lualib-src
LIB_DIR = ./luaclib

INCLUDE_DIR=skynet/3rd/lua

all:build

build:
	mkdir -p luaclib

CFLAGS = -g3 -O2 -rdynamic -Wall -I$(INCLUDE_DIR)
SHARED = -fPIC --shared

all:${LIB_DIR}/aes.so ${LIB_DIR}/packet.so ${LIB_DIR}/random.so \
	${LIB_DIR}/webclient.so ${LIB_DIR}/codec.so ${LIB_DIR}/cjson.so \
	${LIB_DIR}/protobuf.so


${LIB_DIR}/aes.so:${SRC_DIR}/lua-aes.c
	gcc ${CFLAGS} ${SHARED} $< -o $@ -lcurl
${LIB_DIR}/packet.so:${SRC_DIR}/lua-packet.c
	gcc ${CFLAGS} ${SHARED} $< -o $@
${LIB_DIR}/random.so:${SRC_DIR}/lua-random.c
	gcc ${CFLAGS} ${SHARED} $< -o $@
${LIB_DIR}/webclient.so:${SRC_DIR}/lua-webclient.c
	gcc ${CFLAGS} ${SHARED} $< -o $@ -lcurl
${LIB_DIR}/codec.so:${SRC_DIR}/lua-codec.c
	gcc ${CFLAGS} ${SHARED} $< -o $@ -lcurl

# cjson
CJSON_SOURCE=3rd/lua-cjson/lua_cjson.c \
			 3rd/lua-cjson/strbuf.c \
			 3rd/lua-cjson/fpconv.c
${LIB_DIR}/cjson.so:${CJSON_SOURCE}
	gcc $(CFLAGS) -I3rd/lua/lua-cjson $(SHARED) $^ -o $@ $(LDFLAGS)

3rd/lua-cjson/lua_cjson.c:
	git submodule update --init 3rd/lua-cjson

# protobuf
PBC_SOURCE=3rd/pbc/pbc.h

${PBC_SOURCE}:
	git submodule update --init 3rd/pbc

${LIB_DIR}/protobuf.so: ${PBC_SOURCE}
	-cd 3rd/pbc && ${MAKE}
	cd 3rd/pbc/binding/lua53 && ${MAKE}
	cp 3rd/pbc/binding/lua53/protobuf.so ${LIB_DIR}

.PHONY:clean
clean:
	rm ${LIB_DIR}/*
