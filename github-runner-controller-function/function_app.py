import logging
import azure.functions as func
import os
import json
from azure.containerregistry import ContainerRegistryClient
from azure.keyvault.secrets import SecretClient
from azure.mgmt.containerinstance.models import ContainerGroupNetworkProtocol
from azure.storage.queue import QueueServiceClient
from azure.identity import DefaultAzureCredential
from azure.mgmt.containerinstance import ContainerInstanceManagementClient
from azure.mgmt.containerregistry import ContainerRegistryManagementClient
from azure.mgmt.containerinstance.models import (
    ContainerGroup,
    ImageRegistryCredential,
    Container,
    ResourceRequests,
    ResourceRequirements,
    OperatingSystemTypes,
    EnvironmentVariable,
    ContainerGroupRestartPolicy,
)

app = func.FunctionApp()

# Read configurations from environment variables
AZURE_CONTAINER_REGISTRY = os.getenv("AZURE_CONTAINER_REGISTRY")
KV_NAME = os.getenv("AZURE_KV_NAME")
ACR_USER = os.getenv("AZURE_ACR_USER")
ACR_PASS = os.getenv("AZURE_ACR_PASS")
GH_APP_PEM_FILE_KEY = os.getenv("GH_APP_PEM_FILE")
GH_APP_CLIENT_ID_KEY = os.getenv("GH_APP_CLIENT_ID_KEY")
GH_APP_INSTT_ID_KEY = os.getenv("GH_APP_INSTT_ID_KEY")
GH_ORG_NAME = os.getenv("GH_ORG_NAME")
SUBSCRIPTION_ID = os.getenv("AZURE_SUBSCRIPTION_ID")
RESOURCE_GROUP_NAME = os.getenv("AZURE_RESOURCE_GROUP")
LOCATION = os.getenv("AZURE_LOCATION", "eastus2")  # Default to 'eastus2'
CONTAINER_IMAGE = os.getenv("CONTAINER_IMAGE", "nginx")  # Default to 'nginx'
CONTAINER_NAME = os.getenv("CONTAINER_NAME", "my-container")
CPU_CORE_COUNT = float(os.getenv("CONTAINER_CPU", 1))
MEMORY_IN_GB = float(os.getenv("CONTAINER_MEMORY", 1.5))

def retrieve_kv_secret():
  key_vault_url = f"https://{ KV_NAME }.vault.azure.net/"
   
  credential = DefaultAzureCredential()
  client = SecretClient(vault_url=key_vault_url, credential=credential)
  gh_app_pem_file = None
  gh_app_client_id = None
  acr_user = None
  acr_pass = None
  # Retrieve the secret
  try:
    gh_app_pem_file = client.get_secret(GH_APP_PEM_FILE_KEY)
    gh_app_client_id = client.get_secret(GH_APP_CLIENT_ID_KEY)
    gh_app_instt_id = client.get_secret(GH_APP_INSTT_ID_KEY)
    acr_user = client.get_secret(ACR_USER)
    acr_pass = client.get_secret(ACR_PASS)
    logging.info(f"gh client id { gh_app_client_id.value }")
  except Exception as ex:
    print(f"An error occurred in extracting the secrets: {ex}")
  container_environment_variable = [
    EnvironmentVariable(name="PEM_CONTENT", secure_value=gh_app_pem_file.value),
    EnvironmentVariable(name="GH_CLIENT_ID", secure_value=gh_app_client_id.value),
    EnvironmentVariable(name="GH_APP_INSTT_ID", secure_value=gh_app_instt_id.value),
    EnvironmentVariable(name="GH_ORG_NAME", value=GH_ORG_NAME)
  ]
  image_registry_credentials = [
    ImageRegistryCredential(
      server=f"{AZURE_CONTAINER_REGISTRY}.azurecr.io",
      username=acr_user.value,
      password=acr_pass.value
    )
  ]
  return container_environment_variable, image_registry_credentials

def create_container_instance(runner_label, workflow_job_id):
  # Use DefaultAzureCredential for authentication
  logging.info("Start Container Creation function")
  credential = DefaultAzureCredential()
  aci_client = ContainerInstanceManagementClient(credential, SUBSCRIPTION_ID)
  logging.info("Subcription done")
  
  container_resource_requests = ResourceRequests(memory_in_gb=1, cpu=1.0)
  logging.info("CPU and memory initialized")

  # Retrieve GH APP secrets from key-vault
  container_environment_variable, image_registry_credentials = retrieve_kv_secret()
  
  container_image_name=f"awesomeprojdevacr.azurecr.io/{runner_label}:latest"
  
  # Configure the container
  container_resource_requirements = ResourceRequirements(
        requests=container_resource_requests)
   
  container = Container(name="test-container",
                          image=container_image_name,
                          resources=container_resource_requirements,
                          environment_variables=container_environment_variable
                          )
  
  logging.info("Container Config done")
  group = ContainerGroup(location=LOCATION,
                           containers=[container],
                           os_type=OperatingSystemTypes.linux,
                          # identity=identity,
                           restart_policy=ContainerGroupRestartPolicy.never,
                           image_registry_credentials=image_registry_credentials
                           )

  aci_client.container_groups.begin_create_or_update(resource_group_name=RESOURCE_GROUP_NAME,
                                                 container_group_name=f"gha-cont-ins-{workflow_job_id}",
                                                 container_group=group).wait()

  logging.info("Container group created")
  container_group = aci_client.container_groups.get(RESOURCE_GROUP_NAME,
                                                      f"gha-cont-ins-{workflow_job_id}")
  

  
  print("Container instance created successfully.")


def parse_incoming_payload(msg):
  data = json.loads(msg)
  labels = data.get("labels", [])
  workflow_job_id = data.get("id")
  return labels, workflow_job_id


@app.queue_trigger(arg_name="azqueue", queue_name=os.getenv("QUEUE_NAME"),
                               connection="storageAccountConnectionString") 
def controller_function(azqueue: func.QueueMessage):
    logging.info('Python Queue trigger processed a message: %s',
                azqueue.get_body().decode('utf-8'))
    runner_label, workflow_job_id = parse_incoming_payload(azqueue.get_body().decode('utf-8'))
    create_container_instance(runner_label, workflow_job_id)  #workflow_job_id "test-wf-id"
    


