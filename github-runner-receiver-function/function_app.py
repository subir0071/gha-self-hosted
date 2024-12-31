import azure.functions as func
import logging
import os
import json

app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)
@app.route(route="receiver_function")
@app.queue_output(
    arg_name="msg", 
    queue_name=os.getenv("QUEUE_NAME"),  # Read queue name from environment
    connection="storageAccountConnectionString"
)
def receiver_function(req: func.HttpRequest, msg: func.Out[str]) -> func.HttpResponse:

    try:
        # Parse the JSON payload from the request
        req_body = req.get_json()
    except ValueError:
        return func.HttpResponse("Invalid JSON payload.", status_code=400)
    request_action = req_body.get('action')
    if request_action != 'queued':
        return func.HttpResponse(f"No runner created for {request_action} webhook", status_code=200)
    
    label_list = {"labels": req_body.get('workflow_job',{}).get('labels', [])}
    
    try:
        # Serialize the JSON to a string to send to the queue
        message = json.dumps(label_list)

        # Send the message to the queue
        msg.set(message)

        logging.info(f"Message successfully sent to the queue.")
        return func.HttpResponse("Message successfully sent to the queue.", status_code=200)
    except Exception as e:
        logging.error(f"Failed to process the request: {str(e)}")
        return func.HttpResponse(f"Failed to send message: {str(e)}", status_code=500)
    