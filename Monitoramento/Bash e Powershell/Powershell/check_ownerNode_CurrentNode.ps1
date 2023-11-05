<#
Nome do Script.............: C:\opmon\scripts\check_ownerNode_CurrentNode.ps1
Sistema....................: OpMon (execução por agente Windows)
Data da Criacao............: 08/05/2018
Criado por.................: Wander Maia da Silva
#*****************************************************************************************************************************************
Descricao..................: Plugin para verificação se os recursos do cluster estão sendo executados no nó preferencial
Entrada....................: Nome do cluster
Saida......................: Local de execução do recurso e código de erro.
Linha do Plugin............: C:\opmon\scripts\check_ownerNode_CurrentNode.ps1 -c 'cluster_name'
Linha Configuração Agente..: check_ownerNode_CurrentNode=cmd /c echo C:\opmon\scripts\check_ownerNode_CurrentNode.ps1 -c $ARG1$ ; exit $LASTEXITCODE | powershell.exe -command -

Execução pelo Agente.......: /usr/local/opmon/libexec/check_nrpe -t 60 -H 127.0.0.1 -c check_ownerNode_CurrentNode -a 'cluster_name'
#>

# Segregando as opções de entrada
Param(
    [parameter(Mandatory=$true)]
    [alias("c")]
    $CLUSTER_NAME)

# Incialização das variáveis Globais
$MENSAGEM = ""
$FLAG_RECURSO = 0
	
# Listando os recursos do Cluster
$RECURSOS_CLUSTER = @(Get-ClusterGroup -cluster $CLUSTER_NAME)

# Verificando se cada recurso está sendo executado no nó preferencial
foreach ($RECURSO in $RECURSOS_CLUSTER){
 
# Verificando o owner node e o owner em execução.
$NOME_RECURSO = $RECURSO.name
$NO_PREFERENCIAL = (Get-ClusterGroup -cluster $CLUSTER_NAME $NOME_RECURSO | Get-ClusterOwnerNode | % OwnerNodes).name
$NO_ATUAL = (Get-ClusterGroup -cluster $CLUSTER_NAME $NOME_RECURSO | % OwnerNode).name

# Verificando se o recurso está em execução no nó preferencial. Em caso negativo, é somado o valor de 1 ao flag de recursos
# Excluindo os recursos "Available Storage" e "Cluster Group"
if ($NO_PREFERENCIAL -ne $NO_ATUAL -and $NOME_RECURSO -ne "Available Storage" -and $NOME_RECURSO -ne "Cluster Group"){
		
		$FLAG_RECURSO = $FLAG_RECURSO + 1
		$MENSAGEM = $MENSAGEM + "O Recurso $NOME_RECURSO não está no nodo preferencial! "
	}
}

# Validando os limites de alertas
if ($FLAG_RECURSO -eq 0) {
	
    Write-Host "Todos os recursos estão sendo executados no nodo preferencial. | Nro_Failover=${FLAG_RECURSO};;;; "
	exit 0
}
else {
	Write-Host "$MENSAGEM | Nro_Failover=${FLAG_RECURSO};;;; "
	exit 2
}

Write-Host "Erro desconhecido!"
exit 3