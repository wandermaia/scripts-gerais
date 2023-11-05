<#
Nome do Script.............: C:\opmon\scripts\check_apache.ps1
Sistema....................: OpMon (execução por agente Windows)
Data da Criacao............: 31/01/2019
Criado por.................: Wander Maia da Silva
#*****************************************************************************************************************************************
Descricao..................: Plugin para verificação das métricas do apache utilizado o módulo mod_status
Entrada....................: URL pra coleta dos dados e limite de alertas para utilização dos workers
Saida......................: Métricas de desempenho do Apache
Linha do Plugin............: C:\opmon\scripts\check_apache.ps1 -u 'http://127.0.0.1/server-status' -w 70 -c 80
Linha Configuração Agente..: check_apache=cmd /c echo C:\opmon\scripts\check_apache.ps1 -u $ARG1$ -w $ARG2$ -c $ARG3$ ; exit $LASTEXITCODE | powershell.exe -command -

Execução pelo Agente.......: /usr/local/opmon/libexec/check_nrpe -t 60 -H 10.125.47.11 -c check_apache -a 'http://127.0.0.1/server-status' 70 80
#>

# Segregando as opções de entrada
Param(
    [parameter(Mandatory=$true)]
    [alias("u")]
    $URL,
	[parameter(Mandatory=$true)]
    [alias("w")]
    $WARNING,
    [parameter(Mandatory=$true)]
    [alias("c")]
    $CRITICAL)

	
# Realizando a coleta de dados da página de status
$COLETA_PAGINA = (new-object System.Net.WebClient).DownloadString("${URL}")

# Limpando os caracteres de HTML e salvando no arquivo
$PAGINA_LIMPA = ($COLETA_PAGINA -replace '<[^>]+>','')
echo "${PAGINA_LIMPA}" > C:\Temp\pagina.txt

# Coletando as linhas de cada métrica
$LINHA_UPTIME = Select-String -Path C:\Temp\pagina.txt -Pattern "Server uptime:" 
$LINHA_LOAD = Select-String -Path C:\Temp\pagina.txt -Pattern "Server load:"
$LINHA_REQUESTS = Select-String -Path C:\Temp\pagina.txt -Pattern "requests/sec" 
$LINHA_WORKER = Select-String -Path C:\Temp\pagina.txt -Pattern "idle workers"

# Segragando o valor de Uptime
$UPTIME = $LINHA_UPTIME.tostring().split(":")[4]

# Segregando os valores de Load
$LOAD_1 = ($LINHA_LOAD.tostring().split("-")[1]).split(" ")[0]
$LOAD_5 = ($LINHA_LOAD.tostring().split("-")[2]).split(" ")[0]
$LOAD_15 = ($LINHA_LOAD.tostring().split("-")[3]).split(" ")[0]

# Segregando os valores de requisições
$REQUESTS_SEC = ($LINHA_REQUESTS.tostring().split(":")[3]).split(" ")[0]
$BYTES_SEC = ($LINHA_REQUESTS.tostring().split("-")[1]).split(" ")[1]
$BYTES_PER_REQUEST = ($LINHA_REQUESTS.tostring().split("-")[2]).split(" ")[1]

# Segregando os valores de workers
$PROCESSING_REQUESTS = ($LINHA_WORKER.tostring().split(":")[3]).split(" ")[0]
$IDLE_WORKERS = ($LINHA_WORKER.tostring().split(",")[1]).split(" ")[1]

# Convertendo para número real
$PROCESSING_REQUESTS = [float]$PROCESSING_REQUESTS
$IDLE_WORKERS = [float]$IDLE_WORKERS

# Calculando o percentual de utilização dos workers e limitando as casas decimais
$WORKERS_UTILIZATION = $PROCESSING_REQUESTS / ( $PROCESSING_REQUESTS + $IDLE_WORKERS ) * 100
$WORKERS_UTILIZATION = $WORKERS_UTILIZATION | % {$_.ToString("#.##")}

# Função responsável por gerar o performance Data
Function PERFORMANCE ($MENSAGEM){

	# Gerando o performance data com a mensagem enviada.
    Write-Host " $MENSAGEM | WORKERS_UTILIZATION=${WORKERS_UTILIZATION}%;${WARNING};${CRITICAL};0;100 Load-1=${LOAD_1};;;; Load-5=${LOAD_5};;;; Load-15=${LOAD_15};;;; REQUESTS_SEC=${REQUESTS_SEC}requests/sec;;;; BYTES_SEC=${BYTES_SEC}B/second;;;; BYTES_PER_REQUEST=${BYTES_PER_REQUEST}B/request;;;; PROCESSING_REQUESTS=${PROCESSING_REQUESTS};;;; IDLE_WORKERS=${IDLE_WORKERS};;;;"
}	

# Validando os limites de alerta
if (${WORKERS_UTILIZATION} -gt ${CRITICAL}) {

    PERFORMANCE "Workers utilization is on Critical! Uptime of service: ${UPTIME}"
	exit 2
}
elseif (${WORKERS_UTILIZATION} -gt ${WARNING}) {

    PERFORMANCE "Workers utilization is on Alert! Uptime of service: ${UPTIME}"
	exit 1
}
else {

    PERFORMANCE "Workers utilization OK! Uptime of service: ${UPTIME}"
	exit 0
}

Write-Host "Unknown error!"
exit 3