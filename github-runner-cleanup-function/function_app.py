import logging
import os
import datetime
import azure.functions as func
from azure.identity import DefaultAzureCredential
from azure.mgmt.containerinstance import ContainerInstanceManagementClient




app = func.FunctionApp()


SUBSCRIPTION_ID = os.getenv("AZURE_SUBSCRIPTION_ID")
RESOURCE_GROUP_NAME = os.getenv("AZURE_RESOURCE_GROUP")

# Set up logging
logging.basicConfig(level=logging.INFO)

# Set up Azure client
credential = DefaultAzureCredential()
container_client = ContainerInstanceManagementClient(credential,"c540fdb6-d9c4-4d9e-9f1d-91743899df62")

# Timer-triggered function that checks and deletes terminated containers every 5 minutes
@app.function_name(name="DeleteTerminatedContainers")
@app.schedule(schedule="0 */2 * * * *", arg_name="mytimer", run_on_start=True)
def main(func.TimerRequest) -> None:

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
    
