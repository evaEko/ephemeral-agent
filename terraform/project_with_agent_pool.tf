resource "azuredevops_agent_pool" "project_agent_pool" {
    name           =  var.agent_pool_name
    auto_provision = false
    auto_update    = false
}

resource "azuredevops_agent_queue" "agent_pool_queue" {
  project_id    = var.project_id
  agent_pool_id = azuredevops_agent_pool.project_agent_pool.id
}

resource "azuredevops_pipeline_authorization" "agent_pool_authorization" {
  project_id  = var.project_id
  resource_id = azuredevops_agent_queue.agent_pool_queue.id
  type        = "queue"
}
