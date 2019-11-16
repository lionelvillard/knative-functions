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

ROOT=$(dirname $BASH_SOURCE[0])/../
source $ROOT/hack/lib/library.sh
NS=test-functions-wait
k8s::create_and_set_ns $NS

u::testsuite "Function wait"

cd $ROOT/wait

u::header "Deploying..."

kone apply -f config
k8s::wait_resource_ready_ns services.serving.knative.dev waits knative-functions

u::header "Testing..."

printf "should return same event after 2 seconds"

kubectl apply -f samples/wait-2.yaml
k8s::wait_resource_ready_ns waits.functions.knative.dev wait-2 $NS
sleep 5

host=$(kubectl get waits.functions.knative.dev wait-2 -o=jsonpath='{$.status.url}')
resp=$(knative::invoke_time ${host:7} '{"msg": "hello"}') # warmup
resp=$(knative::invoke_time ${host:7} '{"msg": "hello"}')

time=${resp:15:1}
if [[ "$time" != "2" ]]; then
    u::fatal "expected 2 seconds, got ${time}"
fi
printf "$CHECKMARK\n"

u::header "cleanup..."
k8s::delete_ns $NS