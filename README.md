# Knative Eventing Functions

This project provides a collection of functions manipulating [Cloud Events](https://cloudevents.io).

## Filter

A filter takes a cloud event as input, evaluates a predicate against it and returns the
unmodified event when the predicate return true, otherwise returns an empty response

### Environment Variables

- `FILTER`: an expression evaluating to a boolean
- all environment variables are made available to the `FILTER` expression



#### NodeJS Knative Serving Example

`FILTER` must be a valid node.js expression.

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

## Transformer

A transformer takes a cloud event as input, transforms the data and returns a cloud event with the data transformed.

### Environment Variables

- `TRANSFORMER`: a function taking an `event` and returning data.
- all environment variables are made available to the `TRANSFORMER` function

#### NodeJS Knative Serving Example


`TRANSFORMER` must be a valid node.js expression.

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

## Switcher

A switcher takes one switch expression and a list of case values. The switcher returns an event when the expression matches a case value AND the URL path matches the case number.

#### NodeJS Knative Serving Example

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
curl -X POST  http://switch.default.demo.us-s
outh.containers.appdomain.cloud/0 -H "content-type:application/json" -d '{"data":{"assigned":"true"}}'
```

produces `{"data":{"assigned":"true"}}`

```sh
curl -X POST  http://switch.default.demo.us-s
outh.containers.appdomain.cloud/1 -H "content-type:application/json" -d '{"data":{"assigned":"true"}}'
```

produces nothing.