# azure

## Prerequisites

1. Azure Subscription
2. Terraform locally installed.
3. Requires the use of [direnv](https://direnv.net/).

### Install the required tooling

This document assumes one is running a current version of Ubuntu. Windows users can install the Ubuntu Terminal from the Microsoft Store. The Ubuntu Terminal enables Linux command-line utilities, including bash, ssh, and git that will be useful for the following deployment. _Note: You will need the Windows Subsystem for Linux installed to use the Ubuntu Terminal on Windows_.

Currently the versions in use are [Terraform 0.14.5](https://releases.hashicorp.com/terraform/0.14.5/).

> Note: Terraform and Go are recommended to be installed using a [Terraform Version Manager](https://github.com/tfutils/tfenv)



### Install the Azure CLI

For information specific to your operating system, see the [Azure CLI install guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest). You can also use the single command install if running on a Unix based machine.

```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login to Azure CLI and ensure subscription is set to desired subscription
az login
az account set --subscription <your_subscription>
```

## Provision the Resources
> [Role Documentation](https://docs.microsoft.com/en-us/azure/role-based-access-control/rbac-and-directory-admin-roles): Provisioning Common Resources requires owner access to the subscription, however AD Service Principals are created that will required an AD Admin to grant approval consent on the principals created.

The script `prepare.sh` script is a _helper_ script designed to help setup some of the common things that are necessary for infrastructure.

- Ensure you are logged into the azure cli with the desired subscription set.
- Ensure you have the access to run az ad commands.

```bash
# Execute Script
export UNIQUE=demo

./infra/scripts/prepare.sh $(az account show --query id -otsv) $UNIQUE
```
