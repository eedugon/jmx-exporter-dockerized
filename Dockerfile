FROM anapsix/alpine-java:8
LABEL maintainer "eedugon <edu.gherran@gmail.com>"

RUN apk update && apk upgrade && apk --update add curl && rm -rf /tmp/* /var/cache/apk/*

ENV VERSION 0.9
ENV JAR jmx_prometheus_httpserver-$VERSION-jar-with-dependencies.jar

RUN curl --insecure -L https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 -o usr/local/bin/dumb-init && chmod +x /usr/local/bin/dumb-init

RUN mkdir -p /opt/jmx_exporter/config
RUN mkdir -p /opt/jmx_exporter/rules

RUN curl -L https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_httpserver/$VERSION/$JAR -o /opt/jmx_exporter/$JAR

COPY prepare_config.sh /opt/jmx_exporter/config/
COPY config.yml.template /opt/jmx_exporter/config/
COPY start.sh /opt/jmx_exporter/
RUN chmod +x /opt/jmx_exporter/prepare_config.sh

CMD ["usr/local/bin/dumb-init", "/opt/jmx_exporter/start.sh"]
