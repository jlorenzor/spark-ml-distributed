# connect-cluster.ps1
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("master", "slave1", "slave2", "all")]
    [string]$Node
)

function Connect-Node {
    param($NodeName, $Port)
    Write-Host "Conectando a $NodeName (puerto $Port)..." -ForegroundColor Green
    ssh -p $Port spark-user@localhost
}

function Show-Status {
    Write-Host "=== ESTADO DEL CLUSTER ===" -ForegroundColor Cyan
    
    $nodes = @(
        @{Name="Master"; Port=2222},
        @{Name="Slave-1"; Port=2223}, 
        @{Name="Slave-2"; Port=2224}
    )
    
    foreach ($node in $nodes) {
        Write-Host -NoNewline "Probando $($node.Name) (puerto $($node.Port)): "
        
        $result = Test-NetConnection -ComputerName localhost -Port $node.Port -WarningAction SilentlyContinue
        if ($result.TcpTestSucceeded) {
            Write-Host "DISPONIBLE" -ForegroundColor Green
        } else {
            Write-Host "NO DISPONIBLE" -ForegroundColor Red
        }
    }
}

switch ($Node) {
    "master" { Connect-Node "Master" 2222 }
    "slave1" { Connect-Node "Slave-1" 2223 }
    "slave2" { Connect-Node "Slave-2" 2224 }
    "all" { Show-Status }
}