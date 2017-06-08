#!/bin/sh

# Udated by eedugon from ...

# Design statements
#  Configuration file will be placed under /opt/jmx_exporter/config/config.yml
#	- That could allow a system like kubernetes to mount the config directory directly from a configMap to override the config

# Supported environment variables to get different configuration
# SERVICE_PORT --> Defaults to
# JVM_OPTS
# DEST_HOST
# DEST_PORT
# SERVICE_PORT
# RULES_MODULE
# JMX_LOCAL_PORT

# Default values.
DEF_SERVICE_PORT=5556
DEF_DEST_HOST="localhost"
DEF_DEST_PORT="5555"
DEF_RULES_MODULE="default"
DEF_JMX_LOCAL_PORT="5544"

# Config dir and file
CONFIG_DIR="/opt/jmx_exporter/config"
CONFIG_FILE="$CONFIG_DIR/config.yml"
PREPARE_CONFIG_SCRIPT="/opt/jmx_exporter/prepare_config.sh"
CONFIG_TEMPLATE="$CONFIG_DIR/config.yml.template"
RULES_DIR="/opt/jmx_exporter/rules"

# Main JAR
EXPORTER_JAR="/opt/jmx_exporter/jmx_prometheus_httpserver-$VERSION-jar-with-dependencies.jar"

# Basic verifications
test -f "$EXPORTER_JAR" || { echo "INTERNAL DOCKER ERROR: jar file not found: $EXPORTER_JAR"; exit 1; }
test -z "$VERSION" || { echo "INTERNAL DOCKER ERROR: VERSION env variable not found. This variable should have been set properly during docker image creation"; exit 1; }
test -d "$RULES_DIR" || { echo "INTERNAL DOCKER ERROR: Rules dir not found: $RULES_DIR"; exit 1; }

# Environment variables verification and default values
test -z "$SERVICE_PORT" && SERVICE_PORT="$DEF_SERVICE_PORT"
test -z "$DEST_HOST" && DEST_HOST="$DEF_DEST_HOST"
test -z "$DEST_PORT" && DEST_PORT="$DEF_DEST_PORT"
test -z "$RULES_MODULE" && RULES_MODULE="$DEF_RULES_MODULE"
test -z "$JMX_LOCAL_PORT" && JMX_LOCAL_PORT="$DEF_JMX_LOCAL_PORT"

# Debug block...
  echo "DEBUG: Environment variables set..."
  echo "Service port (metrics): $SERVICE_PORT"
  echo "Destination host: $DEST_HOST"
  echo "Destination port: $DEST_PORT"
  echo "Rules to appy: $RULES_MODULE"
  echo "Local JMX: $JMX_LOCAL_PORT"
  echo

# Note: we should find a way to disable jmx in the jmx-exporter itself (pending)
#jvm opts processing (it requires JMX_LOCAL_PORT to be processed already)
DEF_JVM_OPTS="-Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.port=$JMX_LOCAL_PORT"
test -z "$JVM_OPTS" && JVM_OPTS="$DEF_JVM_OPTS"

# PREPARE_CONFIG TRUE OR FALSE
# If config.yml already exists then something overwrote the configuration. we don't need to prepare it based on environment variables
test -f "$CONFIG_FILE" && { echo "CONFIG FILE found, creation not needed"; PREPARE_CONFIG="false"; } \
    || { echo "CONFIG FILE not found. Trying to prepare it based on environment variables"; PREPARE_CONFIG="true"; }

# Configuration preparation
if [ "$PREPARE_CONFIG" == "true" ]; then
  # test -x "$PREPARE_CONFIG_SCRIPT" || { echo "ERROR, $PREPARE_CONFIG_SCRIPT not executable"; exit 1; }
  #  $PREPARE_CONFIG_SCRIPT > $CONFIG_FILE
  # config inline...
  echo "Preparing configuration based on environment variables"

  cat "$CONFIG_TEMPLATE" | sed -e "s/XXX_HOST_XXX/$DEST_HOST/" -e "s/XXX_PORT_XXX/$DEST_PORT/" > $CONFIG_FILE

  # Rules processing
  RULES_FILE="${RULES_DIR}/${RULES_MODULE}.yml"
  test -f "$RULES_FILE" || { echo "ERROR: Expected rules file $RULES_FILE not found";
      echo "Available modules:"; ls $RULES_DIR/; exit 1; }
  cat "$RULES_FILE" >> $CONFIG_FILE

  echo "Configuration preparation completed, final cofiguration dump:"
  echo "############"
  cat $CONFIG_FILE
  echo "########"
else
  echo "Configuration already present:"
  echo "#######"
  cat $CONFIG_FILE
  echo "########"
fi

# Redundant check, but just in case :)
test -f "$CONFIG_FILE" || { echo "ERROR: config file not found: $CONFIG_FILE"; exit 1; }

# Service launch
java $JVM_OPTS -jar $EXPORTER_JAR $SERVICE_PORT $CONFIG_FILE
