#!/bin/bash

KEYSTONE_HOST="${KEYSTONE_HOST:-localhost}"
DATABASE_HOST="${DATABASE_HOST:-localhost}"
KEYSTONE_DB_USER="${KEYSTONE_DB_USER:-keystone}"
KEYSTONE_DB_PASSWORD="${KEYSTONE_DB_PASSWORD:-914de29bc82616d7c159eaf9b1f39402}"
KEYSTONE_DB_NAME="${KEYSTONE_DB_NAME:-keystone}"

sed -i.bak s/DATABASE_HOST/$DATABASE_HOST/g /etc/keystone/keystone.conf
sed -i.bak s/KEYSTONE_DB_USER/$KEYSTONE_DB_USER/g /etc/keystone/keystone.conf
sed -i.bak s/KEYSTONE_DB_PASSWORD/$KEYSTONE_DB_PASSWORD/g /etc/keystone/keystone.conf
sed -i.bak s/KEYSTONE_DB_NAME/$KEYSTONE_DB_NAME/g /etc/keystone/keystone.conf

# Keystone Database and Kernet setup
keystone-manage db_sync
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

# Start Apache / Keystone Service
apachectl -D FOREGROUND &

keystone-manage bootstrap --bootstrap-password ADMIN_PASS \
  --bootstrap-admin-url http://$KEYSTONE_HOST:35357/v3/ \
  --bootstrap-internal-url http://$KEYSTONE_HOST:5000/v3/ \
  --bootstrap-public-url http://$KEYSTONE_HOST:5000/v3/ \
  --bootstrap-region-id RegionOne


if [ -f /usr/bin/post-keystone.sh ]; then
    echo "Running post-keystone.sh script"
    /usr/bin/post-keystone.sh
fi

tail -f /var/log/apache2/*
