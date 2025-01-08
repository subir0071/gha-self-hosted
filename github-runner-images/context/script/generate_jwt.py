#!/usr/bin/env python3
import time
import os
import jwt
import subprocess

PEM_FILE = os.getenv("PEM_CONTENT")
GH_CLIENT_ID = os.getenv("GH_CLIENT_ID")

# Write PEM
with open('key_file.pem', 'w') as pem_file:
     pem_file.write(PEM_FILE)

payload = {
    # Issued at time
    'iat': int(time.time()),
    # JWT expiration time (10 minutes maximum)
    'exp': int(time.time()) + 600,  
    # GitHub App's client ID
    'iss': GH_CLIENT_ID
}

# Create JWT
encoded_jwt = jwt.encode(payload, PEM_FILE, algorithm='RS256') #signing_key

print(encoded_jwt)

