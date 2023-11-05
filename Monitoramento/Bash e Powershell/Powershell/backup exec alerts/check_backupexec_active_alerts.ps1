<#
Nome do Script.............: C:\opmon\scripts\check_backupexec_active_alerts.ps1
Sistema....................: Opmon (execução por agente Windows)
Data da Criacao............: 18/05/2017
Criado por.................: Wander Maia da Silva
#*****************************************************************************************************************************************
Descricao..................: Plugin para verificação de alertas ativos no Backupexec com severidade Warning ou Error
Entrada....................: Não necessário.
Saida......................: Número de erros ou warnings do bakcupexec.
Linha do Plugin............: .\check_backupexec_active_alerts.ps1
Linha Configuração Agente..: check_backupexec_active_alerts = powershell.exe -executionpolicy bypass -file scripts\check_backupexec_active_alerts.ps1
Execução pelo Agente.......: /usr/local/opmon/libexec/check_nrpe -t 20 -H 127.0.0.1 -c check_backupexec_active_alerts
#>

# Carregando o módulo de gerência do BackupExec para linha de comando
Import-Module BEMCLI

# Verificando o número de errors e warnings dos Alertas no BackupExec
$errors =  @(Get-BEAlert -Severity Error).Count
$warnings =  @(Get-BEAlert -Severity warning).Count


# Validando os valores informados:
if (${errors} -ne "0") {
	
    write-host "Alertas de error : ${errors}, Alertas de warning : ${warnings} | total_warnings=${warnings};;;; total_errors=${errors};;;; "
	exit 2
}
elseif (${warnings} -ne "0") {
    Write-Host "Alertas de warning : ${warnings}, Alertas de error : ${errors} | total_warnings=${warnings};;;; total_errors=${errors};;;; "
	exit 1
}
else {
	Write-Host "Sem alertas no Backupexec! | total_warnings=${warnings};;;; total_errors=${errors};;;; "
	exit 0
}

Write-Host "Erro desconhecido!"
exit 3