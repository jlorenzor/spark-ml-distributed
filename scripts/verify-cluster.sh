#!/bin/bash

echo "=== VERIFICACIÓN DEL CLUSTER ==="

echo "1. Verificando procesos Java:"
jps

echo
echo "2. Verificando estado de HDFS:"
hdfs dfsadmin -report

echo
echo "3. Verificando conectividad de nodos:"
for i in {1..5}; do
    echo -n "spark-slave$i: "
    ssh spark-user@spark-slave$i "echo 'OK'" 2>/dev/null || echo "FAIL"
done

echo
echo "4. Verificando Spark Master:"
curl -s http://spark-master:8080 > /dev/null && echo "Spark Master: OK" || echo "Spark Master: FAIL"

echo
echo "5. Probando HDFS:"
echo "Test HDFS" | hdfs dfs -put - /test-file
hdfs dfs -cat /test-file
hdfs dfs -rm /test-file

echo
echo "6. Probando Spark:"
spark-submit --class org.apache.spark.examples.SparkPi $SPARK_HOME/examples/jars/spark-examples_2.12-3.0.1.jar 2

echo "=== VERIFICACIÓN COMPLETADA ==="