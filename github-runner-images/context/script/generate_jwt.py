#!/usr/bin/env python3
import time
import os
import jwt
import subprocess

PEM_PATH = os.getenv("PEM_PATH", "/home/subir/terraform-modules/terraform-auth-app_private-key.pem")
GH_CLIENT_ID = os.getenv("GH_CLIENT_ID")

# Open PEM
with open(PEM_PATH, 'rb') as pem_file:
    signing_key = pem_file.read()

payload = {
    # Issued at time
    'iat': int(time.time()),
    # JWT expiration time (10 minutes maximum)
    'exp': int(time.time()) + 600,  
    # GitHub App's client ID
    'iss': GH_CLIENT_ID
}

# Create JWT
encoded_jwt = jwt.encode(payload, signing_key, algorithm='RS256')

print(encoded_jwt)

