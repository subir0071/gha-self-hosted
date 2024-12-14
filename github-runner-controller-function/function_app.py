import azure.functions as func
import logging
import os
from azure.identity import DefaultAzureCredential
from azure.mgmt.containerinstance import ContainerInstanceManagementClient
from azure.mgmt.containerinstance.models import (
    ContainerGroup,
    Container,
    ContainerPort,
    ResourceRequests,
    ResourceRequirements,
    OperatingSystemTypes,
    ImageRegistryCredential,
    Port,
    IpAddress,
    ContainerGroupNetworkProtocol,
)

app = func.FunctionApp()

@app.queue_trigger(arg_name="azqueue", queue_name=os.getenv("QUEUE_NAME"),
                               connection="storageAccountConnectionString") 
def controller_function(azqueue: func.QueueMessage):
    logging.info('Python Queue trigger processed a message: %s',
                azqueue.get_body().decode('utf-8'))
    


    # Replace with your Azure Subscription ID
    SUBSCRIPTION_ID = "your_subscription_id"

    # Replace with your desired resource group and container group details
    RESOURCE_GROUP = "your_resource_group"
    CONTAINER_GROUP_NAME = "your_container_group_name"
    CONTAINER_NAME = "your_container_name"
    CONTAINER_IMAGE = "nginx:latest"  # Replace with your desired container image
    CONTAINER_PORT = 80

    # Authenticate using DefaultAzureCredential
    credential = DefaultAzureCredential()

    # Initialize the Container Instance client
    container_client = ContainerInstanceManagementClient(credential, SUBSCRIPTION_ID)

    # Define the container resource requirements
    container_resource_requests = ResourceRequests(memory_in_gb=1.0, cpu=1.0)
    container_resource_requirements = ResourceRequirements(requests=container_resource_requests)

    # Define the container instance
    container = Container(
        name=CONTAINER_NAME,
        image=CONTAINER_IMAGE,
        resources=container_resource_requirements,
        ports=[ContainerPort(port=CONTAINER_PORT)],
    )

    # Define the container group
    container_group = ContainerGroup(
        location="eastus",  # Replace with your desired Azure region
        containers=[container],
        os_type=OperatingSystemTypes.LINUX,
        ip_address=IpAddress(
            ports=[Port(protocol=ContainerGroupNetworkProtocol.TCP, port=CONTAINER_PORT)],
            type="Public",
        ),
    )

    # Create the container group
    response = container_client.container_groups.begin_create_or_update(
        RESOURCE_GROUP, CONTAINER_GROUP_NAME, container_group
    )
    result = response.result()

    print(f"Container group '{CONTAINER_GROUP_NAME}' created with state: {result.provisioning_state}")
