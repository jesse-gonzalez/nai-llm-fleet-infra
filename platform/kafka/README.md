helm repo add bitnami https://charts.bitnami.com/bitnami

helm upgrade --install  kafka bitnami/kafka --create-namespace -n kafka -f values.yaml


Change number of Partitions to allow scaling knative

kafka-topics.sh --bootstrap-server localhost:9092 --alter --topic OSSEvents --partitions 4

kubectl exec -it svc/kafka-kafka -n kafka -c kafka -- $KAFKA_HOME/kafka-topics.sh --bootstrap-server localhost:9092 --alter --topic $TOPIC_NAME --partitions 4