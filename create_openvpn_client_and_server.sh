#!/bin/bash

# Vérifiez si un nom de client et un mot de passe ont été fournis
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <client_name> <client_password>"
  exit 1
fi

CLIENT_NAME=$1
CLIENT_PASSWORD=$2

# Exécutez le script pour générer les certificats OpenVPN
./generate_openvpn_client.sh "$CLIENT_NAME" "$CLIENT_PASSWORD"

# Vérifiez si le script de génération des certificats a réussi
if [ $? -ne 0 ]; then
  echo "Failed to generate client certificates."
  exit 1
fi

# Exécutez le script Expect pour générer la configuration du serveur OpenVPN
/usr/bin/expect -f generate_server_config.exp "$CLIENT_NAME"

# Vérifiez si le script Expect a réussi
if [ $? -ne 0 ]; then
  echo "Failed to generate server configuration."
  exit 1
fi

# Démarrer le service OpenVPN pour le client spécifié
systemctl start "openvpn@$CLIENT_NAME"

echo "Client and server configuration completed successfully."
