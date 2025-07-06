# FASE 2: Configuración Cluster Hadoop HDFS + Spark

## **PASO 1: CONFIGURACIÓN DE HADOOP HDFS**

### 1.1 Configurar Hadoop en el Master (spark-master)

```bash
# Conectar al master
cd $HADOOP_HOME/etc/hadoop

# Configurar JAVA_HOME en hadoop-env.sh
sudo nano hadoop-env.sh
```

**En hadoop-env.sh, agregar/modificar:**
```bash
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export HADOOP_LOG_DIR=$HADOOP_HOME/logs
```

### 1.2 Configurar core-site.xml
```bash
sudo nano core-site.xml
```

**Contenido de core-site.xml:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://spark-master:9000</value>
    </property>
    <property>
        <name>hadoop.tmp.dir</name>
        <value>/home/spark-user/hadoop/tmp</value>
    </property>
    <property>
        <name>hadoop.http.staticuser.user</name>
        <value>spark-user</value>
    </property>
</configuration>
```

### 1.3 Configurar hdfs-site.xml
```bash
sudo nano hdfs-site.xml
```

**Contenido de hdfs-site.xml:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>2</value>
    </property>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>/home/spark-user/hadoop/data/namenode</value>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>/home/spark-user/hadoop/data/datanode</value>
    </property>
    <property>
        <name>dfs.namenode.http-address</name>
        <value>spark-master:9870</value>
    </property>
    <property>
        <name>dfs.namenode.secondary.http-address</name>
        <value>spark-master:9868</value>
    </property>
    <property>
        <name>dfs.datanode.http-address</name>
        <value>0.0.0.0:9864</value>
    </property>
</configuration>
```

### 1.4 Configurar yarn-site.xml
```bash
sudo nano yarn-site.xml
```

**Contenido de yarn-site.xml:**
```xml
<?xml version="1.0"?>
<configuration>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>spark-master</value>
    </property>
    <property>
        <name>yarn.nodemanager.resource.memory-mb</name>
        <value>1536</value>
    </property>
    <property>
        <name>yarn.nodemanager.resource.cpu-vcores</name>
        <value>1</value>
    </property>
</configuration>
```

### 1.5 Configurar mapred-site.xml
```bash
sudo nano mapred-site.xml
```

**Contenido de mapred-site.xml:**
```xml
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
    <property>
        <name>mapreduce.application.classpath</name>
        <value>$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/*:$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/lib/*</value>
    </property>
</configuration>
```

### 1.6 Configurar workers (antes slaves)
```bash
sudo nano workers
```

**Contenido de workers:**
```
spark-slave1
spark-slave2
spark-slave3
spark-slave4
spark-slave5
```

### 1.7 Crear directorios necesarios
```bash
# Crear directorios en master
mkdir -p ~/hadoop/tmp
mkdir -p ~/hadoop/data/namenode
mkdir -p ~/hadoop/data/datanode
mkdir -p ~/hadoop/logs

# Dar permisos
chmod 755 ~/hadoop/data/namenode
chmod 755 ~/hadoop/data/datanode
```

## **PASO 2: COPIAR CONFIGURACIÓN A TODOS LOS SLAVES**

### 2.1 Script para copiar configuración
```bash
# En master, crear script de distribución
nano ~/distribute_config.sh
```

**Contenido del script:**
```bash
#!/bin/bash
echo "Distribuyendo configuración de Hadoop a todos los slaves..."

for i in {1..5}; do
    echo "Copiando configuración a spark-slave$i..."
    
    # Copiar configuraciones de Hadoop
    scp $HADOOP_HOME/etc/hadoop/core-site.xml spark-user@spark-slave$i:$HADOOP_HOME/etc/hadoop/
    scp $HADOOP_HOME/etc/hadoop/hdfs-site.xml spark-user@spark-slave$i:$HADOOP_HOME/etc/hadoop/
    scp $HADOOP_HOME/etc/hadoop/yarn-site.xml spark-user@spark-slave$i:$HADOOP_HOME/etc/hadoop/
    scp $HADOOP_HOME/etc/hadoop/mapred-site.xml spark-user@spark-slave$i:$HADOOP_HOME/etc/hadoop/
    scp $HADOOP_HOME/etc/hadoop/workers spark-user@spark-slave$i:$HADOOP_HOME/etc/hadoop/
    scp $HADOOP_HOME/etc/hadoop/hadoop-env.sh spark-user@spark-slave$i:$HADOOP_HOME/etc/hadoop/
    
    # Crear directorios en slaves
    ssh spark-user@spark-slave$i "mkdir -p ~/hadoop/tmp ~/hadoop/data/namenode ~/hadoop/data/datanode ~/hadoop/logs"
    ssh spark-user@spark-slave$i "chmod 755 ~/hadoop/data/namenode ~/hadoop/data/datanode"
    
    echo "spark-slave$i configurado ✓"
done

echo "Configuración distribuida a todos los nodos!"
```

```bash
# Ejecutar script
chmod +x ~/distribute_config.sh
./distribute_config.sh
```

## **PASO 3: CONFIGURACIÓN DE SPARK**

### 3.1 Configurar Spark en Master
```bash
cd $SPARK_HOME/conf

# Copiar plantillas
cp spark-defaults.conf.template spark-defaults.conf
cp spark-env.sh.template spark-env.sh
cp workers.template workers
```

### 3.2 Configurar spark-env.sh
```bash
nano spark-env.sh
```

**Agregar al final de spark-env.sh:**
```bash
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export HADOOP_HOME=/opt/hadoop
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export SPARK_MASTER_HOST=spark-master
export SPARK_MASTER_PORT=7077
export SPARK_MASTER_WEBUI_PORT=8080
export SPARK_WORKER_CORES=1
export SPARK_WORKER_MEMORY=1g
export SPARK_WORKER_PORT=7078
export SPARK_WORKER_WEBUI_PORT=8081
export SPARK_LOG_DIR=$SPARK_HOME/logs
export SPARK_PID_DIR=$SPARK_HOME/pids
```

### 3.3 Configurar spark-defaults.conf
```bash
nano spark-defaults.conf
```

**Contenido de spark-defaults.conf:**
```
spark.master                     spark://spark-master:7077
spark.eventLog.enabled           true
spark.eventLog.dir               hdfs://spark-master:9000/spark-logs
spark.serializer                 org.apache.spark.serializer.KryoSerializer
spark.sql.adaptive.enabled       true
spark.sql.adaptive.coalescePartitions.enabled true
spark.default.parallelism        10
spark.sql.adaptive.advisoryPartitionSizeInBytes 64MB
```

### 3.4 Configurar workers de Spark
```bash
nano workers
```

**Contenido de workers:**
```
spark-slave1
spark-slave2
spark-slave3
spark-slave4
spark-slave5
```

### 3.5 Crear directorios de Spark
```bash
mkdir -p $SPARK_HOME/logs
mkdir -p $SPARK_HOME/pids
```

## **PASO 4: DISTRIBUIR CONFIGURACIÓN DE SPARK**

### 4.1 Script para distribuir Spark
```bash
nano ~/distribute_spark_config.sh
```

**Contenido del script:**
```bash
#!/bin/bash
echo "Distribuyendo configuración de Spark a todos los slaves..."

for i in {1..5}; do
    echo "Copiando configuración de Spark a spark-slave$i..."
    
    # Copiar configuraciones de Spark
    scp $SPARK_HOME/conf/spark-env.sh spark-user@spark-slave$i:$SPARK_HOME/conf/
    scp $SPARK_HOME/conf/spark-defaults.conf spark-user@spark-slave$i:$SPARK_HOME/conf/
    scp $SPARK_HOME/conf/workers spark-user@spark-slave$i:$SPARK_HOME/conf/
    
    # Crear directorios en slaves
    ssh spark-user@spark-slave$i "mkdir -p $SPARK_HOME/logs $SPARK_HOME/pids"
    
    echo "spark-slave$i configurado para Spark ✓"
done

echo "Configuración de Spark distribuida!"
```

```bash
chmod +x ~/distribute_spark_config.sh
./distribute_spark_config.sh
```

## **PASO 5: FORMATEAR HDFS Y INICIAR CLUSTER**

### 5.1 Formatear NameNode
```bash
# En master, formatear HDFS (SOLO LA PRIMERA VEZ)
$HADOOP_HOME/bin/hdfs namenode -format -force
```

### 5.2 Iniciar HDFS
```bash
# Iniciar DFS (NameNode y DataNodes)
$HADOOP_HOME/sbin/start-dfs.sh

# Verificar que HDFS esté funcionando
$HADOOP_HOME/bin/hdfs dfsadmin -report
```

### 5.3 Crear directorio para logs de Spark en HDFS
```bash
# Crear directorio en HDFS para logs de Spark
$HADOOP_HOME/bin/hdfs dfs -mkdir -p /spark-logs
$HADOOP_HOME/bin/hdfs dfs -chmod 777 /spark-logs
```

### 5.4 Iniciar Spark Cluster
```bash
# Iniciar Spark Master y Workers
$SPARK_HOME/sbin/start-all.sh

# Verificar procesos
jps
```

## **PASO 6: VERIFICACIÓN DEL CLUSTER**

### 6.1 Verificar procesos Java
```bash
# En master debería aparecer:
# - NameNode
# - SecondaryNameNode  
# - ResourceManager
# - Master (Spark)

# En cada slave debería aparecer:
# - DataNode
# - NodeManager
# - Worker (Spark)

jps
```

### 6.2 Verificar interfaces web
```bash
echo "Interfaces web disponibles:"
echo "HDFS NameNode: http://192.168.100.10:9870"
echo "Spark Master: http://192.168.100.10:8080"
echo "YARN ResourceManager: http://192.168.100.10:8088"
```

### 6.3 Script de verificación completa
```bash
nano ~/verify_full_cluster.sh
```

**Contenido del script:**
```bash
#!/bin/bash
echo "=== VERIFICACIÓN COMPLETA DEL CLUSTER ==="
echo

echo "=== PROCESOS EN MASTER ==="
echo "Procesos Java en $(hostname):"
jps
echo

echo "=== VERIFICACIÓN HDFS ==="
echo "Estado de HDFS:"
$HADOOP_HOME/bin/hdfs dfsadmin -report | head -20
echo

echo "=== VERIFICACIÓN SPARK ==="
echo "Workers de Spark registrados:"
curl -s http://spark-master:8080/ | grep -o "spark-slave[0-9]" | sort | uniq
echo

echo "=== VERIFICACIÓN DE CONECTIVIDAD ==="
for i in {1..5}; do
    echo -n "spark-slave$i: "
    ssh spark-user@spark-slave$i "jps | grep -E 'DataNode|Worker'" | wc -l | xargs echo "procesos activos"
done

echo
echo "=== PRUEBA BÁSICA HDFS ==="
echo "Creando archivo de prueba..."
echo "Hola cluster HDFS!" > /tmp/test.txt
$HADOOP_HOME/bin/hdfs dfs -put /tmp/test.txt /test.txt
echo "Leyendo archivo desde HDFS:"
$HADOOP_HOME/bin/hdfs dfs -cat /test.txt
$HADOOP_HOME/bin/hdfs dfs -rm /test.txt
rm /tmp/test.txt

echo
echo "=== PRUEBA BÁSICA SPARK ==="
echo "Ejecutando prueba de Spark..."
$SPARK_HOME/bin/spark-shell --master spark://spark-master:7077 --executor-memory 512m --total-executor-cores 2 << 'EOF'
val data = sc.parallelize(1 to 100)
val result = data.map(x => x * 2).reduce(_ + _)
println(s"Resultado de la prueba: $result")
:quit
EOF
```

```bash
chmod +x ~/verify_full_cluster.sh
./verify_full_cluster.sh
```

## **PASO 7: CAPTURAS DE PANTALLA REQUERIDAS**

### 7.1 Capturas obligatorias para documentación:
1. **Salida del comando `jps` en master**
2. **Salida del comando `jps` en un slave**
3. **Interfaz web de HDFS** (puerto 9870)
4. **Interfaz web de Spark Master** (puerto 8080)
5. **Reporte de HDFS** (`hdfs dfsadmin -report`)
6. **Script de verificación ejecutándose**
7. **Prueba básica de Spark funcionando**

### 7.2 Comandos útiles para capturas:
```bash
# Estado detallado de HDFS
$HADOOP_HOME/bin/hdfs dfsadmin -report

# Lista de workers en Spark
$SPARK_HOME/sbin/slaves.sh jps

# Estado de procesos en todos los nodos
for i in {1..5}; do echo "=== spark-slave$i ==="; ssh spark-user@spark-slave$i jps; done
```

## **PASO 8: SCRIPTS DE CONTROL**

### 8.1 Script para iniciar cluster
```bash
nano ~/start_cluster.sh
```

**Contenido:**
```bash
#!/bin/bash
echo "Iniciando cluster Hadoop + Spark..."
$HADOOP_HOME/sbin/start-dfs.sh
$HADOOP_HOME/sbin/start-yarn.sh
$SPARK_HOME/sbin/start-all.sh
echo "Cluster iniciado! Verificando..."
sleep 5
jps
```

### 8.2 Script para detener cluster
```bash
nano ~/stop_cluster.sh
```

**Contenido:**
```bash
#!/bin/bash
echo "Deteniendo cluster Hadoop + Spark..."
$SPARK_HOME/sbin/stop-all.sh
$HADOOP_HOME/sbin/stop-yarn.sh
$HADOOP_HOME/sbin/stop-dfs.sh
echo "Cluster detenido!"
```

```bash
chmod +x ~/start_cluster.sh ~/stop_cluster.sh
```

---

## **CHECKLIST FASE 2 COMPLETADA**

- [ ] Configuraciones de Hadoop creadas y distribuidas
- [ ] Configuraciones de Spark creadas y distribuidas
- [ ] HDFS formateado e iniciado
- [ ] Cluster Spark iniciado
- [ ] Interfaces web accesibles
- [ ] Pruebas básicas funcionando
- [ ] Scripts de verificación ejecutándose
- [ ] Capturas de pantalla tomadas
- [ ] Scripts de control creados

**Próximo paso:** FASE 3 - Selección y preparación de dataset