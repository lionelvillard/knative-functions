#!/usr/bin/env bash

curl -H "host: async.function-demo.example.com" localhost:8080 -d '{"message":"hello"}'
