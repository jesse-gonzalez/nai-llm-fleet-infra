## add Repo

helm repo add nvidia https://nvidia.github.io/gpu-operator

helm repo update

## Preparations
kubectl create ns gpu-operator

## in case time slicing is required (also enable feature in value file)




kubectl apply -n gpu-operator -f time-slicing-config.yaml

## install chart

helm upgrade --install gpu-operator -n gpu-operator nvidia/gpu-operator -f nvidia-values.yaml --version=v23.9.0

## only needed for day2 activation of time slicing
kubectl patch clusterpolicy/cluster-policy \
    -n gpu-operator --type merge \
    -p '{"spec": {"devicePlugin": {"config": {"name": "time-slicing-config", "default": "any"}}}}'


## on kommander

cat <<EOF | kubectl apply -n kommander -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: time-slicing-config
  annotations:
    kustomize.toolkit.fluxcd.io/force: enabled
data:
  any: |-
    version: v1
    flags:
      migStrategy: none
    sharing:
      timeSlicing:
        renameByDefault: false
        failRequestsGreaterThanOne: false
        resources:
          - name: nvidia.com/gpu
            replicas: 3
EOF

kubectl patch clusterpolicy/cluster-policy \
    -n kommander --type merge \
    -p '{"spec": {"devicePlugin": {"config": {"name": "time-slicing-config", "default": "any"}}}}'