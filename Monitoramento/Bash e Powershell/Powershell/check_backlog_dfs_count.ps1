<#
Nome do Script.............: C:\opmon\scripts\check_backlog_dfs_count.ps1
Sistema....................: Opmon (execução por agente Windows)
Data da Criacao............: 14/05/2019
Criado por.................: Wander Maia da Silva
#*****************************************************************************************************************************************
Descricao..................: Plugin para verificação do backup log de replicação de arquivos do DFS
Entrada....................: Nome dos servidores de origem e destino, além do seviços de replicação. Também são necessários os limites de alerta
Saida......................: Quantidade de arquivos pendente replicação.
Linha do Plugin............: .\check_backlog_dfs_count.ps1 -g "DEPARTAMENTOS" -s "origem" -d "destino" -w 20 -c 30
Linha Configuração Agente..: check_backlog_dfs_count=cmd /c echo C:\opmon\scripts\check_backlog_dfs_count.ps1 -g $ARG1$ -s $ARG2$ -d $ARG3$ -w $ARG4$ -c $ARG5$ ; exit $LASTEXITCODE | powershell.exe -command -
Execução pelo Agente.......: /usr/local/opmon/libexec/check_nrpe -t 20 -H 127.0.0.1 -c check_backlog_dfs_count -a "DEPARTAMENTOS" "origem" "destino" 20 30
Observações................: Foi necessário adicionar um usuário de domínio com permissão de administrador para iniciar o serviço do agente. Essa função depende de permissão de administrador.
#>

# Segregando as opções de entrada
Param(
    [parameter(Mandatory=$true)]
    [alias("g")]
    $groupName,
    [parameter(Mandatory=$true)]
    [alias("s")]
    $sourceComputer,
	[parameter(Mandatory=$true)]
    [alias("d")]
    $destinationComputer,
	[parameter(Mandatory=$true)]
    [alias("w")]
    $warning,
	[parameter(Mandatory=$true)]
    [alias("c")]
    $critical
	)

# Coletando a os dados da replicação dos arquivos
$replicacao = Get-DfsrBacklog -GroupName "${groupName}" -FolderName "${groupName}" -SourceComputerName "${sourceComputer}" -DestinationComputerName "${destinationComputer}"

# Separando a quantidade de arquivos com replicação pendente
$filesCount = $replicacao.count

# Função responsável por gerar o performance Data
Function performance ($mensagem){

	# Gerando o performance data com a mensagem enviada.
    Write-Host "${mensagem} | TOTAL_PENDING_FILES=${filesCount};${warning};${critical};; "
}	

# Validando os limites de alerta
if (${filesCount} -gt ${critical}) {

    performance "DFS replication is critical! Total Pending Files : ${filesCount} files"
	exit 2
}
elseif (${filesCount} -gt ${warning}) {

    performance "DFS Replication is on Alert! Total Pending Files : ${filesCount} files"
	exit 1
}
else {

    performance "DFS Replication is ok! Total Pending Files : ${filesCount} files"
	exit 0
}

Write-Host "Unknown error!"
exit 3