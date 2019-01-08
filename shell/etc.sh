#生成一份配置(需要在shell目录下运行)
workspace=../bewater #相对skyne程序位置
if [ $# -lt 2 ]
then
    echo 至少需要两个参数, etc.sh 配置名 启动脚本 是否后台执行
    exit
fi

etc_name=$1 #master
start_script=$2
clustername=$3 #master
is_deamon=$4 #true

config=${etc_name}.cfg

mkdir -p ../log
mkdir -p ../etc

if [ "${workspace}" == "../bewater" ]
then
    echo_etc=echo_etc.sh
else
    echo_etc=../../../bewater/shell/echo_etc.sh
fi

sh ${echo_etc} ${workspace} ${etc_name} ${start_script} ${clustername} ${is_deamon} > ../etc/${etc_name}.cfg
