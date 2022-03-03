#!/usr/bin/env bash

curl -H "host: identity.function-demo.example.com" localhost:8080 -d '{"message":"hello"}'
