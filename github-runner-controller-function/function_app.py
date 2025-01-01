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
from azure.mgmt.containerinstance.models import (
    ContainerGroup,
    ImageRegistryCredential,
    Container,
    ResourceRequests,
    ResourceRequirements,
    OperatingSystemTypes,
    EnvironmentVariable,
    ContainerPort,
    Port,
    IpAddress,
)


app = func.FunctionApp()

# Read configurations from environment variables
AZURE_CONTAINER_REGISTRY = os.getenv("AZURE_CONTAINER_REGISTRY")
KV_NAME = os.getenv("AZURE_KV_NAME")
GH_APP_PEM_FILE_KEY = os.getenv("GH_APP_PEM_FILE")
GH_APP_INSTT_ID_KEY = os.getenv("GH_APP_INSTT_ID")
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
  gh_app_instt_id = None
  # Retrieve the secret
  try:
    gh_app_pem_file = client.get_secret(GH_APP_PEM_FILE_KEY)
    gh_app_instt_id = client.get_secret(GH_APP_INSTT_ID_KEY)
    print(f"PEM Value: { gh_app_pem_file.value } and { gh_app_instt_id.value }")
  except Exception as ex:
    print(f"An error occurred: {ex}")
  container_environment_variable = [
    EnvironmentVariable(name="PEM_file", secure_value=gh_app_pem_file.value),
    EnvironmentVariable(name="GH_CLIENT_ID", secure_value=gh_app_instt_id.value)
  ]
  return container_environment_variable

def create_container_instance(runner_label):
  # Use DefaultAzureCredential for authentication
  logging.info("Start Containefr Creation function")
  credential = DefaultAzureCredential()
  aci_client = ContainerInstanceManagementClient(credential, SUBSCRIPTION_ID)
  logging.info("Subcription done")
  
  container_resource_requests = ResourceRequests(memory_in_gb=1, cpu=1.0)
  logging.info("CPU and memory initialized")

  # Retrieve GH APP secrets from key-vault
  container_environment_variable = retrieve_kv_secret()
  
  # Retrieve requested container image



  # container_group_name = f"{ runner_label }"
  # container_image_name = f"{ AZURE_CONTAINER_REGISTRY }/{ runner_label }:latest"
  container_image_name="awesomeprojdevacr/gha-runner:202501010134"
  
  # Configure the container
  container_resource_requirements = ResourceRequirements(
        requests=container_resource_requests)
  
  
  container = Container(name="test-container",
                          image=container_image_name,
                          resources=container_resource_requirements,
                          environment_variables=container_environment_variable,
                          ports=[ContainerPort(port=80)])
  
  logging.info("Container Config done")

  group = ContainerGroup(location=LOCATION,
                           containers=[container],
                           os_type=OperatingSystemTypes.linux,
                           identity = {"type": "SystemAssigned"})

  aci_client.container_groups.begin_create_or_update(resource_group_name=RESOURCE_GROUP_NAME,
                                                 container_group_name="container-group",
                                                 container_group=group)

  container_group = aci_client.container_groups.get(RESOURCE_GROUP_NAME,
                                                      "container-group")
  

  
  print("Container instance created successfully.")


def parse_incoming_payload(msg):
  data = json.loads(msg)
  labels = data.get("labels", [])
  return labels


@app.queue_trigger(arg_name="azqueue", queue_name=os.getenv("QUEUE_NAME"),
                               connection="storageAccountConnectionString") 
def controller_function(azqueue: func.QueueMessage):
    logging.info('Python Queue trigger processed a message: %s',
                azqueue.get_body().decode('utf-8'))
    runner_label = parse_incoming_payload(azqueue.get_body().decode('utf-8'))
    create_container_instance(runner_label)
    


