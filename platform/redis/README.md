helm repo add bitnami https://charts.bitnami.com/bitnami

helm upgrade --install redis bitnami/redis --create-namespace -n redis --version 18.1.6

export REDIS_PASSWORD=$(kubectl get secret --namespace redis redis -o jsonpath="{.data.redis-password}" | base64 -d)