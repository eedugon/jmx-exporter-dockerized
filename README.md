# jmx-exporter in a Docker with extra features

This project consists of a dockerised JMX Exporter image, based on the original project created by sscaling (sscaling/jmx_exporter), using alpine-java, dumb-init and fetching the official released version of jmx_exporter from the [maven central repository](https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_httpserver/)

This version of the docker includes the following extra features:

  * Automatic Configuration: config.xml creation based on environment variables and templates.
  * Static Configuration: if config.xml is mapped into /opt/jmx_exporter/config/, then environment variables won't be considered, and the provided configuration used.
  * Flexible rules: via environment variable we can select the rules to apply to the configuration (only if Automatic Configuration feature is used and only 1 rules file allowed).
  * check_init : With check init enabled (by default is disabled), jmx_exporter will wait until the remote jmx port is available (this feature uses nagios check_jmx plugin).

Environment variables supported to get different behavior/configuration:

  * SERVICE_PORT -- port to receive http /metrics requests
  * DEST_HOST -- host to monitor via jmx
  * DEST_PORT -- jmx port of destination host
  * RULES_MODULE -- rules to apply
  * JVM_LOCAL_OPTS -- options for local jvm
  * JMX_LOCAL_PORT -- port for local jmxremote
  * CHECK_INIT -- (true | false) - enable/disable check_init feature
  * CHECK_INIT_ACTION -- (exit | continue) -- What to do in case of failing checks
  * CHECK_INIT_MAX_DELAY --  Maximum time to spend checking remote JVM
  * CHECK_INIT_INTERVAL -- interval between attempts

Supported modules in current version (only one can be selected):
  * default (this will translate all mbeans to metrics)
  * kafka-0-2-8

The objectives of implementing these features are:

  * Being able to use the same docker image of jmx_exporter for different scenarios, as the configuration can be built from environment variables.
  * In a Kubernetes environment, run jmx_exporter docker as an extra container (sidecar) in the pod to monitor (in this case DEST_HOST should be localhost).
  * In a Kubernetes environment, run jmx_exporter docker in a dedicated pod, in order to monitor another pod (in this case DEST_HOST should be the name of a k8s service pointing to the pod).

## Default Settings

If no environment variables or volumes are provided to the image, the exporter will have the following default behavior:

  * HTTP listening port: 9072
  * Remote JVM to connect to: localhost: 7072
	* Rules to apply: default (which means a simple pattern: ".\*" )
	* Local jmxremote port: 7071 (in case someone wants to check this JVM)
  * CHECK_INIT module will be disabled by default.

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

## CHECK_INIT considerations

I still need to check if we can use nagios check_jmx plugin inside this project. Anyway, it can be removed from the code easily:
  * Remove from start.sh the block of CHECK_INIT feature plus all CHECK_INIT variables definition.
  * Remove from Dockerfile the copy of resources/check_jmx to the docker.
