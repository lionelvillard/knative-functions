# Knative Eventing Functions

This project provides a collection of functions manipulating [Cloud Events](https://cloudevents.io).

There are two categories of functions:
- the ones accepting only one set of parameters (standalone function), and
- the ones accepting multiple sets of parameters (dispatch function).

The functions accepting multiple sets of parameters are compatible with the [Knative function controller](https://github.com/lionelvillard/knative-functions-controller).

All functions are currently only _callable_ (synchronous). We are planning to add _composable_ (asynchronous) functions
the near future.

Function parameters are statically bound, either through environment variables for standalone functions or
through custom objects for dispatch functions. We are planning to also support dynamic variable bindings.

The functions are:

- [Filter](#filter) (both [standalone](#standalone) and [dispatch](#dispatch) modes)
- [Transformer](#transformer)
- [Switch](#switch) (both [standalone](#standalone-1) and [dispatch](#dispatch-1) modes)
- [Wait](#wait) (both [standalone](#standalone-2) and [dispatch](#dispatch-2) modes)

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

## Wait

The Wait function is the identity function waiting X seconds.

### Standalone

#### Environment Variables

- `SECONDS`: number of seconds to wait

#### Knative Serving Example

```yaml
apiVersion: serving.knative.dev/v1alpha1
kind: Service
metadata:
  name: wait
spec:
  template:
    spec:
      containers:
      - image:  villardl/waiter-nodejs
        env:
        - name: SECONDS
          value: "15"
```

### Dispatch

#### Installation

```sh
kone apply -f ./wait-dispatcher/config/
```

#### Example

```yaml
apiVersion: function.knative.dev/v1alpha1
kind: Wait
metadata:
  name: wait-5
spec:
  seconds: 5
```
