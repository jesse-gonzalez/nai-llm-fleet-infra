- [ ] kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.11.6/serving-crds.yaml
- [ ] kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.11.6/serving-core.yaml
- 
# HPA
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.11.6/serving-hpa.yaml


TODO: 


Configure base domain:

```
kubectl patch configmap config-domain -n knative-serving --patch '
data:
  kubeflow.gptnvd.dachlab.net: ""
'
```

Allow Tolerations:

```
kubectl patch configmap config-features -n knative-serving --patch '
data:
  kubernetes.podspec-tolerations: "enabled"
'
```

Remember to add tolerations to inferenceservice like (nai-helm does it automatically):
```
  predictor:
    tolerations:
      - key: "dedicated"
        operator: "Equal"
        value: "gpu"
        effect: "NoSchedule"
```

Create wildcard DNS entries for each namespace you want to run kserve inferencing

Configure Garbage Collection:

```
kubectl patch configmap config-gc -n knative-serving --patch '
data:
  max-non-active-revisions: "0"
  min-non-active-revisions: "0"
  retain-since-create-time: "disabled"
  retain-since-last-active-time: "disabled"
'
```
