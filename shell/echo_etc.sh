workspace=$1 #xxx/xxx/xx
etc_name=$2 #master
start_script=$3
clustername=$4 #master
is_deamon=$5 #true

echo workspace = \"${workspace}/\"
echo thread = 8
echo logpath = \".\"
echo harbor = 0
echo start = \"${start_script}\"
echo 'bootstrap = "snlua bootstrap"'
echo 'lualoader = "lualib/loader.lua"'
echo 'snax = workspace.."service/?.lua"'
if [ "${workspace}" == "../bewater" ]
then
    echo 'luaservice = workspace.."/examples/?.lua;"..workspace.."service/?/init.lua;"..workspace.."service/?.lua;"..workspace.."service/?.lua;".."./service/?.lua;".."./liblua/?.lua;"'
    echo 'cpath = workspace.."luaclib/?.so;"..workspace.."luaclib/?.so;".."./cservice/?.so;./luaclib/?.so"'
    echo 'lua_path = workspace.."script/?.lua;"..workspace.."lualib/?.lua;"..workspace.."lualib/?.lua;".."./lualib/?.lua;"'
    echo 'lua_cpath = workspace.."luaclib/?.so;"..workspace.."luaclib/?.so;".."./luaclib/?.so;"'
else
    echo 'luaservice = workspace.."service/?/init.lua;"..workspace.."service/?.lua;"..workspace.."../../bewater/service/?/init.lua;"..workspace.."../../bewater/service/?.lua;".."./service/?.lua;".."./liblua/?.lua;"'
    echo 'cpath = workspace.."luaclib/?.so;"..workspace.."../../luaclib/?.so;".."./cservice/?.so;./luaclib/?.so"'
    echo 'lua_path = workspace.."script/?.lua;"..workspace.."lualib/?.lua;"..workspace.."../../bewater/lualib/?.lua;".."./lualib/?.lua;"'
    echo 'lua_cpath = workspace.."luaclib/?.so;"..workspace.."../../bewater/luaclib/?.so;".."./luaclib/?.so;"'
fi
echo logger = \"logger\"
echo logservice = \"snlua\"

if [ "${clustername}" != "" ]
then
    echo clustername = \"${clustername}\"
else
    echo clustername = \"${etc_name}\"
fi

if [ "${is_deamon}" == "true" ]
then
    echo daemon = workspace..\"/log/pid/${clustername}.pid\"
fi

