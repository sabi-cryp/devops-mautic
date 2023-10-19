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
  ${CLIENT_NAME}:
    image: mautic/mautic:v4-apache
    container_name: ${CLIENT_NAME}
    ports:
      - "$PORT_NUMBER:80"
    environment:
      MAUTIC_URL: http://gmarket.gnet.tn/$CLIENT_NAME
      MAUTIC_DB_HOST: db-${CLIENT_NAME}
      MAUTIC_DB_USER: ${CLIENT_NAME}
      MAUTIC_DB_PASSWORD: ${CLIENT_NAME}_password
      MAUTIC_DB_NAME: ${CLIENT_NAME}_db
      MAUTIC_RUN_CRON_JOBS: 'false'
    volumes:
      - ${CLIENT_NAME}_data:/var/www/html

  db-${CLIENT_NAME}:
    image: mariadb:10.6
    container_name: db-${CLIENT_NAME}
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: root_password
      MYSQL_DATABASE: ${CLIENT_NAME}_db
      MYSQL_USER: ${CLIENT_NAME}
      MYSQL_PASSWORD: ${CLIENT_NAME}_password
    ports:
      - "$((PORT_NUMBER + 1000)):3306"
    volumes:
      - db-${CLIENT_NAME}_data:/var/lib/mysql

volumes:
  ${CLIENT_NAME}_data:
  db-${CLIENT_NAME}_data:
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

# Step 8: Create Nginx Configuration
NGINX_CONFIG_FILE="/etc/nginx/sites-available/client_${CLIENT_NAME}"
cat <<EOL > "$NGINX_CONFIG_FILE"
server {
    listen 80;
    server_name ${CLIENT_NAME}-gmarket.gnet.tn;

    location / {
        proxy_pass http://10.10.204.7:${PORT_NUMBER};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    error_log /var/log/nginx/error.log;
    access_log /var/log/nginx/access.log;
}
EOL

# Step 9: Create Symbolic Link for Nginx Configuration
 ln -s "$NGINX_CONFIG_FILE" /etc/nginx/sites-enabled/

# Step 10: Test Nginx Configuration
 nginx -t

# Step 11: If you want to deploy to Kubernetes, apply the Kubernetes configuration
kubectl apply -f "$K8S_CONFIG_FILE"
kubectl apply -f "$K8S_SERVICE_FILE"
