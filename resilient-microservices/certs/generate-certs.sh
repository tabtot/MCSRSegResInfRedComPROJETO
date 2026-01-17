#!/bin/bash

echo "Generating self-signed TLS certificates..."

openssl req -x509 -newkey rsa:4096 -nodes \
  -keyout key.pem \
  -out cert.pem \
  -days 365 \
  -subj "/C=PT/ST=Lisbon/L=Lisbon/O=ISCTE/OU=Cybersecurity/CN=localhost"

echo "Certificates generated: cert.pem and key.pem"
