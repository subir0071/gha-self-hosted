import azure.functions as func
import logging
import os
import json
from azure.identity import DefaultAzureCredential
from azure.mgmt.containerservice import ContainerInstanceManagementClient
from azure.mgmt.containerservice.models import ContainerGroup

app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)
@app.route(route="receiver_function")
@app.queue_output(
    arg_name="msg", 
    queue_name=os.getenv("QUEUE_NAME"),  # Read queue name from environment
    connection="storageAccountConnectionString"
)
def receiver_function(req: func.HttpRequest, msg: func.Out[str]) -> func.HttpResponse:
    req_body = None
    try:
        # Parse the JSON payload from the request
        req_body = req.get_json()
    except ValueError:
        return func.HttpResponse("Invalid JSON payload.", status_code=400)
    request_action = req_body.get('action')
    if request_action == 'queued':
      workflow_job = req_body.get('workflow_job',{})    
      try:
        # Serialize the JSON to a string to send to the queue
        message = json.dumps(workflow_job)
        # Send the message to the queue
        msg.set(message)
        logging.info(f"Message successfully sent to the queue.")
        return func.HttpResponse("Message successfully sent to the queue.", status_code=200)
      except Exception as e:
        logging.error(f"Failed to process the request: {str(e)}")
        return func.HttpResponse(f"Failed to send message: {str(e)}", status_code=500)
    elif request_action == 'completed':
      SUBSCRIPTION_ID = os.getenv("AZURE_SUBSCRIPTION_ID")
      RESOURCE_GROUP_NAME = os.getenv("AZURE_RESOURCE_GROUP")
      credential = DefaultAzureCredential()
      client = ContainerInstanceManagementClient(credential, SUBSCRIPTION_ID)
      container_groups = client.container_groups.list_by_resource_group(RESOURCE_GROUP_NAME)
      deleted_container_count = 0

      for container_group in container_groups:
    # Check if the container group has terminated (or any other status you want)
        if container_group.instance_view.state == "Terminated":
          print(f"Terminated container group found: {container_group.name}")
        
        # Delete the terminated container group
          delete_operation = client.container_groups.begin_delete(RESOURCE_GROUP_NAME, container_group.name)
          delete_operation.wait()  # Wait for the deletion to complete
          print(f"Deleted terminated container group: {container_group.name}")
          deleted_container_count=deleted_container_count+1
      return func.HttpResponse(f"{deleted_container_count} container(s) deleted", status_code=200)
    else:
       return func.HttpResponse(f"No container created for {request_action} action webhook", status_code=200)

       
    