#!/bin/sh
npm i
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
${DIR}/download.sh
mkdir -p ${DIR}/output
if [[ $1 == "noprepare" ]]
then
    ${DIR}/node_modules/coffee-script/bin/coffee tool_cross.coffee -c level
else
    ${DIR}/node_modules/coffee-script/bin/coffee tool_cross.coffee -c run
fi
mkdir -p ${DIR}/Artifacts
cp ${DIR}/output/level.csv ${DIR}/Artifacts/