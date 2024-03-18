helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
kubectl create ns elastic-dev
helm upgrade --install elastic-dev bitnami/elasticsearch -n elastic-dev --version 19.13.10 -f elastic-values.yaml