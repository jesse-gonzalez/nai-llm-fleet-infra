## Install the Knative Operator

https://knative.dev/docs/install/operator/knative-with-operators/#verifying-image-signatures

```bash
## create new knative-operator as to not install in default, wtf
kubectl create ns knative-operator
kubectl apply -f https://github.com/knative/operator/releases/download/knative-v1.13.1/operator.yaml
```