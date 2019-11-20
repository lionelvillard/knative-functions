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
NS=test-functions-filter
k8s::create_and_set_ns $NS

u::testsuite "Filter Function"

cd $ROOT/filter

u::header "Deploying..."

kone apply -f config
k8s::wait_resource_ready_ns services.serving.knative.dev filters knative-functions

u::header "Testing..."

kubectl apply -f samples/filter.yaml
k8s::wait_resource_ready_ns filters.functions.knative.dev filter $NS
sleep 5 # wait for pods to reload

printf "should return the event"

host=$(kubectl get filters.functions.knative.dev filter -o=jsonpath='{$.status.url}')
resp=$(knative::invoke ${host:7} '{"assigned": true}')
if [[ "$resp" != '{"assigned":true}' ]]; then
     u::fatal "unexpected response, got ${resp}"
fi
printf "$CHECKMARK\n"

printf "should not return the event"

resp=$(knative::invoke ${host:7} '{"assigned": false}')
if [[ "$resp" != "" ]]; then
     u::fatal "unexpected response, got ${resp}"
fi
printf "$CHECKMARK\n"

u::header "cleanup..."
k8s::delete_ns $NS