<#
Nome do Script.............: C:\opmon\scripts\check_conexoes_iis.ps1
Sistema....................: Opmon (execução por agente Windows)
Data da Criacao............: 21/03/2017
Criado por.................: Wander Maia da Silva
#*****************************************************************************************************************************************
Descricao..................: Plugin para verificação do número de conexões ativas do IIS.
Entrada....................: Dados para acesso e nome do job
Saida......................: Número de conexões ativas no IIS
Linha do Plugin............: \check_conexoes_iis.ps1 -s 127.0.0.1 -w 80 -c 90
Linha Configuração Agente..: check_conexoes_iis=cmd /c echo C:\opmon\scripts\check_conexoes_iis.ps1 -s $ARG1$ -w $ARG2$ -c $ARG3$ | C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -command -
Execução pelo Agente.......: /usr/local/opmon/libexec/check_nrpe -t 20 -H 127.0.0.1 -c check_conexoes_iis -a 127.0.0.1 70 80
#>

# Segregando as opções de entrada
Param(
    [parameter(Mandatory=$true)]
    [alias("s")]
    $srvname,
    [parameter(Mandatory=$true)]
    [alias("w")]
    $warnlevel,
    [parameter(Mandatory=$true)]
    [alias("c")]
    $critlevel)


# Realizando a coleta do número de conexões do IIS no host informado.
$connections = Get-WmiObject -Class Win32_PerfFormattedData_W3SVC_WebService -ComputerName $srvname | Where {$_.Name -eq "_Total"} | % {$_.CurrentConnections}

# Validando os valores informados:
if ($connections -gt $critlevel) {
	
    Write-Host "Numero de conexoes IIS em estado Critico! total: ${connections} Conexoes | CONEXOES_IIS=${connections};${warnlevel};${critlevel};;"
	exit 2
}
elseif ($connections -gt $warnlevel) {
    Write-Host "Numero de conexoes IIS esta em Alerta! total: ${connections} Conexoes | 'CONEXOES_IIS'=${connections};${warnlevel};${critlevel};;"
	exit 1
}
else {
	Write-Host "Numero de conexoes IIS esta OK! total: ${connections} Conexoes | 'CONEXOES_IIS'=${connections};${warnlevel};${critlevel};;"
	exit 0
}

Write-Host "Erro desconhecido!"
exit 3