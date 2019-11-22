#!/usr/bin/env bash

# Copyright 2019 IBM Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
ROOT=$(dirname $BASH_SOURCE[0])/../../..
source $ROOT/hack/lib/library.sh

function cleanup {
    if [[ -n $pid ]]; then
        kill $pid
        unset pid
    fi
}
trap cleanup EXIT

u::testsuite "Function - single"

# setting up directory structure

SRCDIR=$ROOT/runtimes/nodejs
TESTDIR=$ROOT/test/runtimes/nodejs

single=$(mktemp -d)
params=$(mktemp -d)
dispatch=$(mktemp -d)
config=$(mktemp -d)

cp $SRCDIR/* $single
cp $SRCDIR/* $params
cp $SRCDIR/* $dispatch
cp $SRCDIR/* $config

cp $TESTDIR/params-test.js $params/function.js
cp $TESTDIR/dispatch-test.js $dispatch/function.js
cp $TESTDIR/params-test.js $config/function.js
cp $TESTDIR/___config.json $config/

export PORT=8081

# SINGLE TESTS

cd $single

node main.js &
pid=$!

sleep 1

printf "should return 404 (bad method)"
o1=$(curl -sw "%{response_code}" localhost:${PORT})
if [[ $o1 != "404" ]]; then
    u::fatal "expected 404 http code"
fi
printf "$CHECKMARK\n"

printf "should return event "
o2=$(curl -s localhost:${PORT} -d '{"message":"hello"}')
if [[ "$o2" != '{"message":"hello"}' ]]; then
    u::fatal "unexpected response $o2"
fi
printf "$CHECKMARK\n"

printf "Should return empty body "
o3=$(curl -s localhost:${PORT} -X POST)
if [[ "$o3" != '' ]]; then
   u::fatal "unexpected response $o3"
fi
printf "$CHECKMARK\n"

# Unicode
printf "data with unicode "
o4=$(curl -s localhost:${PORT} -d '{"message":"†˙ˆß ˆß çøø¬"}')
if [[ "$o4" != '{"message":"†˙ˆß ˆß çøø¬"}' ]]; then
    u::fatal "unexpected response $o4"
fi
printf "$CHECKMARK\n"

printf "Invalid JSON data "
o=$(curl -s localhost:${PORT} -d '{"message":"missing bracket}')
if  [[ "$o" != 'invalid JSON: SyntaxError: Unexpected end of JSON input' ]]; then
    u::fatal "unexpected response $o"
fi
printf "$CHECKMARK\n"

kill $pid

u::testsuite "Function - params"

cd $params

node main.js &
pid=$!

sleep 1

printf "should replace event data to be world"
resp=$(curl -s localhost:${PORT}?data=world -d '{}')
if [[ $resp != '"world"' ]]; then
     u::fatal "unexpected response $resp"
fi
printf "$CHECKMARK\n"

printf "should not replace anything"
resp=$(curl -s localhost:${PORT}? -d '{}')
if [[ $resp != '{}' ]]; then
     u::fatal "unexpected response $resp"
fi
printf "$CHECKMARK\n"

kill $pid


u::testsuite "Function - config"

cd $config

node main.js &
pid=$!

sleep 1

printf "should replace event data to be world"
resp=$(curl -s localhost:${PORT} -d '{}')
if [[ $resp != '"world"' ]]; then
     u::fatal "unexpected response $resp"
fi
printf "$CHECKMARK\n"

printf "should replace event data to be world - trim domain"
resp=$(curl -s -H "host: localhost:8081" localhost:${PORT} -d '{}')
if [[ $resp != '"world"' ]]; then
     u::fatal "unexpected response $resp"
fi
printf "$CHECKMARK\n"

kill $pid

u::testsuite "Function - dispatch"

cd $dispatch

node main.js &
pid=$!

sleep 1

printf "dispatch - should return 404 (root) "
o=$(curl -X POST -sw "%{response_code}" localhost:${PORT})
if  [[ $o != "404" ]]; then
    u::fatal "expected 404 http code"
fi
printf "$CHECKMARK\n"

printf "dispatch - should return 404 (invalid function name) "
o=$(curl -X POST -sw "%{response_code}" localhost:${PORT}/invalid/path)
if  [[ $o != "404" ]]; then
    u::fatal "expected 404 http code"
fi
printf "$CHECKMARK\n"

printf "dispatch - should evaluate content filter  "
o=$(curl -s localhost:${PORT}/content-filter -d '{"filter":true}')
if  [[ $o != "" ]]; then
    u::fatal "expected empty event"
fi
printf "$CHECKMARK\n"

printf "dispatch - should evaluate attribute type filter  "
o=$(curl -s localhost:${PORT}/attr-type-filter -H 'ce-type: my.event.type' -d '{"message":"hello"}')
if  [[ $o != '{"message":"hello"}' ]]; then
    u::fatal "unexpected response $o"
fi
printf "$CHECKMARK\n"


u::header "cleanup"