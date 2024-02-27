Use version 1.10.1 to match kserve knative installation for 1.25.x

# Knative Eventing Core
kubectl apply -f https://github.com/knative/eventing/releases/download/knative-v1.11.11/eventing-crds.yaml
kubectl apply -f https://github.com/knative/eventing/releases/download/knative-v1.11.11/eventing-core.yaml

# Knative Eventing Kafka Broker

kubectl apply -f https://github.com/knative-sandbox/eventing-kafka-broker/releases/download/knative-v1.11.11/eventing-kafka-controller.yaml
kubectl apply -f https://github.com/knative-sandbox/eventing-kafka-broker/releases/download/knative-v1.11.11/eventing-kafka-source.yaml


