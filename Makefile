SRC_DIR = ./lualib-src
LIB_DIR = ./luaclib

SRC = ${wildcard ${SRC_DIR}/*.c}
LIB = ${patsubst lua-%.c, ${LIB_DIR}/%.so, ${notdir ${SRC}}}


all:${LIB_DIR}/aes.so ${LIB_DIR}/packet.so ${LIB_DIR}/random.so \
	${LIB_DIR}/webclient.so ${LIB_DIR}/codec.so

${LIB_DIR}/aes.so:${SRC_DIR}/lua-aes.c
	cc -g -O2 -Wall -Iskynet/3rd/lua -fPIC --shared $< -o $@ -lcurl
${LIB_DIR}/packet.so:${SRC_DIR}/lua-packet.c
	cc -g -O2 -Wall -Iskynet/3rd/lua -fPIC --shared $< -o $@
${LIB_DIR}/random.so:${SRC_DIR}/lua-random.c
	cc -g -O2 -Wall -Iskynet/3rd/lua -fPIC --shared $< -o $@
${LIB_DIR}/webclient.so:${SRC_DIR}/lua-webclient.c
	cc -g -O2 -Wall -Iskynet/3rd/lua -fPIC --shared $< -o $@ -lcurl
${LIB_DIR}/codec.so:${SRC_DIR}/lua-codec.c
	cc -g -O2 -Wall -Iskynet/3rd/lua -fPIC --shared $< -o $@ -lcurl

.PHONY:clean
clean:
	rm ${LIB}
