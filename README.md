# Spark + Hadoop Cluster Setup
Configuración automatizada de cluster Spark 3.0.1 + Hadoop 3.2.1

## Requisitos
- 3 VMs Ubuntu 20.04 con IPs: 192.168.100.10-12
- Java 8, Scala 2.12.10, Hadoop 3.2.1, Spark 3.0.1 instalados
- SSH sin contraseña configurado

## Instalación Rápida

### En Master (192.168.100.10):
```bash
wget -O install.sh https://raw.githubusercontent.com/jlorenzor/spark-ml-distributed/main/install.sh
chmod +x install.sh
./install.sh master
cd cluster-setup
./scripts/format-hdfs.sh
./scripts/start-cluster.sh
```

### En Slaves (192.168.100.11-12):
```bash
wget -O install.sh https://raw.githubusercontent.com/jlorenzor/spark-ml-distributed/main/install.sh

chmod +x install.sh
./install.sh slave
```

### Verificación
```bash
cd cluster-setup
./scripts/verify-cluster.sh
```