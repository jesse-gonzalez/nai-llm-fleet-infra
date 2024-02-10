kubectl create ns opentelemetry

kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/latest/download/opentelemetry-operator.yaml

kubectl apply -f prometheus-rbac.yaml -n opentelemetry
kubectl apply -f targetallocator.yaml -n opentelemetry



helm upgrade --install opentelemetry-collector-deployment open-telemetry/opentelemetry-collector -f otel-deployment-values.yaml -n opentelemetry

helm upgrade --install opentelemetry-collector-daemon open-telemetry/opentelemetry-collector -f otel-daemon-values.yaml -n opentelemetry

helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm install my-opentelemetry-collector open-telemetry/opentelemetry-collector \
   --set mode=<daemonset|deployment|statefulset>




helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm install my-opentelemetry-operator open-telemetry/opentelemetry-operator \
  --set admissionWebhooks.certManager.enabled=false \
  --set admissionWebhooks.certManager.autoGenerateCert.enabled=true


components:
  frontendProxy:
    ingress:
      enabled: true
      annotations: {}
      hosts:
        - host: otel-demo.my-domain.com
          paths:
            - path: /
              pathType: Prefix
              port: 8080
