workspace=$(cd "$(dirname "$0")"; pwd)/..

mkdir -p $workspace/log/pid/

if [ $# -le 0 ]
then
    echo 请输入配置名，如: run.sh game
    exit
fi

cd $workspace/../../skynet
./skynet ${workspace}/etc/${1}.cfg
