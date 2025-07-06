#!/bin/bash

set -e

NODE_TYPE=$1
REPO_URL="https://raw.githubusercontent.com/jlorenzor/spark-ml-distributed/main"

if [ "$NODE_TYPE" != "master" ] && [ "$NODE_TYPE" != "slave" ]; then
    echo "Uso: $0 {master|slave}"
    exit 1
fi

echo "=== CONFIGURANDO NODO $NODE_TYPE ==="

# Crear directorios
mkdir -p ~/cluster-setup/{configs,scripts}
cd ~/cluster-setup

# Descargar configuraciones
echo "Descargando configuraciones..."
wget -q $REPO_URL/configs/hadoop/core-site.xml -O configs/core-site.xml
wget -q $REPO_URL/configs/hadoop/hdfs-site.xml -O configs/hdfs-site.xml
wget -q $REPO_URL/configs/hadoop/yarn-site.xml -O configs/yarn-site.xml
wget -q $REPO_URL/configs/hadoop/workers -O configs/workers
wget -q $REPO_URL/configs/spark/spark-defaults.conf -O configs/spark-defaults.conf
wget -q $REPO_URL/configs/spark/spark-env.sh -O configs/spark-env.sh
wget -q $REPO_URL/configs/spark/slaves -O configs/slaves
wget -q $REPO_URL/configs/system/hosts -O configs/hosts

# Descargar scripts
echo "Descargando scripts..."
wget -q $REPO_URL/scripts/setup-$NODE_TYPE.sh -O scripts/setup.sh
wget -q $REPO_URL/scripts/start-cluster.sh -O scripts/start-cluster.sh
wget -q $REPO_URL/scripts/stop-cluster.sh -O scripts/stop-cluster.sh
wget -q $REPO_URL/scripts/format-hdfs.sh -O scripts/format-hdfs.sh
wget -q $REPO_URL/scripts/verify-cluster.sh -O scripts/verify-cluster.sh

# Dar permisos
chmod +x scripts/*.sh

# Ejecutar configuración específica
./scripts/setup.sh

echo "=== CONFIGURACIÓN $NODE_TYPE COMPLETADA ==="