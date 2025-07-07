# configure-ports-clean.ps1
Write-Host "=== CONFIGURANDO PUERTOS PARA 3 VMs ===" -ForegroundColor Green
Write-Host "VMs: spark-master, spark-slave-1, spark-slave-2" -ForegroundColor Cyan

# Verificar que todas las VMs esten apagadas
Write-Host ""
Write-Host "Verificando estado de VMs..." -ForegroundColor Yellow
$runningVMs = & "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" list runningvms

if ($runningVMs) {
    Write-Host "ERROR: Hay VMs ejecutandose. Apagalas primero:" -ForegroundColor Red
    Write-Host $runningVMs
    Write-Host ""
    Write-Host "Para apagarlas ejecuta:" -ForegroundColor Yellow
    Write-Host "VBoxManage controlvm spark-master poweroff" -ForegroundColor Cyan
    Write-Host "VBoxManage controlvm spark-slave-1 poweroff" -ForegroundColor Cyan
    Write-Host "VBoxManage controlvm spark-slave-2 poweroff" -ForegroundColor Cyan
    exit 1
}

Write-Host "OK - Todas las VMs estan apagadas" -ForegroundColor Green

# CONFIGURAR SPARK-MASTER
Write-Host ""
Write-Host "--- Configurando spark-master ---" -ForegroundColor Yellow

try {
    & "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "spark-master" --natpf1 "SSH-Master,tcp,127.0.0.1,2222,,22"
    Write-Host "OK - SSH (2222 -> 22)" -ForegroundColor Green
    
    & "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "spark-master" --natpf1 "HDFS-UI,tcp,127.0.0.1,9870,,9870"
    Write-Host "OK - HDFS UI (9870 -> 9870)" -ForegroundColor Green
    
    & "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "spark-master" --natpf1 "Spark-UI,tcp,127.0.0.1,8080,,8080"
    Write-Host "OK - Spark UI (8080 -> 8080)" -ForegroundColor Green
    
    & "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "spark-master" --natpf1 "YARN-UI,tcp,127.0.0.1,8088,,8088"
    Write-Host "OK - YARN UI (8088 -> 8088)" -ForegroundColor Green
    
    & "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "spark-master" --natpf1 "History,tcp,127.0.0.1,18080,,18080"
    Write-Host "OK - Spark History (18080 -> 18080)" -ForegroundColor Green
    
} catch {
    Write-Host "ERROR configurando spark-master: $($_.Exception.Message)" -ForegroundColor Red
}

# CONFIGURAR SPARK-SLAVE-1
Write-Host ""
Write-Host "--- Configurando spark-slave-1 ---" -ForegroundColor Yellow

try {
    & "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "spark-slave-1" --natpf1 "SSH-Slave1,tcp,127.0.0.1,2223,,22"
    Write-Host "OK - SSH (2223 -> 22)" -ForegroundColor Green
    
    & "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "spark-slave-1" --natpf1 "DataNode1,tcp,127.0.0.1,9864,,9864"
    Write-Host "OK - DataNode UI (9864 -> 9864)" -ForegroundColor Green
    
    & "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "spark-slave-1" --natpf1 "Worker1,tcp,127.0.0.1,8081,,8081"
    Write-Host "OK - Spark Worker UI (8081 -> 8081)" -ForegroundColor Green
    
    & "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "spark-slave-1" --natpf1 "NodeMgr1,tcp,127.0.0.1,8042,,8042"
    Write-Host "OK - YARN NodeManager (8042 -> 8042)" -ForegroundColor Green
    
} catch {
    Write-Host "ERROR configurando spark-slave-1: $($_.Exception.Message)" -ForegroundColor Red
}

# CONFIGURAR SPARK-SLAVE-2
Write-Host ""
Write-Host "--- Configurando spark-slave-2 ---" -ForegroundColor Yellow

try {
    & "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "spark-slave-2" --natpf1 "SSH-Slave2,tcp,127.0.0.1,2224,,22"
    Write-Host "OK - SSH (2224 -> 22)" -ForegroundColor Green
    
    & "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "spark-slave-2" --natpf1 "DataNode2,tcp,127.0.0.1,9865,,9864"
    Write-Host "OK - DataNode UI (9865 -> 9864)" -ForegroundColor Green
    
    & "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "spark-slave-2" --natpf1 "Worker2,tcp,127.0.0.1,8082,,8081"
    Write-Host "OK - Spark Worker UI (8082 -> 8081)" -ForegroundColor Green
    
    & "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "spark-slave-2" --natpf1 "NodeMgr2,tcp,127.0.0.1,8043,,8042"
    Write-Host "OK - YARN NodeManager (8043 -> 8042)" -ForegroundColor Green
    
} catch {
    Write-Host "ERROR configurando spark-slave-2: $($_.Exception.Message)" -ForegroundColor Red
}

# RESUMEN FINAL
Write-Host ""
Write-Host "=== CONFIGURACION COMPLETADA ===" -ForegroundColor Green

Write-Host ""
Write-Host "ACCESO SSH:" -ForegroundColor Cyan
Write-Host "ssh -p 2222 spark-user@localhost  # spark-master"
Write-Host "ssh -p 2223 spark-user@localhost  # spark-slave-1"
Write-Host "ssh -p 2224 spark-user@localhost  # spark-slave-2"

Write-Host ""
Write-Host "INTERFACES WEB:" -ForegroundColor Cyan
Write-Host "http://localhost:9870   # HDFS NameNode"
Write-Host "http://localhost:8080   # Spark Master"
Write-Host "http://localhost:8088   # YARN ResourceManager"
Write-Host "http://localhost:18080  # Spark History Server"
Write-Host "http://localhost:8081   # Spark Worker 1"
Write-Host "http://localhost:8082   # Spark Worker 2"
Write-Host "http://localhost:9864   # DataNode 1"
Write-Host "http://localhost:9865   # DataNode 2"

Write-Host ""
Write-Host "Listo para iniciar las VMs!" -ForegroundColor Green