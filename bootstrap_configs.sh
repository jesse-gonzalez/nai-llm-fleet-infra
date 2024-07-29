#!/usr/bin/env bash

set -o errexit
set -eo pipefail

# shellcheck disable=SC2155
export PROJECT_DIR=$(git rev-parse --show-toplevel)

# shellcheck disable=SC2155
export SOPS_AGE_KEY_FILE="${PROJECT_DIR}/.local/_common/age.agekey"

show_help() {
cat << EOF
Usage: $(basename "$0") <options>
    -h, --help      Display help
    --cluster_name  Kubernetes Cluster Name 
    --verify        Verify .env settings within .local/cluster_name/
Examples:
  # Verify that all configs have been set and are correct
  ./$(basename "$0") --cluster_name nai-llm-prod-mgmt --verify

  # Generate and encrypt configs from templates defined in tmpl/cluster directory
  ./$(basename "$0") --cluster_name nai-llm-prod-mgmt
EOF
}

main() {
    local verify=
    local cluster_name=

    parse_command_line "$@"

    verify_binaries

    export K8S_CLUSTER_NAME=${cluster_name}

    CLUSTER_LOCAL_DIR=""
    CLUSTER_PLATFORM_DIR="${PROJECT_DIR}/clusters/${K8S_CLUSTER_NAME}/platform"
    TEMPLATES_DIR="${PROJECT_DIR}/tmpl/cluster"

    if [ ! -f .local/${K8S_CLUSTER_NAME}/.env ]; then
      _log "ERROR" ".local/${K8S_CLUSTER_NAME}/.env doesn't exist."
      _log "INFO" "This can be done by initially running the command below and making sure all the variables prefixed with 'BOOTSTRAP_' are updated accordingly:"
      _log "INFO" "  cp ./.env.sample.yaml ./.env.${K8S_CLUSTER_NAME}.yaml"
      _log "INFO" "  after updating ./.env.${K8S_CLUSTER_NAME}.yaml"
      exit
    fi

    # generate age key if it doesn't exist
    if [ ! -f ${SOPS_AGE_KEY_FILE} ]; then
      generate_age
    fi

    export AGE_PUBLIC_KEY=$(age-keygen -y ${SOPS_AGE_KEY_FILE})

    source "${PROJECT_DIR}/.local/${K8S_CLUSTER_NAME}/.env"

    ## only run if verify option has been passed in. otherwise, generate template configs
    if [[ "${verify}" == 1 ]]; then
        verify_all
        verify_success
    else
        # generate cluster directories
        task bootstrap:generate_local_configs
        #mkdir -p "$CLUSTER_PLATFORM_DIR"
        # copy over flux-system bootstrap configs
        #cp -rf "$TEMPLATES_DIR/flux-system" "${PROJECT_DIR}/clusters/${K8S_CLUSTER_NAME}"
        # touch gotk-components.yaml and gotk-sync.yaml files. These are managed by completely managed by flux bootstrap process.
        #touch "${PROJECT_DIR}/clusters/${K8S_CLUSTER_NAME}/flux-system/gotk-components.yaml"
        #touch "${PROJECT_DIR}/clusters/${K8S_CLUSTER_NAME}/flux-system/gotk-sync.yaml"
        # generate cluster settings
        #envsubst < "$TEMPLATES_DIR/platform/cluster-configs.yaml" \
        #    > "$CLUSTER_PLATFORM_DIR/cluster-configs.yaml"
        # generate cluster secrets
        #envsubst < "$TEMPLATES_DIR/platform/cluster-secrets.sops.yaml" \
        #    > "$CLUSTER_PLATFORM_DIR/cluster-secrets.sops.yaml"
        # generate .sops.yaml file
        #envsubst < "$TEMPLATES_DIR/platform/.sops.yaml" \
        #    > "$CLUSTER_PLATFORM_DIR/.sops.yaml"
        # encrypt cluster secrets
        #sops --encrypt --in-place "$CLUSTER_PLATFORM_DIR/cluster-secrets.sops.yaml"
        # generate kustomization file
        #envsubst < "$TEMPLATES_DIR/platform/kustomization.yaml" \
        #    > "$CLUSTER_PLATFORM_DIR/kustomization.yaml"
        ## generating .dockerconfig jsonfile and then encrypting as per these flux instructions: https://fluxcd.io/flux/components/kustomize/kustomizations/#kustomize-secretgenerator
        ## There is known bug when trying to generate that doesn't seem to be resolved - https://github.com/kubernetes-sigs/kustomize/issues/4653
        #envsubst < "$TEMPLATES_DIR/platform/hub.dockerconfig.json.encrypted" \
        #    > "$CLUSTER_PLATFORM_DIR/hub.dockerconfig.json.encrypted"
        ## encrypt docker config needed for image pull secrets
        #sops --encrypt --input-type=json --output-type=json --in-place --age $AGE_PUBLIC_KEY $CLUSTER_PLATFORM_DIR/hub.dockerconfig.json.encrypted
        #success
    fi
}

verify_all() {
  verify_vars
  verify_age
  #verify_prism
  #verify_kubevip
  #verify_git_repository
}

parse_command_line() {

    while :; do
        case "${1:-}" in
            -h|--help)
                show_help
                exit
                ;;
            --verify)
                verify=1
                ;;
            --cluster_name)
                shift
                cluster_name=$1
                ;;
            *)
                break
                ;;
        esac

        shift
    done

    if [[ -z "$verify" ]]; then
        verify=0
    fi

    if [ -z $cluster_name ]; then
      echo "Cluster name is required, provide it with the flag: --cluster-name cluster_name. See Help Below:"
      show_help
      exit
    fi
}

_has_binary() {
    command -v "${1}" >/dev/null 2>&1 || {
        _log "ERROR" "${1} is not installed or not found in \$PATH"
        exit 1
    }
}

_has_optional_envar() {
    local option="${1}"
    
    if [ "${!option}" == "" ]; then
      _log "WARN" "Unset optional variable ${option}"
    elif [ "${2}" == "is_secret" ]; then
      _log "INFO" "Found sensitive variable '${option}' with value '**********'"
    else
      _log "INFO" "Found variable '${option}' with value '${!option}'"
    fi
}

_has_envar() {
    local option="${1}"

    if [ "${!option}" == "" ]; then
      _log "ERROR" "Required variable ${option} has not been set"
      exit 1
    elif [ "${2}" == "is_secret" ]; then
      _log "INFO" "Found sensitive variable '${option}' with value '**********'"
    else
      _log "INFO" "Found variable '${option}' with value '${!option}'"
    fi
}

# _has_valid_ip() {
#     local ip="${1}"
#     local variable_name="${2}"

#     if ! ipcalc "${ip}" | awk 'BEGIN{FS=":"; is_invalid=0} /^INVALID/ {is_invalid=1; print $1} END{exit is_invalid}' >/dev/null 2>&1; then
#       _log "INFO" "Variable '${variable_name}' has an invalid IP address '${ip}'"
#       exit 1
#     else
#       _log "INFO" "Variable '${variable_name}' has a valid IP address '${ip}'"
#     fi
# }

generate_age() {
    _has_envar "SOPS_AGE_KEY_FILE"

    ## if age key is not in .local/_common path then auto-generate
    if [ ! -f ${SOPS_AGE_KEY_FILE} ]; then
      _log "INFO" "SOPS_AGE_KEY_FILE: ${SOPS_AGE_KEY_FILE} file doesn't exist, generating now."
      mkdir -p .local/_common && age-keygen -o ${SOPS_AGE_KEY_FILE}
    fi
}

verify_age() {
    _has_envar "AGE_PUBLIC_KEY" "is_secret"
    _has_envar "SOPS_AGE_KEY_FILE"

    if [[ ! "$AGE_PUBLIC_KEY" =~ ^age.* ]]; then
        _log "ERROR" "AGE_PUBLIC_KEY does not start with age"
        exit 1
    else
        _log "INFO" "Age public key is in the correct format"
    fi

}

verify_binaries() {
    #_has_binary "envsubst"
    _has_binary "git"
    _has_binary "age"
    #_has_binary "ipcalc"
    _has_binary "jq"
    _has_binary "yq"
    _has_binary "sops"
    _has_binary "task"
    _has_binary "age-keygen"
    _has_binary "htpasswd"
}

verify_vars(){
    _log "INFO" "Validating all REQUIRED environment variables"
    _has_envar "BOOTSTRAP_cluster_name"
    _has_envar "BOOTSTRAP_environment"
    _has_envar "BOOTSTRAP_cluster_profile"
    _has_envar "BOOTSTRAP_github_repo_url"
    _has_envar "BOOTSTRAP_github_user" "is_secret"
    _has_envar "BOOTSTRAP_github_api_token" "is_secret"
    _has_envar "BOOTSTRAP_docker_hub_user" "is_secret"
    _has_envar "BOOTSTRAP_docker_hub_password" "is_secret"

    _log "INFO" "Validating all OPTIONAL environment variables"
    _has_optional_envar "BOOTSTRAP_github_app_id" "is_secret"
    _has_optional_envar "BOOTSTRAP_github_app_installation_id" "is_secret"
    _has_optional_envar "BOOTSTRAP_kube_vip_ipam_range"
    _has_optional_envar "BOOTSTRAP_kube_vip_nginx_ingress_ipam"
    _has_optional_envar "BOOTSTRAP_kube_vip_istio_system_ipam"
    _has_optional_envar "BOOTSTRAP_wildcard_ingress_subdomain"
    _has_optional_envar "BOOTSTRAP_objects_host"
    _has_optional_envar "BOOTSTRAP_objects_access_key" "is_secret"
    _has_optional_envar "BOOTSTRAP_objects_secret_key" "is_secret"
    _has_optional_envar "BOOTSTRAP_prism_central_endpoint"
    _has_optional_envar "BOOTSTRAP_prism_central_user"
    _has_optional_envar "BOOTSTRAP_prism_central_password" "is_secret"
    _has_optional_envar "BOOTSTRAP_aws_route53_dns_zone"
    _has_optional_envar "BOOTSTRAP_aws_route53_region"
    _has_optional_envar "BOOTSTRAP_aws_access_key_id" "is_secret"
    _has_optional_envar "BOOTSTRAP_aws_access_key_secret" "is_secret"
    _has_optional_envar "BOOTSTRAP_management_cluster_ingress_subdomain"
    _has_optional_envar "BOOTSTRAP_model"
    _has_optional_envar "BOOTSTRAP_revision"
    _has_optional_envar "BOOTSTRAP_nfs_export"
    _has_optional_envar "BOOTSTRAP_nfs_server"
}


verify_prism() {
    local basic_auth_token=
    local errors=

    _has_envar "BOOTSTRAP_prism_central_endpoint"
    _has_envar "BOOTSTRAP_prism_central_user" "is_secret"
    _has_envar "BOOTSTRAP_prism_central_password" "is_secret"

    _log "INFO" "Verifying Prism Central Endpoint and Credentials are valid"

    basic_auth_token=$(echo -n "${BOOTSTRAP_prism_central_user}:${BOOTSTRAP_prism_central_password}" | base64)

    # Try to retrieve zone information from Cloudflare's API
    {
        prism_check=$(curl -c 3 -m 10 -s --insecure --request GET "https://${BOOTSTRAP_prism_central_endpoint}:9440/api/nutanix/v3/prism_central" \
            -H "Authorization: Basic ${basic_auth_token}" \
            -H "Content-Type: application/json" \
            -H "Accept: application/json" \
            --data '{}' 
        )
    } || { 
        _log "ERROR" "Attempt to connect to Prism Central timed out trying to reach ${BOOTSTRAP_prism_central_endpoint}"; 
        exit 1; 
    }

    if [[ "$(echo "${prism_check}" | jq -e ".message | length == 0")" == "true" ]]; then
        _log "INFO" "Verified Prism Central Endpoint and Credentials are valid"
    else
        errors=$(echo -n '${prism_check}')
        _log "ERROR" "Unable to verify Prism Central Credentials are valid ${errors}"
        exit 1
    fi
}

verify_kubevip() {
    local ip_floor=
    local ip_ceil=
    _has_envar "BOOTSTRAP_kube_vip_ipam_range"

    ip_floor=$(echo "${BOOTSTRAP_kube_vip_ipam_range}" | cut -d- -f1)
    ip_ceil=$(echo "${BOOTSTRAP_kube_vip_ipam_range}" | cut -d- -f2)

    #_has_valid_ip "${ip_floor}" "BOOTSTRAP_kube_vip_ipam_range"

    _has_envar "BOOTSTRAP_kube_vip_istio_system_ipam"
    _has_envar "BOOTSTRAP_kube_vip_nginx_ingress_ipam"
    
    #_has_valid_ip "${BOOTSTRAP_kube_vip_nginx_ingress_ipam}" "BOOTSTRAP_kube_vip_nginx_ingress_ipam"
    #_has_valid_ip "${BOOTSTRAP_kube_vip_nginx_ingress_ipam}" "BOOTSTRAP_kube_vip_nginx_ingress_ipam"
}

verify_git_repository() {
    _has_envar "BOOTSTRAP_github_repo_url"

    export GIT_TERMINAL_PROMPT=0
    pushd "$(mktemp -d)" >/dev/null 2>&1
    [ "$(git ls-remote "${BOOTSTRAP_github_repo_url}" 2> /dev/null)" ] || {
        _log "ERROR" "Unable to find the remote Git repository '${BOOTSTRAP_github_repo_url}'"
        exit 1
    }
    popd >/dev/null 2>&1
    export GIT_TERMINAL_PROMPT=1
}

verify_success() {
    _log "INFO" "All checks passed!"
    _log "INFO" "Run the script without --verify to template all the files out"
    exit 0
}


success() {
    _log "INFO" "All files have been updated accordingly. Please review generated files within directory before proceeding: clusters/${K8S_CLUSTER_NAME}"
    exit 0
}

_log() {
    local type="${1}"
    local msg="${2}"
    printf "[%s] [%s] %s\n" "$(date -u)" "${type}" "${msg}"
}

main "$@"
