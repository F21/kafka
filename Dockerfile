FROM openjdk:8-jre-alpine
MAINTAINER Francis Chuang <francis.chuang@boostport.com>

ENV KAFKA_VER 2.1.1
ENV SCALA_VER 2.12

RUN apk --no-cache --update add bash ca-certificates gnupg openssl su-exec tar \
 && update-ca-certificates \
\
# Set up directories
 && mkdir -p /opt/kafka \
\
# Download Kafka
 && wget -O /tmp/KEYS https://kafka.apache.org/KEYS \
 && gpg --import /tmp/KEYS \
 && wget -q -O /tmp/kafka.tar.gz http://apache.mirror.serversaustralia.com.au/kafka/$KAFKA_VER/kafka_$SCALA_VER-$KAFKA_VER.tgz \
 && wget -O /tmp/kafka.asc https://dist.apache.org/repos/dist/release/kafka/$KAFKA_VER/kafka_$SCALA_VER-$KAFKA_VER.tgz.asc \
 && gpg --verify /tmp/kafka.asc /tmp/kafka.tar.gz \
 && tar -xzf /tmp/kafka.tar.gz -C /opt/kafka  --strip-components 1 \
\
# Set up permissions
 && addgroup -S kafka \
 && adduser -h /opt/kafka -G kafka -S -D -H -s /bin/false -g kafka kafka \
 && chown -R kafka:kafka /opt/kafka \
\
# Clean up
 && apk del gnupg openssl tar \
 && rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

ADD run-kafka.sh /run-kafka.sh

VOLUME ["/var/lib/kafka/data"]

EXPOSE 9092

CMD ["/run-kafka.sh"]