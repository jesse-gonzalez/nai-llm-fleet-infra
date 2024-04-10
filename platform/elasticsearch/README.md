helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
kubectl create ns elastic-dev
helm upgrade --install elastic-dev bitnami/elasticsearch -n elastic-dev --version 19.13.10 -f elastic-values.yaml


helm repo add elastic https://helm.elastic.co
helm install my-elasticsearch elastic/elasticsearch --version 8.5.1

elastic values

for operator: ( replicas 1 we are using )

    resources:
      limits:
        cpu: 250m
        ephemeral-storage: 1Gi
        memory: 512Mi
      requests:
        cpu: 250m
        ephemeral-storage: 1Gi
        memory: 512Mi

    initResources:
      limits:
        cpu: 100m
        ephemeral-storage: 1008Mi
        memory: 50Mi
      requests:
        cpu: 100m
        ephemeral-storage: 1008Mi
        memory: 50Mi

    volumeClaimTemplate:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 500Gi

resources:
      limits:
        cpu: 250m
        ephemeral-storage: 1Gi
        memory: 512Mi
      requests:
        cpu: 250m
        ephemeral-storage: 1Gi
        memory: 512Mi

for elaticsearch [ 500gb space better for prod ]

image: docker.elastic.co/elasticsearch/elasticsearch:8.11.1
        name: elastic-internal-init-filesystem
        resources:
          limits:
            cpu: 100m
            ephemeral-storage: 1008Mi
            memory: 50Mi
          requests:
            cpu: 100m
            ephemeral-storage: 1008Mi
            memory: 50Mi
