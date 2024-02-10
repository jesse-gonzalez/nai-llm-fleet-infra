locals {
    ## GitHub Provider Configs / App Credentials Required (using local vars)
    github_app_id = var.github_app_id
    github_app_installation_id = var.github_app_installation_id
    github_org = var.github_org
    github_repository = var.github_repository
    pem_file = file("${path.module}/private-key.pem")
}

resource "kind_cluster" "this" {
  name = var.cluster_name
}

# Deploy Key Generation (used by the Flux provider)
resource "tls_private_key" "flux" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

module "flux" {
  source = "../modules/flux-cluster"

  cluster_name = var.cluster_name
  public_key_openssh = tls_private_key.flux.public_key_openssh

  profile_name = var.profile_name

  # Flux repo configuration
  github_org = var.github_org
  github_repository = var.github_repository
  github_branch = var.github_branch

  ## TODO: replace with config map templates
  cluster_secrets = {
    foo = "bar"
  }
  
  cluster_config = {
    foo2 = "bar2"
  }
}
