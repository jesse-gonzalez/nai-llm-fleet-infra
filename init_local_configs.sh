#!/bin/bash

#####
## This script will populate the .local creds and underlying cluster configs for target k8s cluster

#####

K8S_CLUSTER_NAME=$1
CLUSTER_PROFILE=$2
ENVIRONMENT_TYPE=$3
SKIP_DELETE_PROMPT=$4

TIMESTAMP=$(date +%s)

ARGS_LIST=($@)

if [ ${#ARGS_LIST[@]} -lt 1 ]; then
	echo 'Usage: ./init_local_configs.sh [k8s_cluster_name] [llm-management|llm-workloads] [prod|non-prod]'
	echo 'Example: ./init_local_configs.sh nke-nvd-llm-management llm-management non-prod'
	exit
fi

CLUSTER_FLUX_SYSTEM_DIR=clusters/$K8S_CLUSTER_NAME/flux-system
CLUSTER_PLATFORM_DIR=clusters/$K8S_CLUSTER_NAME/platform
CLUSTER_APPS_DIR=clusters/$K8S_CLUSTER_NAME/apps

## check if local cluster-secrets exists
if [ ! -f ./cluster-secrets.yaml ]; then
  echo "./cluster-secrets.yaml doesn't exist, copy ./cluster-secrets.yaml.example and update accordingly"
  exit
fi

## check if local cluster-configs exists
if [ ! -f ./cluster-configs.yaml ]; then
  echo "./cluster-configs.yaml doesn't exist, copy ./cluster-configs.yaml.example and update accordingly"
  exit
fi

# install shyaml if it doesn't already exists to easily loop through yaml file
echo "Validating secret values have no default values..."
if [ ! -f /usr/local/bin/shyaml ]; then
	pip install --no-cache-dir shyaml -q
fi

# loop through each cluster secret and check value
for i in $(cat ./cluster-secrets.yaml | shyaml keys)
do
  key_val=$(cat ./cluster-secrets.yaml | shyaml get-value $i)
  if [ "$key_val" == "required_secret" ]; then
    echo "ERROR: The following REQUIRED Password key: '$i' still has a default value of 'required_secret' set in ./cluster-secrets.yaml. please update"
    exit
  fi
  if [ "$key_val" == "required_api_key" ]; then
    echo "ERROR: The following REQUIRED API key: '$i' still has a default value of 'required_api_key' set in ./cluster-secrets.yaml. please update"
    exit
  fi
  if [ "$key_val" == "optional_secret" ]; then
    echo "INFO: The '$i' key still has 'optional_secret' set in ./cluster-secrets.yaml. Please re-run if needed."
  fi
done

# loop through each cluster config and make sure that required values have been set
for i in $(cat ./cluster-configs.yaml | shyaml keys)
do
  key_val=$(cat ./cluster-configs.yaml | shyaml get-value $i)
  if [ "$key_val" == "required_config" ]; then
    echo "ERROR: The following REQUIRED Config key: '$i' still has a default value of 'required_config' set in ./cluster-configs.yaml. please update"
    exit
  fi
  if [ "$key_val" == "optional_config" ]; then
    echo "INFO: The '$i' key still has 'optional_config' set in ./cluster-configs.yaml. Please re-run if needed."
  fi
done

echo "Initialize $CLUSTER_PLATFORM_DIR Directories if it doesn't exist"

if [ ! -d $CLUSTER_PLATFORM_DIR ]; then
	mkdir -p $CLUSTER_PLATFORM_DIR
fi

echo "Creating kustomization.yaml config in Platform Directory"

cat <<EOF | tee $CLUSTER_PLATFORM_DIR/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: flux-system
components:
- ../../_profiles/${CLUSTER_PROFILE}/${ENVIRONMENT_TYPE}
resources:
- cluster-secrets.yaml
- cluster-configs.yaml
EOF


echo "Copying cluster-configs.yaml to $CLUSTER_PLATFORM_DIR"

if [ -f $CLUSTER_PLATFORM_DIR/cluster-configs.yaml ]; then
  echo "$CLUSTER_PLATFORM_DIR/cluster-configs.yaml already exist, backing up and overwriting"
  mv $CLUSTER_PLATFORM_DIR/cluster-configs.yaml $CLUSTER_PLATFORM_DIR/cluster-configs-$TIMESTAMP.yaml
fi

cp ./cluster-configs.yaml $CLUSTER_PLATFORM_DIR/cluster-configs.yaml

echo "Copying plaintext cluster-secrets.yaml to $CLUSTER_PLATFORM_DIR"

if [ -f $CLUSTER_PLATFORM_DIR/cluster-secrets.yaml ]; then
  echo "$CLUSTER_PLATFORM_DIR/cluster-secrets.yaml already exist, backing up and overwriting"
  mv $CLUSTER_PLATFORM_DIR/cluster-secrets.yaml $CLUSTER_PLATFORM_DIR/cluster-secrets-$TIMESTAMP.yaml
fi

cp ./cluster-secrets.yaml $CLUSTER_PLATFORM_DIR/cluster-secrets.yaml

## if age keys are not in .local/_common path then auto-generate
if [ ! -f .local/_common/age.agekey ]; then
  echo ".local/_common/age.agekey doesn't exist, generating now."
  age-keygen -o .local/_common/age.agekey
fi

AGE_PUBLIC_KEY=$(age-keygen -y .local/_common/age.agekey)

echo "Setting fingerprint: $AGE_PUBLIC_KEY in file $CLUSTER_PLATFORM_DIR/.sops.yaml"

if [ ! -f $CLUSTER_PLATFORM_DIR/.sops.yaml ]; then
echo "$CLUSTER_PLATFORM_DIR/.sops.yaml doesn't exist, generating now."
cat <<EOF | tee $CLUSTER_PLATFORM_DIR/.sops.yaml
creation_rules:
- encrypted_regex: "^(data|stringData|auth)$"
  age: $(echo $AGE_PUBLIC_KEY)
EOF
fi

echo "Encrypting $CLUSTER_PLATFORM_DIR/cluster-secrets.yaml with fingerprint: $AGE_PUBLIC_KEY"

sops --encrypt --in-place --age $AGE_PUBLIC_KEY $CLUSTER_PLATFORM_DIR/cluster-secrets.yaml


## generating .dockerconfig jsonfile and then encrypting as per these flux instructions: https://fluxcd.io/flux/components/kustomize/kustomizations/#kustomize-secretgenerator
## There is known bug when trying to generate that doesn't seem to be resolved - https://github.com/kubernetes-sigs/kustomize/issues/4653
echo "Generating Encrypted .dockerconfigjson file"

DOCKER_HUB_USER=$(cat ./cluster-secrets.yaml | shyaml get-value stringData.docker_hub_user)
DOCKER_HUB_PASS=$(cat ./cluster-secrets.yaml | shyaml get-value stringData.docker_hub_password)
DOCKER_HUB_AUTH=$(echo "${DOCKER_HUB_USER}:${DOCKER_HUB_PASS}" | base64)

cat <<EOF | tee $CLUSTER_PLATFORM_DIR/hub.dockerconfig.json.encrypted >/dev/null
{"auths": {"http://docker-registry/v2/": {"username":"${DOCKER_HUB_USER}","password":"${DOCKER_HUB_PASS}","auth":"${DOCKER_HUB_AUTH}"} }}
EOF

sops --encrypt --input-type=json --output-type=json --in-place --age $AGE_PUBLIC_KEY $CLUSTER_PLATFORM_DIR/hub.dockerconfig.json.encrypted

delete_prompt="y"

if [ "$SKIP_DELETE_PROMPT" != "true" ]; then
  read -p "Would you like to delete local ./cluster-secrets.yaml and ./cluster-configs.yaml files? (y or n): " delete_prompt
fi

if [ "$delete_prompt" == "y" ]; then
  echo "Backing up ./cluster-secrets.yaml and ./cluster-configs locally just in case"
  cp ./cluster-secrets.yaml ./cluster-secrets-$K8S_CLUSTER_NAME-$TIMESTAMP.yaml
  cp ./cluster-configs.yaml ./cluster-configs-$K8S_CLUSTER_NAME-$TIMESTAMP.yaml
  echo "Deleting ./cluster-secrets.yaml and ./cluster-configs.yaml"
  rm ./cluster-secrets.yaml
  rm ./cluster-configs.yaml
elif [ "$delete_prompt" == "n" ]; then
  echo "Copying & renaming ./cluster-secrets.yaml to ./cluster-secrets-$K8S_CLUSTER_NAME-$TIMESTAMP.yaml"
  cp ./cluster-secrets.yaml ./cluster-secrets-$K8S_CLUSTER_NAME-$TIMESTAMP.yaml
  echo "Copying & renaming ./cluster-configs.yaml to ./cluster-configs-$K8S_CLUSTER_NAME-$TIMESTAMP.yaml"
  cp ./cluster-configs.yaml ./cluster-configs-$K8S_CLUSTER_NAME-$TIMESTAMP.yaml
else
  echo "Invalid Entry. please type 'y' or 'n'."
  read -p "Would you like to delete local ./cluster-secrets.yaml and ./cluster-configs.yaml files? (y or n): " delete_prompt
fi

echo "Creating Flux bootstrap directories and patch files needed to enable decryption provider"

## creating directory and empty gotk files to initialize new cluster. if it already exists it won't touch
if [ ! -d $CLUSTER_FLUX_SYSTEM_DIR ]; then
  echo "$CLUSTER_FLUX_SYSTEM_DIR doesn't exist, creating directory and files now."
  mkdir -p $CLUSTER_FLUX_SYSTEM_DIR
  touch $CLUSTER_FLUX_SYSTEM_DIR/gotk-components.yaml \
      $CLUSTER_FLUX_SYSTEM_DIR/gotk-sync.yaml
fi


## creating gotk-patch to override decryption provider
cat <<EOF | tee $CLUSTER_FLUX_SYSTEM_DIR/gotk-patches.yaml
kind: Kustomization
metadata:
  name: flux-system
  namespace: flux-system
spec:
  decryption:
    provider: sops
    secretRef:
      name: sops-age
EOF

## creating gotk-patch to include decryption provider
cat <<EOF | tee $CLUSTER_FLUX_SYSTEM_DIR/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- gotk-components.yaml
- gotk-sync.yaml
patches:
- path: gotk-patches.yaml
  target:
    kind: Kustomization
EOF