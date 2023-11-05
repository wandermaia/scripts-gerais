<#
Nome do Script.............: C:\opmon\scripts\check_task_scheduler.ps1
Sistema....................: OpMon (execução por agente Windows)
Data da Criacao............: 27/06/2018
Criado por.................: Wander Maia da Silva
#*****************************************************************************************************************************************
Descricao..................: Plugin para verificação do status da última execução da tarefa agendada.
Entrada....................: Nome da tarefa
Saida......................: Status da última execução
Linha do Plugin............: C:\opmon\scripts\check_task_scheduler.ps1 -t 'Apagar_Backups_Antigos'
Linha Configuração Agente..: check_task_scheduler=cmd /c echo C:\opmon\scripts\check_task_scheduler.ps1 -t $ARG1$ ; exit $LASTEXITCODE | powershell.exe -command -
Execução pelo Agente.......: /usr/local/opmon/libexec/check_nrpe -t 60 -H 127.0.0.1 -c check_task_scheduler -a 'Apagar_Backups_Antigos'
#>

# Segregando as opções de entrada
Param(
    [parameter(Mandatory=$true)]
    [alias("t")]
    $nomeTaskScheduler)


# Coletando os dados da TasqScheduler informada
$dadosTaskScheduler = Get-ScheduledTask | Where TaskName -eq ${nomeTaskScheduler} 

# Validando se a task informada foi encontrada
if (!$dadosTaskScheduler) { 

    Write-Host "Task not found." 
    exit 2
}

# Validando se a task está habilitada
$statusDaTask= $dadosTaskScheduler.State
if ( $statusDaTask -eq "Disabled") { 
    Write-Host "The task is disabled." 
    exit 2
}

# Coletando todos os valores referentes a última execução
$execucaoTaskScheduler = Get-ScheduledTask | Where TaskName -eq ${nomeTaskScheduler} | Get-ScheduledTaskInfo

# Segregando os valores
$horaUltimaExecucao= $execucaoTaskScheduler.LastRunTime
$statusUltimaExecucao= $execucaoTaskScheduler.LastTaskResult

# Validando se o job foi executado.
if (${statusUltimaExecucao} -eq 0) {
	
    Write-Host "The '${nomeTaskScheduler}' task has been successfully executed. Last execution: ${horaUltimaExecucao} | STATUS_LAST_EXECUTION=${statusUltimaExecucao};;;; "
	exit 0
}
else {
	Write-Host "The '${nomeTaskScheduler}' task failed! Last execution: ${horaUltimaExecucao} | STATUS_LAST_EXECUTION=${statusUltimaExecucao};;;; "
	exit 2
}

Write-Host "Erro desconhecido!"
exit 3