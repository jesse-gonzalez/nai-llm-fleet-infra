helm repo add uptrace https://charts.uptrace.dev
helm repo update uptrace
kubectl create ns uptrace

helm upgrade --install -n uptrace uptrace uptrace/uptrace -f uptrace-values.yaml --version=v1.5.7

kubectl apply -f grpc-ingress.yaml -n uptrace