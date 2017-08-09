#!/bin/sh
npm i
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
${DIR}/download.sh
${DIR}/node_modules/coffee-script/bin/coffee tool_cross.coffee -c run
mkdir -p ${DIR}/Artifacts
cp ${DIR}/output/level.csv ${DIR}/Artifacts/