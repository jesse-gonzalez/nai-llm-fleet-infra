kubectl create ns jupyterhub

## if shared Folder should be used create the shared pvc upfront
kubectl apply -f shared-volume.yaml

helm repo add jupyterhub https://hub.jupyter.org/helm-chart/
helm repo update

helm upgrade --install jupyterhub jupyterhub/jupyterhub \
  --namespace jupyterhub \
  --values values.yaml \
  --version=3.1.0
  