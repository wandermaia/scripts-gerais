<#
Nome do Script.............: C:\opmon\scripts\check_sessoes_ts.ps1
Sistema....................: Opmon (execução por agente Windows)
Data da Criacao............: 31/03/2017
Criado por.................: Wander Maia da Silva
#*****************************************************************************************************************************************
Descricao..................: Plugin para verificação do número de conexões de terminal services
Entrada....................: Limites de alertas
Saida......................: Número de conexões TS totais e ativas
Linha do Plugin............: C:\opmon\scripts\check_sessoes_ts.ps1 -w 80 -c 90
Linha Configuração Agente..: check_sessoes_ts=cmd /c echo C:\opmon\scripts\check_sessoes_ts.ps1 -w $ARG1$ -c $ARG2$  ; exit $LASTEXITCODE | powershell.exe -command -
Execução pelo Agente.......: /usr/local/opmon/libexec/check_nrpe -t 60 -H 127.0.0.1 -c check_sessoes_ts -a 70 80
#>

# Segregando as opções de entrada
Param(
    [parameter(Mandatory=$true)]
    [alias("w")]
    $warnlevel,
    [parameter(Mandatory=$true)]
    [alias("c")]
    $critlevel)

# Coletando as sessões de Terminal Services ativas
$coleta = qwinsta /server:localhost | Select-String -Pattern rdp

# Verificando o número de sessões
$totalSessions = $coleta.count

# Validando os valores informados:
if ($totalSessions -gt $critlevel) {
	
    Write-Host "Numero de sessoes TS em estado Critico! Total de Sessoes: ${totalSessions} | TOTAL=${totalSessions};${warnlevel};${critlevel};; "
	exit 2
}
elseif ($totalSessions -gt $warnlevel) {
    Write-Host "Numero de sessoes TS em Alerta! Total de Sessoes: ${totalSessions} | TOTAL=${totalSessions};${warnlevel};${critlevel};; "
	exit 1
}
else {
	Write-Host "Numero de sessoes TS esta OK! Total de Sessoes: ${totalSessions} | TOTAL=${totalSessions};${warnlevel};${critlevel};; "
	exit 0
}

Write-Host "Erro desconhecido!"
exit 3