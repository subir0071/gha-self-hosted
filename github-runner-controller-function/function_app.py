import logging
import azure.functions as func
import os
from azure.mgmt.containerinstance.models import ContainerGroupNetworkProtocol
from azure.storage.queue import QueueServiceClient
from azure.identity import DefaultAzureCredential
from azure.mgmt.containerinstance import ContainerInstanceManagementClient
from azure.mgmt.containerinstance.models import (
    ContainerGroup,
    Container,
    ResourceRequests,
    ResourceRequirements,
    OperatingSystemTypes,
    ContainerPort,
    Port,
    IpAddress,
)


app = func.FunctionApp()

# Read configurations from environment variables
SUBSCRIPTION_ID = os.getenv("AZURE_SUBSCRIPTION_ID")
RESOURCE_GROUP_NAME = os.getenv("AZURE_RESOURCE_GROUP")
LOCATION = os.getenv("AZURE_LOCATION", "eastus2")  # Default to 'eastus2'
CONTAINER_IMAGE = os.getenv("CONTAINER_IMAGE", "nginx")  # Default to 'nginx'
CONTAINER_NAME = os.getenv("CONTAINER_NAME", "my-container")
CPU_CORE_COUNT = float(os.getenv("CONTAINER_CPU", 1))
MEMORY_IN_GB = float(os.getenv("CONTAINER_MEMORY", 1.5))

def create_container_instance(message_content):
  # Use DefaultAzureCredential for authentication
  logging.info("Start Containefr Creation function")
  credential = DefaultAzureCredential()
  aci_client = ContainerInstanceManagementClient(credential, SUBSCRIPTION_ID)
  logging.info("Subcription done")
  
  container_resource_requests = ResourceRequests(memory_in_gb=1, cpu=1.0)
  logging.info("CPU and memory initialized")

  
  container_group_name = "test-group"
  container_image_name = 'microsoft\aci-helloworld:latest'

  # Configure the container
  container_resource_requirements = ResourceRequirements(
        requests=container_resource_requests)
  
  container = Container(name=container_group_name,
                          image=container_image_name,
                          resources=container_resource_requirements,
                          ports=[ContainerPort(port=80)])
  
  logging.info("Container Config done")

  ports = [Port(protocol=ContainerGroupNetworkProtocol.tcp, port=80)]

  group_ip_address = IpAddress(ports=ports,
                                 dns_name_label=container_group_name,
                                 type="Public")
  group = ContainerGroup(location=LOCATION,
                           containers=[container],
                           os_type=OperatingSystemTypes.linux,
                           ip_address=group_ip_address)

  aci_client.container_groups.begin_create_or_update(RESOURCE_GROUP_NAME,
                                                 container_group_name,
                                                 group)

  container_group = aci_client.container_groups.get(RESOURCE_GROUP_NAME,
                                                      container_group_name)
  

  
  print("Container instance created successfully.")



@app.queue_trigger(arg_name="azqueue", queue_name=os.getenv("QUEUE_NAME"),
                               connection="storageAccountConnectionString") 
def controller_function(azqueue: func.QueueMessage):
    logging.info('Python Queue trigger processed a message: %s',
                azqueue.get_body().decode('utf-8'))
    create_container_instance(azqueue.get_body().decode('utf-8'))
    


