#!/bin/bash

# Vérifiez si un nom de client et un mot de passe ont été fournis
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <client_name> <client_password>"
  exit 1
fi

CLIENT=$1
PASSWORD=$2

# Changez de répertoire pour Easy-RSA
cd /etc/openvpn/easy-rsa/ || exit

# Créez un fichier temporaire pour le mot de passe
echo "$PASSWORD" > pkitmp

# Construisez le certificat pour le client avec un mot de passe
./easyrsa --batch --passin=file:pkitmp --passout=file:pkitmp build-client-full "$CLIENT"

# Supprimez le fichier temporaire du mot de passe
rm pkitmp

# Vérifiez si la construction du certificat a réussi
if [ $? -ne 0 ]; then
  echo "Failed to generate client certificate"
  exit 1
fi

# Créez le répertoire de sortie si nécessaire
OUTPUT_DIR="/root"
mkdir -p "$OUTPUT_DIR"

# Déterminez si tls-auth ou tls-crypt est utilisé
if grep -qs "^tls-crypt" /etc/openvpn/server.conf; then
  TLS_SIG="1"
elif grep -qs "^tls-auth" /etc/openvpn/server.conf; then
  TLS_SIG="2"
fi

# Génère le fichier client.ovpn
CONFIG_FILE="$OUTPUT_DIR/$CLIENT.ovpn"
cp /etc/openvpn/client-template.txt "$CONFIG_FILE"

{
  echo "<ca>"
  cat "/etc/openvpn/ca.crt"
  echo "</ca>"

  echo "<cert>"
  awk '/BEGIN/,/END CERTIFICATE/' "/etc/openvpn/easy-rsa/pki/issued/$CLIENT.crt"
  echo "</cert>"

  echo "<key>"
  cat "/etc/openvpn/easy-rsa/pki/private/$CLIENT.key"
  echo "</key>"

  case $TLS_SIG in
  1)
    echo "<tls-crypt>"
    cat /etc/openvpn/tls-crypt.key
    echo "</tls-crypt>"
    ;;
  2)
    echo "key-direction 1"
    echo "<tls-auth>"
    cat /etc/openvpn/tls-auth.key
    echo "</tls-auth>"
    ;;
  esac
} >> "$CONFIG_FILE"

echo ""
echo "The configuration file has been written to $CONFIG_FILE."
echo "Download the .ovpn file and import it into your OpenVPN client."
