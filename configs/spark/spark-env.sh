#!/usr/bin/env bash

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export HADOOP_HOME=/opt/hadoop
export SPARK_HOME=/opt/spark
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export YARN_CONF_DIR=$HADOOP_HOME/etc/hadoop
export SPARK_DIST_CLASSPATH=$($HADOOP_HOME/bin/hadoop classpath)

# Spark Master
export SPARK_MASTER_HOST=spark-master
export SPARK_MASTER_PORT=7077
export SPARK_MASTER_WEBUI_PORT=8080

# Spark Worker
export SPARK_WORKER_CORES=1
export SPARK_WORKER_MEMORY=1g
export SPARK_WORKER_PORT=7078
export SPARK_WORKER_WEBUI_PORT=8081

# Spark History Server
export SPARK_HISTORY_OPTS="-Dspark.history.ui.port=18080 -Dspark.history.retainedApplications=3 -Dspark.history.fs.logDirectory=hdfs://spark-master:9000/spark-logs"