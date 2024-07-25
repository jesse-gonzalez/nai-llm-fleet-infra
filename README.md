- [Deploying GPT-in-a-Box NVD Reference Application using GitOps (FluxCD)](#deploying-gpt-in-a-box-nvd-reference-application-using-gitops-fluxcd)
  - [Overview](#overview)
  - [PreRequisites](#prerequisites)
  - [Getting Started](#getting-started)
    - [Option 1: Install Minimal CLI Tools on Local Machine / JumpServer](#option-1-install-minimal-cli-tools-on-local-machine--jumpserver)
    - [Option 2: Leverage Devbox NIX Shell as Development Environment](#option-2-leverage-devbox-nix-shell-as-development-environment)
    - [Bootstrapping Management and Workload NKE Clusters](#bootstrapping-management-and-workload-nke-clusters)
      - [Silent Bootstrap](#silent-bootstrap)
  - [LLM Managment and Workload Profile Overview](#llm-managment-and-workload-profile-overview)
    - [Component to Profile Mappings](#component-to-profile-mappings)
    - [Variables](#variables)
      - [`k8s_cluster` Section](#k8s_cluster-section)
      - [`flux` Section](#flux-section)
      - [`infra` Section](#infra-section)
      - [`services` Section](#services-section)
      - [`apps` Section](#apps-section)
  - [Appendix](#appendix)
    - [Directory Structure](#directory-structure)

# Deploying GPT-in-a-Box NVD Reference Application using GitOps (FluxCD)

*WARNING:* This repository is intended to be a supplementary repository for bootstrapping the reference application explored with the [Nutanix GPT-in-a-Box Validated Design (NVD)](https://portal.nutanix.com/page/documents/solutions/details?targetId=NVD-2115-GPT-in-a-Box-6-7-Design:NVD-2115-GPT-in-a-Box-6-7-Design) document, and is intended to be used only as a reference for self-learning or lab development purposes - not for production!

## Overview

This repository was designed to support the [GPT-in-a-Box NVD reference application](https://portal.nutanix.com/page/documents/solutions/details?targetId=NVD-2115-GPT-in-a-Box-6-7-Design:application-cluster-designs.html), and includes a GitOps based reference framework for explicitly deploying the applications and  dependent platform services on both the centralized management and dependent workload clusters running on Kubernetes using [FluxCD](https://fluxcd.io/).

## PreRequisites

Overall there are few [core infrastructure components](https://portal.nutanix.com/page/documents/solutions/details?targetId=NVD-2115-GPT-in-a-Box-6-7-Design:core-infrastructure-design.html), such as Nutanix NKE and NUS that required to deploy and integrate all components of the GPT-in-a-Box (GiaB) NVD Reference Application, and will be needed to be made available prior to deployment.  

Detailed deployment instructions of dependent components will not be covered in detail in this repository.

## Getting Started

The below assumes that you are either leveraging a local machine with Linux terminal or jumpserver

### Option 1: Install Minimal CLI Tools on Local Machine / JumpServer

Whether you're on a jumpserver, or running each step on local Linux/Windows terminal, the minimum tools needed are listed to bootstrap and configure any NKE cluster below:

| Tool | Install Link | macOS Example | Linux Example | Purpose | License Link |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| Go-Task | [Task GitHub](https://github.com/go-task/task#installation) | `brew install go-task/tap/go-task` | `sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d` | A task runner / simpler Make alternative written in Go | [MIT License](https://github.com/go-task/task/blob/main/LICENSE) |
| Gomplate | [Gomplate GitHub](https://github.com/hairyhenderson/gomplate#installation) | `brew install gomplate` | ```curl -o /usr/local/bin/gomplate -sSL https://github.com/hairyhenderson/gomplate/releases/latest/download/gomplate_linux-amd64 && chmod 755 /usr/local/bin/gomplate``` | Template renderer which supports various data sources | [MIT License](https://github.com/hairyhenderson/gomplate/blob/main/LICENSE) |
| Kubectl | [Kubectl Docs](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) | `brew install kubectl` | ```curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && chmod +x kubectl && sudo mv kubectl /usr/local/bin/``` | Command-line tool for controlling Kubernetes clusters | [Apache License 2.0](https://github.com/kubernetes/kubernetes/blob/master/LICENSE) |
| Helm | [Helm Docs](https://helm.sh/docs/intro/install/) | `brew install helm` | `curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \| bash` | Package manager for Kubernetes | [Apache License 2.0](https://github.com/helm/helm/blob/main/LICENSE) |
| Age | [Age GitHub](https://github.com/FiloSottile/age#installation) | `brew install age` | ```curl -LO https://github.com/FiloSottile/age/releases/download/v1.0.0/age-v1.0.0-linux-amd64.tar.gz && tar -xzf age-v1.0.0-linux-amd64.tar.gz && sudo mv age/age /usr/local/bin/ && sudo mv age/age-keygen /usr/local/bin/``` | A simple, modern, and secure file encryption tool | [BSD 3-Clause License](https://github.com/FiloSottile/age/blob/main/LICENSE) |
| Sops | [SOPS GitHub](https://github.com/mozilla/sops#1-install) | `brew install sops` | ```wget https://github.com/mozilla/sops/releases/download/v3.7.3/sops-v3.7.3.linux.amd64 && mv sops-v3.7.3.linux.amd64 /usr/local/bin/sops && chmod +x /usr/local/bin/sops``` | Encryption tool for managing secrets | [Mozilla Public License 2.0](https://github.com/mozilla/sops/blob/develop/LICENSE) |
| Flux | [Flux Docs](https://fluxcd.io/docs/installation/) | `brew install fluxcd/tap/flux` | `curl -s https://fluxcd.io/install.sh \| sudo bash` | GitOps tool for deploying applications to Kubernetes | [Apache License 2.0](https://github.com/fluxcd/flux2/blob/main/LICENSE) |
| Krew Kubectl Plugin Package Manager | [Krew Docs](https://krew.sigs.k8s.io/docs/user-guide/setup/install/) | ```See [Krew Install](https://krew.sigs.k8s.io/docs/user-guide/setup/install/)``` | Same | Plugin manager for kubectl command-line tool | [Apache License 2.0](https://github.com/kubernetes-sigs/krew/blob/master/LICENSE) |
| Karbon Plugin | [Karbon CLI Docs](https://portal.nutanix.com/page/documents/details?targetId=Karbon-v2_1:kar-karbon-cli-reference-r.html) | `kubectl krew install karbon` (after installing Krew) | Same | Nutanix Karbon plugin for kubectl | [Apache License 2.0](https://github.com/nutanix/karbon/blob/master/LICENSE) |
| jq | [jq GitHub](https://github.com/stedolan/jq) | `brew install jq` | `sudo apt-get install jq` | Command-line JSON processor | [MIT License](https://github.com/stedolan/jq/blob/master/COPYING) |
| yq | [yq GitHub](https://github.com/mikefarah/yq) | `brew install yq` | `wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq` | Portable command-line YAML, JSON, and XML processor | [MIT License](https://github.com/mikefarah/yq/blob/master/LICENSE) |
| Gum Charm | [Gum GitHub](https://github.com/charmbracelet/gum) | `brew install gum` | ```curl -sSL https://github.com/charmbracelet/gum/releases/latest/download/gum_linux_amd64.tar.gz \| tar xz && sudo mv gum /usr/local/bin/``` | Tool for creating glamorous shell scripts | [MIT License](https://github.com/charmbracelet/gum/blob/main/LICENSE) |
| arkade | [arkade GitHub](https://github.com/alexellis/arkade) | `curl -sLS https://get.arkade.dev \| sudo sh` | Same | Marketplace for downloading your favorite devops CLIs and installing helm charts | [MIT License](https://github.com/alexellis/arkade/blob/master/LICENSE) |
| GitHub CLI | [GitHub CLI Docs](https://cli.github.com/) | `brew install gh` | `sudo apt install gh` | GitHub’s official command line tool | [MIT License](https://github.com/cli/cli/blob/trunk/LICENSE) |
| fzf | [fzf GitHub](https://github.com/junegunn/fzf) | `brew install fzf` | `sudo apt-get install fzf` | A command-line fuzzy finder | [MIT License](https://github.com/junegunn/fzf/blob/master/LICENSE) |

### Option 2: Leverage Devbox NIX Shell as Development Environment

As an alternative, you can leverage [Devbox NixOS Shell](https://github.com/jetpack-io/devbox) to provision the tools needed within an isolated developoment environment either locally or on remote jumpserver/bastion host.

Install `devbox` and Accept All Defaults:

```sh
curl -fsSL https://get.jetpack.io/devbox | bash
```

Start the `devbox shell` and if `nix` isn't available, you will be prompted to install:

```sh
devbox shell
```

By default, Devbox will install the cli tool packages listed in `devbox.json` when you run `devbox shell` within the code workspace. These packages are available within the [Nixos](https://search.nixos.org/packages) package manager, and below is listing of each package

| Tool | Install Link | Purpose | License Link | Devbox Add Command |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------- | -------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ | ----------------------------------- |
| [jq@1.7.1](https://search.nixos.org/packages?channel=23.11&show=jq&from=0&size=50&sort=relevance&type=packages&query=jq) | [jq GitHub](https://github.com/stedolan/jq) | Command-line JSON processor | [MIT License](https://github.com/stedolan/jq/blob/master/COPYING) | `devbox add jq@1.7.1` |
| [gum@0.13.0](https://search.nixos.org/packages?channel=23.11&show=gum&from=0&size=50&sort=relevance&type=packages&query=gum) | [Gum GitHub](https://github.com/charmbracelet/gum) | Tool for creating glamorous shell scripts | [MIT License](https://github.com/charmbracelet/gum/blob/main/LICENSE) | `devbox add gum@0.13.0` |
| [gh@2.46.0](https://search.nixos.org/packages?channel=23.11&show=gh&from=0&size=50&sort=relevance&type=packages&query=gh) | [GitHub CLI Docs](https://cli.github.com/) | GitHub's official command line tool | [MIT License](https://github.com/cli/cli/blob/trunk/LICENSE) | `devbox add gh@2.46.0` |
| [kubectl@1.29.3](https://search.nixos.org/packages?channel=23.11&show=kubectl&from=0&size=50&sort=relevance&type=packages&query=kubectl) | [Kubectl Docs](https://kubernetes.io/docs/tasks/tools/) | Command-line tool for controlling Kubernetes clusters | [Apache License 2.0](https://github.com/kubernetes/kubernetes/blob/master/LICENSE) | `devbox add kubectl@1.29.3` |
| [age@1.1.1](https://search.nixos.org/packages?channel=23.11&show=age&from=0&size=50&sort=relevance&type=packages&query=age) | [Age GitHub](https://github.com/FiloSottile/age) | A simple, modern, and secure file encryption tool | [BSD 3-Clause License](https://github.com/FiloSottile/age/blob/master/LICENSE) | `devbox add age@1.1.1` |
| [arkade@0.11.6](https://search.nixos.org/packages?channel=23.11&show=arkade&from=0&size=50&sort=relevance&type=packages&query=arkade) | [arkade GitHub](https://github.com/alexellis/arkade) | Marketplace for downloading your favorite devops CLIs and installing helm charts | [MIT License](https://github.com/alexellis/arkade/blob/master/LICENSE) | `devbox add arkade@0.11.6` |
| [yq-go@4.43.1](https://search.nixos.org/packages?channel=23.11&show=yq-go&from=0&size=50&sort=relevance&type=packages&query=yq-go) | [yq GitHub](https://github.com/mikefarah/yq) | Portable command-line YAML, JSON, and XML processor | [MIT License](https://github.com/mikefarah/yq/blob/master/LICENSE) | `devbox add yq-go@4.43.1` |
| [sops@3.8.1](https://search.nixos.org/packages?channel=23.11&show=sops&from=0&size=50&sort=relevance&type=packages&query=sops) | [SOPS GitHub](https://github.com/mozilla/sops) | Encryption tool for managing secrets | [Mozilla Public License 2.0](https://github.com/mozilla/sops/blob/develop/LICENSE) | `devbox add sops@3.8.1` |
| [kubernetes-helm@3.14.3](https://search.nixos.org/packages?channel=23.11&show=kubernetes-helm&from=0&size=50&sort=relevance&type=packages&query=kubernetes-helm) | [Helm Docs](https://helm.sh/docs/intro/install/) | Package manager for Kubernetes | [Apache License 2.0](https://github.com/helm/helm/blob/main/LICENSE) | `devbox add kubernetes-helm@3.14.3` |
| [go-task@3.35.1](https://search.nixos.org/packages?channel=23.11&show=go-task&from=0&size=50&sort=relevance&type=packages&query=go-task) | [Task GitHub](https://github.com/go-task/task) | A task runner / simpler Make alternative written in Go | [MIT License](https://github.com/go-task/task/blob/main/LICENSE) | `devbox add go-task@3.35.1` |
| [krew@0.4.4](https://search.nixos.org/packages?channel=23.11&show=krew&from=0&size=50&sort=relevance&type=packages&query=krew) | [Krew Docs](https://krew.sigs.k8s.io/docs/user-guide/setup/install/) | Plugin manager for kubectl command-line tool | [Apache License 2.0](https://github.com/kubernetes-sigs/krew/blob/master/LICENSE) | `devbox add krew@0.4.4` |
| [kubectx@0.9.5](https://search.nixos.org/packages?channel=23.11&show=kubectx&from=0&size=50&sort=relevance&type=packages&query=kubectx) | [kubectx GitHub](https://github.com/ahmetb/kubectx) | Tool to switch between Kubernetes contexts | [Apache License 2.0](https://github.com/ahmetb/kubectx/blob/master/LICENSE) | `devbox add kubectx@0.9.5` |
| [opentofu@1.6.2](https://search.nixos.org/packages?channel=23.11&show=opentofu&from=0&size=50&sort=relevance&type=packages&query=opentofu) | [OpenTofu GitHub](https://github.com/opentofu/opentofu) | Open-source alternative to Terraform | [Mozilla Public License 2.0](https://github.com/opentofu/opentofu/blob/main/LICENSE) | `devbox add opentofu@1.6.2` |
| [fluxcd@2.2.3](https://search.nixos.org/packages?channel=23.11&show=fluxcd&from=0&size=50&sort=relevance&type=packages&query=fluxcd) | [Flux Docs](https://fluxcd.io/docs/installation/) | GitOps tool for deploying applications to Kubernetes | [Apache License 2.0](https://github.com/fluxcd/flux2/blob/main/LICENSE) | `devbox add fluxcd@2.2.3` |
| [stern@1.28.0](https://search.nixos.org/packages?channel=23.11&show=stern&from=0&size=50&sort=relevance&type=packages&query=stern) | [Stern GitHub](https://github.com/stern/stern) | Multi pod and container log tailing for Kubernetes | [Apache License 2.0](https://github.com/stern/stern/blob/master/LICENSE) | `devbox add stern@1.28.0` |
| [fzf@0.47.0](https://search.nixos.org/packages?channel=23.11&show=fzf&from=0&size=50&sort=relevance&type=packages&query=fzf) | [fzf GitHub](https://github.com/junegunn/fzf) | A command-line fuzzy finder | [MIT License](https://github.com/junegunn/fzf/blob/master/LICENSE) | `devbox add fzf@0.47.0` |
| [gomplate@3.11.7](https://search.nixos.org/packages?channel=23.11&show=gomplate&from=0&size=50&sort=relevance&type=packages&query=gomplate) | [Gomplate GitHub](https://github.com/hairyhenderson/gomplate) | Template renderer which supports various data sources | [MIT License](https://github.com/hairyhenderson/gomplate/blob/main/LICENSE) | `devbox add gomplate@3.11.7` |

### Bootstrapping Management and Workload NKE Clusters

Follow the procedures below for the management cluster has run into full completion, then rinse and repeat for each subsequent workload specific cluster (e.g., prod, dev, qa, etc.)

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

    For a breakdown of what components are required to be configured for each profile (i.e., `llm-management` or `llm-workloads`) based on environment-type (i.e., `non-prod` vs `prod`), see [LLM Managment and Workload Profile to Component Mappings](#llm-managment-and-workload-profile-overview).

    To see more detail on what variables are required for each component based on environment type, see [Variables](#variables).

3. Generate and Validate Configurations
  
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

6. [Optional] Taint GPU Nodepool with `nvidia.com/gpu.present=true:NoSchedule`

    > NOTE: if undesired workloads already running on gpu nodepools, drain nodes using `task kubectl:drain_gpu_nodes`

    ```bash
    ## taint gpu nodes with label nvidia.com/gpu.present=true
    task kubectl:taint_gpu_nodes

    ## view taint configurations on all nodes
    kubectl get nodes -o='custom-columns=NodeName:.metadata.name,TaintKey:.spec.taints[*].key,TaintValue:.spec.taints[*].value,TaintEffect:.spec.taints[*].effect'
    ```

7. Run Flux Bootstrapping - `task bootstrap:silent`

    ```bash
    task bootstrap:silent
    ```

    > NOTE: if there are any issues, troubleshot using `task ts:flux-collect`. You can re-run task `bootstrap:silent` as many times needed

8. Monitor on New Terminal

    ```bash
    eval $(task nke:switch-shell-env) && \
    task flux:watch
    ```

    > NOTE: if there are any issues, update local git repo, push up changes and run `task flux:reconcile`

## LLM Managment and Workload Profile Overview

### Component to Profile Mappings

The table below provides an overview of which components are recommended to be configured based on the different profile types and environments listed under `clusters/_profiles/llm-*`.

Legend:

- ✅: Required for given profile
- ❌: Not applicable or not specified for this profile
- ✅ (non-prod): Is enabled ONLY in non-production environments
- ✅ (prod): Is enabled ONLY in production environments

| Component | Parameter | llm-management | llm-workloads |
| ----------------------- | ------------------------------------------- | :------------: | :-----------: |
| GPU Operator | `gpu_operator.enabled` |       ❌ |       ✅ |
| GPU Time Slicing | `gpu_operator.time_slicing.enabled` |       ❌ | ✅ (non-prod) |
| Prism Central | `nutanix.prism_central.enabled` |       ✅ |       ✅ |
| Objects Store | `nutanix.objects.enabled` |       ✅ |       ✅ |
| Kube-vip | `kube_vip.enabled` |       ✅ |       ✅ |
| Nginx Ingress | `nginx_ingress.enabled` |       ✅ |       ✅ |
| Istio | `istio.enabled` |       ❌ |       ✅ |
| Cert Manager | `cert_manager.enabled` |       ✅ |       ✅ |
| AWS Route53 ACME DNS | `cert_manager.aws_route53_acme_dns.enabled` |    ✅ (prod) |   ✅ (prod) |
| Kyverno | `kyverno.enabled` |       ✅ |       ✅ |
| KServe | `kserve.enabled` |       ❌ |       ✅ |
| Knative Serving | `knative_serving.enabled` |       ❌ |       ✅ |
| Knative Istio | `knative_istio.enabled` |       ❌ |       ✅ |
| Milvus | `milvus.enabled` |       ✅ |       ✅ |
| Knative Eventing | `knative_eventing.enabled` |       ❌ |       ✅ |
| Kafka | `kafka.enabled` |       ✅ |       ✅ |
| OpenTelemetry Collector | `opentelemetry_collector.enabled` |       ✅ |       ✅ |
| OpenTelemetry Operator | `opentelemetry_operator.enabled` |       ✅ |       ✅ |
| Uptrace | `uptrace.enabled` |       ✅ |       ❌ |
| JupyterHub | `jupyterhub.enabled` |       ❌ | ✅ (non-prod) |
| Weave GitOps | `weave_gitops.enabled` |       ✅ |       ✅ |
| GPT NVD Reference App | `gptnvd_reference_app.enabled` |       ❌ |       ✅ |
| NAI LLM Helm Chart | `nai_helm.enabled` |       ❌ |       ✅ |

### Variables

Below are the various variables and values that could be defined with the `.env.CLUSTER_NAME.yaml` configuration file.

The parameters are listed based on the various sections required for either all profiles and environments, or specific to just `llm-management`, `llm-workloads` or `non-prod`, `prod` use cases.  

> NOTE: While `prod` is in the naming convention of `environment` name, it is only intended to demonstrate what a `production-like` configuration may require from an advanced configuration perspective, such as valid TLS, monitoring, logging, HA, etc.

#### `k8s_cluster` Section

This section is required for all profiles and environments. It includes configurations for the Kubernetes cluster, Docker Hub registry, and GPU-specific settings.

| Parameter | Required | Default Value | Profile/Environment Type | Description |
| ----------------------------------------- | -------- | --------------- | ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------- |
| `distribution` | No | nke | All | Kubernetes distribution. Supported options are "nke" and "kind". Example: kind |
| `name` | Yes | "" | All | Kubernetes cluster name. Example: my-cluster |
| `profile` | Yes | "" | All | Cluster profile type. Can be anything under clusters/_profiles (e.g., llm-management, llm-workloads, etc.). Example: llm-management |
| `environment` | Yes | "" | All | Environment name based on the selected profile under clusters/_profiles/<profile>/ (e.g., prod, non-prod, etc.). Example: prod |
| `registry.docker_hub.user` | Yes | "" | All | Docker Hub registry username. Example: docker_user |
| `registry.docker_hub.password` | Yes | "" | All | Docker Hub registry password. Example: docker_password |
| `gpu_operator.enabled` | No | false | llm-workloads | Enable NVIDIA GPU operator. Example: true |
| `gpu_operator.version` | No | v23.9.0 | llm-workloads | Version of the NVIDIA GPU operator. Example: v24.0.0 |
| `gpu_operator.cuda_toolkit_version` | No | v1.14.3-centos7 | llm-workloads | CUDA toolkit version for the GPU operator. Example: v1.15.0-ubuntu |
| `gpu_operator.time_slicing.enabled` | No | false | llm-workloads (non-prod) | Enable GPU time slicing. Example: true |
| `gpu_operator.time_slicing.replica_count` | No | 2 | llm-workloads (non-prod) | Number of replicas for GPU time slicing. Example: 3 |

#### `flux` Section

This section is required for all profiles and environments. It includes Flux-specific configurations for the GitHub repository.

| Parameter | Required | Default Value | Profile/Environment Type | Description |
| ----------------------- | -------- | ------------- | ------------------------ | --------------------------------------------------------------------- |
| `github.repo_url` | Yes | "" | All | GitHub repository URL for Flux. Example: https://github.com/user/repo |
| `github.repo_user` | Yes | "" | All | GitHub username for Flux. Example: github_user |
| `github.repo_api_token` | Yes | "" | All | GitHub API token for Flux. Example: github_token |

#### `infra` Section

This section is required for all profiles and environments. It includes global Nutanix configurations, including Prism Central credentials and Nutanix Objects Store configurations.

| Parameter | Required | Default Value | Profile/Environment Type | Description |
| -------------------------------- | ------------------------------------------ | ------------- | ----------------------------- | ------------------------------------------------------- |
| `nutanix.prism_central.enabled` | No | true | All | Enable Nutanix Prism Central. Example: false |
| `nutanix.prism_central.endpoint` | Yes | "" | All | Nutanix Prism Central endpoint. Example: prism_endpoint |
| `nutanix.prism_central.user` | Yes | "" | All | Nutanix Prism Central username. Example: prism_user |
| `nutanix.prism_central.password` | Yes | "" | All | Nutanix Prism Central password. Example: prism_password |
| `nutanix.objects.enabled` | No | false | llm-management, llm-workloads | Enable Nutanix Objects Store. Example: true |
| `nutanix.objects.host` | No (Required - If objects section enabled) | "" | llm-management, llm-workloads | Nutanix Objects store host. Example: objects_host |
| `nutanix.objects.port` | No (Required - If objects section enabled) | "" | llm-management, llm-workloads | Nutanix Objects store port. Example: 9000 |
| `nutanix.objects.region` | No (Required - If objects section enabled) | "" | llm-management, llm-workloads | Nutanix Objects store region. Example: us-west-1 |
| `nutanix.objects.use_ssl` | No (Required - If objects section enabled) | "" | llm-management, llm-workloads | Use SSL for Nutanix Objects store. Example: true |
| `nutanix.objects.access_key` | No (Required - If objects section enabled) | "" | llm-management, llm-workloads | Nutanix Objects store access key. Example: access_key |
| `nutanix.objects.secret_key` | No (Required - If objects section enabled) | "" | llm-management, llm-workloads | Nutanix Objects store secret key. Example: secret_key |

#### `services` Section

This section is required for all profiles and environments. It includes configurations for various services such as kube-vip, nginx-ingress, istio, and others.

| Parameter | Required | Default Value | Profile/Environment Type | Description |
| ---------------------------------------------------- | ------------------------------------------------------- | --------------- | ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------ |
| `kube_vip.enabled` | No | false | All | Enable kube-vip. Example: true |
| `kube_vip.ipam_range` | Yes | "" | All | IP range for kube-vip IPAM pool. Minimum of 2 IPs should be provided. Example: 172.20.0.22-172.20.0.23 |
| `nginx_ingress.enabled` | No | false | All | Enable nginx-ingress. Example: true |
| `nginx_ingress.version` | No | 4.8.3 | All | Version of nginx-ingress. Example: 4.9.0 |
| `nginx_ingress.vip` | Yes | "" | All | Virtual IP Address (VIP) dedicated for nginx-ingress controller. Example: 172.20.0.20 |
| `nginx_ingress.wildcard_ingress_subdomain` | Yes | "" | All | NGINX Wildcard Ingress Subdomain for all default ingress objects. Example: flux-kind-local.172.20.0.20.nip.io |
| `nginx_ingress.management_cluster_ingress_subdomain` | Yes | "" | All | Wildcard Ingress Subdomain for management cluster. Example: management.flux-kind-local.172.20.0.20.nip.io |
| `istio.enabled` | No | false | llm-workloads | Enable Istio. Example: true |
| `istio.version` | No | 1.17.2 | llm-workloads | Version of Istio. Example: 1.18.0 |
| `istio.vip` | No (Required - If istio section enabled) | "" | llm-workloads | Virtual IP Address (VIP) dedicated for Istio ingress gateway. Example: 172.20.0.21 |
| `istio.wildcard_ingress_subdomain` | No (Required - If istio section enabled) | "" | llm-workloads | Istio Ingress Gateway Wildcard Subdomain for knative/kserve LLM inference endpoints. Example: llm.flux-kind-local.172.20.0.21.nip.io |
| `cert_manager.enabled` | No | true | All | Enable cert-manager. Example: false |
| `cert_manager.version` | No | v1.13.5 | All | Version of cert-manager. Example: v1.14.0 |
| `cert_manager.aws_route53_acme_dns.enabled` | No | false | All (prod) | Enable AWS Route53 ACME DNS for Let's Encrypt. Example: true |
| `cert_manager.aws_route53_acme_dns.email` | No (Required - If aws_route53_acme_dns section enabled) | "" | All (prod) | Email for Let's Encrypt ACME DNS challenge. Example: user@example.com |
| `cert_manager.aws_route53_acme_dns.zone` | No (Required - If aws_route53_acme_dns section enabled) | "" | All (prod) | DNS zone for Let's Encrypt ACME DNS challenge. Example: example.com |
| `cert_manager.aws_route53_acme_dns.hosted_zone_id` | No (Required - If aws_route53_acme_dns section enabled) | "" | All (prod) | AWS Route53 hosted zone ID for Let's Encrypt ACME DNS challenge. Example: Z1234567890 |
| `cert_manager.aws_route53_acme_dns.region` | No (Required - If aws_route53_acme_dns section enabled) | "" | All (prod) | AWS region for Let's Encrypt ACME DNS challenge. Example: us-west-2 |
| `cert_manager.aws_route53_acme_dns.key_id` | No (Required - If aws_route53_acme_dns section enabled) | "" | All (prod) | AWS access key ID for Let's Encrypt ACME DNS challenge. Example: AWS_KEY_ID |
| `cert_manager.aws_route53_acme_dns.key_secret` | No (Required - If aws_route53_acme_dns section enabled) | "" | All (prod) | AWS secret access key for Let's Encrypt ACME DNS challenge. Example: AWS_KEY_SECRET |
| `kyverno.enabled` | No | true | All | Enable Kyverno. Example: false |
| `kyverno.version` | No | 3.1.4 | All | Version of Kyverno. Example: 3.2.0 |
| `kserve.enabled` | No | false | llm-workloads | Enable KServe. Example: true |
| `kserve.version` | No | v0.11.2 | llm-workloads | Version of KServe. Example: v0.12.0 |
| `knative_serving.enabled` | No | false | llm-workloads | Enable Knative Serving. Example: true |
| `knative_serving.version` | No | knative-v1.10.1 | llm-workloads | Version of Knative Serving. Example: knative-v1.11.0 |
| `knative_istio.enabled` | No | false | llm-workloads | Enable Knative Istio. Example: true |
| `knative_istio.version` | No | knative-v1.10.0 | llm-workloads | Version of Knative Istio. Example: knative-v1.11.0 |
| `milvus.enabled` | No | false | All | Enable Milvus. Example: true |
| `milvus.version` | No | 4.1.13 | All | Version of Milvus. Example: 4.2.0 |
| `milvus.milvus_bucket_name` | No | milvus | All | Milvus vector database bucket name. Example: milvus-bucket |
| `knative_eventing.enabled` | No | false | llm-workloads | Enable Knative Eventing. Example: true |
| `knative_eventing.version` | No | knative-v1.10.1 | llm-workloads | Version of Knative Eventing. Example: knative-v1.11.0 |
| `kafka.enabled` | No | false | All | Enable Kafka. Example: true |
| `kafka.version` | No | 26.8.5 | All | Version of Kafka. Example: 27.0.0 |
| `opentelemetry_collector.enabled` | No | false | All | Enable OpenTelemetry Collector. Example: true |
| `opentelemetry_collector.version` | No | 0.80.1 | All | Version of OpenTelemetry Collector. Example: 0.81.0 |
| `opentelemetry_operator.enabled` | No | false | All | Enable OpenTelemetry Operator. Example: true |
| `opentelemetry_operator.version` | No | 0.47.0 | All | Version of OpenTelemetry Operator. Example: 0.48.0 |
| `uptrace.enabled` | No | false | llm-management | Enable Uptrace. Example: true |
| `uptrace.version` | No | 1.5.7 | llm-management | Version of Uptrace. Example: 1.6.0 |
| `jupyterhub.enabled` | No | false | llm-workloads (non-prod) | Enable JupyterHub. Example: true |
| `jupyterhub.version` | No | 3.1.0 | llm-workloads (non-prod) | Version of JupyterHub. Example: 3.2.0 |
| `jupyterhub.password` | No | "" | llm-workloads (non-prod) | JupyterHub Default password for admin and allowed_users. Example: jupyterhub_password |
| `jupyterhub.overrides` | No | {} | llm-workloads (non-prod) | JupyterHub Custom Overrides YAML. Similar to helm-chart values key-pair values. Used to override values not handled by default (ex. adding custom allowed_users). Example below |
| `weave_gitops.enabled` | Yes | true | All | Enable Weave GitOps. Example: false |
| `weave_gitops.version` | Yes | 4.0.36 | All | Version of Weave GitOps. Example: 4.1.0 |
| `weave_gitops.password` | Yes | "" | All | Weave Gitops password for admin and allowed_users. Example: weave_gitops_password |

---

Example of `jupyterhub.overrides` in JupyterHub section:

  ```yaml
  ## Jupyterhub is deployed on non-prod workload clusters in NVD Reference
  jupyterhub:
    enabled: true
    version: 3.1.0
    ## default admin account password
    default_password: Nutanix.123
    ## this will merge or override only the inline values defined within platform/jupyterhub/_operators/jupyterhub.yaml, 
    ## but could be overriden by add-ons/patches, so use at your own risk
    ## example below merges hub config with additional users:
    overrides: |-
      hub:
        config:
          Authenticator:
            allowed_users:
            - wolfgang
            - jesse
  ```

#### `apps` Section

This section is required only for llm-workloads profiles and environments. It includes configurations for the GPT NVD Reference Application and NAI LLM Helm Chart.

| Parameter | Required | Default Value | Profile/Environment Type | Description |
| -------------------------------------------- | ------------------------------------------ | ---------------------------------------- | ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `gptnvd_reference_app.enabled` | No | false | llm-workloads | Enable GPT NVD Reference Application. Example: true |
| `gptnvd_reference_app.version` | No | 0.2.7 | llm-workloads | Version of GPT NVD Reference Application. Example: 0.3.0 |
| `gptnvd_reference_app.documents_bucket_name` | Yes | documents01 | llm-workloads | Document bucket name for GPT NVD Reference Application. Example: my-documents |
| `nai_helm.enabled` | No | false | llm-workloads | Enable NAI LLM Helm Chart. Example: true |
| `nai_helm.version` | No | 0.1.1 | llm-workloads | Version of NAI LLM Helm Chart. Example: 0.2.0 |
| `nai_helm.model` | No | llama2_7b_chat | llm-workloads | LLM model name to be used. Example: llama-2-13b-chat |
| `nai_helm.revision` | No | 94b07a6e30c3292b8265ed32ffdeccfdadf434a8 | llm-workloads | Revision of the LLM model. Example: c2f3ec81aac798ae26dcc57799a994dfbf521496 |
| `nai_helm.maxTokens` | No | 4000 | llm-workloads | Maximum number of tokens for LLM inference. Example: 5000 |
| `nai_helm.repPenalty` | No | 1.2 | llm-workloads | Repetition penalty for LLM inference. Example: 1.5 |
| `nai_helm.temperature` | No | 0.2 | llm-workloads | Temperature setting for LLM inference. Example: 0.3 |
| `nai_helm.topP` | No | 0.9 | llm-workloads | Top-p (nucleus sampling) setting for LLM inference. Example: 0.95 |
| `nai_helm.useExistingNFS` | No | false | llm-workloads | Use existing NFS for LLM models. Example: true |
| `nai_helm.nfs_export` | No (Required - If useExistingNFS is true) | "" | llm-workloads | NFS share where LLM models are stored. Example: /llm-model-store |
| `nai_helm.nfs_server` | No (Required - If useExistingNFS is true) | "" | llm-workloads | NFS server FQDN or IP address of Nutanix Files instance. Example: nfs_server |
| `nai_helm.huggingFaceToken` | No (Required - If useExistingNFS is false) | "" | llm-workloads | Hugging Face token required when useExistingNFS is False. Used to download the model when LLM is initialized. Example: hugging_face_token |

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
