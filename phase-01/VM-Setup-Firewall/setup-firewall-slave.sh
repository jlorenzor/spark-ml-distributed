#!/bin/bash

# setup-firewall-slave.sh
# Configurar firewall para SLAVES (spark-slave-1, spark-slave-2)

echo "========================================"
echo "CONFIGURANDO FIREWALL PARA SLAVE"
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

# HDFS DataNode
print_info "Configurando HDFS DataNode..."
sudo ufw allow 9864/tcp  # DataNode Web UI
sudo ufw allow 9866/tcp  # DataNode Data Transfer
sudo ufw allow 9867/tcp  # DataNode Address
print_success "HDFS DataNode (9864, 9866, 9867) permitidos"

# YARN NodeManager
print_info "Configurando YARN NodeManager..."
sudo ufw allow 8042/tcp  # NodeManager Web UI
sudo ufw allow 8040/tcp  # NodeManager Localizer
sudo ufw allow 8041/tcp  # NodeManager
print_success "YARN NodeManager (8042, 8040, 8041) permitidos"

# Spark Worker
print_info "Configurando Spark Worker..."
sudo ufw allow 7078/tcp  # Spark Worker port
sudo ufw allow 8081/tcp  # Spark Worker Web UI
sudo ufw allow 4040/tcp  # Spark Application Web UI
print_success "Spark Worker (7078, 8081, 4040) permitidos"

# Rangos de puertos dinámicos para Spark
print_info "Configurando rangos dinámicos para Spark..."
sudo ufw allow 4041:4080/tcp  # Spark Application UIs
sudo ufw allow 7070:7090/tcp  # Spark services
print_success "Rangos dinámicos Spark permitidos"

# Puertos para comunicación entre nodos
print_info "Configurando comunicación entre nodos..."
sudo ufw allow 50010/tcp  # DataNode Transfer
sudo ufw allow 50020/tcp  # DataNode IPC
sudo ufw allow 50070/tcp  # NameNode HTTP
sudo ufw allow 50075/tcp  # DataNode HTTP
sudo ufw allow 50090/tcp  # Secondary NameNode HTTP
print_success "Comunicación entre nodos permitida"

# Mostrar estado final
echo ""
echo "========================================"
echo "CONFIGURACIÓN COMPLETADA - SLAVE"
echo "========================================"
print_success "Firewall configurado para SLAVE"
print_info "Puertos habilitados:"
echo "  - SSH: 22"
echo "  - HDFS DataNode: 9864, 9866, 9867"
echo "  - YARN NodeManager: 8042, 8040, 8041"
echo "  - Spark Worker: 7078, 8081, 4040, 4041-4080"
echo "  - Comunicación: 50010, 50020, 50070, 50075, 50090"
echo ""
sudo ufw status numbered