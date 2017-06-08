#!/bin/bash

# Script that prepares configuration and startup scripts based on environment variables.
# in order to be used when creating this docker from kubernetes for example

# Supported variables
# DEST_HOST
# DEST_PORT
# SERVICE_PORT
# RULES_MODULE
# JMX_LOCAL_PORT
# JMV_OPTS
# kafka-0-8-2.yml

echo "DEBUG: Environment variables set..."
echo "Service port (metrics): $SERVICE_PORT"
echo "Destination host: $DEST_HOST"
echo "Destination port: $DEST_PORT"
echo "Rules to appy: $RULES_MODULE"
echo "Local JMX: $JMX_LOCAL_PORT"

# scrip not used for the moment, this logic is in start.sh
#CONFIG_TEMPLATE=""
# script to prepare the config.yml
#cp config_basic.yml config.yml

# rules module processing

exit 0
