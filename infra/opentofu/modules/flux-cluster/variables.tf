## Github Org specific configs
variable "github_org" {
  description = "Name of the Github repository where the flux bootstrap will happen"
  default = "jesse-gonzalez"
  type = string
}

variable "github_repository" {
  description = "Name of the Github repository where the flux bootstrap will happen"
  default = "nai-llm-fleet-infra"
  type = string 
}

variable "github_branch" {
  description = "Name of the Github Branch that flux will be pulling configs from"
  default = "main"
  type = string 
}

variable "public_key_openssh" {
  description = "Public OpenSSH key used to sync K8s cluster with flux bootstrap repository"
  type = string
}

## Cluster specific configs
variable "cluster_name" {
  description = "Name of Kubernetes Cluster"
  default = "kind-minimalist"
  type = string
}

variable "profile_name" {
  description = "Profile name to use from flux bootstrap repository"
  default = "minimalist"
  type = string
}

variable "environment_type" {
  description = "Environment Type"
  default = "kind"
  type = string
}

variable "cluster_secrets" {
  description = "Cluster secrets to be installed in flux-system namespace"
  type = map
  default = {}
  sensitive = true
}

variable "cluster_config" {
  description = "Cluster config to be installed in the fux-system namespace"
  type = map
  default = {}
}

variable "overwrite_files_on_create" {
  description = "Will force over-write any files generated by tofu"
  default = false
  type = bool
}