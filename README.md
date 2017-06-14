# EEDUGON: TO BE UPDATED ALL THIS

This project consists of a dockerised JMX Exporter image, based on the original image created by sscaling (sscaling/jmx_exporter), using alpine-java, dumb-init and fetching the official released version of jmx_exporter from the [maven central repository](https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_httpserver/)

This image includes the following extra features:

  * Automatic Configuration: config.xml creation based on environment variables
  * Static Configuration: if config.xml is mapped into /opt/jmx_exporter/config/, then environment variables won't be considered, and the provided configuration used.
  * Flexible rules: via environment variable we can select the rules to apply to the configuration (only if Automatic Configuration feature is used)

Environment variables supported to get different behavior

  * SERVICE_PORT -- port to receive http /metrics requests
  * DEST_HOST -- host to monitor via jmx
	* DEST_PORT -- jmx port of destination host
	* RULES_MODULE -- rules to apply
	* JVM_LOCAL_OPTS -- options for local jvm
	* JMX_LOCAL_PORT -- port for local jmxremote

Supported modules in current version (only one can be selected):
  * default
	* kafka-0-2-8

## Default Settings

If no environment variables or volumes are provided to the image, the exporter will have the following behavior:

  * HTTP listening port: 9072
  * Remote JVM to connect to: localhost: 7072
	* Rules to apply: default (which means a simple pattern: ".\*" )
	* Local jmxremote port: 7071 (in case someone wants to check this JVM)

## Building docker image

	docker build -t eedugon/jmx-exporter .

## Running

	docker run --rm -p "9072:9072" eedugon/jmx-exporter

Then you can visit the metrics endpoint: [http://127.0.0.1:9072/metrics]() (assuming docker is running on localhost)

Note: If you want to test jmx_exporter monitoring it's own metrics, you could set DEST_PORT to 7071, which is the jmx port of the jmx_exporter itself.

  docker run --rm -e "DEST_PORT=7071" -p "9072:9072" eedugon/jmx-exporter


## Configuration modes: Auto generation of config.xml vs static configuration

This docker allows 2 configuration modes, automatic generation of config.xml (default) or providing a static configuration file via volume mount.

Example of setting our own config:

	docker run --rm -p "9072:9072" -v "$PWD/config.yml:/opt/jmx_exporter/config/config.yml" eedugon/jmx-exporter

The configuration options are documented: [https://github.com/prometheus/jmx_exporter](https://github.com/prometheus/jmx_exporter)

### Environment variables

Additionally, the following environment variables can be defined

* SERVICE_PORT -- port to receive http /metrics requests
* DEST_HOST -- host to monitor via jmx
* DEST_PORT -- jmx port of destination host
* RULES_MODULE -- rules to apply
* JVM_LOCAL_OPTS -- options for local jvm
* JMX_LOCAL_PORT -- port for local jmxremote

## Using with Prometheus

Minimal example config:

	global:
	 scrape_interval: 10s
	 evaluation_interval: 10s
	scrape_configs:
	 - job_name: 'jmx'
	   static_configs:
	    - targets:
	      - 127.0.0.1:5556
