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
trap cleanup ERR

testname=${1:-}

# setting up directory structure

SRCDIR=$ROOT/proxies/nodejs
TESTDIR=$ROOT/test/proxies/nodejs

# init single test
single=$(mktemp -d)
cp -R $SRCDIR/* $single

# init param test
params=$(mktemp -d)
cp -R $SRCDIR/* $params
cp $TESTDIR/params-test.js $params/function.js

# init dispatch test
dispatch=$(mktemp -d)
cp -R $SRCDIR/* $dispatch
cp $TESTDIR/dispatch-test.js $dispatch/function.js

# init config test
config=$(mktemp -d)
cp -R $SRCDIR/* $config
cp $TESTDIR/params-test.js $config/function.js
cp $TESTDIR/___config.json $config/

# init redis test
redis=$(mktemp -d)
cp -R $SRCDIR/* $redis
cp $TESTDIR/redis-test.js $redis/function.js
cp $TESTDIR/___config-redis.json $redis/___config.json

export PORT=8081

# SINGLE TESTS

if [[ -z $testname || "$testname" == "single" ]]; then
    u::testsuite "Function - single"

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
fi

if [[ -z $testname || "$testname" == "params" ]]; then
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
fi

if [[ -z $testname || "$testname" == "config" ]]; then
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
fi

if [[ -z $testname || "$testname" == "dispatch" ]]; then
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

    kill $pid
fi

if [[ -z $testname || "$testname" == "redis" ]]; then
    u::testsuite "Function - redis"

    cd $redis

    docker run -d -p 6379:6379 --name redis1 redis > /dev/null

    node main.js &
    pid=$!

    sleep 1

    printf "redis - should store event in redis"
    resp=$(curl -s localhost:${PORT} -H 'ce-id: my-event' -d '{"message":"hello"}')
    if [[ $resp != '{"message":"hello"}' ]]; then
        u::fatal "unexpected response $resp"
    fi
    printf "$CHECKMARK\n"

    printf "redis - should read event from redis"
    resp=$(curl -s localhost:${PORT} -H 'ce-id: my-event' -d '')
    if [[ $resp != '{"message":"hello"}' ]]; then
        u::fatal "unexpected response $resp"
    fi
    printf "$CHECKMARK\n"

    kill $pid

    docker stop redis1  > /dev/null
    docker rm redis1 > /dev/null
fi
