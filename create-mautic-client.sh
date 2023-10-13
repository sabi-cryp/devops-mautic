#!/bin/bash

# Input: Client name, passed as a parameter to the script
CLIENT_NAME=$1

# Define database and URL variables for the client
DB_HOST="db-server"  # Database server hostname
DB_USER="${CLIENT_NAME}_db_user"  # Unique database username for the client
DB_PASSWORD="${CLIENT_NAME}_db_password"  # Unique database password for the client
CLIENT_URL="http://10.10.204.6:8080/$CLIENT_NAME"  # Unique URL for the client

# Step 1: Create a Database for the Client
# In this step, the script connects to the database server and creates a dedicated database for the client. The database name is derived from the client name.

mysql -u root -p -e "CREATE DATABASE $CLIENT_NAME;"

# Step 2: Configure Mautic for the Client
# This is a placeholder for configuring Mautic for the client. You would set up Mautic settings, templates, and other configurations specific to the client's needs. This might involve copying configuration files, applying templates, and more.

# Step 3: Create a Virtual Host or URL Routing
# In this step, the script creates a virtual host or sets up URL routing to map the client's URL to the Mautic instance. This allows clients to access Mautic using their dedicated URL.

# Example: Creating an Apache Virtual Host
# This step can involve editing the Apache configuration to create a virtual host for the client. This is an example of how you might do it:

# Create a configuration file for the client's virtual host
cat <<EOF > /etc/apache2/sites-available/${CLIENT_NAME}.conf
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    ServerName $CLIENT_NAME.mautic-server.com
    DocumentRoot /var/www/html/$CLIENT_NAME

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined

    # Additional configuration specific to the client can be added here
</VirtualHost>
EOF

# Enable the virtual host configuration
a2ensite ${CLIENT_NAME}.conf

# Reload Apache to apply the changes
systemctl reload apache2

# End of the Script
# The script ends by echoing a success message to indicate that the client has been created.

echo "Client $CLIENT_NAME has been created successfully."
