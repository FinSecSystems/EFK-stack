#!/bin/bash
pushd . > /dev/null
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $dir
./deploy-script.sh nopush $@
popd > /dev/null
