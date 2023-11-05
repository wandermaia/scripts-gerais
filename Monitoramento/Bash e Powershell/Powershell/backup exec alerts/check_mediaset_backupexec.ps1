<#
Nome do Script.............: C:\opmon\scripts\check_mediaset_backupexec.ps1
Sistema....................: Opmon (execução por agente Windows)
Data da Criacao............: 01/08/2018
Criado por.................: Wander Maia da Silva
#*****************************************************************************************************************************************
Descricao..................: Plugin para verificação se o serviço do site do IIS está disponível.
Entrada....................: Dados do caminho do site no IIS
Saida......................: Número de conexões ativas no IIS
Linha do Plugin............: .\check_mediaset_backupexec.ps1 -n 'DR4000'
Linha Configuração Agente..: check_mediaset_backupexec=cmd /c echo C:\opmon\scripts\check_mediaset_backupexec.ps1 -n $ARG1$ ; exit $LASTEXITCODE | powershell.exe -command -
Execução pelo Agente.......: /usr/local/opmon/libexec/check_nrpe -t 60 -H 127.0.0.1 -c check_mediaset_backupexec -a 'DR4000'
#>

# Segregando as opções de entrada
Param(
    [parameter(Mandatory=$true)]
    [alias("n")]
    $media)

# Importando o módulo necessário para execução
Import-Module BEMCLI

# Realizando a coleta do status do site
# Get-WebURL -PSPath 'IIS:\sites\SITES\GESTAOFROTA' | Select-Object -ExpandProperty Status
$estado = Get-BEStorage -Name "$media" | Select-Object -ExpandProperty Active

# Validando os valores informados:
if ($estado -eq "True") {
	
    Write-Host "O media set '$media' esta ativo! | STATUS_MEDIA_SET=0;;;;"
	exit 0
}
else {
	Write-Host "O media set '$media' esta inativo! | STATUS_MEDIA_SET=2;;;;"
	exit 2
}

Write-Host "Erro desconhecido!"
exit 3