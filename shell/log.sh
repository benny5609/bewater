workspace=$(cd "$(dirname "$0")"; pwd)/..
tail -f $workspace/log/$1.log
