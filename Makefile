.PHONY:all skynet lib

SRC_DIR = ./lualib-src
LIB_DIR = ./luaclib

INCLUDE_DIR=skynet/3rd/lua

all:build skynet lib

build:
	mkdir -p luaclib
	mkdir -p logs

SKYNET_MAKEFILE=skynet/Makefile
$(SKYNET_MAKEFILE):
	git submodule update --init

skynet: | $(SKYNET_MAKEFILE)
	cd skynet && $(MAKE) linux

CC = gcc
CFLAGS = -g3 -O2 -rdynamic -Wall -I$(INCLUDE_DIR)
SHARED = -fPIC --shared

lib:${LIB_DIR}/aes.so ${LIB_DIR}/packet.so ${LIB_DIR}/random.so \
	${LIB_DIR}/webclient.so ${LIB_DIR}/codec.so ${LIB_DIR}/cjson.so \
	${LIB_DIR}/protobuf.so ${LIB_DIR}/syslog.so


${LIB_DIR}/aes.so:${SRC_DIR}/lua-aes.c
	${CC} ${CFLAGS} ${SHARED} $< -o $@ -lcurl
${LIB_DIR}/packet.so:${SRC_DIR}/lua-packet.c
	${CC} ${CFLAGS} ${SHARED} $< -o $@
${LIB_DIR}/random.so:${SRC_DIR}/lua-random.c
	${CC} ${CFLAGS} ${SHARED} $< -o $@
${LIB_DIR}/webclient.so:${SRC_DIR}/lua-webclient.c
	${CC} ${CFLAGS} ${SHARED} $< -o $@ -lcurl
${LIB_DIR}/codec.so:${SRC_DIR}/lua-codec.c
	${CC} ${CFLAGS} ${SHARED} $< -o $@ -lcurl
${LIB_DIR}/syslog.so:${SRC_DIR}/lua-syslog.c
	${CC} ${CFLAGS} ${SHARED} $< -o $@

# cjson
CJSON_SOURCE=3rd/lua-cjson/lua_cjson.c \
			 3rd/lua-cjson/strbuf.c \
			 3rd/lua-cjson/fpconv.c
${LIB_DIR}/cjson.so:${CJSON_SOURCE}
	${CC} $(CFLAGS) -I3rd/lua/lua-cjson $(SHARED) $^ -o $@ $(LDFLAGS)

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
	rm -f ${LIB_DIR}/*
