#!/usr/bin/env bash
#
#  Purpose: Initialize the resources necessary for building infrastructure.
#  Usage:
#    prepare.sh

###############################
## ARGUMENT INPUT            ##
###############################
usage() { echo "Usage: prepare.sh <subscription_id> <unique>" 1>&2; exit 1; }

if [ ! -z $1 ]; then ARM_SUBSCRIPTION_ID=$1; fi
if [ -z $ARM_SUBSCRIPTION_ID ]; then
  tput setaf 1; echo 'ERROR: ARM_SUBSCRIPTION_ID not provided' ; tput sgr0
  usage;
fi

if [ ! -z $2 ]; then UNIQUE=$2; fi
if [ -z $UNIQUE ]; then
  tput setaf 1; echo 'ERROR: UNIQUE not provided' ; tput sgr0
  usage;
fi

if [ -z $AZURE_GROUP ]; then
  AZURE_GROUP="grasplabs-${UNIQUE}"
fi

if [ -z $AZURE_LOCATION ]; then
  AZURE_LOCATION="northeurope"
fi

if [ -z $AZURE_VAULT ]; then
  AZURE_VAULT="grasplabs-vault"
fi

if [ -z $RANDOM_NUMBER ]; then
  RANDOM_NUMBER=$(echo $((RANDOM%9999+100)))
  echo "export RANDOM_NUMBER=${RANDOM_NUMBER}" > .envrc
fi

if [ -z $AZURE_STORAGE ]; then
  AZURE_STORAGE="sttf${RANDOM_NUMBER}"
fi

if [ -z $REMOTE_STATE_CONTAINER ]; then
  REMOTE_STATE_CONTAINER="remote-state-container"
fi


###############################
## FUNCTIONS                 ##
###############################
function CreateResourceGroup() {
  # Required Argument $1 = RESOURCE_GROUP
  # Required Argument $2 = LOCATION

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (RESOURCE_GROUP) not received'; tput sgr0
    exit 1;
  fi
  if [ -z $2 ]; then
    tput setaf 1; echo 'ERROR: Argument $2 (LOCATION) not received'; tput sgr0
    exit 1;
  fi

  local _result=$(az group show --name $1 2>/dev/null)
  if [ "$_result"  == "" ]
    then
      OUTPUT=$(az group create --name $1 \
        --location $2 \
        -ojsonc)
      LOCK=$(az group lock create --name "OSDU-PROTECTED" \
        --resource-group $1 \
        --lock-type CanNotDelete \
        -ojsonc)
    else
      tput setaf 3;  echo "Resource Group $1 already exists."; tput sgr0
    fi
}

function CreateKeyVault() {
  # Required Argument $1 = KV_NAME
  # Required Argument $2 = RESOURCE_GROUP
  # Required Argument $3 = LOCATION

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (KV_NAME) not received' ; tput sgr0
    exit 1;
  fi
  if [ -z $2 ]; then
    tput setaf 1; echo 'ERROR: Argument $2 (RESOURCE_GROUP) not received' ; tput sgr0
    exit 1;
  fi
  if [ -z $3 ]; then
    tput setaf 1; echo 'ERROR: Argument $3 (LOCATION) not received' ; tput sgr0
    exit 1;
  fi

  local _vault=$(az keyvault list --resource-group $2 --query [].name -otsv 2>/dev/null)
  if [ "$_vault"  == "" ]
    then
      OUTPUT=$(az keyvault create --name $1 --resource-group $2 --location $3 --query [].name -otsv)
    else
      tput setaf 3;  echo "Key Vault $1 already exists."; tput sgr0
    fi
}

function CreateStorageAccount() {
  # Required Argument $1 = STORAGE_ACCOUNT
  # Required Argument $2 = RESOURCE_GROUP
  # Required Argument $3 = LOCATION

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (STORAGE_ACCOUNT) not received' ; tput sgr0
    exit 1;
  fi
  if [ -z $2 ]; then
    tput setaf 1; echo 'ERROR: Argument $2 (RESOURCE_GROUP) not received' ; tput sgr0
    exit 1;
  fi
  if [ -z $3 ]; then
    tput setaf 1; echo 'ERROR: Argument $3 (LOCATION) not received' ; tput sgr0
    exit 1;
  fi

  local _storage=$(az storage account show --name $1 --resource-group $2 --query name -otsv 2>/dev/null)
  if [ "$_storage"  == "" ]
      then
      OUTPUT=$(az storage account create \
        --name $1 \
        --resource-group $2 \
        --location $3 \
        --sku Standard_LRS \
        --kind StorageV2 \
        --encryption-services blob \
        --query name -otsv)
      else
        tput setaf 3;  echo "Storage Account $1 already exists."; tput sgr0
      fi
}

function GetStorageAccountKey() {
  # Required Argument $1 = STORAGE_ACCOUNT
  # Required Argument $2 = RESOURCE_GROUP

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (STORAGE_ACCOUNT) not received'; tput sgr0
    exit 1;
  fi
  if [ -z $2 ]; then
    tput setaf 1; echo 'ERROR: Argument $2 (RESOURCE_GROUP) not received'; tput sgr0
    exit 1;
  fi

  local _result=$(az storage account keys list \
    --account-name $1 \
    --resource-group $2 \
    --query '[0].value' \
    --output tsv)
  echo ${_result}
}

function CreateBlobContainer() {
  # Required Argument $1 = CONTAINER_NAME
  # Required Argument $2 = STORAGE_ACCOUNT
  # Required Argument $3 = STORAGE_KEY

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (CONTAINER_NAME) not received' ; tput sgr0
    exit 1;
  fi

  if [ -z $2 ]; then
    tput setaf 1; echo 'ERROR: Argument $2 (STORAGE_ACCOUNT) not received' ; tput sgr0
    exit 1;
  fi

  if [ -z $3 ]; then
    tput setaf 1; echo 'ERROR: Argument $3 (STORAGE_KEY) not received' ; tput sgr0
    exit 1;
  fi

  local _container=$(az storage container show --name $1 --account-name $2 --account-key $3 --query name -otsv 2>/dev/null)
  if [ "$_container"  == "" ]
      then
        OUTPUT=$(az storage container create \
              --name $1 \
              --account-name $2 \
              --account-key $3 -otsv)
        if [ $OUTPUT == True ]; then
          tput setaf 3;  echo "Storage Container $1 created."; tput sgr0
        else
          tput setaf 1;  echo "Storage Container $1 not created."; tput sgr0
        fi
      else
        tput setaf 3;  echo "Storage Container $1 already exists."; tput sgr0
      fi
}

function AddKeyToVault() {
  # Required Argument $1 = KEY_VAULT
  # Required Argument $2 = SECRET_NAME
  # Required Argument $3 = SECRET_VALUE
  # Optional Argument $4 = isFile (bool)

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (KEY_VAULT) not received' ; tput sgr0
    exit 1;
  fi

  if [ -z $2 ]; then
    tput setaf 1; echo 'ERROR: Argument $2 (SECRET_NAME) not received' ; tput sgr0
    exit 1;
  fi

  if [ -z $3 ]; then
    tput setaf 1; echo 'ERROR: Argument $3 (SECRET_VALUE) not received' ; tput sgr0
    exit 1;
  fi

  if [ "$4" == "file" ]; then
    local _secret=$(az keyvault secret set --vault-name $1 --name $2 --file $3)
  else
    local _secret=$(az keyvault secret set --vault-name $1 --name $2 --value $3)
  fi
}

#########################################
## EXECUTION
#########################################
printf "\n"

tput setaf 2; echo "Creating Resources" ; tput sgr0
tput setaf 3; echo "------------------------------------" ; tput sgr0

tput setaf 2; echo 'Logging in and setting subscription...' ; tput sgr0
az account set --subscription ${ARM_SUBSCRIPTION_ID}

tput setaf 2; echo 'Creating the Resource Group...' ; tput sgr0
CreateResourceGroup $AZURE_GROUP $AZURE_LOCATION

tput setaf 2; echo "Creating a Key Vault..." ; tput sgr0
CreateKeyVault $AZURE_VAULT $AZURE_GROUP $AZURE_LOCATION

tput setaf 2; echo "Creating a Common Storage Account..." ; tput sgr0
CreateStorageAccount $AZURE_STORAGE $AZURE_GROUP $AZURE_LOCATION

tput setaf 2; echo "Retrieving the Storage Account Key..." ; tput sgr0
STORAGE_KEY=$(GetStorageAccountKey $AZURE_STORAGE $AZURE_GROUP)

tput setaf 2; echo "Creating a Storage Account Container..." ; tput sgr0
CreateBlobContainer $REMOTE_STATE_CONTAINER $AZURE_STORAGE $STORAGE_KEY

tput setaf 2; echo "Adding Storage Account Secrets to Vault..." ; tput sgr0
AddKeyToVault $AZURE_VAULT "${AZURE_STORAGE}-storage" $AZURE_STORAGE
AddKeyToVault $AZURE_VAULT "${AZURE_STORAGE}-storage-key" $STORAGE_KEY


cat > .envrc << EOF
# ENVIRONMENT ${UNIQUE}
# ------------------------------------------------------------------------------------------------------
export RANDOM_NUMBER=${RANDOM_NUMBER}
export UNIQUE=${UNIQUE}
export COMMON_VAULT="${AZURE_VAULT}"
export ARM_TENANT_ID="$(az account show -ojson --query tenantId -otsv)"
export ARM_ACCESS_KEY="$(az keyvault secret show --id https://$AZURE_VAULT.vault.azure.net/secrets/sttf${RANDOM_NUMBER}-storage-key --query value -otsv)"
export TF_VAR_remote_state_account="$(az keyvault secret show --id https://$AZURE_VAULT.vault.azure.net/secrets/sttf${RANDOM_NUMBER}-storage --query value -otsv)"
export TF_VAR_remote_state_container="remote-state-container"
export TF_VAR_resource_group_location="${AZURE_LOCATION}"
export TF_VAR_cosmosdb_replica_location="${AZURE_LOCATION}"
EOF

cp .envrc .envrc_${UNIQUE}
