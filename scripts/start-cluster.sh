#!/bin/bash

set -e

echo "=== INICIANDO CLUSTER ==="

# Solo ejecutar en master
if [ "$(hostname)" != "spark-master" ]; then
    echo "Este script debe ejecutarse solo en el master"
    exit 1
fi

echo "Iniciando HDFS..."
$HADOOP_HOME/sbin/start-dfs.sh

echo "Verificando estado de HDFS..."
$HADOOP_HOME/bin/hdfs dfsadmin -report

echo "Esperando que HDFS esté listo..."
sleep 10

echo "Creando directorios en HDFS para Spark..."
if [ -f ~/create-spark-dirs.sh ]; then
    ~/create-spark-dirs.sh
    rm ~/create-spark-dirs.sh
fi

echo "Iniciando YARN..."
$HADOOP_HOME/sbin/start-yarn.sh

echo "Iniciando Spark..."
$SPARK_HOME/sbin/start-all.sh

echo "Iniciando Spark History Server..."
$SPARK_HOME/sbin/start-history-server.sh

echo "=== CLUSTER INICIADO ==="
echo "Interfaces web disponibles:"
echo "- HDFS NameNode: http://192.168.100.10:9870"
echo "- YARN ResourceManager: http://192.168.100.10:8088"
echo "- Spark Master: http://192.168.100.10:8080"
echo "- Spark History: http://192.168.100.10:18080"