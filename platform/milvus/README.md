# Cluster Install
helm repo add milvus https://zilliztech.github.io/milvus-helm/
helm repo update

helm upgrade --install milvus-vectordb milvus/milvus -n milvus --create-namespace -f values.yaml --version=4.1.13