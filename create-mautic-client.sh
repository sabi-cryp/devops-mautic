#!/bin/bash

# Input: Client name and port number
CLIENT_NAME=$1
PORT_NUMBER=$2

# Step 1: Create a directory for the client
CLIENT_DIR="/var/lib/jenkins/$CLIENT_NAME"
mkdir -p "$CLIENT_DIR"

# Step 2: Create a Docker Compose file for the client
DOCKER_COMPOSE_FILE="$CLIENT_DIR/docker-compose-$CLIENT_NAME.yml"
cat <<EOL > "$DOCKER_COMPOSE_FILE"
version: '3'
services:
  $CLIENT_NAME-mautic:
    image: mautic/mautic:v4-apache
    container_name: $CLIENT_NAME-mautic
    ports:
      - "$PORT_NUMBER:80"
    volumes:
      - ./mautic-data-$CLIENT_NAME:/var/www/html
    environment:
      - MAUTIC_DB_HOST=db
      - MAUTIC_DB_NAME=$CLIENT_NAME
      - MAUTIC_DB_USER=$CLIENT_NAME-user
      - MAUTIC_DB_PASSWORD=$CLIENT_NAME-password
EOL

# Step 3: Create a Kubernetes configuration file for the client
K8S_CONFIG_FILE="$CLIENT_DIR/k8s-config-$CLIENT_NAME.yaml"
cat <<EOL > "$K8S_CONFIG_FILE"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $CLIENT_NAME-mautic-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $CLIENT_NAME-mautic
  template:
    metadata:
      labels:
        app: $CLIENT_NAME-mautic
    spec:
      containers:
        - name: $CLIENT_NAME-mautic
          image: mautic/mautic:v4-apache
          ports:
            - containerPort: 80
  # Define other Kubernetes resources (e.g., Service) if needed
EOL

# Step 4: Create a Kubernetes service configuration for the client
K8S_SERVICE_FILE="$CLIENT_DIR/k8s-service-$CLIENT_NAME.yaml"
cat <<EOL > "$K8S_SERVICE_FILE"
apiVersion: v1
kind: Service
metadata:
  name: $CLIENT_NAME-mautic-service
spec:
  selector:
    app: $CLIENT_NAME-mautic
  ports:
    - protocol: TCP
      port: $PORT_NUMBER
      targetPort: 80
  type: NodePort  # Use the appropriate service type for your setup
EOL

# Step 5: Additional client-specific setup
# Add more steps here to perform any other client-specific configurations

echo "Client $CLIENT_NAME has been created successfully."

# Step 6: Deploy the client using Docker Compose
docker-compose -f "$DOCKER_COMPOSE_FILE" up -d

# Step 7: Push the Docker image to Nexus
docker login -u skerchaoui -p skerchaoui23#
docker tag mautic/mautic:v4-apache nexus.gnet.tn:8443/gmarket/$CLIENT_NAME:v4-apache
docker push nexus.gnet.tn:8443/gmarket/$CLIENT:v4-apache

# Step 8: If you want to deploy to Kubernetes, apply the Kubernetes configuration
kubectl apply -f "$K8S_CONFIG_FILE"
kubectl apply -f "$K8S_SERVICE_FILE"
