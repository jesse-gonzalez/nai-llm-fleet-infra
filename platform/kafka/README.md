helm repo add bitnami https://charts.bitnami.com/bitnami

helm upgrade --install  kafka bitnami/kafka --create-namespace -n kafka -f values.yaml

Change number of Partitions to allow scaling knative

kafka-topics.sh --bootstrap-server localhost:9092 --alter --topic OSSEvents --partitions 4

kubectl exec -it svc/kafka-kafka -n kafka -c kafka -- $KAFKA_HOME/kafka-topics.sh --bootstrap-server localhost:9092 --alter --topic $TOPIC_NAME --partitions 4

https://milvus.io/docs/v2.2.x/deploy_pulsar.md
https://kafka.apache.org/documentation/#brokerconfigs_message.max.bytes

max.request.size	The maximum size of a request in bytes.	5242880
message.max.bytes	The largest record batch size allowed by Kafka (1048588 = 1 MiB).	10485760
auto.create.topics.enable	Enable auto creation of topic on the server.	true
num.partitions	The default number of log partitions per topic. 1