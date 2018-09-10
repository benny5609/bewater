#生成一份配置

if [ $# -lt 2 ]
then
    echo 至少需要两个参数, etc.sh 配置名 启动脚本 是否后台执行
    exit
fi

cd ../../
rootspace=$(cd $(dirname $0); pwd)
root_name=$(basename $rootspace)
cd -

cd ../
workspace=$(cd $(dirname $0); pwd)
proj_name=$(basename $workspace)
cd -

etc_name=$1 #master
start_script=$2
clustername=$3 #master
is_deamon=$4 #true

config=${etc_name}.cfg

mkdir -p ${workspace}/log
mkdir -p ${workspace}/etc
cd ${workspace}/etc

echo workspace = \"../${root_name}/${proj_name}/\" > ${config}
echo thread = 8 >> ${config}
echo logpath = \".\" >> ${config}
echo harbor = 0 >> ${config}
echo start = \"${start_script}\" >> ${config}
echo 'bootstrap = "snlua bootstrap"' >> ${config}
echo 'lualoader = "lualib/loader.lua"' >> ${config}
echo 'snax = workspace.."service/?.lua"' >> ${config}
echo 'luaservice = workspace.."service/?.lua;"..workspace.."../../common/service/?.lua;".."./service/?.lua;".."./liblua/?.lua;"' >> ${config}
echo 'cpath = workspace.."luaclib/?.so;"..workspace.."../../luaclib/?.so;".."./cservice/?.so;./luaclib/?.so"' >> ${config}
echo 'lua_path = workspace.."script/?.lua;"..workspace.."lualib/?.lua;"..workspace.."../../common/lualib/?.lua;".."./lualib/?.lua;"' >> ${config}
echo 'lua_cpath = workspace.."luaclib/?.so;"..workspace.."../../common/luaclib/?.so;".."./luaclib/?.so;"'  >> ${config}
echo logger = \"logger\" >> ${config}
echo logservice = \"snlua\" >> ${config}

if [ "${clustername}" != "" ]
then
    echo clustername = \"${clustername}\" >> ${config}
else
    echo clustername = \"${etc_name}\" >> ${config}
fi

if [ "${is_deamon}" == "true" ]
then
    echo daemon = workspace..\"/log/pid/${etc_name}.pid\" >> ${config}
fi

