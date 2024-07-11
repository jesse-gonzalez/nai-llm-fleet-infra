## About this platform directory

IMPORTANT: The `manifests/localized-files` folders are generated from the `kustomization.yaml` that are stored within root of each directory.

To generate the `manifests/localized-files` directories using `kusomize local` cli, you can run one for the following commands:

```bash
kustomize:localize-all:                      Leverages kustomize localize to download all remote manifests
kustomize:localize-knative-eventing:         Leverages kustomize localize to download all remote manifests for knative-eventing
kustomize:localize-knative-istio:            Leverages kustomize localize to download all remote manifests for knative-istio
kustomize:localize-knative-serving:          Leverages kustomize localize to download all remote manifests for knative-serving
kustomize:localize-kserve:                   Leverages kustomize localize to download all remote manifests for kserve
kustomize:localize-kubeflow:                   Leverages kustomize localize to download all remote manifests for kubeflow
```
