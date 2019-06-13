workspace=$(cd $(dirname $0); pwd)/..

cd  ${workspace}/examples/lualib/def/proto
find . -name "*.proto" | xargs ${workspace}/tools/protoc3 -o package.pb

echo done.

