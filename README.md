# Knative Eventing Functions
[![Build Status](https://travis-ci.org/lionelvillard/knative-functions.svg?branch=master)](https://travis-ci.org/lionelvillard/knative-functions)

This project provides a collection of functions manipulating [Cloud Events](https://cloudevents.io).

All functions are currently only _callable_ (synchronous). We are planning to add _composable_ (asynchronous) functions
the near future.


## Installation

You first need to install the [Knative Eventing Function Controller](https://github.com/lionelvillard/knative-functions-controller):

```sh
kubectl apply -f https://github.com/lionelvillard/knative-functions-controller/releases/download/v0.1.2/function.yaml
```

Then install the function library:

```sh
kubectl apply -f https://github.com/lionelvillard/knative-functions/releases/download/v0.1.0/functions.yaml
```

## Functions

The functions are:

- [Wait](#wait)
<!--
- [Filter](#filter) (both [standalone](#standalone) and [dispatch](#dispatch) modes)
- [Transformer](#transformer)
- [Switch](#switch) (both [standalone](#standalone-1) and [dispatch](#dispatch-1) modes)
-->

### Wait

The `Wait` function forward events after X seconds.

#### Example

```yaml
apiVersion: functions.knative.dev/v1alpha1
kind: Wait
metadata:
  name: wait-5
spec:
  seconds: 5
```

<!--
## Filter

A filter takes a cloud event as input, evaluates a predicate against it and returns the
unmodified event when the predicate return true, otherwise returns an empty response

Supported predicate languages:
- nodejs

### Standalone

#### Environment Variables

- `FILTER`: an expression evaluating to a boolean
- all environment variables are made available to the `FILTER` expression

##### Knative Serving Example (node.js)

```yaml
apiVersion: serving.knative.dev/v1alpha1
kind: Service
metadata:
  name: filter
spec:
  template:
    spec:
      containers:
      - image:  villardl/filter-nodejs
        env:
        - name: FILTER
          value: event.data.assigned
```

`FILTER` must be a valid node.js expression.

### Dispatch

#### Installation

```sh
kone apply -f ./filter-dispatcher/config/
```

#### Example

```yaml
apiVersion: function.knative.dev/v1alpha1
kind: Filter
metadata:
  name: filter
spec:
  language: nodejs
  expression: event.data.assigned
```

After applying this configuration, check the status:

```sh
kubectl get filters.function.knative.dev

NAME     READY   REASON   URL                                                        AGE
filter   True             http://filter-filter.knative-functions.svc.cluster.local   13h
```

## Transformer

A transformer takes a cloud event as input, transforms the data and returns a cloud event with the data transformed.

### Environment Variables

- `TRANSFORMER`: a function taking an `event` and returning data.
- all environment variables are made available to the `TRANSFORMER` function

#### Knative Serving Example (node.js)

```yaml
apiVersion: serving.knative.dev/v1alpha1
kind: Service
metadata:
  name: step1
spec:
  template:
    spec:
      containers:
      - image:  villardl/transformer-nodejs
        env:
        - name: TRANSFORMER
          value: |
            event => ({
              sequence: event.data.Sequence,
              message: `${event.data.Message} - Handled by ${env.STEP}`
            })
        - name: STEP
          value: step1
```

`TRANSFORMER` must be a function taking one event and
returning data.

## Switch

The Switch function takes one switch expression and a list of case values. The switch function returns an event when the expression matches a case value AND the URL path matches the case number.

### Standalone

#### Knative Serving Example (node.js)

```yaml
apiVersion: serving.knative.dev/v1alpha1
kind: Service
metadata:
  name: switch
spec:
  template:
    spec:
      containers:
      - image:  villardl/switcher-nodejs
        env:
        - name: EXPRESSION
          value: event.data.assigned
        - name: CASES
          value: '["true", "false"]'
```

Deploy and test it using curl:

```sh
curl -X POST http://switch.default.demo.us-s
outh.containers.appdomain.cloud/0 -H "content-type:application/json" -d '{"data":{"assigned":"true"}}'
```

produces `{"data":{"assigned":"true"}}`

```sh
curl -X POST http://switch.default.demo.us-s
outh.containers.appdomain.cloud/1 -H "content-type:application/json" -d '{"data":{"assigned":"true"}}'
```

produces nothing, as expected.

### Dispatch

#### Installation

```sh
kone apply -f ./switch-dispatcher/config/
```

#### Example

```yaml
apiVersion: function.knative.dev/v1alpha1
kind: Switch
metadata:
  name: switch-data-assigned
spec:
  language: nodejs
  expression: event.data.assigned
  cases:
    - true
    - false
```
-->