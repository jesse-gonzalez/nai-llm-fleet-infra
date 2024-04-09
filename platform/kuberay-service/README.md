## RayService LLM Testing

```bash

## Mixtral-8-7b-Instruct examples

## ray service config map for setting up raycluster deployment/engine and scaling configurations
https://github.com/ray-project/ray-llm/blob/master/models/continuous_batching/mistralai--Mixtral-8-7b-Instruct-v01.yaml

## ray service config for ray-llm application.  This will configure inferencing endpoint
https://github.com/ray-project/ray-llm/blob/master/serve_configs/mistralai--Mixtral-8-7b-Instruct-v01.yaml


## See https://github.com/ray-project/kuberay/blob/master/docs/guidance/rayStartParams.md for the default settings of `rayStartParams` in KubeRay.
## See https://docs.ray.io/en/latest/cluster/cli.html#ray-start for all available options in `rayStartParams`.

## Good References

https://cloud.google.com/kubernetes-engine/docs/how-to/serve-llm-l4-ray#prepare_workload
https://github.com/GoogleCloudPlatform/kubernetes-engine-samples/blob/main/ai-ml/gke-ray/rayserve
https://cloud.google.com/kubernetes-engine/docs/tutorials/serve-gemma-gpu-vllm

```

## Configure Taints on GPU Worker Nodes for KubeRay Cluster Nodes

```bash
## configure ray worker node taints on gpu nodes
kubectl taint node -l nvidia.com/gpu.present=true ray.io/node-type=worker:NoSchedule

## if workloads already scheduled on gpu nodes drain each one
kubectl get node -l nvidia.com/gpu.present=true -o name | cut -d/ -f2 | xargs -I {} sh -c "kubectl drain {} --delete-emptydir-data --ignore-daemonsets && kubectl uncordon {}"
```

## Deploy Mistral-8x7b-instruct Ray LLM App with Gradio

```bash
## Using kustomize
kubectl apply -k platform/kuberay-service/mistral-8x7b-instruct/.

## watch progress
watch "kubectl get rayservice,raycluster,po,svc,pvc && kubectl exec -it $(kubectl get pods -l ray.io/node-type=head -o custom-columns=POD:metadata.name --no-headers) -- serve status"
kubectl exec -it $(kubectl get pods -l ray.io/node-type=head -o custom-columns=POD:metadata.name --no-headers) -- ray status

## monitor logs
kubectl logs -l app.kubernetes.io/instance=kuberay-operator --all-containers --tail=50 --follow
kubectl logs -l ray.io/node-type=head --all-containers --tail=50 --follow
kubectl logs -l ray.io/node-type=worker --all-containers --tail=50 --follow --max-log-requests 8

## open ray-llm cluster dashboard using port forwarding and navigate to http://127.0.0.1:8265/
kubectl port-forward $(kubectl get svc -l ray.io/node-type=head -o name) 8265:8265


```


## Validation Questions

```bash
How do I make fried rice?
----
What are the most influential punk bands of all time? 
----
What are the best places in the world to visit? 
----
Which Olympics were held in Australia? What years and what cities?
```

## MicroBenchmarking

https://github.com/ray-project/kuberay/blob/master/docs/guidance/rayservice-high-availability.md


## Troubleshooting

https://docs.ray.io/en/master/cluster/kubernetes/troubleshooting/rayservice-troubleshooting.html#kuberay-raysvc-troubleshoot

```bash

kubectl describe rayservice 

# Run ray status
kubectl exec -it $(kubectl get pods -l ray.io/node-type=head -o custom-columns=POD:metadata.name --no-headers) -- ray status
kubectl exec -it $(kubectl get pods -l ray.io/node-type=head -o custom-columns=POD:metadata.name --no-headers) -- ray summary actors
kubectl exec -it $(kubectl get pods -l ray.io/node-type=head -o custom-columns=POD:metadata.name --no-headers) -- serve status
kubectl exec -it $(kubectl get pods -l ray.io/node-type=head -o custom-columns=POD:metadata.name --no-headers) -- ray summary actors
kubectl exec -it $(kubectl get pods -l ray.io/node-type=head -o custom-columns=POD:metadata.name --no-headers) -- ray list placement-groups --detail

kubectl get po -l ray.io/node-type=worker -L status.phase=Running -o name | cut -d/ -f2 | xargs -I {} kubectl exec -t {} -- ray status
kubectl get po -l ray.io/node-type=worker -L status.phase=Running -o name | cut -d/ -f2 | xargs -I {} kubectl exec -t {} -- ray summary actors
kubectl get po -l ray.io/node-type=worker -L status.phase=Running -o name | cut -d/ -f2 | xargs -I {} kubectl exec -t {} -- serve status

# Check the logs under /tmp/ray/session_latest/logs/serve/
kubectl exec -it $(kubectl get pods -l ray.io/node-type=head -o custom-columns=POD:metadata.name --no-headers) -- bash
kubectl exec -it $(kubectl get pods -l ray.io/node-type=worker -o custom-columns=POD:metadata.name --no-headers) -- bash

# Check ALL the logs under /tmp/ray/session_latest/logs
kubectl get po -l ray.io/node-type=worker -L status.phase=Running -o name | cut -d/ -f2 | xargs -I {} kubectl exec -t {} -- ls /tmp/ray/session_latest/logs

## view metrics
kubectl top nodes
kubectl top nodes --show-capacity
kubectl top pod --containers --sort-by=memory
kubectl top pod -l ray.io/node-type=worker --containers 
kubectl top pod -l ray.io/node-type=worker --sort-by=memory --containers 

## view taint
kubectl get nodes -o='custom-columns=NodeName:.metadata.name,TaintKey:.spec.taints[*].key,TaintValue:.spec.taints[*].value,TaintEffect:.spec.taints[*].effect'

# List PersistentVolumes sorted by capacity
kubectl get pv --sort-by=.spec.capacity.storage


```

## Cleanup Mistral-8x7b-instruct Ray LLM App with Gradio

```bash
## Using kustomize
kubectl delete -k platform/kuberay-service/mistral-8x7b-instruct/.
```