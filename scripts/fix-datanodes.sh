#!/bin/bash

echo "=== DIAGNÓSTICO Y REPARACIÓN DE DATANODES ==="

# Solo ejecutar en master
if [ "$(hostname)" != "spark-master" ]; then
    echo "❌ Este script debe ejecutarse solo en el master (spark-master)"
    exit 1
fi

echo "1. Verificando estado actual..."
echo "Procesos en master:"
jps
echo

echo "2. Verificando DataNodes en slaves..."
for i in {1..2}; do
    echo "--- spark-slave$i ---"
    ssh spark-user@spark-slave$i "hostname; jps | grep DataNode || echo 'DataNode NO encontrado'" 2>/dev/null || echo "❌ No se puede conectar"
done
echo

echo "3. Verificando logs de DataNodes..."
for i in {1..2}; do
    echo "--- Logs de spark-slave$i ---"
    ssh spark-user@spark-slave$i "ls -la $HADOOP_HOME/logs/*datanode* 2>/dev/null | tail -2 || echo 'No hay logs de DataNode'" 2>/dev/null
    echo "Últimas líneas del log:"
    ssh spark-user@spark-slave$i "tail -5 $HADOOP_HOME/logs/hadoop-spark-user-datanode-*.log 2>/dev/null || echo 'Log no accesible'" 2>/dev/null
    echo
done

echo "4. Verificando configuración de red..."
echo "Verificando resolución de nombres:"
for node in spark-master spark-slave1 spark-slave2; do
    ping -c 1 $node > /dev/null 2>&1 && echo "$node: ✅ OK" || echo "$node: ❌ FAIL"
done
echo

echo "5. Verificando permisos de directorios..."
for i in {1..2}; do
    echo "--- Permisos en spark-slave$i ---"
    ssh spark-user@spark-slave$i "ls -la ~/hadoop/data/ 2>/dev/null || echo 'Directorio no existe'" 2>/dev/null
done
echo

echo "6. INTENTANDO REPARAR..."

# Detener cluster completo
echo "Deteniendo cluster..."
$HADOOP_HOME/sbin/stop-all.sh 2>/dev/null
$SPARK_HOME/sbin/stop-all.sh 2>/dev/null
sleep 5

# Limpiar logs antiguos
echo "Limpiando logs antiguos..."
rm -rf $HADOOP_HOME/logs/*
for i in {1..2}; do
    ssh spark-user@spark-slave$i "rm -rf $HADOOP_HOME/logs/*" 2>/dev/null
done

# Recrear directorios de datos
echo "Recreando directorios de datos..."
rm -rf ~/hadoop/data/*
mkdir -p ~/hadoop/data/namenode
for i in {1..2}; do
    ssh spark-user@spark-slave$i "rm -rf ~/hadoop/data/*; mkdir -p ~/hadoop/data/datanode" 2>/dev/null
done

# Re-formatear NameNode
echo "Re-formateando HDFS..."
$HADOOP_HOME/bin/hdfs namenode -format -force -clusterId myCluster

echo "7. Verificando configuración de slaves..."
echo "Contenido de workers:"
cat $HADOOP_HOME/etc/hadoop/workers
echo

echo "Verificando que los slaves tengan la configuración correcta..."
for i in {1..2}; do
    echo "--- Verificando spark-slave$i ---"
    ssh spark-user@spark-slave$i "cat $HADOOP_HOME/etc/hadoop/core-site.xml | grep spark-master" 2>/dev/null && echo "Configuración OK" || echo "❌ Configuración incorrecta"
done

echo "8. Reiniciando cluster paso a paso..."

# Iniciar NameNode
echo "Iniciando NameNode..."
$HADOOP_HOME/bin/hdfs --daemon start namenode
sleep 10

# Verificar NameNode
if jps | grep NameNode > /dev/null; then
    echo "✅ NameNode iniciado correctamente"
else
    echo "❌ NameNode falló al iniciar"
    echo "Verificando log:"
    tail -10 $HADOOP_HOME/logs/hadoop-spark-user-namenode-*.log
    exit 1
fi

# Iniciar DataNodes manualmente
echo "Iniciando DataNodes manualmente..."
for i in {1..2}; do
    echo "Iniciando DataNode en spark-slave$i..."
    ssh spark-user@spark-slave$i "$HADOOP_HOME/bin/hdfs --daemon start datanode" 2>/dev/null
    sleep 5
done

# Verificar DataNodes
echo "Verificando DataNodes..."
sleep 10
for i in {1..2}; do
    ssh spark-user@spark-slave$i "jps | grep DataNode" 2>/dev/null && echo "spark-slave$i DataNode: ✅ OK" || echo "spark-slave$i DataNode: ❌ FAIL"
done

# Iniciar ResourceManager y NodeManagers
echo "Iniciando YARN..."
$HADOOP_HOME/sbin/start-yarn.sh

# Crear directorios de Spark en HDFS
echo "Creando directorios de Spark en HDFS..."
sleep 5
hdfs dfs -mkdir -p /spark-logs 2>/dev/null
hdfs dfs -mkdir -p /spark-warehouse 2>/dev/null
hdfs dfs -chmod 777 /spark-logs 2>/dev/null
hdfs dfs -chmod 777 /spark-warehouse 2>/dev/null

# Iniciar Spark
echo "Iniciando Spark..."
$SPARK_HOME/sbin/start-all.sh

echo "9. VERIFICACIÓN FINAL..."
sleep 10

echo "Estado de HDFS:"
hdfs dfsadmin -report | head -20

echo
echo "Procesos Java en master:"
jps

echo
echo "Procesos en slaves:"
for i in {1..2}; do
    echo "spark-slave$i:"
    ssh spark-user@spark-slave$i "jps" 2>/dev/null
done

echo
echo "=== PRUEBA FINAL DE HDFS ==="
DATANODE_COUNT=$(hdfs dfsadmin -report 2>/dev/null | grep "Live datanodes" | awk '{print $3}' | tr -d ':')
if [ "$DATANODE_COUNT" -gt 0 ] 2>/dev/null; then
    echo "✅ DataNodes activos: $DATANODE_COUNT"
    echo "Probando HDFS..."
    echo "Test reparación $(date)" | hdfs dfs -put - /test-repair
    hdfs dfs -cat /test-repair
    hdfs dfs -rm /test-repair
    echo "✅ HDFS funcionando correctamente"
else
    echo "❌ Aún hay problemas con los DataNodes"
    echo "Revisa los logs manualmente:"
    echo "  tail -20 $HADOOP_HOME/logs/hadoop-spark-user-namenode-*.log"
    for i in {1..2}; do
        echo "  ssh spark-slave$i 'tail -20 $HADOOP_HOME/logs/hadoop-spark-user-datanode-*.log'"
    done
fi

echo
echo "=== REPARACIÓN COMPLETADA ==="
echo "Si aún hay problemas, verifica:"
echo "1. Conectividad de red entre nodos"
echo "2. Resolución de nombres DNS"
echo "3. Configuración de firewall"
echo "4. Logs detallados en $HADOOP_HOME/logs/"