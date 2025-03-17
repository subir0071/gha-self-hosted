import logging
import os
import datetime
import azure.functions as func
from azure.identity import DefaultAzureCredential
from azure.mgmt.containerinstance import ContainerInstanceManagementClient
from azure.functions import TimerRequest




app = func.FunctionApp()




# Set up logging
logging.basicConfig(level=logging.INFO)

# Set up Azure client


# Timer-triggered function that checks and deletes terminated containers every 5 minutes
@app.function_name(name="DeleteTerminatedContainers")
@app.schedule(schedule="0 */2 * * * *", arg_name="mytimer", run_on_start=True)
def main(mytimer: func.TimerRequest) -> None:
    SUBSCRIPTION_ID = os.getenv("AZURE_SUBSCRIPTION_ID")
    RESOURCE_GROUP_NAME = os.getenv("AZURE_RESOURCE_GROUP")

    logging.info(f"Subscription ID: {SUBSCRIPTION_ID}")
    
    logging.info(f"Resource Group: {RESOURCE_GROUP_NAME}")

    credential = DefaultAzureCredential()
    container_client = ContainerInstanceManagementClient(credential,SUBSCRIPTION_ID)
    try:
        # List all container groups in the specified resource group
        container_groups_list = container_client.container_groups.list_by_resource_group(RESOURCE_GROUP_NAME)
        
        logging.info(f"Checking for terminated containers {container_groups_list}")
        for group in container_groups_list:
            container_group = container_client.container_groups.get(RESOURCE_GROUP_NAME,
                                                      group.name)
            # Check if the container group has any containers that are terminated
            logging.info(f"for each container group (few params) {group}")
            logging.info(f"for each container group (after get params) {container_group}")
            
            for container in container_group.containers:
                # If container state is "terminated", delete the container group
                
                logging.info(f"for each container {container} and state is {container.instance_view.current_state.state}")
                if container.instance_view.current_state.state == 'Terminated':
                    logging.info(f"Container '{container.name}' has terminated. Deleting container group '{group.name}'")
                    container_client.container_groups.begin_delete(RESOURCE_GROUP_NAME, group.name)
                    logging.info(f"Container group '{group.name}' deleted successfully.")
    except Exception as e:
        logging.error(f"Error while checking/deleting container groups: {str(e)}")
    
