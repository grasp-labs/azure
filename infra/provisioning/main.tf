terraform {
  required_version = ">= 0.14"

  backend "azurerm" {
    key = "terraform.tfstate"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.64.0"
    }
  }
}

#-------------------------------
# Providers
#-------------------------------
provider "azurerm" {
  features {}
}

#-------------------------------
# Private Variables
#-------------------------------
locals {
    base_name               = "aditro"
    resource_group_name     = "${local.base_name}-rg"
    graphdb_name            = "${local.base_name}-graph"
}

#-------------------------------
# Resource Group
#-------------------------------
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.resource_group_location
  tags     = var.tags

  lifecycle {
    ignore_changes = [tags]
  }
}

#-------------------------------
# CosmosDB
#-------------------------------
module "graph_account" {
  source = "../modules/cosmosdb"

  name                     = local.graphdb_name
  resource_group_name      = azurerm_resource_group.main.name
  primary_replica_location = var.cosmosdb_replica_location
  automatic_failover       = var.cosmosdb_automatic_failover
  consistency_level        = var.cosmosdb_consistency_level
  databases                = var.cosmos_databases
  sql_collections          = var.cosmos_collections

  tags = var.tags
}
