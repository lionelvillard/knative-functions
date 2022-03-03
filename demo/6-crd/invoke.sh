#!/usr/bin/env bash

curl -H "host: waits-function-demo-wait-2.knative-functions.example.com" localhost:8080 -d '"hello"'
