# Introduction

This section will take you through install NKE(Kubernetes) on Nutanix cluster as we will be deploying AI applications on these kubernetes clusters. 

This section will expand to other available Kubernetes implementations on Nutanix.

## NKE Setup

We will use Infrastucture as Code framework to deploy NKE kubernetes clusters. 

## Pre-requisites

- NKE is enabled on Nutanix Prism Central
- NKE is at version 1.8 (updated through LCM)
- NKE OS at version 1.5

## Preparing OpenTofu 

On your Linux workstation run the following scripts to install OpenTofu. See [here]for latest instructions and other platform information. 

```bash title="Download the installer script:"
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
```
```bash title="Give it execution permissions:"
chmod +x install-opentofu.sh
```
```bash title="Run the installer:"
./install-opentofu.sh --install-method rpm
```

## NKE High Level Cluster Design

We will create the following resources for a PROD and DEV NKE (kubernetes) cluster to deploy our AI applications:

We will create PROD and DEV clusters to deploy our application. Once DEV deployment is tested successful, we can deploy applications to PROD cluster.

### Management Cluster

| OCP Role   |  No. of Nodes (VM) | Operating System    |    vCPU    |  RAM         | Storage   | IOPS |           
| -------------| ----| ---------------------- |  -------- | ----------- |  --------- |  -------- | 
| Master    | 1 | NKE 1.5                 |  4       |  16 GB       | 100 GB    | 300 | 
| ETCD       | 1 | NKE 1.5                 |  4        | 16 GB      |  100 GB   |  300 | 
| Worker       | 1| NKE 1.5               |  8  |  16 GB      |  100 GB |    300 | 

### Prod Cluster

The prod cluster will have a GPU node pool.
  
| OCP Role   |  No. of Nodes (VM) | Operating System    |    vCPU    |  RAM         | Storage   | IOPS |           
| -------------| ----| ---------------------- |  -------- | ----------- |  --------- |  -------- | 
| Master    | 1 | NKE 1.5                 |  4       |  16 GB       | 100 GB    | 300 | 
| ETCD       | 1 | NKE 1.5                 |  4        | 16 GB      |  100 GB   |  300 | 
| Worker       | 1| NKE 1.5               |  8  |  16 GB      |  100 GB |    300 | 


## Getting TOFU Setup to connect to Prism Central

1. Create the variables definitions file
   
    ```bash
    cat << EOF > variables.tf
    variable "cluster_name" {
    type = string
    }
    variable "subnet_name" {
    type = string
    }
    variable "password" {
    description = "nutanix cluster password"
    type      = string
    sensitive = true
    }
    variable "endpoint" {
    type = string
    }
    variable "user" {
    description = "nutanix cluster username"
    type      = string
    sensitive = true
    }
    variable "storage_container"{
    type = string
    }
    variable "nke_k8s_version" {
    type = string
    }
    variable "node_os_version" {
    type = string
    
    }
    variable "master_num_instances"{
    type = number
    }
    variable "etcd_num_instances"{
    type = number
    }
    variable "worker_num_instances"{
    type = number
    }
    EOF
    ```

2. Create the variables file and modify the values to suit your Nutanix environment
   
    ```bash
    vi terraform.tfvars
    ```
    
    === "Template file"

        ```bash
        cluster_name         = "Prism Element Name" # << Change this
        subnet_name          = "your AHV network's name"  # << Change this
        user                 = "admin"             # << Change this
        password             = "XXXXXXX"           # << Change this
        endpoint             = "Prism Central IP"  # << Change this
        storage_container    = "default"           # << Change this to desired storage container
        nke_k8s_version      = "1.x.x-x"           # << Change this
        node_os_version      = "ntnx-x.x.x"        # << Change this
        master_num_instances = 1                   # << Change this  
        etcd_num_instances   = 1                   # << Change this
        worker_num_instances = 1                   # << Change this
        ```

    === "Example file with values"

        ```bash 
        cluster_name         = "MY_PE"
        subnet_name          = "User1"
        user                 = "admin"
        password             = "XXXXXXXX"
        endpoint             = "pc.example.com"
        storage_container    = "default"
        nke_k8s_version      = "1.26.8-0"
        node_os_version      = "ntnx-1.6.1"
        master_num_instances = 1
        etcd_num_instances   = 1
        worker_num_instances = 1
        ```
    
3. Create ``main.tf`` file to initialize nutanix provider
   
    ```bash
    cat << EOF > main.tf
    terraform {
    required_providers {
        nutanix = {
        source  = "nutanix/nutanix"
        version = "1.9.1"
        }
    }
    }

    data "nutanix_cluster" "cluster" {
    name = var.cluster_name
    }

    data "nutanix_subnet" "subnet" {
    subnet_name = var.subnet_name
    }

    provider "nutanix" {
    username     = var.user
    password     = var.password
    endpoint     = var.endpoint
    port         = var.port
    insecure     = true
    wait_timeout = 60
    }
    EOF
    ```

## Deploying Management Cluster

1. Create the following tofu resource file for Management NKE cluster

    ```json
    cat << EOF > nke-mgt.tf
    resource "nutanix_karbon_cluster" "mgt_cluster" {
    name       = "mgt_cluster"
    version    = var.nke_k8s_version
    storage_class_config {
        reclaim_policy = "Delete"
        volumes_config {
        file_system                = "ext4"
        flash_mode                 = false
        password                   = var.password
        prism_element_cluster_uuid = data.nutanix_cluster.cluster.id
        storage_container          = var.storage_container
        username                   = var.user
        }
    }
    cni_config {
        node_cidr_mask_size = 24
        pod_ipv4_cidr       = "172.20.0.0/16"
        service_ipv4_cidr   = "172.19.0.0/16"
    }
    worker_node_pool {
        node_os_version = var.node_os_version 
        num_instances   = var.worker_num_instances
        ahv_config {
        network_uuid               = data.nutanix_subnet.subnet.id
        prism_element_cluster_uuid = data.nutanix_cluster.cluster.id
        }
    }
    etcd_node_pool {
        node_os_version = var.node_os_version 
        num_instances   = var.etcd_num_instances
        ahv_config {
        network_uuid               = data.nutanix_subnet.subnet.id
        prism_element_cluster_uuid = data.nutanix_cluster.cluster.id
        }
    }
    master_node_pool {
        node_os_version = var.node_os_version 
        num_instances   = var.master_num_instances
        ahv_config {
        network_uuid               = data.nutanix_subnet.subnet.id
        prism_element_cluster_uuid = data.nutanix_cluster.cluster.id
        }
    }
    timeouts {
        create = "1h"
        update = "30m"
        delete = "10m"
        }
    }
    EOF
    ```

2. Validate your tofu code

    ```bash
    tofu validate
    ```

3.  Apply your tofu code to create NKE cluster, associated virtual machines and other resources
  
    ```bash
    tofu apply 

    # Terraform will show you all resources that it will to create
    # Type yes to confirm 
    ```

4.  Run the Terraform state list command to verify what resources have been created

    ``` bash
    tofu state list
    ```

    ``` { .bash .no-copy }
    # Sample output for the above command

    data.nutanix_cluster.cluster            # < This is your existing Prism Element cluster
    data.nutanix_subnet.subnet              # < This is your existing primary subnet
    nutanix_karbon_cluster.mgt_cluster      # < This is your Management NKE cluster
    ```

## Deploying DEV cluster

The DEV cluster will contain GPU node pool to deploy your AI apps.

1. Create the following tofu resource file for Dev NKE cluster

    ```json
    cat << EOF > nke-dev.tf
        terraform {
        resource "nutanix_karbon_cluster" "dev_cluster" {
        name       = "dev_cluster"
        version    = var.nke_k8s_version
        storage_class_config {
            reclaim_policy = "Delete"
            volumes_config {
            file_system                = "ext4"
            flash_mode                 = false
            password                   = var.password
            prism_element_cluster_uuid = data.nutanix_cluster.cluster.id
            storage_container          = var.storage_container
            username                   = var.user
            }
        }
        cni_config {
            node_cidr_mask_size = 24
            pod_ipv4_cidr       = "172.20.0.0/16"
            service_ipv4_cidr   = "172.19.0.0/16"
        }
        worker_node_pool {
            node_os_version = var.node_os_version 
            num_instances   = var.worker_num_instances
            ahv_config {
            network_uuid               = data.nutanix_subnet.subnet.id
            prism_element_cluster_uuid = data.nutanix_cluster.cluster.id
            }
        }
        etcd_node_pool {
            node_os_version = var.node_os_version 
            num_instances   = var.etcd_num_instances
            ahv_config {
            network_uuid               = data.nutanix_subnet.subnet.id
            prism_element_cluster_uuid = data.nutanix_cluster.cluster.id
            }
        }
        master_node_pool {
            node_os_version = var.node_os_version 
            num_instances   = var.master_num_instances
            ahv_config {
            network_uuid               = data.nutanix_subnet.subnet.id
            prism_element_cluster_uuid = data.nutanix_cluster.cluster.id
            }
        }
        timeouts {
            create = "1h"
            update = "30m"
            delete = "10m"
            }
        }
        EOF
    ```

2. Validate your tofu code

    ```bash
    tofu validate
    ```

3.  Apply your tofu code to create NKE cluster, associated virtual machines and other resources
  
    ```bash
    tofu apply 

    # Terraform will show you all resources that it will to create
    # Type yes to confirm 
    ```

4.  Run the Terraform state list command to verify what resources have been created

    ``` bash
    tofu state list
    ```

    ``` { .bash .no-copy }
    # Sample output for the above command

    data.nutanix_cluster.cluster            # < This is your existing Prism Element cluster
    data.nutanix_subnet.subnet              # < This is your existing primary subnet
    nutanix_karbon_cluster.dev_cluster      # < This is your Management NKE cluster
    ```

### Adding NodePool with GPU

In this section we will create a nodepool to host the AI apps with a GPU. At this time there is no `tofu` support for creating a nodepool with GPU parameters. We will use NKE's `karbonctl` tool. Once tofu nodepool resource is updated with gpu parameters, we will update this section. 

It is necessary to connect to Prism Central (PC) to be able to access the `karbonctl`

1. Login to the ssh session of PC
    
    ```bash
    ssh -l admin pc.example.com
    ```

2. Login to NKE control plane using karbonctl tool
   
    ```bash
    alias karbonctl=/home/nutanix/karbon/karbonctl
    karbonctl login --pc-username admin
    ```

3. Check the number of available GPUs for Dev NKE cluster
   
    ```bash
    karbonctl cluster gpu-inventory list --cluster-name dev_cluster
    ```
    ```bash title="Command execution"
    PCVM:~$ karbonctl cluster gpu-inventory list --cluster-name dev_cluster
    Name            Total Count    Assignable Count
    Lovelace 40S    8              2
    ```

4. Create a new gpu nodepool and assing it 1 GPU
   
    ```bash
    karbonctl cluster node-pool add --cluster-name dev_cluster --count 1 --memory 12 --gpu-count 1 --gpu-name "Lovelace 40S" --node-pool-name gpu
    ```

    ```bash title="Command execution"
    PCVM:~$ karbonctl cluster node-pool add --cluster-name dev_cluster --count 2 --memory 12 --gpu-count 1 --gpu-name "Lovelace 40S" --node-pool-name gpu
    
    I acknowledge that GPU enablement requires installation of NVIDIA datacenter driver software governed by NVIDIA licensing terms. Y/[N]:Y
    
    Successfully submitted request to add a node pool: [POST /karbon/v1-alpha.1/k8s/clusters/{name}/add-node-pool][202] addK8sClusterNodePoolAccepted  &{TaskUUID:0xc001168e50}
    ``` 

5. Monitor PC tasks to confirm creation on VM and allocation of GPU to the VM
   
6. Once nodepool is created, go to **PC > Kubernetes Management > dev_cluster > Node Pools** and select **gpu** nodepool
   
7. Click on update in the drop-down menu
   
8. You should see that one GPU is assigned to node pool
   
    ![](images/gpu_nodepool.png)

We now have a node that can be used to deploy AI applications and use the GPU.
   