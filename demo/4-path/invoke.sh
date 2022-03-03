#!/usr/bin/env bash

curl -H "host: path.function-demo.example.com" localhost:8080/attr-type-filter -H 'ce-type: my.event.type' -d '{"message":"hello"}'
