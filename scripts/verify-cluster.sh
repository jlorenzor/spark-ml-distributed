#!/bin/bash

echo "=== VERIFICACIÓN DETALLADA DEL CLUSTER ==="

echo "1. Verificando procesos Java en Master:"
echo "Procesos esperados: NameNode, SecondaryNameNode, ResourceManager, Master"
jps
echo

echo "2. Verificando DataNodes en Slaves:"
for i in {1..2}; do
    echo "=== Verificando spark-slave$i ==="
    ssh spark-user@spark-slave$i "echo 'Conectividad: OK'; jps | grep -E '(DataNode|NodeManager|Worker)' || echo 'No se encontraron procesos Hadoop/Spark'" 2>/dev/null || echo "CONEXIÓN FALLIDA"
    echo
done

echo "3. Verificando estado detallado de HDFS:"
echo "--- Reporte de HDFS ---"
hdfs dfsadmin -report
echo
echo "--- Lista de DataNodes ---"
hdfs dfsadmin -printTopology
echo

echo "4. Verificando logs de NameNode:"
echo "Últimas 10 líneas del log de NameNode:"
tail -10 $HADOOP_HOME/logs/hadoop-spark-user-namenode-spark-master.log 2>/dev/null || echo "Log de NameNode no encontrado"
echo

echo "5. Verificando configuración de red:"
echo "Red configurada en core-site.xml:"
grep -A1 "fs.defaultFS" $HADOOP_HOME/etc/hadoop/core-site.xml
echo

echo "6. Verificando conectividad de puertos HDFS:"
nc -z spark-master 9000 && echo "Puerto 9000 (HDFS): OK" || echo "Puerto 9000 (HDFS): FAIL"
nc -z spark-master 9870 && echo "Puerto 9870 (NameNode Web): OK" || echo "Puerto 9870 (NameNode Web): FAIL"

echo
echo "7. Verificando Spark Master:"
curl -s http://spark-master:8080 > /dev/null && echo "Spark Master Web UI: OK" || echo "Spark Master Web UI: FAIL"
nc -z spark-master 7077 && echo "Puerto 7077 (Spark Master): OK" || echo "Puerto 7077 (Spark Master): FAIL"

echo
echo "8. Verificando Workers de Spark:"
for i in {1..2}; do
    nc -z spark-slave$i 7078 && echo "spark-slave$i Puerto 7078 (Worker): OK" || echo "spark-slave$i Puerto 7078 (Worker): FAIL"
done

echo
echo "9. Probando HDFS (solo si hay DataNodes):"
DATANODE_COUNT=$(hdfs dfsadmin -report 2>/dev/null | grep "Live datanodes" | awk '{print $3}' | tr -d ':')
if [ "$DATANODE_COUNT" -gt 0 ] 2>/dev/null; then
    echo "DataNodes activos: $DATANODE_COUNT"
    echo "Probando escritura en HDFS..."
    echo "Test HDFS $(date)" | hdfs dfs -put - /test-file-$(date +%s) 2>/dev/null && echo "Escritura HDFS: OK" || echo "Escritura HDFS: FAIL"
    hdfs dfs -ls / 2>/dev/null | head -5
else
    echo "❌ PROBLEMA: No hay DataNodes activos"
    echo "Ejecuta el script de diagnóstico para solucionar"
fi

echo
echo "10. Probando Spark (solo ejemplo básico):"
if pgrep -f "org.apache.spark.deploy.master.Master" > /dev/null; then
    echo "Spark Master está corriendo, probando ejemplo..."
    timeout 60 spark-submit --master local[1] --class org.apache.spark.examples.SparkPi $SPARK_HOME/examples/jars/spark-examples_2.12-3.0.1.jar 1 2>/dev/null && echo "Spark Pi (local): OK" || echo "Spark Pi (local): FAIL o TIMEOUT"
else
    echo "❌ Spark Master no está corriendo"
fi

echo
echo "=== RESUMEN ==="
echo "NameNode: $(jps | grep NameNode > /dev/null && echo "✅ OK" || echo "❌ FAIL")"
echo "DataNodes: $([ "$DATANODE_COUNT" -gt 0 ] 2>/dev/null && echo "✅ $DATANODE_COUNT activos" || echo "❌ 0 activos")"
echo "Spark Master: $(jps | grep Master > /dev/null && echo "✅ OK" || echo "❌ FAIL")"
echo "Spark Workers: $(ssh spark-user@spark-slave1 "jps | grep Worker" 2>/dev/null > /dev/null && echo "✅ OK" || echo "❌ FAIL")"

if [ "$DATANODE_COUNT" -eq 0 ] 2>/dev/null; then
    echo
    echo "🚨 ACCIÓN REQUERIDA:"
    echo "Los DataNodes no están funcionando. Ejecuta:"
    echo "  ./fix-datanodes.sh"
fi

echo
echo "=== VERIFICACIÓN COMPLETADA ==="