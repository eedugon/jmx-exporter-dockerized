#!/bin/sh

# Todo:
# Add message when check_init is successfull.

# Design statements
#  Configuration file will be placed under /opt/jmx_exporter/config/config.yml
#	- That could allow a system like kubernetes to mount the config directory directly from a configMap to override the config

# Supported environment variables to get different behavior
# SERVICE_PORT -- port to receive http /metrics requests
# DEST_HOST -- host to monitor via jmx
# DEST_PORT -- jmx port of destination host
# RULES_MODULE -- rules to apply
# JVM_LOCAL_OPTS -- options for local jvm
# JMX_LOCAL_PORT -- port for local jmxremote
# CHECK_INIT* -- variables for CHECK_INIT feature (check remote jmx port before starting jmx_exporter)

# Supported modules: default, kafka-0-2-8

# Default values.
DEF_SERVICE_PORT="9072"
DEF_DEST_HOST="localhost"
DEF_DEST_PORT="7072"
DEF_RULES_MODULE="default"
DEF_JMX_LOCAL_PORT="7071"
DEF_CHECK_INIT="false"
DEF_CHECK_INIT_MAX_DELAY="300"
DEF_CHECK_INIT_INTERVAL="10"
DEF_CHECK_INIT_ACTION="continue" # set it to continue to not exit in case of check init fails

# check_jmx executable file
CHECK_JMX="/opt/jmx_exporter/check_jmx/check_jmx"

# Configuration related vars
CONFIG_DIR="/opt/jmx_exporter/config"
CONFIG_FILE="$CONFIG_DIR/config.yml"
#PREPARE_CONFIG_SCRIPT="/opt/jmx_exporter/prepare_config.sh"
CONFIG_TEMPLATE="$CONFIG_DIR/config.yml.template"
RULES_DIR="/opt/jmx_exporter/rules"
RULES_OFFICIAL_DIR="/opt/jmx_exporter/rules_official"

# Main JAR
test -z "$VERSION" && { echo "INTERNAL DOCKER ERROR: VERSION env variable not found. This variable should have been set properly during docker image creation"; exit 1; }
EXPORTER_JAR="/opt/jmx_exporter/jmx_prometheus_httpserver-$VERSION-jar-with-dependencies.jar"

# Basic verifications
test -f "$EXPORTER_JAR" || { echo "INTERNAL DOCKER ERROR: jar file not found: $EXPORTER_JAR"; exit 1; }
test -d "$RULES_DIR" || { echo "INTERNAL DOCKER ERROR: Rules dir not found: $RULES_DIR"; exit 1; }
test -d "$RULES_OFFICIAL_DIR" || { echo "INTERNAL DOCKER ERROR: Rules official dir not found: $RULES_OFFICIAL_DIR"; exit 1; }

# Environment variables verification and default values
test -z "$SERVICE_PORT" && SERVICE_PORT="$DEF_SERVICE_PORT"
test -z "$DEST_HOST" && DEST_HOST="$DEF_DEST_HOST"
test -z "$DEST_PORT" && DEST_PORT="$DEF_DEST_PORT"
test -z "$RULES_MODULE" && RULES_MODULE="$DEF_RULES_MODULE"
test -z "$JMX_LOCAL_PORT" && JMX_LOCAL_PORT="$DEF_JMX_LOCAL_PORT"
test -z "$CHECK_INIT" && CHECK_INIT="$DEF_CHECK_INIT"
test -z "$CHECK_INIT_MAX_DELAY" && CHECK_INIT_MAX_DELAY="$DEF_CHECK_INIT_MAX_DELAY"
test -z "$CHECK_INIT_INTERVAL" && CHECK_INIT_INTERVAL="$DEF_CHECK_INIT_INTERVAL"
test -z "$CHECK_INIT_ACTION" && CHECK_INIT_ACTION="$DEF_CHECK_INIT_ACTION"

CHECK_INIT_ITERATIONS=$(expr $CHECK_INIT_MAX_DELAY / $CHECK_INIT_INTERVAL)

# Debug block...
  echo "DEBUG: Environment variables set/received..."
  echo "Service port (metrics): $SERVICE_PORT"
  echo "Destination host: $DEST_HOST"
  echo "Destination port: $DEST_PORT"
  echo "Rules to appy: $RULES_MODULE"
  echo "Local JMX: $JMX_LOCAL_PORT"
  echo

# Note: we should find a way to disable jmx in the jmx-exporter itself (pending)
#jvm opts processing (it requires JMX_LOCAL_PORT to be processed already)
DEF_JVM_LOCAL_OPTS="-Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.port=$JMX_LOCAL_PORT"
test -z "$JVM_LOCAL_OPTS" && JVM_LOCAL_OPTS="$DEF_JVM_LOCAL_OPTS"

# PREPARE_CONFIG TRUE OR FALSE
# If config.yml already exists then we don't need to prepare anything
test -f "$CONFIG_FILE" && { echo "CONFIG FILE found, creation not needed"; PREPARE_CONFIG="false"; } \
    || { echo "CONFIG FILE not found, enabling PREPARE_CONFIG feature"; PREPARE_CONFIG="true"; }

# Configuration preparation
if [ "$PREPARE_CONFIG" = "true" ]; then
  # test -x "$PREPARE_CONFIG_SCRIPT" || { echo "ERROR, $PREPARE_CONFIG_SCRIPT not executable"; exit 1; }
  #  $PREPARE_CONFIG_SCRIPT > $CONFIG_FILE
  # config inline...
  echo "Preparing configuration based on environment variables"
  test -f "$CONFIG_TEMPLATE" || { echo "ERROR: Configuration template not found: $CONFIG_TEMPLATE"; exit 1; }
  cat "$CONFIG_TEMPLATE" | sed -e "s/XXX_HOST_XXX/$DEST_HOST/" -e "s/XXX_PORT_XXX/$DEST_PORT/" > $CONFIG_FILE

  # Rules processing
  RULES_FILE="${RULES_DIR}/${RULES_MODULE}.yml"
  if ! test -f "$RULES_FILE"; then
    # we support finding the module in the official downloaded modules dir.
    test -f "${RULES_OFFICIAL_DIR}/${RULES_MODULE}.yml" && RULES_FILE="${RULES_OFFICIAL_DIR}/${RULES_MODULE}.yml" \
      || {  echo "ERROR: Expected rules file $RULES_MODULE not found in any rules directory";
      echo "Available modules:"; ls $RULES_DIR; ls $RULES_OFFICIAL_DIR; rm $CONFIG_FILE; echo; exit 1; }
  fi
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

# Double check that we can use nagios check_jmx tool within this project
if [ "$CHECK_INIT" = "true" ]; then
    # CHECK_INIT validations
    test -x "$CHECK_JMX" || { echo "CHECK_INIT: $CHECK_JMX not found or not executable"; exit 1; }
    # check that interval and max_delay are integers

    # Check status of remote endpoint before starting
    #   ./check_jmx -U service:jmx:rmi:///jndi/rmi://localhost:7072/jmxrmi -O java.lang:type=Memory -A HeapMemoryUsage -K used -I HeapMemoryUsage -J used -vvvv -w 4248302272 -c 5498760192
    echo "CHECK_INIT: module enabled"
    echo "CHECK_INIT: interval check: $CHECK_INIT_INTERVAL"
    echo "CHECK_INIT: iterations: $CHECK_INIT_ITERATIONS"
    echo "CHECK_INIT: action: $CHECK_INIT_ACTION"

    n=0
    until OUT="$($CHECK_JMX -U service:jmx:rmi:///jndi/rmi://$DEST_HOST:$DEST_PORT/jmxrmi -O java.lang:type=Memory -A HeapMemoryUsage -K used -I HeapMemoryUsage -J used -vvvv -w 42483022720 -c 54987601920 && echo "CHECK_INIT: Check SUCCESS")"; do
      #statements
      echo "CHECK_INIT: Check_jmx returned error $?"
      echo "CHECK_INIT: Response from check_jmx:"
      echo "$OUT"
      echo
      n="$(expr $n + 1)"
#      ((n++))
      if test "$n" -ge "$CHECK_INIT_ITERATIONS"; then
        echo "CHECK_INIT: Number of retries exceeded ($n). Configured action is $CHECK_INIT_ACTION"
        test "$CHECK_INIT_ACTION" = "exit" && { echo "CHECK_INIT: exiting"; exit 1; } \
          || { echo "CHECK_INIT: giving up. Continuing with start procedure anyway"; break; }
      fi
      echo "CHECK_INIT: Attempt $n completed"
      echo "CHECK_INIT: To disable CHECK_INIT feature set environment variable CHECK_INIT to false"
      echo "CHECK_INIT: will try again in $CHECK_INIT_INTERVAL seconds..."
      sleep $CHECK_INIT_INTERVAL
    done
fi
# Service launch
echo "Starting Service..."
java $JVM_LOCAL_OPTS -jar $EXPORTER_JAR $SERVICE_PORT $CONFIG_FILE
