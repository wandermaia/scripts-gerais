<#
Nome do Script.............: C:\opmon\scripts\check_sessoes_ts_sv.ps1
Sistema....................: Opmon (execução por agente Windows)
Data da Criacao............: 31/03/2017
Criado por.................: Wander Maia da Silva
#*****************************************************************************************************************************************
Descricao..................: Plugin para verificação do número de conexões de terminal services
Entrada....................: Limites de alertas
Saida......................: Número de conexões TS totais e ativas - Validação de Warning e Critical feita direto no Nagios
Linha do Plugin............: C:\opmon\scripts\check_sessoes_ts.ps1
Linha Configuração Agente..: check_sessoes_ts_sv=cmd /c echo C:\opmon\scripts\check_sessoes_ts_sv.ps1  | powershell.exe -command -
Execução pelo Agente.......: /usr/local/opmon/libexec/check_nrpe -t 60 -H  $HOST -c check_sessoes_ts_sv
#>

# Coletando as sessões de Terminal Services ativas
$coleta = qwinsta /server:localhost | Select-String -Pattern rdp

# Verificando o número de sessões
$totalSessions = $coleta.count

Write-Host $totalSessions