#!/usr/bin/env bash
##一键安装lua5.3 和 luarocks 脚本
cd /usr/local
wget http://www.lua.org/ftp/lua-5.3.5.tar.gz
tar -zxvf lua-5.3.5.tar.gz
cd  lua-5.3.5
make linux && make test && make install && make local

echo "重新安装luarocks"
if [ ! -d "/usr/local/luarocks-2.4.1" ];then
cd /usr/local && wget http://luarocks.org/releases/luarocks-2.4.1.tar.gz && tar -zxvf luarocks-2.4.1.tar.gz
else
echo "/usr/local/luarocks-2.4.1 文件夹已经存在"
fi
cd /usr/local/luarocks-2.4.1
./configure  --with-lua=/usr/local  --with-lua-include=/usr/local/lua-5.3.5/install/include
make build && make install &&  make bootstrap
source ~/.bash_profile
echo "测试luarocks安装luacheck"
luarocks install luacheck
lua -v
