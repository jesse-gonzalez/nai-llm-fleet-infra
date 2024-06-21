- [Deploying GPT-in-a-Box NVD Reference Application using GitOps (FluxCD)](#deploying-gpt-in-a-box-nvd-reference-application-using-gitops-fluxcd)
  - [Getting Started](#getting-started)
    - [Option 1: Using Devbox NIX Shell](#option-1-using-devbox-nix-shell)
    - [Option 2: Using VSCode Devcontainer](#option-2-using-vscode-devcontainer)
    - [Bootstrapping New NKE Cluster](#bootstrapping-new-nke-cluster)
      - [Silent Bootstrap](#silent-bootstrap)
  - [Appendix](#appendix)
    - [Directory Structure](#directory-structure)

# Deploying GPT-in-a-Box NVD Reference Application using GitOps (FluxCD)

## Getting Started

### Option 1: Using Devbox NIX Shell

This project uses [devbox](https://github.com/jetpack-io/devbox) to manage its development environment.

Install `devbox` and accept all defaults:

```sh
curl -fsSL https://get.jetpack.io/devbox | bash
```

Start the `devbox shell` and if `nix` isn't available, you will be prompted to install:

```sh
devbox shell
```

### Option 2: Using VSCode Devcontainer

See Devcontainer Tutorial on using Devcontainer.json - [https://code.visualstudio.com/docs/devcontainers/tutorial](https://code.visualstudio.com/docs/devcontainers/tutorial)

### Bootstrapping New NKE Cluster

#### Silent Bootstrap

1. Set K8S_CLUSTER_NAME environment variable and copy `./.env.sample.yaml` to `./.env.${K8S_CLUSTER_NAME}.yaml`

    ```bash
    export K8S_CLUSTER_NAME=flux-kind-local
    cp ./.env.sample.yaml ./.env.${K8S_CLUSTER_NAME}.yaml
    ```

2. Update `.env.${K8S_CLUSTER_NAME}.yaml` with required values. If parameter is enabled, update required parameters below each section

    For example, if `kube_vip.enabled` is true, then uncomment and configure `kube_vip.ipam_range`:

    ```yaml
      kube_vip:
        enabled: false
        ## min. 2 ips for range (i.e., 10.38.110.22-10.38.110.23)
        ipam_range: required
    ```

3. [Optional] Generate and Validate Configurations
  
    ```bash
    task bootstrap:generate_cluster_configs
    ```
    Verify the generated cluster configs

    ```bash
    cat .local/${K8S_CLUSTER_NAME}/.env
    cat clusters/${K8S_CLUSTER_NAME}/platform/cluster-configs.yaml
    ```

4. [Optional] Validate Encrypted Secrets

    ```bash
    task sops:decrypt
    ```

5. Select New (or Switching to Existing) Cluster and Download NKE Creds

    ```bash
    eval $(task nke:switch-shell-env) && \
    task nke:download-creds && \
    kubectl get nodes
    ```
6. Taint the GPU nodes
    
    ```bash
    task kubectl:taint_gpu_nodes
    # if gpu are over utilised
    # task kubectl:drain_gpu_nodes
    ```

6. Run Flux Bootstrapping - `task bootstrap:silent`

    ```bash
    task bootstrap:silent
    ```

    > NOTE: if there are any issues, troubleshot using `task ts:flux-collect`. You can re-run task `bootstrap:silent` as many times needed

7. Monitor on New Terminal

    ```bash
    eval $(task nke:switch-shell-env) && \
    task flux:watch
    ```

    > NOTE: if there are any issues, update local git repo, push up changes and run `task flux:reconcile`

8. [Optional] Post Install - Taint GPU Nodepool with dedicated=gpu:NoSchedule

    >  if undesired workloads already running on gpu nodepools, drain nodes using `task kubectl:drain_gpu_nodes`

    ```bash
    ## taint gpu nodes with label nvidia.com/gpu.present=true
    task kubectl:taint_gpu_nodes

    ## view taint configurations on all nodes
    kubectl get nodes -o='custom-columns=NodeName:.metadata.name,TaintKey:.spec.taints[*].key,TaintValue:.spec.taints[*].value,TaintEffect:.spec.taints[*].effect'
    ```

## Appendix

### Directory Structure

```bash
.
├── configs # Directory for env configs used by local scripts
│   ├── _common
│   │   └── .env # Global env configs 
│   └── ...
├── scripts # Common path for local scripts
├── clusters
│   ├── _profiles # Directory for the varying different profiles
│   │   ├── _base # Base for all cluster profiles (things installed in all variants)
│   │       └── kustomization.yaml # Kustomize ref to one or many platform _base/<service> and _components/feature
│   │   ├── llm-management # Management cluster profile (defines management specific applications and platform variants)
│   │   └── llm-workloads # Workloads cluster profile (defines workload specific applications and platform variants)
│   ├── nke-management-cluster # An example cluster instance generated from `_templates/management-cluster`
│   │   ├── flux-system # Generated by flux bootstrap
│   │   └── platform # generated from _templates
│   │       ├── kustomization.yaml # Maps to `management` profile above and injects secrets/config in the cluster
│   │       ├── cluster-secrets.sops.yaml
│   │       └── cluster-configs.yaml
│   └── nke-workload-cluster-00 # An example cluster instance generated from `_templates/[prod|non-prod]-workload-cluster`
└── platform # Contains catalogue of all the platform services
    ├── cert-manager
    ├── ingress-nginx # Example service
    │   ├── _base # Base implementation of this service     
    │       ├── kustomization.yaml # Kustomize ref to ingress-nginx.yaml
    │       └── ingress-nginx.yaml # helm chart release details for ingress-nginx
    │   └── nodeport # Feature to expose nginx in a NodePort instead of in a LoadBalancer
    │       ├── kustomization.yaml # Component ref to _base and ingress-nginx-patch
    │       └── ingress-nginx-patch.yaml # patch that overrides ingress-nginx helm chart
    └── ...
```
