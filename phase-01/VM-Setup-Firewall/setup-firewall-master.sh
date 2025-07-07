#!/bin/bash

# Configurar firewall para MASTER (spark-master)

echo "========================================"
echo "CONFIGURANDO FIREWALL PARA MASTER"
echo "========================================"

# Función para imprimir mensajes
print_success() {
    echo -e "\033[32m✓ $1\033[0m"
}

print_info() {
    echo -e "\033[34mℹ $1\033[0m"
}

# Habilitar UFW si no está activo
print_info "Habilitando UFW..."
sudo ufw --force enable

# SSH (puerto 22)
print_info "Configurando SSH..."
sudo ufw allow 22/tcp
print_success "SSH (22) permitido"

# HDFS NameNode
print_info "Configurando HDFS NameNode..."
sudo ufw allow 9000/tcp  # HDFS filesystem
sudo ufw allow 9870/tcp  # NameNode Web UI
sudo ufw allow 9868/tcp  # Secondary NameNode
print_success "HDFS NameNode (9000, 9870, 9868) permitidos"

# YARN ResourceManager
print_info "Configurando YARN ResourceManager..."
sudo ufw allow 8088/tcp  # ResourceManager Web UI
sudo ufw allow 8030/tcp  # ResourceManager Scheduler
sudo ufw allow 8031/tcp  # ResourceManager Tracker
sudo ufw allow 8032/tcp  # ResourceManager Admin
sudo ufw allow 8033/tcp  # ResourceManager Web App Proxy
print_success "YARN ResourceManager (8088, 8030-8033) permitidos"

# Spark Master
print_info "Configurando Spark Master..."
sudo ufw allow 7077/tcp  # Spark Master port
sudo ufw allow 8080/tcp  # Spark Master Web UI
sudo ufw allow 4040/tcp  # Spark Application Web UI
print_success "Spark Master (7077, 8080, 4040) permitidos"

# Spark History Server
print_info "Configurando Spark History Server..."
sudo ufw allow 18080/tcp # History Server Web UI
print_success "Spark History Server (18080) permitido"

# MapReduce JobHistoryServer
print_info "Configurando MapReduce JobHistoryServer..."
sudo ufw allow 19888/tcp # JobHistory Web UI
sudo ufw allow 10020/tcp # JobHistory IPC
print_success "MapReduce JobHistoryServer (19888, 10020) permitidos"

# Rangos de puertos dinámicos para Spark
print_info "Configurando rangos dinámicos para Spark..."
sudo ufw allow 4041:4080/tcp  # Spark Application UIs
sudo ufw allow 7070:7080/tcp  # Spark services
print_success "Rangos dinámicos Spark permitidos"

# Mostrar estado final
echo ""
echo "========================================"
echo "CONFIGURACIÓN COMPLETADA - MASTER"
echo "========================================"
print_success "Firewall configurado para MASTER"
print_info "Puertos habilitados:"
echo "  - SSH: 22"
echo "  - HDFS: 9000, 9870, 9868"
echo "  - YARN: 8088, 8030-8033"
echo "  - Spark: 7077, 8080, 4040, 4041-4080"
echo "  - History: 18080"
echo "  - JobHistory: 19888, 10020"
echo ""
sudo ufw status numbered