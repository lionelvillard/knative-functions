#!/usr/bin/env bash

curl -H "host: static-binding.function-demo.example.com" "localhost:8080" -d '{"message":"hello"}'
