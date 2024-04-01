https://ray-project.github.io/kuberay/deploy/helm/

```bash
# Step 1: Register a Helm chart repo
helm repo add kuberay https://ray-project.github.io/kuberay-helm/
helm repo update kuberay

$ helm search repo kuberay

NAME                            CHART VERSION   APP VERSION     DESCRIPTION                                       
kuberay/kuberay-apiserver       1.1.0                           A Helm chart for kuberay-apiserver                
kuberay/kuberay-operator        1.1.0                           A Helm chart for Kubernetes                       
kuberay/ray-cluster             1.1.0                           A Helm chart for Kubernetes     


# Step 2: Install both CRDs and KubeRay operator v1.1.0.
helm install kuberay-operator kuberay/kuberay-operator --version 1.1.0

# Step 3: Install a RayCluster custom resource
helm install raycluster kuberay/ray-cluster --version 1.1.0

# Step 4: Verify the installation of KubeRay operator and RayCluster 
kubectl get pods
# NAME                                          READY   STATUS    RESTARTS   AGE
# kuberay-operator-6fcbb94f64-gkpc9             1/1     Running   0          89s
# raycluster-kuberay-head-qp9f4                 1/1     Running   0          66s
# raycluster-kuberay-worker-workergroup-2jckt   1/1     Running   0          66s

# Step 5: Forward the port of Dashboard
kubectl port-forward svc/kuberay-kuberay-cluster-head-svc 8265:8265

# Step 6: Check 127.0.0.1:8265 for the Dashboard

# Step 7: Log in to Ray head Pod and execute a job.

export HEAD_POD=$(kubectl get pods --selector=ray.io/node-type=head -o custom-columns=POD:metadata.name --no-headers)
echo $HEAD_POD
# raycluster-kuberay-head-vkj4n

# Print the cluster resources.
kubectl exec -it $HEAD_POD -- python -c "import ray; ray.init(); print(ray.cluster_resources())"

# Step 8: Check 127.0.0.1:8265/#/job. The status of the job should be "SUCCEEDED".

```

## Leveraging RayJob

```bash

# Step 9: Run Ray Job Sample, Deploys both Ray Cluster and Ray Job
kubectl apply -f https://raw.githubusercontent.com/ray-project/kuberay/v1.1.0-rc.0/ray-operator/config/samples/ray-job.sample.yaml

$ k get rayjob,raycluster
NAME                          JOB STATUS   DEPLOYMENT STATUS   START TIME             END TIME               AGE
rayjob.ray.io/rayjob-sample   SUCCEEDED    Complete            2024-04-01T16:51:00Z   2024-04-01T16:51:56Z   2m1s

NAME                                               DESIRED WORKERS   AVAILABLE WORKERS   CPUS   MEMORY   GPUS   STATUS   AGE
raycluster.ray.io/kuberay-kuberay-cluster          1                 1                   2      3G       0      ready    13m
raycluster.ray.io/rayjob-sample-raycluster-nsfzc   1                 1                   400m   0        0      ready    2m1s

# Step 10: Check the status of the RayJob.
kubectl get rayjobs.ray.io rayjob-sample -o jsonpath='{.status.jobStatus}'
# [Expected output]: "SUCCEEDED"

kubectl get rayjobs.ray.io rayjob-sample -o jsonpath='{.status.jobDeploymentStatus}'
# [Expected output]: "Complete"
kubectl logs -l=job-name=rayjob-sample
kubectl delete -f https://raw.githubusercontent.com/ray-project/kuberay/v1.1.0-rc.0/ray-operator/config/samples/ray-job.sample.yaml


## Create a RayJob with shutdownAfterJobFinishes set to true

kubectl apply -f https://raw.githubusercontent.com/ray-project/kuberay/v1.1.0-rc.0/ray-operator/config/samples/ray-job.shutdown.yaml
kubectl delete -f https://raw.githubusercontent.com/ray-project/kuberay/v1.1.0-rc.0/ray-operator/config/samples/ray-job.shutdown.yaml
```




TODO: 
- [ ] Setup Prometheus
- [ ] Setup Grafana
- [ ] Setup FlameDriver/Stack Driver