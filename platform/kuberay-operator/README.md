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
kubectl port-forward svc/raycluster-kuberay-head-svc 8265:8265

# Step 6: Check 127.0.0.1:8265 for the Dashboard

# Step 7: Log in to Ray head Pod and execute a job.
kubectl exec -it ${RAYCLUSTER_HEAD_POD} -- bash
python -c "import ray; ray.init(); print(ray.cluster_resources())" # (in Ray head Pod)

# Step 8: Check 127.0.0.1:8265/#/job. The status of the job should be "SUCCEEDED".
```