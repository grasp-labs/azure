variable "resource_group_location" {
  description = "The Azure region where container registry resources in this template should be created."
  type        = string
  default     = "northeurope"
}

variable "cosmosdb_replica_location" {
  description = "The name of the Azure region to host replicated data. i.e. 'East US' 'East US 2'. More locations can be found at https://azure.microsoft.com/en-us/global-infrastructure/locations/"
  type        = string
  default     = null
}

variable "cosmosdb_consistency_level" {
  description = "The level of consistency backed by SLAs for Cosmos database. Developers can chose from five well-defined consistency levels on the consistency spectrum."
  type        = string
  default     = "Session"
}

variable "cosmosdb_automatic_failover" {
  description = "Determines if automatic failover is enabled for CosmosDB."
  type        = bool
  default     = true
}

variable "cosmos_graph_databases" {
  description = "The list of Cosmos DB Graph Databases."
  type = list(object({
    name       = string
    throughput = number
  }))
  default = [
      {
          name = "employment-graph",
          throughput = 4000
      }
  ]
}

variable "cosmos_graphs" {
  description = "The list of cosmos graphs to create. Names must be unique per cosmos instance."
  type = list(object({
    name               = string
    database_name      = string
    partition_key_path = string
  }))
  default = [
      {
          name = "Employments",
          database_name = "employment-graph",
          partition_key_path = "id"
      }
  ]
}

variable "tags" {
  description = "Map of tags to apply to this template."
  type        = map(string)
  default     = {}
}

