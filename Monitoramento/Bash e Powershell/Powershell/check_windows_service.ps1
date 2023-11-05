<#
Nome do Script......................: C:\opmon\scripts\check_windows_service.ps1
Sistema.............................: Opmon (execução por agente Windows)
Data da Criacao.....................: 25/05/2017
Criado por..........................: Wander Maia da Silva
#*****************************************************************************************************************************************
Descricao...........................: Plugin para verificação dos serviços Windows (Ativo, consumo memória e CPU).
Entrada.............................: Dados do serviço e limites de alerta
Saida...............................: Status do serviço e consumo de CPU e memória
Linha do Plugin.....................: .\check_windows_service.ps1 -s "Dhcp" -wc 5 -cc 10 -wm 50 -cm 100
Comentário do arquivo confgiguração.: ;Verifica consumo de recursos de um serviço windows por powershell
Linha Configuração Agente...........: check_windows_service=cmd /c echo C:\opmon\scripts\check_windows_service.ps1 -s $ARG1$ -wc $ARG2$ -cc $ARG3$ -wm $ARG4$ -cm $ARG5$  ; exit $LASTEXITCODE | powershell.exe -command -
Execução pelo Agente................: /usr/local/opmon/libexec/check_nrpe -H 127.0.0.1 -t 20 -c check_windows_service -a "Dhcp" 5 10 50 100
#>

# Segregando as opções de entrada
Param(
    [parameter(Mandatory=$true)]
    [alias("s")]
    $SERVICE_NAME,
	[parameter(Mandatory=$true)]
    [alias("wc")]
    $WARNING_CPU,
    [parameter(Mandatory=$true)]
    [alias("cc")]
    $CRITICAL_CPU,
	[parameter(Mandatory=$true)]
    [alias("wm")]
    $WARNING_MEMORY,
    [parameter(Mandatory=$true)]
    [alias("cm")]
    $CRITICAL_MEMORY)

# Função responsável por gerar o performance Data
Function PERFORMANCE ($MENSAGEM){

	# Limitando as casas Decimais da memória
	$MEMORY = $MEMORY | % {$_.ToString("#.##")}
	# Gerando o performance data com a mensagem enviada.
    Write-Host " $MENSAGEM PERCENT_PROCESSOR_TIME: ${CPU_PERCENT}% , MEMORY: ${MEMORY}MB | PERCENT_PROCESSOR_TIME=${CPU_PERCENT}%;${WARNING_CPU};${CRITICAL_CPU};; MEMORY=${MEMORY}MB;${WARNING_MEMORY};${CRITICAL_MEMORY};;"
}	

# Realizando a coleta do ID do processo referente ao serviço informado.
$ID = Get-WmiObject -Class Win32_Service -Filter "Name LIKE '$SERVICE_NAME'" | Select-Object -ExpandProperty ProcessId

# Validando se o serviço está ativo
$STATUS = Get-Service  -Name $SERVICE_NAME | Select-Object -ExpandProperty Status

# Verificando se o serviço não foi encontrado
if (!${STATUS}) {
	
    Write-Host "Error! Service not found!"
	exit 3
}

# Verificando se o serviço está em execução
if (${STATUS} -eq "Stopped") {
	
    Write-Host "The service '${SERVICE_NAME}' is stopped! | PERCENT_PROCESSOR_TIME=0%;${WARNING_CPU};${CRITICAL_CPU};; MEMORY=0.00MB;${WARNING_MEMORY};${CRITICAL_MEMORY};;"
	exit 1
}

# Realizando a coleta do ID do processo referente ao serviço informado.
# WorkingSet (Em bytes): O tamanho do conjunto de trabalho do processo, em quilobytes. O conjunto de trabalho consiste nas páginas de memória que foram recentemente referenciadas pelo processo.
# PercentProcessorTime : A quantidade de tempo do processador que o processo usou em todos os processadores, em segundos.
$CONSUMO_GERAL = Get-WmiObject -ComputerName localhost -class Win32_PerfFormattedData_PerfProc_Process -Filter "IDProcess = '$ID'" | Select-Object Name, PercentProcessorTime, IDProcess, WorkingSet

# Segregando os valores
$MEMORY = $CONSUMO_GERAL.WorkingSet
$CPU_PERCENT = $CONSUMO_GERAL.PercentProcessorTime

# Convertendo para MB
$MEMORY = $MEMORY/1024/1024

# Verificando os limites de alertas
if ( ($CPU_PERCENT -lt $WARNING_CPU ) -and ($MEMORY -lt $WARNING_MEMORY)) {
	
	$INFORMACAO = "Service features '${SERVICE_NAME}' is OK!"
	PERFORMANCE $INFORMACAO
	exit 0
}
elseif (($CPU_PERCENT -lt $CRITICAL_CPU ) -and ( $MEMORY -lt $CRITICAL_MEMORY)) {

    $INFORMACAO = "Service features '${SERVICE_NAME}' is on Alert!"
	PERFORMANCE $INFORMACAO
	exit 1
}
else {
	
    $INFORMACAO = "Service features '${SERVICE_NAME}' is on Critical!"
	PERFORMANCE $INFORMACAO
	exit 2
}

Write-Host "Unknown error!"
exit 3