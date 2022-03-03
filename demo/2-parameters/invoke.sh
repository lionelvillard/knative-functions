#!/usr/bin/env bash

curl -H "host: parameters.function-demo.example.com" "localhost:8080?seconds=5" -d '{"message":"hello"}'
