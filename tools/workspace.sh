if [ ! -d "skynet" ]; then
    git clone https://github.com/zhandouxiaojiji/skynet.git
fi

if [ ! -d "common" ]; then
    git clone https://github.com/zhandouxiaojiji/common.git
fi

mkdir -p proj
cd proj

if [ ! -d "monitor" ]; then
    git clone https://github.com/zhandouxiaojiji/monitor.git
fi

if [ ! -d "share" ]; then
    git clone https://github.com/zhandouxiaojiji/share.git
fi
