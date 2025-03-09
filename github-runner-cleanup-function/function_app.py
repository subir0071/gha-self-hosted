import logging
import os
import azure.functions as func
from azure.identity import DefaultAzureCredential
from azure.mgmt.containerservice import ContainerInstanceManagementClient


app = func.FunctionApp()


SUBSCRIPTION_ID = os.getenv("AZURE_SUBSCRIPTION_ID")
RESOURCE_GROUP_NAME = os.getenv("AZURE_RESOURCE_GROUP")

# Set up logging
logging.basicConfig(level=logging.INFO)

# Set up Azure client
credential = DefaultAzureCredential()
container_client = ContainerInstanceManagementClient(credential, SUBSCRIPTION_ID)

# Timer-triggered function that checks and deletes terminated containers every 5 minutes
@app.function_name(name="DeleteTerminatedContainers")
@app.schedule("0 */5 * * * *", arg_name="mytimer", run_on_start=True)
def main(mytimer: func.TimerRequest) -> None:
    utc_timestamp = mytimer.timestamp
    logging.info(f"Checking for terminated containers at {utc_timestamp}")

    try:
        # List all container groups in the specified resource group
        container_groups = container_client.container_groups.list_by_resource_group(RESOURCE_GROUP_NAME)

        for group in container_groups:
            # Check if the container group has any containers that are terminated
            for container in group.containers:
                # If container state is "terminated", delete the container group
                if container.instance_view.state == 'Terminated':
                    logging.info(f"Container '{container.name}' has terminated. Deleting container group '{group.name}'")
                    container_client.container_groups.delete(RESOURCE_GROUP_NAME, group.name)
                    logging.info(f"Container group '{group.name}' deleted successfully.")
    except Exception as e:
        logging.error(f"Error while checking/deleting container groups: {str(e)}")
    
