FROM f21global/java:8
MAINTAINER Francis Chuang <francis.chuang@boostport.com>

ENV KAFKA_VER 0.10.0.0
ENV SCALA_VER 2.11

RUN groupadd kafka \
    && adduser --system --home /opt/kafka --disabled-login --ingroup kafka kafka  \
    && apt-get update \
    && apt-get install -y wget ca-certificates wget \
    && wget -q -O - http://apache.uberglobalmirror.com/kafka/$KAFKA_VER/kafka_$SCALA_VER-$KAFKA_VER.tgz | tar -xzf - -C /opt/kafka  --strip-components 1 \
    && chown -R kafka:kafka /opt/kafka

RUN arch="$(dpkg --print-architecture)" \
	&& set -x \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.7/gosu-$arch" \
	&& chmod +x /usr/local/bin/gosu

ADD run-kafka.sh /run-kafka.sh

VOLUME ["/var/lib/kafka/data"]

EXPOSE 9092

CMD ["/run-kafka.sh"]