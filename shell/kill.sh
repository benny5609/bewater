#ps -Al | grep skynet | cut -c 10-16 | xargs kill -9

workspace=$(cd "$(dirname "$0")"; pwd)/..
pid=`cat $workspace/log/pid/${1}.pid`
if [ "$2" != "" ] 
then
    kill -$2 $pid
else
    kill -1 $pid
fi
