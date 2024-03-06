# Ephemeral Pipeline Agents in managed build environments

This PoC contains code that creates the infrastructure in terraform and runs a build agent. 

The process is split into the following pipelines:
  * create-pipelines: creates the pipelines below
  * create-storage-account: 
    * creates variable groups with data about the storage account and resources 
    * creates the storage account (not governed by terraform)
    * create_infra: runs terraform to create the resource group, registry, registry connection, agent pool in the organization using the state in the storage account container. If the state file or account does not exists, it creates a new account and the state file.
    * create_image: creates the docker image based on the Dockerfile in the root of this repo, uploads it to registry, creates a container for the image (Docker image contains the azure pipeline agent which is registered with the pool), runs a mock build job on the agent, deregisters the agent from the pool, destroys the container, destroy the image (tag)
  * destroy: destroys pools, registry connection, resource group, registry, etc. Note that the service principal for registry is not destroyed (TODO).
  * build: runs pipelines in the specified order using REST

Note: Pipelines are change with triggers defined in the resources section, for example the create-image pipeline is triggered whenever the create_infrastructure pipeline runs (names of the pipelines are defines in the create-pipelines pipeline):
```
resources:
  pipelines:
  - pipeline: CreateInfrastructure
    source: create_infrastructure
    trigger: 
      branches:
        include:
        - main
```
This mechanism is not reliable and the pipelines are not always triggered. It is unclear why. Consider using REST calls as defined in the build pipeline: This approach allows also more flexibility in pipeline orchestration. This approach will however require simultanenous run of multiple pipelines and is checking the status of the triggered pipeline periodically. An alternative could be web hooks, however, these require further resources which notify the web hook.
    
**Important**: This POC ignores security concerns.

## General notes

* Pipelines support using tasks: mind that task parameters are validated before the pipeline run: hence if any of the resources provided in parameters are created dynamically (such as registry connection), validation of any pipelines which uses the registry as a task parameter fails if the resource does not exist at the moment the pipeline is triggered. Possible solutions:
  * use scripts instead of tasks so that there are no parameters which can be validated
(see more info https://julie.io/writing/terraform-on-azure-pipelines-best-practices/)
  * use different pipelines: you will need to orchestrate the pipelines
* This POC is using ubuntu for all its Microsoft-hosted runners
* This POC uses one server connection to connect to Azure whenever necessary with the exception of registry connection. More granular service connections are to be considered.
* The build pipeline could not be fully tested.
* It will be necessary to specify unique identifiers for resources. Mind that agent pools are created on the organization level.
* Multiple pipelines are provided, primarily due to inability of tasks to work with dynamically created resources.
* The option of the pipelines running on different branches is not implemented.
* This repo is creating a registry connection on its own project using terraform: this is done by passing the current project id as a parameter to terraform: when attempting to import the project into terraform so as to have the entire project under terraform, the project was wiped. Hence it seems that this post is still valid:
https://stackoverflow.com/questions/70116190/terraform-import-azure-devops-project

## How to

### Prerequisites

* a subscription for the project is available (it resides under a dedicated management group)
* PAT token for project access
* install terraform from market place Terraform by microsoft devlabs

### Setup

1. Create the service principal for the service connection:

* Create a variable group set as AZ_TOKEN variable in the AzureDevopsACI.Secrets variable group; allow all pipelines to use the group; alternatively, you can do it manually on the first run of a pipeline or via a script; in the variable group also: SERVICE_CONNECTION with the name of the service connection (defaul System.AccessToken does not have all necessary permissions: it is however possible to tweak this with pipeline permissions)
* service principal can read AzureDevOpsACI.Secrets


To setup the service connection for the pipeline runs, do the following:
1. Create service principal:
  1. Log in to azure: `az login`
  2. Set the correct subscription `az account set --subscription <SUBSCRIPTION_ID>`
  3. Create a service principal for service connection: `az ad sp create-for-rbac --name "<PRINCIPAL_NAME>" --role Contributor --scopes /subscriptions/<SUBSCRIPTION_ID>`

     Relevant output:
        * appId (set as ARM_CLIENT_ID in both pipelines)
        * password (set as ARM_CLIENT_SECRET)
  4. Verify the service principal: az login --service-principal -u <appId> -p "<password>" --tenant <tenant_id>
  5. Log back in as your user: `az login`
  6. Grant the service principal the API permission Application.ReadWrite.All: (required to manipulate the project resources (variable groups))
     1. Go to Entra portal.
     2. Click Applications > App registrations
     3. Click the service principal.
     4. Click API permissions
     5. Click **Add a permission**
     6. Click **Microsoft Graph**
     7. Click **Application permissions**
     8. Expand *Application* and select **Application.ReadWrite.All**
2. Create the service connection:
   1. In az cli, install the devops extension: `az extension add --name azure-devops`
   2. Create the service endpoint and connection:
      ```
      az devops service-endpoint azurerm create --azure-rm-service-principal-id "<appId>" --azure-rm-subscription-id "<subscription_id>" --azure-rm-subscription-name "<arbitrary_subscription_name>" --azure-rm-tenant-id "<tenant_id>" --name "<name_of_service_connection>" --project "<name_of_project_with_pipelines>"
      ```
   3. Enter the password from step 3 output.
3. Add the service principal to project team (cli not supported, can be dont via REST):
   1. In your browser, go to Azure DevOps and open your project.
   2. In the lower left corner, click **Project Settings** 
   3. Under *General*, click **Permissions**
   4. In the Groups list, click the project team.
   5. Click the Members tab.
   6. Click the **Add** button.
   7. Enter the name of the service principal.
   8. Click **Save**

Note: Consider using managed identity instead of a service principal.

### Create variable group

Create a variable group with the PAT token and the service connection name:
1. Create the group with the service connection variable:
```
az pipelines variable-group create --name AzureDevopsACI.Secrets --variables SERVICE_CONNECTION="<SERVICE_CONNECTION_NAME>" --project <PROJECT_NAME> --org "https://dev.azure.com/<ORG_NAME>"

```
2. Add the pat token variable:
```
az pipelines variable-group variable create --group-id <GROUP_ID_FROM_STEP_ABOVE> --name AZ_TOKEN --secret true --value "<TOKEN_VALUE>" --project "<PROJECT_NAME>" --org "https://dev.azure.com/<ORG_NAME>"
```

### Allow pipelines to use variable groups

Not possible from cli or rest. in devops, go to the variable group, click the three dots next to it, go to Pipeline permissions, click three dots in the upper right corner, click Open Access.

### Create and run

* create pipelines:
```
az pipelines create --name "create-pipelines" --description "Creates pipelines for agent process" --repository <REPOSITORY_NAME> --branch <BRANCH> --repository-type tfsgit --yml-path "pipelines/create-pipelines.yml" --project <PROJECT_NAME>
```
* run the pipelines:
  * create-storage-account pipeline:
    1. Creates a variable group with generic variables
    2. Creates a variable group with storage account details
    3. Creates the storage account if it does not exist.
    
    After create-storage-account is finished, the create-infra pipeline should be triggered.
  * create-infra pipeline (uses the terraform-setup-template):
    1. installs terraform.
    2. prepares backend config file based on template.
    3. prepares terraform.tfvars based on template.
    4. initializes terraform based on the backend config file.
    5. runs terraform apply (check resource group, registry connection, registry, agent pool)
   After create-infra pipeline is finished, the create-image pipeline should be triggered.
  * create-image pipeline 
    1. Builds the image of the Dockerfile in the root of this repo
    2. Uploads it to the azure container registry using the registry connection
    3. Creates a container with the image 
    4. The docker container has azure pipelines agent set up and registers into the pool created by terraform.
    5. The agent is picked up by the pipeline (currently any agent that is in the pool)
    6. A mock build runs on the agent.
    7. Clean up: agent is deregistered, image (tag) removed and container erased.
  * destroy_infra pipeline (uses the terraform-setup-template):
    1. installs terraform.
    2. prepares backend config file based on template.
    3. prepares terraform.tfvars based on template.
    4. initializes terraform based on the backend config file.
    5. runs terraform destroy on:
       * resource group for the container registry
       * azure container registry
       * regitry service connection of the project
       * an agent pool 

For option on service end point in azure
https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/resources/serviceendpoint_azurerm


# Troubleshooting

* if terraform part is stuck without a reasonable error, check the service connectivity and service principal
* if you get an error that the agent pool already exists, delete the pool from the organization (it might be deleted from project but remains in the organization)
* if your pipeline is not triggered when another pipeline is created, make sure you dont have the default trigger (trigger: none) at the top of the pipeline
* you get an error that the template file could not be found, it is likely a problem with the content of the file
* i get ERROR: TF400813: The user '<WEIRD_ID>' is not authorized to access this resource.
##[error]Script failed with exit code: 1
  - make sure your service principal is the project team

## TODO

* add rights for pipelines to secrets variable group and service connection on create if possible
* image pipeline now picks a random agent (should pick the one crated the the parent pipeline)
* pipeline chaining does not work on first run generally
* create a total destroy, destroy storage account, variable groups and sp for registry connection, tfstate, pipelines
* use managed identity instead of service principal
* decide which service connections with which service principals to use
* when creating variable group (create-storage-account.yml), update the variable values if the group exists (or delete and recreate) or even better: get rid of variable groups
* https://github.com/Azure/terraform-azurerm-aci-devops-agent 
* https://marketplace.visualstudio.com/items?itemName=tiago-pascoal.EphemeralPipelinesAgents
* terraform.tfvars as template
* cleanup vars in terraform
* remove service principal of registry connection on destroy
* switch to windows container
* i am creating the docker image in the registry regardless of whether the image was changed since i am deleting the image on every agent run (create-image pipeline); possibly keep the images and use the last in the current image if it is the same; questionable whether to delete image tag after the build (it is reproducible easily though)
