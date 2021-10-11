output "properties" {
  description = "Properties of the deployed CosmosDB account."
  value = {
    cosmosdb = {
      id                 = azurerm_cosmosdb_account.cosmosdb.id
      endpoint           = azurerm_cosmosdb_account.cosmosdb.endpoint
      primary_master_key = azurerm_cosmosdb_account.cosmosdb.primary_master_key
      connection_strings = azurerm_cosmosdb_account.cosmosdb.connection_strings
    }
  }
  sensitive = true
}

output "account_name" {
  description = "The name of the CosmosDB account."
  value       = azurerm_cosmosdb_account.cosmosdb.name
}

output "account_id" {
  description = "The name of the CosmosDB account."
  value       = azurerm_cosmosdb_account.cosmosdb.id
}
