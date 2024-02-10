##
podman build . -t quay.io/wolfgangntnx/doc-ingest:0.0.2
podman run -it -p 8080:8080 -e MILVUS_HOST=10.54.78.13 quay.io/wolfgangntnx/doc-ingest:0.0.2
