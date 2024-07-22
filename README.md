- [Deploying GPT-in-a-Box NVD Reference Application using GitOps (FluxCD)](#deploying-gpt-in-a-box-nvd-reference-application-using-gitops-fluxcd)
  - [Overview](#overview)
  - [PreRequisites](#prerequisites)
  - [Getting Started](#getting-started)
    - [Option 1: Install Minimal CLI Tools on Local Machine / JumpServer](#option-1-install-minimal-cli-tools-on-local-machine--jumpserver)
    - [Option 2: Leverage Devbox NIX Shell as Development Environment](#option-2-leverage-devbox-nix-shell-as-development-environment)
    - [Option 3: Using VSCode Devcontainer](#option-3-using-vscode-devcontainer)
    - [Bootstrapping each NKE Cluster](#bootstrapping-each-nke-cluster)
      - [Silent Bootstrap](#silent-bootstrap)
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

| Tool                                | Install Link | macOS Example | Linux Example | Purpose | License Link |
|-------------------------------------|--------------|---------------|---------------|---------|--------------|
| Go-Task       | [Task GitHub](https://github.com/go-task/task#installation) | `brew install go-task/tap/go-task` | `sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d` | A task runner / simpler Make alternative written in Go | [MIT License](https://github.com/go-task/task/blob/main/LICENSE) |
| Gomplate      | [Gomplate GitHub](https://github.com/hairyhenderson/gomplate#installation) | `brew install gomplate` | ```curl -o /usr/local/bin/gomplate -sSL https://github.com/hairyhenderson/gomplate/releases/latest/download/gomplate_linux-amd64 && chmod 755 /usr/local/bin/gomplate``` | Template renderer which supports various data sources | [MIT License](https://github.com/hairyhenderson/gomplate/blob/main/LICENSE) |
| Kubectl       | [Kubectl Docs](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) | `brew install kubectl` | ```curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && chmod +x kubectl && sudo mv kubectl /usr/local/bin/``` | Command-line tool for controlling Kubernetes clusters | [Apache License 2.0](https://github.com/kubernetes/kubernetes/blob/master/LICENSE) |
| Helm          | [Helm Docs](https://helm.sh/docs/intro/install/) | `brew install helm` | `curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \| bash` | Package manager for Kubernetes | [Apache License 2.0](https://github.com/helm/helm/blob/main/LICENSE) |
| Age           | [Age GitHub](https://github.com/FiloSottile/age#installation) | `brew install age` | ```curl -LO https://github.com/FiloSottile/age/releases/download/v1.0.0/age-v1.0.0-linux-amd64.tar.gz && tar -xzf age-v1.0.0-linux-amd64.tar.gz && sudo mv age/age /usr/local/bin/ && sudo mv age/age-keygen /usr/local/bin/``` | A simple, modern, and secure file encryption tool | [BSD 3-Clause License](https://github.com/FiloSottile/age/blob/main/LICENSE) |
| Sops          | [SOPS GitHub](https://github.com/mozilla/sops#1-install) | `brew install sops` | ```wget https://github.com/mozilla/sops/releases/download/v3.7.3/sops-v3.7.3.linux.amd64 && mv sops-v3.7.3.linux.amd64 /usr/local/bin/sops && chmod +x /usr/local/bin/sops``` | Encryption tool for managing secrets | [Mozilla Public License 2.0](https://github.com/mozilla/sops/blob/develop/LICENSE) |
| Flux          | [Flux Docs](https://fluxcd.io/docs/installation/) | `brew install fluxcd/tap/flux` | `curl -s https://fluxcd.io/install.sh \| sudo bash` | GitOps tool for deploying applications to Kubernetes | [Apache License 2.0](https://github.com/fluxcd/flux2/blob/main/LICENSE) |
| Krew Kubectl Plugin Package Manager | [Krew Docs](https://krew.sigs.k8s.io/docs/user-guide/setup/install/) | ```See [Krew Install](https://krew.sigs.k8s.io/docs/user-guide/setup/install/)``` | Same | Plugin manager for kubectl command-line tool | [Apache License 2.0](https://github.com/kubernetes-sigs/krew/blob/master/LICENSE) |
| Karbon Plugin | [Karbon CLI Docs](https://portal.nutanix.com/page/documents/details?targetId=Karbon-v2_1:kar-karbon-cli-reference-r.html) | `kubectl krew install karbon` (after installing Krew) | Same | Nutanix Karbon plugin for kubectl | [Apache License 2.0](https://github.com/nutanix/karbon/blob/master/LICENSE) |
| jq            | [jq GitHub](https://github.com/stedolan/jq) | `brew install jq` | `sudo apt-get install jq` | Command-line JSON processor | [MIT License](https://github.com/stedolan/jq/blob/master/COPYING) |
| yq            | [yq GitHub](https://github.com/mikefarah/yq) | `brew install yq` | `wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq` | Portable command-line YAML, JSON, and XML processor | [MIT License](https://github.com/mikefarah/yq/blob/master/LICENSE) |
| Git           | [Git Docs](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) | `brew install git` | `sudo apt-get install git` | Distributed version control system | [GPL-2.0 License](https://github.com/git/git/blob/master/COPYING) |
| ipcalc        | [ipcalc GitHub](https://github.com/kjokjo/ipcalc) | `brew install ipcalc` | `sudo apt-get install ipcalc` | IP subnet calculator | [GPL-2.0 License](https://github.com/kjokjo/ipcalc/blob/master/LICENSE) |
| Gum Charm     | [Gum GitHub](https://github.com/charmbracelet/gum) | `brew install gum` | ```curl -sSL https://github.com/charmbracelet/gum/releases/latest/download/gum_linux_amd64.tar.gz \| tar xz && sudo mv gum /usr/local/bin/``` | Tool for creating glamorous shell scripts | [MIT License](https://github.com/charmbracelet/gum/blob/main/LICENSE) |
| arkade        | [arkade GitHub](https://github.com/alexellis/arkade) | `curl -sLS https://get.arkade.dev \| sudo sh` | Same | Marketplace for downloading your favorite devops CLIs and installing helm charts | [MIT License](https://github.com/alexellis/arkade/blob/master/LICENSE) |
| GitHub CLI    | [GitHub CLI Docs](https://cli.github.com/) | `brew install gh` | `sudo apt install gh` | GitHub’s official command line tool | [MIT License](https://github.com/cli/cli/blob/trunk/LICENSE) |
| fzf           | [fzf GitHub](https://github.com/junegunn/fzf) | `brew install fzf` | `sudo apt-get install fzf` | A command-line fuzzy finder | [MIT License](https://github.com/junegunn/fzf/blob/master/LICENSE) |

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
|------|--------------|---------|--------------|---------------------|
| [jq@1.7.1](https://search.nixos.org/packages?channel=23.11&show=jq&from=0&size=50&sort=relevance&type=packages&query=jq) | [jq GitHub](https://github.com/stedolan/jq) | Command-line JSON processor | [MIT License](https://github.com/stedolan/jq/blob/master/COPYING) | `devbox add jq@1.7.1` |
| [gum@0.13.0](https://search.nixos.org/packages?channel=23.11&show=gum&from=0&size=50&sort=relevance&type=packages&query=gum) | [Gum GitHub](https://github.com/charmbracelet/gum) | Tool for creating glamorous shell scripts | [MIT License](https://github.com/charmbracelet/gum/blob/main/LICENSE) | `devbox add gum@0.13.0` |
| [gh@2.46.0](https://search.nixos.org/packages?channel=23.11&show=gh&from=0&size=50&sort=relevance&type=packages&query=gh) | [GitHub CLI Docs](https://cli.github.com/) | GitHub's official command line tool | [MIT License](https://github.com/cli/cli/blob/trunk/LICENSE) | `devbox add gh@2.46.0` |
| [kubectl@1.29.3](https://search.nixos.org/packages?channel=23.11&show=kubectl&from=0&size=50&sort=relevance&type=packages&query=kubectl) | [Kubectl Docs](https://kubernetes.io/docs/tasks/tools/) | Command-line tool for controlling Kubernetes clusters | [Apache License 2.0](https://github.com/kubernetes/kubernetes/blob/master/LICENSE) | `devbox add kubectl@1.29.3` |
| [git@2.44.0](https://search.nixos.org/packages?channel=23.11&show=git&from=0&size=50&sort=relevance&type=packages&query=git) | [Git Docs](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) | Distributed version control system | [GPL-2.0 License](https://github.com/git/git/blob/master/COPYING) | `devbox add git@2.44.0` |
| [age@1.1.1](https://search.nixos.org/packages?channel=23.11&show=age&from=0&size=50&sort=relevance&type=packages&query=age) | [Age GitHub](https://github.com/FiloSottile/age) | A simple, modern, and secure file encryption tool | [BSD 3-Clause License](https://github.com/FiloSottile/age/blob/master/LICENSE) | `devbox add age@1.1.1` |
| [ipcalc@1.0.3](https://search.nixos.org/packages?channel=23.11&show=ipcalc&from=0&size=50&sort=relevance&type=packages&query=ipcalc) | [ipcalc GitHub](https://github.com/kjokjo/ipcalc) | IP subnet calculator | [GPL-2.0 License](https://github.com/kjokjo/ipcalc/blob/master/LICENSE) | `devbox add ipcalc@1.0.3` |
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


### Option 3: Using VSCode Devcontainer

See Devcontainer Tutorial on using Devcontainer.json - [https://code.visualstudio.com/docs/devcontainers/tutorial](https://code.visualstudio.com/docs/devcontainers/tutorial)

### Bootstrapping each NKE Cluster

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

6. Optionally - Taint the GPU nodes

    ```bash
    task kubectl:taint_gpu_nodes
    # if gpu are over utilised
    # task kubectl:drain_gpu_nodes
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

9. [Optional] Post Install - Taint GPU Nodepool with dedicated=gpu:NoSchedule

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
