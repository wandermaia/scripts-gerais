#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /root/scripts/manage_services.sh
# Sistema.............: OpMon
# Criado por..........: Wander Maia da Silva
# Data da Criação.....: 03/06/2018
# Descrição...........: Edita as propriedades de um serviço, uma lista de hosts ou serviços pertencentes à um service group.
# Entrada.............: Dados do serviço, host e/ou dados dos parâmetros que serão modificados.
#*****************************************************************************************************************************************************
# Data da Alteração...: 11/06/2018
# Motivo..............: Acréscimo da função para remover os contactgroups dos serviços de um host, uma lista de hosts ou hostgroups
# Data da Alteração...: 26/06/2018
# Motivo..............: Alteradas as funções para uma melhorar o reaproveitamento de código e facilitar a implementação de novos módulos 
# Data da Alteração...: 19/06/2018
# Motivo..............: Acréscimo das funções: Remover contacgroups dos serivcegroup, adicionar contacgroup aos serviços de um host, de uma lista e de um servicegroup
# Data da Alteração...: 06/03/2019
# Motivo..............: Acréscimo da função: Adicionar uma lista de serviços a um servicegroup
#*****************************************************************************************************************************************************

# Menu de Ajuda
help () {

    cat <<EOF

Descrição do Script
			  
	Script para editar as propriedades dos serviços e servicegroups.
 
Parâmetros

	-h  : Exibe este menu de ajuda
	-o  : Opção de modificação. Opções disponíveis:
			- lista_contactgroups: Lista os contactgroup de todos os serviços de um host, lista de serviços ou servicegroups
			- remove_contactgroup: Remove o contactgroup de todos os serviços de um host, lista de serviços ou servicegroups
			- adiciona_contactgroup: Adiciona um contactgroup aos serviços de um host, lista de serviços 
			- adiciona_servicegroup: Adiciona um servicegroup aos serviços de um host, lista de serviços 
	-n  : Nome do servidor, caminho do arquivo ou nome do servicegroup (dependendo da opção -o) ou servicegroups
	-c  : Opção adicional. Opções disponíveis:
			- Nome do contactgroup (no caso da utilização de remove_contactgroup, pode ser informada a opção REMOVE_ALL para remover todos os contactgroups)
			- Nome do servicegroup (para operações de inclusão em serviços)
	-t  : Tipo: Pode ser host, lista (lista de servios no formando 'host,serviço') ou servicegroup

Exemplos de Utilização
  
	Listar os contactgroups de todos os serviços de um servidor
	/root/scripts/manage_services.sh -o lista_contactgroups -n 'CentOS-6-PRD' -t host
	
	Listar os contactgroups de uma lista de serviços
	/root/scripts/manage_services.sh -o lista_contactgroups -n '/tmp/servicos.txt' -t lista
	
	Listar os contactgroups dos serviços de um servicegroup
	/root/scripts/manage_services.sh -o lista_contactgroups -n 'CPU' -t servicegroup  
	
	Adicionar o contactgroup 'Operadores' aos serviços do host 'CentOS-6-PRD'
	/root/scripts/manage_services.sh -o adiciona_contactgroup -n 'CentOS-6-PRD' -t host -c 'Operadores'
	
	Adicionar o contactgroup 'Operadores' a lista de serviços informada
	/root/scripts/manage_services.sh -o adiciona_contactgroup -n '/tmp/servicos.txt' -t lista -c 'Operadores'
	
	Adicionar o contactgroup 'Operadores' aos servicos do servicegroup 'CPU'
	/root/scripts/manage_services.sh -o adiciona_contactgroup -n 'CPU' -t servicegroup -c 'Operadores'
	
	Adicionar os serviços da lista informada ao servicegroup 'Disk' 
	/root/scripts/manage_services.sh -o adiciona_servicegroup -n '/tmp/servicos.txt' -t lista -c 'Disk'
	
	Remover todos os contactgroups serviços de um host (será adicionado o contactgroup opmonadmins)
	/root/scripts/manage_services.sh -o remove_contactgroup -n 'CentOS-6-PRD' -t host
	
	Remover todos os contactgroups (será adicionado o contactgroup opmonadmins) serviços de uma lista de serviços
	/root/scripts/manage_services.sh -o remove_contactgroup -n '/tmp/servicos.txt' -t lista -c REMOVE_ALL
	
	Remover todos os contactgroups (será adicionado o contactgroup opmonadmins) dos serviços de um servicegroup
	/root/scripts/manage_services.sh -o remove_contactgroup -n 'CPU' -t servicegroup -c REMOVE_ALL

	Remover o contactgroup 'Operadores' de todos os serviços de uma lista de serviços
	/root/scripts/manage_services.sh -o remove_contactgroup -n '/tmp/servicos.txt' -t lista -c Operadores
	
	Remover o contactgroup 'Operadores' de todos os serviços do servicegroup 'CPU'
	/root/scripts/manage_services.sh -o remove_contactgroup -n 'CPU' -t servicegroup -c Operadores
	
EOF

	exit
}

# Menu de validacao de entradas
while getopts "o:n:c:i:t:s:hd" Option
do
  case $Option in
    o )
      OPCAO=$OPTARG
      ;;
    n )
      NOME=$OPTARG
      ;;
    c )
      CONTACTGROUP=$OPTARG
      ;;
    t )
      TIPO=$OPTARG
      ;;
    h )
      help
      ;;
  esac
done


# Função que executa o export das configurações.
executaExport(){
	
	echo -e "\nInciando o export: \n"
	/usr/local/opmon/utils/opmon-export.php
	echo -e "\nExport Finalizado!\n"
	
}

# Função que executa as operações relacionadas a serviços de hosts.
operacoesEmServicosHosts(){

	# Capturando os dados enviados por Parâmetros
	nomeHost=$1
	tipoExecucao=$2
	nomeContactgroup=$3
	
	# Coletando o ID do host
	idHost=`mysql -N -u root -e "SELECT host_id FROM nagios_hosts where host_name='${nomeHost}'" opcfg `
	
	# Validando se o host foi encontrado
	[ -z ${idHost} ] && echo -e "\nO Host '${nomeHost}' não foi encontrado! \n" && exit
	
	case ${tipoExecucao} in
        lista_contactgroups)				listaContactgroupsHost "${nomeHost}" "${idHost}"  ;;
		remove_contactgroup)				removeContactgroupsHost "${nomeHost}" "${idHost}" "${nomeContactgroup}" ; executaExport ;;
		adiciona_contactgroup)				adicionaContactgroupHost "${nomeHost}" "${idHost}" "${nomeContactgroup}" ; executaExport ;;
	    *)  			                	echo -e "\nValor da opção '-o' desconhecida!\n" ;;
	esac
}


# Função que executa as operações relacionadas a lista de serviços
operacoesEmLista (){
	
	caminhoArquivo=$1
	tipoExecucao=$2
	adicionalOption=$3
	
	# Flag para identificar quando será necessário executar export
	habilitaExport=0
	
	# validando se a lista existe.
	[ ! -e ${caminhoArquivo} ] && echo -e "\nO arquivo '${caminhoArquivo}' não foi encontrado! \n" && exit
	
	# Lendo as linhas do arquivo
	while read linha
	do
		nomeHost=`echo -e "${linha}" | awk -F ',' '{print $1}'`
		nomeServico=`echo -e "${linha}" | awk -F ',' '{print $2}'`
		
		# Coletando o ID do host e serviço
		idHost=`mysql -N -u root -e "SELECT host_id FROM nagios_hosts where host_name='${nomeHost}'" opcfg `
		idServico=`mysql -N -u root -e "SELECT service_id FROM nagios_services WHERE host_id='${idHost}' AND service_description='${nomeServico}'" opcfg `

		# Validando se o host e o serviço foram encontrados
		if [ ! -z ${idHost} ] && [ ! -z ${idServico} ]
		then
		
			# Validando a operação solicitada
			case ${tipoExecucao} in
				lista_contactgroups)				listarContactgroupsServico "${linha}" "${idServico}" "${nomeHost}" ;;
				remove_contactgroup)				removeContactgroupListaServicos "${idServico}" "${adicionalOption}" ; habilitaExport=1 ;;
				adiciona_contactgroup)				adicionaContactgroupListaServicos "${idServico}" "${adicionalOption}" ; habilitaExport=1 ;;
				adiciona_servicegroup)				adicionaServicegroupListaServicos "${idServico}" "${adicionalOption}" ; habilitaExport=1 ;;
				*)  			                	echo -e "\nValor da opção '-o' desconhecida!\n" ; exit 2 ;;
			esac			
		else
			echo -e "\nO Serviço '${linha}' não foi encontrado!\n"
		fi
		
	done < ${caminhoArquivo}

	# Validando se é necessário export
	if [ ${habilitaExport} -gt 0 ]
	then
		executaExport
	fi;

}


# Função que executa as operações relacionadas a servicegroups
operacoesEmServicegroups () {
	
	nomeServicegroup=$1
	tipoExecucao=$2
	nomeContactgroup=$3
	
	# Obtendo o ID  do servicegroup
	idServicegroup=`mysql -N -u root -e "SELECT servicegroup_id FROM nagios_servicegroups WHERE servicegroup_name='${nomeServicegroup}'" opcfg `
	[ -z ${idServicegroup} ] && echo -e "\nO servicegroup '${nomeServicegroup}' não foi encontrado! \n" && exit

	# Coletando a lista de IDs dos serviços associados ao serivcegroup
	listaIDsServicos=`mysql -N -u root -e "SELECT service_id FROM nagios_servicegroup_membership WHERE servicegroup_id='${idServicegroup}'" opcfg `
	
	# Validando se o servicegroup possui serviços associados
	quantidadeIDsServicos=`echo -e ${listaIDsServicos} | wc -w`
	if [ ${quantidadeIDsServicos} -lt 1 ]
	then
		# Validando se o hostgroup possui hosts associados
		echo -e "\nO servicegroup '${nomeServicegroup}' não possui serviços associados!\n" && exit
	fi;
	
	# Flag para identificar quando será necessário executar export
	habilitaExport=0
	
	# Loop para tratativa de todos os IDs de serviços encontrados
	for linha in ${listaIDsServicos}; do 
		
		# Coletando os dados para repassar para as funções
		nomeServico=`mysql -N -u root -e "SELECT service_description FROM nagios_services WHERE service_id='${linha}'" opcfg `
		idHost=`mysql -N -u root -e "SELECT host_id FROM nagios_services WHERE service_id='${linha}'" opcfg `
		nomeHost=`mysql -N -u root -e "SELECT host_name FROM nagios_hosts where host_id='${idHost}'" opcfg`
                
		
		# Validando a operação solicitada
		case ${tipoExecucao} in
			lista_contactgroups)				listarContactgroupsServico "${nomeServico}" "${linha}" "${nomeHost}" ;;
			remove_contactgroup)				removeContactgroupListaServicos "${linha}" "${nomeContactgroup}" ; habilitaExport=1 ;;
			adiciona_contactgroup)				adicionaContactgroupListaServicos "${linha}" "${nomeContactgroup}" ; habilitaExport=1 ;;
			*)  			                	echo -e "\nValor da opção '-o' desconhecida!\n" ; exit 2 ;;
		esac
		
	done 	
	
	
	# Validando se é necessário export
	if [ ${habilitaExport} -gt 0 ]
	then
		executaExport
	fi;
	
}


# Função para remover contactgroup quando for utilizada a lista
removeContactgroupListaServicos () {

	idServico=$1
	nomeContactgroup=$2

	[ -z ${nomeContactgroup} ] && echo -e "\nNão foi informada nenhuma opção para o parâmetro '-c'!\n" && exit
	
	# Variável global
	idContactgroup=""
	
	# Validando se foi informado algum contactgroup group
	flagContactgroups=`echo ${nomeContactgroup} | egrep -x REMOVE_ALL | wc -w`
	
	# Obtendo o ID do contactgroup, caso tenha sido informado um nome
	if [ ${flagContactgroups} -eq 0 ]
	then
		# Obtendo o ID  do contactgroup
		idContactgroup=`mysql -N -u root -e "SELECT contactgroup_id FROM nagios_contactgroups WHERE contactgroup_name='${nomeContactgroup}'" opcfg`
		[ -z ${idContactgroup} ] && echo -e "\nO contacgroup '${idContactgroup}' não foi encontrado! \n" && exit
	fi;
	
	#Chamando a função que remove o(s) contactgroup(s) do(s) serviço(s)
	removeContactgroupServico "${idServico}" "${idContactgroup}" "${flagContactgroups}" 

}


# Função para listar todos os contacgroups dos serviços de um host
listaContactgroupsHost() {
	
	nomeHost=$1
	idHost=$2

	# Obtendo a lista de IDs dos serviços que estão associados ao host
	listaIDsServicos=`mysql -N -u root -e "SELECT service_id FROM nagios_services where host_id='${idHost}' ORDER BY  service_description" opcfg`
	
	# Validando se o host possui serviços associados
	quantidadeIDsServicos=`echo -e ${listaIDsServicos} | wc -w`
	if [ ${quantidadeIDsServicos} -lt 1 ]
	then
		# Validando se o hostgroup possui hosts associados
		echo -e "\nO Host '${nomeHost}' não possui serviços associados! \n" && exit
	fi;

	# Loop para exibição do nome de todos os host_groups
	for linha in ${listaIDsServicos}; do 
	
		# Coletando o nome do serviço
		nomeServico=`mysql -N -u root -e "SELECT service_description FROM nagios_services WHERE service_id='${linha}'" opcfg`
		
		# Função para listar os contactgroups dos serviço
		listarContactgroupsServico "${nomeServico}" "${linha}" "${nomeHost}"
		
	done 

}


# Função para listar os contacgroups de um serviço
listarContactgroupsServico(){
	
	nomeServico=$1
	idServico=$2
	nomeHost=$3
	
	# Obtendo a lista de IDs dos contactgroups que estão associados ao serviço
	listaIDsContactgroups=`mysql -N -u root -e "SELECT contactgroup_id FROM nagios_service_contactgroups where service_id='${idServico}'" opcfg`
	
	echo -e "	Serviço '${nomeHost},${nomeServico}':"
	# Validando se o serviço possui contacgroups associados
	quantidadeIDsContactgroup=`echo -e ${listaIDsContactgroups} | wc -w`
	if [ ${quantidadeIDsContactgroup} -lt 1 ]
	then

		echo -e "Este serviço não possui contacgroups associados!"
		
	else

		# Loop para exibição do nome de todos os host_groups
		for linha in ${listaIDsContactgroups}; do 
	
			# Coletando o nome do contacgroup
			nomeContactgroup=`mysql -N -u root -e "SELECT contactgroup_name FROM nagios_contactgroups where contactgroup_id='${linha}'" opcfg`
			echo -e "${nomeContactgroup}"
	
		done 
		
	fi;
}


# Função para remover o contactgroup dos serviços
removeContactgroupsHost (){
	
	nomeHost=$1
	idHost=$2
	nomeContactgroup=$3
	
	[ -z ${nomeContactgroup} ] && echo -e "\nNão foi informada nenhuma opção para o parâmetro '-c'!\n" && exit
	
	# Variável global
	idContactgroup=""
	
	# Validando se foi informado algum contactgroup group
	flagContactgroups=`echo ${nomeContactgroup} | egrep -x REMOVE_ALL | wc -w`
	
	# Obtendo o ID do contactgroup, caso tenha sido informado um nome
	if [ ${flagContactgroups} -eq 0 ]
	then
		# Obtendo o ID  do contactgroup
		idContactgroup=`mysql -N -u root -e "SELECT contactgroup_id FROM nagios_contactgroups WHERE contactgroup_name='${nomeContactgroup}'" opcfg`
		
		# Validando se o contactgroup foi encontrado
		quantidadeIDsContactgroup=`echo ${idContactgroup} | wc -w`
		
		# Informando ao usuário se o contactgroup não foi encontrado.
		if [ ${quantidadeIDsContactgroup} -lt 1 ]
		then
			# Validando se o hostgroup foi encontrado
			echo -e "\nO contactgroup '${nomeContactgroup}' não foi encontrado!\n" && exit
		fi;
	fi;
	
	# Obtendo a lista de IDs dos serviços que estão associados ao host
	listaIDsServicos=`mysql -N -u root -e "SELECT service_id FROM nagios_services where host_id='${idHost}' ORDER BY  service_description" opcfg`
	
	# Validando se o host possui serviços associados
	quantidadeIDsServicos=`echo -e ${listaIDsServicos} | wc -w`
	if [ ${quantidadeIDsServicos} -lt 1 ]
	then
		# Validando se o hostgroup possui hosts associados
		echo -e "\nO Host '${nomeHost}' não possui serviços associados! \n" && exit
	fi;
	
	# Loop para exibição do nome de todos os host_groups
	for linha in ${listaIDsServicos}; do 
	
		# Coletando o nome do serviço
		nomeServico=`mysql -N -u root -e "SELECT service_description FROM nagios_services WHERE service_id='${linha}'" opcfg`
	
		# Chamando a função que remove o(s) contactgroup(s) do(s) serviço(s)
		removeContactgroupServico "${linha}" "${idContactgroup}" "${flagContactgroups}" 
		
		# Caso não tenha sido informado um contactgroup, serão limpos todos os contactgroupse será adicionado o opmon-admins
		if [ ${flagContactgroups} -gt 0 ]
		then
			echo -e "Removidos todos os contactgroups do serviço '${nomeServico}' do host '${nomeHost}'."
		else
			echo -e "Removido o contactgroup '${nomeContactgroup}' do '${nomeServico}' do host '${nomeHost}'."
		fi;
		
	done 
	
}

# adicionaContactgroupHost "${nomeHost}" "${idHost}" "${nomeContactgroup}"
adicionaContactgroupHost () {

	nomeHost=$1
	idHost=$2
	nomeContactgroup=$3
	
	
	# Validando se foi informado o nome do contacgroup	
	[ -z ${nomeContactgroup} ] && echo -e "\nNão foi informada nenhuma opção para o parâmetro '-c'!\n" && exit
	
	
	# Obtendo o ID  do contactgroup
	idContactgroup=`mysql -N -u root -e "SELECT contactgroup_id FROM nagios_contactgroups WHERE contactgroup_name='${nomeContactgroup}'" opcfg`
	quantidadeIDsContactgroup=`echo ${idContactgroup} | wc -w`
	if [ ${quantidadeIDsContactgroup} -lt 1 ]
	then
		# Validando se o hostgroup foi encontrado
		echo -e "\nO contactgroup '${nomeContactgroup}' não foi encontrado!\n" && exit
	fi;
	
	# Obtendo a lista de IDs dos serviços que estão associados ao host
	listaIDsServicos=`mysql -N -u root -e "SELECT service_id FROM nagios_services where host_id='${idHost}' ORDER BY service_description" opcfg`
	
	# Validando se o host possui serviços associados
	quantidadeIDsServicos=`echo -e ${listaIDsServicos} | wc -w`
	if [ ${quantidadeIDsServicos} -lt 1 ]
	then
		# Validando se o hostgroup possui hosts associados
		echo -e "\nO Host '${nomeHost}' não possui serviços associados! \n" && exit
	fi;
	
	# Loop para exibição do nome de todos os host_groups
	for linha in ${listaIDsServicos}; do 
	
		# Coletando o nome do serviço
		nomeServico=`mysql -N -u root -e "SELECT service_description FROM nagios_services WHERE service_id='${linha}'" opcfg`
	
		# Chamando a função que adiciona o contacgroup ao serviço.
		adicionaContactgroupServico "${linha}" "${idContactgroup}" 
		echo -e "Adicionado o contacgroup '${nomeContactgroup}' ao serviço '${nomeHost},${nomeServico}'."
		
	done 
}

# Remove o contactgroup de um serviço. Se o flag estiver sinalizado que não foi nenhum contacgroup, todos os contactgroups do serviço será removido.
removeContactgroupServico(){
	
	# Capturando os valores passados por parâmetro
	idServico=$1
	idContactgroup=$2
	flag=$3

	# Caso não tenha sido informado um contactgroup, serão limpos todos os contactgroupse será adicionado o opmon-admins
	if [ ${flag} -gt 0 ]
	then
		# Removendo todos os contactgroups relacionados ao host
		mysql -u root -e "DELETE FROM nagios_service_contactgroups WHERE service_id='${idServico}'" opcfg

		# Inserindo o contactgroup opmon-admins ao host
        mysql -N -u root -e "INSERT INTO nagios_service_contactgroups ( service_id, contactgroup_id ) VALUES ( ${idServico} , '1' )" opcfg
	
	# Se o contactgroup foi informado, o mesmo será removido
	else
		
		# Removendo o contactgroups informado do serviço.
		mysql -u root -e "DELETE FROM nagios_service_contactgroups WHERE contactgroup_id='${idContactgroup}' AND service_id='${idServico}'" opcfg

	fi;
}


# Função para remover contactgroup quando for utilizada a lista
adicionaContactgroupListaServicos () {

	idServico=$1
	nomeContactgroup=$2
	
	# Validando se foi informado o parâmetro do nome do contacgroup
	[ -z ${nomeContactgroup} ] && echo -e "\nNão foi informada nenhuma opção para o parâmetro '-c'!\n" && exit

	# Coletando o ID do contacgroup
	idContactgroup=`mysql -N -u root -e "SELECT contactgroup_id FROM nagios_contactgroups WHERE contactgroup_name='${nomeContactgroup}'" opcfg`
	[ -z ${idContactgroup} ] && echo -e "\nO contacgroup '${idContactgroup}' não foi encontrado! \n" && exit

	#Chamando a função que remove o(s) contactgroup(s) do(s) serviço(s)
	adicionaContactgroupServico "${idServico}" "${idContactgroup}"

}


# Função para adicionar o contactgroup ao serviço.
adicionaContactgroupServico () {
	
	idServico=$1
	idContactgroup=$2
	
	# Verificando se o serviço já está associado ao servicegroup antes de realizar a inserção
	validaContact=`mysql -N -u root -e "SELECT COUNT(*) FROM nagios_service_contactgroups WHERE service_id='${idServico}' AND contactgroup_id='${idContactgroup}'" opcfg`

	if [ ${validaContact} -eq 0 ]
	then
		mysql -N -u root -e "INSERT INTO nagios_service_contactgroups ( service_id, contactgroup_id ) VALUES ( ${idServico} , ${idContactgroup} )" opcfg
	fi;

}


# Função para adicionar o serviço ao servicegroup quando for utilizada a lista
adicionaServicegroupListaServicos () {

	idServico=$1
	nomeServicegroup=$2

	# Validando se foi informado o parâmetro do nome do contacgroup
	[ -z ${nomeServicegroup} ] && echo -e "\nNão foi informada nenhuma opção para o parâmetro '-c'!\n" && exit

	# Coletando o ID do contacgroup
	idServicegroup=`mysql -N -u root -e "SELECT servicegroup_id FROM nagios_servicegroups WHERE servicegroup_name='${nomeServicegroup}'" opcfg`
	[ -z ${idServicegroup} ] && echo -e "\nO servicegroup '${nomeServicegroup}' não foi encontrado! \n" && exit
	
	#Chamando a função que remove o(s) contactgroup(s) do(s) serviço(s)
	adicionaServicegroupServico "${idServico}" "${idServicegroup}"

}



# Função para adicionar o servicegroup ao serviço informado.
adicionaServicegroupServico () {
	
	idServico=$1
	idServicegroup=$2
	
	# Verificando se o serviço já está associado ao servicegroup antes de realizar a inserção
	validaContact=`mysql -N -u root -e "SELECT COUNT(*) FROM nagios_servicegroup_membership WHERE service_id='${idServico}' AND servicegroup_id='${idServicegroup}'" opcfg`

	# Se ainda não houver nenhum serviço contactgroup associado ao serviço.
	if [ ${validaContact} -eq 0 ]
	then
		mysql -N -u root -e "INSERT INTO nagios_servicegroup_membership ( service_id, servicegroup_id ) VALUES ( '${idServico}' , '${idServicegroup}' )" opcfg
	fi;

}



# Validando as opções selecionadas
[ -z ${TIPO} ] && echo -e "\nNão foi informada nenhuma opção para o parâmetro '-t'!\n" && exit
[ -z ${NOME} ] && echo -e "\nNão foi informada nenhuma opção para o parâmetro '-n'!\n" && exit

# Verificando qual opção informado
case ${TIPO} in
        host)					operacoesEmServicosHosts ${NOME} ${OPCAO} ${CONTACTGROUP} ;;
		lista)					operacoesEmLista ${NOME} ${OPCAO} ${CONTACTGROUP} ;;
		servicegroup)			operacoesEmServicegroups ${NOME} ${OPCAO} ${CONTACTGROUP} ;;
	    *)  			        echo -e "\nValor da opção '-t' desconhecida!\n" ;;
esac
