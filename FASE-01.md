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
sudo apt install -y net-tools curl wget htop

# Configurar IP estática
sudo nano /etc/netplan/00-installer-config.yaml
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
sudo nano /etc/hosts
```

**Contenido de /etc/hosts:**
```
127.0.0.1 localhost
127.0.1.1 spark-server

# Cluster Spark-Hadoop
192.168.100.10 spark-master
192.168.100.11 spark-slave1
192.168.100.12 spark-slave2
192.168.100.13 spark-slave3
192.168.100.14 spark-slave4
192.168.100.15 spark-slave5

# IPv6 entries
::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts
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

### 4.4 Instalar Spark 3.0.1
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

## **PASO 5: CREAR CLONES DE LA VM**

### 5.1 Preparar VM Base para Clonación
```bash
# En la VM master, limpiar historial y apagar
history -c
sudo apt autoremove -y
sudo apt autoclean
sudo shutdown -h now
```

### 5.2 Clonar VMs
1. **En VirtualBox**, clic derecho en `spark-master`
2. **Clonar...**
3. **Configuración de clonación:**
   - **Nombre**: spark-slave1
   - **Política MAC**: Generar nuevas direcciones MAC
   - **Tipo**: Clonación completa
4. **Repetir proceso** para crear:
   - spark-slave2
   - spark-slave3
   - spark-slave4
   - spark-slave5

### 5.3 Configurar Recursos de Slaves
Para cada slave:
1. **Clic derecho** → Configuración
2. **Sistema** → **Memoria**: 2048 MB
3. **Sistema** → **Procesador**: 1 CPU

## **PASO 6: CONFIGURAR CADA SLAVE**

### 6.1 Configurar Hostnames y IPs
**Para cada slave (spark-slave1 a spark-slave5):**

```bash
# Iniciar VM y conectar
# Cambiar hostname
sudo hostnamectl set-hostname spark-slave1  # Cambiar número según slave

# Configurar IP en netplan
sudo nano /etc/netplan/00-installer-config.yaml
```

**IPs para cada slave:**
- spark-slave1: 192.168.100.11
- spark-slave2: 192.168.100.12
- spark-slave3: 192.168.100.13
- spark-slave4: 192.168.100.14
- spark-slave5: 192.168.100.15

```bash
# Aplicar configuración
sudo netplan apply

# Reiniciar para aplicar hostname
sudo reboot
```

## **PASO 7: CONFIGURAR SSH SIN CONTRASEÑA**

### 7.1 Desde Master hacia todos los Slaves
```bash
# En spark-master
# Copiar clave pública a cada slave
ssh-copy-id spark-user@spark-slave1
ssh-copy-id spark-user@spark-slave2
ssh-copy-id spark-user@spark-slave3
ssh-copy-id spark-user@spark-slave4
ssh-copy-id spark-user@spark-slave5

# Copiar clave a sí mismo
ssh-copy-id spark-user@spark-master

# Verificar conexión sin contraseña
ssh spark-user@spark-slave1
exit
```

### 7.2 Verificar Conectividad
```bash
# En master, probar conexión a todos los nodos
for i in {1..5}; do
    echo "Probando conexión a spark-slave$i"
    ssh spark-user@spark-slave$i "hostname && date"
done
```

## **PASO 8: CONFIGURAR DIRECTORIOS COMPARTIDOS**

### 8.1 Crear Directorios en todos los nodos
```bash
# En master y cada slave
mkdir -p ~/hadoop/logs
mkdir -p ~/hadoop/data/namenode
mkdir -p ~/hadoop/data/datanode
mkdir -p ~/spark/logs
mkdir -p ~/datasets
```

## **PASO 9: VERIFICACIÓN FINAL**

### 9.1 Script de Verificación
```bash
# En master, crear script de verificación
nano ~/verify_cluster.sh
```

**Contenido del script:**
```bash
#!/bin/bash
echo "=== VERIFICACIÓN DEL CLUSTER ==="
echo "Nodo Master: $(hostname)"
echo "IP Master: $(hostname -I)"
echo

echo "=== VERIFICACIÓN DE CONECTIVIDAD ==="
for i in {1..5}; do
    echo -n "spark-slave$i: "
    ssh spark-user@spark-slave$i "hostname" 2>/dev/null && echo "OK" || echo "FAIL"
done

echo
echo "=== VERIFICACIÓN DE VERSIONES ==="
echo "Java: $(java -version 2>&1 | head -1)"
echo "Scala: $(scala -version 2>&1)"
echo "Hadoop: $(hadoop version 2>&1 | head -1)"
echo "Spark: $(spark-shell --version 2>&1 | grep version | head -1)"
```

```bash
# Dar permisos y ejecutar
chmod +x ~/verify_cluster.sh
./verify_cluster.sh
```

## **PASO 10: CAPTURAS DE PANTALLA REQUERIDAS**

### 10.1 Capturas Obligatorias
1. **VirtualBox Manager** mostrando las 6 VMs
2. **Configuración de red** de cada VM
3. **Verificación de versiones** en master
4. **Conectividad SSH** entre nodos
5. **Estructura de directorios** creada
6. **Script de verificación** ejecutándose

---

## **CHECKLIST FASE 1 COMPLETADA**

- [ ] 6 VMs creadas (1 master + 5 slaves)
- [ ] Ubuntu Server 20.04 instalado en todas
- [ ] Red interna configurada (192.168.100.x)
- [ ] SSH sin contraseña configurado
- [ ] Java 8 instalado y configurado
- [ ] Scala 2.12.10 instalado
- [ ] Hadoop 3.2.1 instalado
- [ ] Spark 3.0.1 instalado
- [ ] Todas las variables de entorno configuradas
- [ ] Conectividad verificada entre todos los nodos
- [ ] Capturas de pantalla tomadas
- [ ] Script de verificación funcionando

**Próximo paso:** FASE 2 - Configuración de Hadoop HDFS y Spark Cluster