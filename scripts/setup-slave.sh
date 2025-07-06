#!/bin/bash

set -e

echo "=== CONFIGURANDO SLAVE ==="

# Actualizar /etc/hosts
sudo cp configs/hosts /etc/hosts

# Crear directorios necesarios
mkdir -p ~/hadoop/{tmp,data/datanode,logs}
mkdir -p ~/spark/logs

# Configurar Hadoop
cp configs/core-site.xml $HADOOP_HOME/etc/hadoop/
cp configs/hdfs-site.xml $HADOOP_HOME/etc/hadoop/
cp configs/yarn-site.xml $HADOOP_HOME/etc/hadoop/
cp configs/workers $HADOOP_HOME/etc/hadoop/

# Configurar Spark
cp configs/spark-defaults.conf $SPARK_HOME/conf/
cp configs/spark-env.sh $SPARK_HOME/conf/
cp configs/slaves $SPARK_HOME/conf/

# Configurar JAVA_HOME en Hadoop
echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh

echo "Slave configurado correctamente"