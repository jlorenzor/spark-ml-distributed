# FASE 1: Configuración VirtualBox - 6 Nodos Spark+Hadoop

## **CONFIGURACIÓN RECOMENDADA DE HARDWARE**

**Para tu máquina (24GB RAM, 16 hilos):**
- **Master**: 3GB RAM, 2 CPUs (más recursos para NameNode y Spark Master)
- **Slaves (5 nodos)**: 2GB RAM, 1 CPU cada uno
- **Total**: 13GB RAM, 7 CPUs → Deja 11GB para tu sistema host

## **PASO 1: DESCARGA E INSTALACIÓN INICIAL**

### 1.1 Descargar VirtualBox
```bash
# Descargar VirtualBox desde: https://www.virtualbox.org/
# Instalar VirtualBox + Extension Pack
```

### 1.2 Descargar Ubuntu Server
```bash
# Descargar Ubuntu Server 20.04 LTS (más ligero que Desktop)
# URL: https://ubuntu.com/download/server
# Archivo: ubuntu-20.04.6-live-server-amd64.iso
```

## **PASO 2: CREAR LA MÁQUINA VIRTUAL BASE**
### 2.1: Crear Red NAT
1. **Abrir VirtualBox**
2. Ir a **"Archivo"** → **"Administrador de red"**
3. **Pestaña Redes NAT**
4. Crear nueva red NAT:
   - **Nombre**: `spark-network`
   - **CIDR**: `10.0.2.0/24`
   - **Habilitar DHCP**: NO
   - **Habilitar IPv6**: NO

### 2.2: Configurar Red Interna
1. Ir a **"Archivo"** → **"Administrador de red"**
2. **Pestaña Redes solo anfitrión**
3. Crear nueva red:
   - **IPv4**: `192.168.56.1` (o cualquier IP libre en la red)
   - **Máscara**: `255.255.255.0`
   - **Sin DHCP**
   - **Habilitar IPv6**: NO

### 2.3 Crear VM Master (spark-master)
1. **Abrir VirtualBox** → Clic en "Nueva"
2. **Configuración básica:**
   - **Nombre**: `spark-master`
   - **Tipo**: Linux
   - **Versión**: Ubuntu (64-bit)
   - **Memoria**: 3072 MB (3GB)
   - **Disco duro**: Crear disco virtual ahora

3. **Configuración de disco:**
   - **Tipo**: VDI (VirtualBox Disk Image)
   - **Almacenamiento**: Reservado dinámicamente
   - **Tamaño**: 25 GB

4. **Configurar VM antes de instalar:**
   - Clic derecho en `spark-master` → **Configuración**
   - **Sistema** → **Procesador**: 2 CPUs
   - **Red** → **Adaptador 1**: NAT
   - **Red** → **Adaptador 2**: Adaptador sólo anfitrión interna
   - **Almacenamiento** → Seleccionar disco óptico → Elegir ISO de Ubuntu

### 2.4 Crear VM Instalar Ubuntu en Master
1. **Iniciar VM** spark-master
2. **Instalación de Ubuntu:**
   - Idioma: English
   - Keyboard: Spanish (o el que prefieras)
   - Network: Configurar más tarde
   - Storage: Use entire disk
   - Profile setup:
     - **Name**: spark-user
     - **Username**: spark-user
     - **Password**: spark123 (o el que prefieras)
   - SSH: **Instalar OpenSSH server** ✓
   - Featured snaps: No seleccionar ninguno

3. **Después de la instalación:**
   - Reiniciar VM
   - Remover ISO del almacenamiento óptico

## **PASO 3: CONFIGURACIÓN DE RED Y SSH**

### 3.1 Configurar Red en Master
```bash
# Conectar a la VM master
# Usuario: spark-user, Password: spark123

# Instalar herramientas necesarias
sudo apt install -y net-tools vim curl wget htop

# Configurar IP estática
sudo vim /etc/netplan/00-installer-config.yaml
```

**Contenido del archivo netplan:**
```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: true
    enp0s8:
      addresses: [192.168.100.10/24]
      dhcp4: false
```

```bash
# Aplicar configuración de red
sudo netplan apply

# Verificar IP
ip addr show
```

### 3.2 Configurar SSH y Hosts
```bash
# Generar clave SSH
ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N ""

# Configurar archivo hosts
sudo vim /etc/hosts
```

**Contenido de /etc/hosts:**
```
127.0.0.1 localhost
192.168.100.10 spark-master
192.168.100.11 spark-slave1
192.168.100.12 spark-slave2
```

## **PASO 4: INSTALACIÓN DE DEPENDENCIAS**

### 4.1 Instalar Java 8
```bash
# Instalar OpenJDK 8
sudo apt install -y openjdk-8-jdk
```

### 4.2 Instalar Scala 2.12.10
```bash
# Crear directorio para herramientas
sudo mkdir -p /opt/scala

# Descargar Scala 2.12.10
cd /tmp
wget https://downloads.lightbend.com/scala/2.12.10/scala-2.12.10.tgz

# Extraer e instalar
sudo tar -xzf scala-2.12.10.tgz -C /opt/scala --strip-components=1
```

### 4.3 Instalar Hadoop 3.2.1 (compatible con Spark 3.0.1)
```bash
# Crear directorio para Hadoop
sudo mkdir -p /opt/hadoop

# Descargar Hadoop 3.2.1
cd /tmp
wget https://archive.apache.org/dist/hadoop/common/hadoop-3.2.1/hadoop-3.2.1.tar.gz

# Extraer e instalar
sudo tar -xzf hadoop-3.2.1.tar.gz -C /opt/hadoop --strip-components=1

# Cambiar permisos
sudo chown -R spark-user:spark-user /opt/hadoop
```

### 4.4 Instalar Spark 3.0.1sudo n
```bash
# Crear directorio para Spark
sudo mkdir -p /opt/spark

# Descargar Spark 3.0.1 precompilado para Hadoop 3.2
cd /tmp
wget https://archive.apache.org/dist/spark/spark-3.0.1/spark-3.0.1-bin-hadoop3.2.tgz

# Extraer e instalar
sudo tar -xzf spark-3.0.1-bin-hadoop3.2.tgz -C /opt/spark --strip-components=1

# Cambiar permisos
sudo chown -R spark-user:spark-user /opt/spark
```

### 4.5 Configurar variables de entorno
```bash
echo 'export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64' >> ~/.bashrc
echo 'export SCALA_HOME=/opt/scala' >> ~/.bashrc
echo 'export HADOOP_HOME=/opt/hadoop' >> ~/.bashrc
echo 'export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop' >> ~/.bashrc
echo 'export SPARK_HOME=/opt/spark' >> ~/.bashrc
echo 'export PATH=$PATH:$JAVA_HOME/bin:$SCALA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$SPARK_HOME/sbin' >> ~/.bashrc

# Configurar variables de entorno
source ~/.bashrc

# Verificar instalación
java -version
javac -version
scala -version
hadoop version
spark-shell --version
```