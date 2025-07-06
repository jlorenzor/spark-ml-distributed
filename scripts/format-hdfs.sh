#!/bin/bash

set -e

echo "=== FORMATEANDO HDFS ==="

# Solo ejecutar en master
if [ "$(hostname)" != "spark-master" ]; then
    echo "Este script debe ejecutarse solo en el master"
    exit 1
fi

# Formatear NameNode
$HADOOP_HOME/bin/hdfs namenode -format -force

echo "HDFS formateado correctamente"
echo "Ahora puedes ejecutar ./scripts/start-cluster.sh"