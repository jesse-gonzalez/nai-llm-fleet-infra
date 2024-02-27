https://knative.dev/docs/install/yaml-install/serving/install-serving-with-yaml/#install-the-knative-serving-component

KNATIVE_ISTIO_VERSION=knative-v1.11.5

## install knative-istio (_operators)

kubectl apply -l knative.dev/crd-install=true -f https://github.com/knative/net-istio/releases/download/${KNATIVE_ISTIO_VERSION}/istio.yaml --dry-run=client -o yaml >| ./istio-crds.yaml

kubectl apply -f https://github.com/knative/net-istio/releases/download/${KNATIVE_ISTIO_VERSION}/istio.yaml --dry-run=client -o yaml >| ./istio.yaml

## install knative-istio-controller (_resource-configs)

kubectl apply -f https://github.com/knative/net-istio/releases/download/${KNATIVE_ISTIO_VERSION}/net-istio.yaml --dry-run=client -o yaml >| ./net-istio.yaml

## Fetch the External IP address or CNAME by running the command:

kubectl --namespace istio-system get service istio-ingressgateway

- [ ] Setup MetalLB to have IP address for Ingress vs. Istio
- [ ] Setup Wildcard DNS Records to have IP address

## Validate DNS record configured correctly

## Here knative.example.com is the domain suffix for your cluster

*.knative.example.com == A 35.233.41.212

## Replace knative.example.com with your domain suffix

kubectl patch configmap/config-domain \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"knative.example.com":""}}'
