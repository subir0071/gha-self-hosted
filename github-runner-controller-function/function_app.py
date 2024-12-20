import os
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
  credential = DefaultAzureCredential()
  container_client = ContainerInstanceManagementClient(credential, SUBSCRIPTION_ID)
        
  container_resource_requests = ResourceRequests(cpu=CPU_CORE_COUNT, memory_in_gb=MEMORY_IN_GB)
  container_resource_requirements = ResourceRequirements(requests=container_resource_requests)
        
  container = Container(
    name=CONTAINER_NAME,
    image=CONTAINER_IMAGE,
    resources=container_resource_requirements,
    ports=[ContainerPort(port=80)]
    )
        
  ip_address = IpAddress(ports=[Port(protocol="TCP", port=80)], type="Public")
        
  container_group = ContainerGroup(
    location=LOCATION,
    containers=[container],
    os_type=OperatingSystemTypes.LINUX,
    ip_address=ip_address,
    restart_policy="OnFailure",
    )
        
  print(f"Creating container instance with content: {message_content}")
  response = container_client.container_groups.begin_create_or_update(
    resource_group_name=RESOURCE_GROUP_NAME,
    container_group_name=CONTAINER_NAME,
    container_group=container_group
    )
  response.result()  # Wait for the operation to complete
  print("Container instance created successfully.")



@app.queue_trigger(arg_name="azqueue", queue_name=os.getenv("QUEUE_NAME"),
                               connection="storageAccountConnectionString") 
def controller_function(azqueue: func.QueueMessage):
    logging.info('Python Queue trigger processed a message: %s',
                azqueue.get_body().decode('utf-8'))
    create_container_instance(azqueue.get_body().decode('utf-8'))
    


