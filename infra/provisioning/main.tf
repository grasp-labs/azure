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
    resource_group_name = format("%s-%s-%s-rg", var.prefix, local.workspace, random_string.workspace_scope.result)
    graphdb_name            = "${local.base_name}-graph"
}

#-------------------------------
# Resource Group
#-------------------------------
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.resource_group_location
  tags     = var.resource_tags

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
  graph_databases          = var.cosmos_graph_databases
  graphs                   = var.cosmos_graphs

  resource_tags = var.resource_tags
}
