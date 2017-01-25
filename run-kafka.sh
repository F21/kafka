#!/usr/bin/env bash

CONFIG_FILE=/opt/kafka/config/server.properties

ESCAPE_SEQUENCE='s/[]\/$*.^|[]/\\&/g'

: ${CLUSTER_NAME:?"CLUSTER_NAME is required."}

CLUSTER_NAME_ESC=$(sed $ESCAPE_SEQUENCE <<< "$CLUSTER_NAME")

LOG_DIRS=${LOG_DIRS:=/var/lib/kafka/data}
LOG_DIRS_ESC=$(sed $ESCAPE_SEQUENCE <<< "$LOG_DIRS")
sed -i "s/log\.dirs=.*/log.dirs=${LOG_DIRS_ESC}/g" "$CONFIG_FILE"

[ ! -z "$DELETE_TOPIC_ENABLE" ] && echo "delete.topic.enable=$DELETE_TOPIC_ENABLE" >> $CONFIG_FILE

# Create and set the data directories correctly
IFS=',' read -ra LOG_DIRS_EXPANDED <<< "$LOG_DIRS"
for i in "${LOG_DIRS_EXPANDED[@]}"; do
    mkdir -p $i
    chown -R kafka:kafka $i
    chmod 700 $i
done

: ${ZOOKEEPER_CONNECT:?"ZOOKEEPER_CONNECT is required."}
ZOOKEEPER_CONNECT_ESC=$(sed $ESCAPE_SEQUENCE <<< "$ZOOKEEPER_CONNECT")
sed -i "s/zookeeper\.connect=.*/zookeeper.connect=${ZOOKEEPER_CONNECT_ESC}\/${CLUSTER_NAME_ESC}/g" "$CONFIG_FILE"

# Wait for zookeeper
IFS=',' read -ra ZOOKEEPER_CONNECTS <<< "$ZOOKEEPER_CONNECT"
num_zk=${#ZOOKEEPER_CONNECTS[*]}

IFS=":" read -ra REMOTE_ADDR <<< "${ZOOKEEPER_CONNECTS[$((RANDOM%num_zk))]}"

until $(nc -z -v -w5 ${REMOTE_ADDR[0]} ${REMOTE_ADDR[1]}); do
    echo "Waiting for zookeeper to be available..."
    sleep 2
done

exec su-exec kafka /opt/kafka/bin/kafka-server-start.sh $CONFIG_FILE