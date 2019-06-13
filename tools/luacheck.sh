# luacheck 修改过的lua文件
STAGED_FILES=$(git status -s | grep "[M|??].*lua$" | awk '{printf $2 "\n"}')
if [ "$1" == "all" ];
then
    STAGED_FILES='.'
fi
luacheck --config .luacheckrc $STAGED_FILES
