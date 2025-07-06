#!/bin/bash

echo "=== DETENIENDO CLUSTER ==="

# Solo ejecutar en master
if [ "$(hostname)" != "spark-master" ]; then
    echo "Este script debe ejecutarse solo en el master"
    exit 1
fi

echo "Deteniendo Spark History Server..."
$SPARK_HOME/sbin/stop-history-server.sh

echo "Deteniendo Spark..."
$SPARK_HOME/sbin/stop-all.sh

echo "Deteniendo YARN..."
$HADOOP_HOME/sbin/stop-yarn.sh

echo "Deteniendo HDFS..."
$HADOOP_HOME/sbin/stop-dfs.sh

echo "=== CLUSTER DETENIDO ==="