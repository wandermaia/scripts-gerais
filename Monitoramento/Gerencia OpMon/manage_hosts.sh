#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /root/scripts/manage_hosts.sh
# Sistema.............: OpMon
# Criado por..........: Wander Maia da Silva
# Data da Criação.....: 25/05/2018
# Descrição...........: Edita as propriedades de um hosts, uma lista de hosts ou hosts pertencentes à um hostgroups e serviços relacionados
# Entrada.............: Dados do host, lista de hosts ou hostgroups; operação que será realizada e time-period (quando aplicável).
#*****************************************************************************************************************************************************
# Data da Alteração...: 27/05/2018
# Motivo..............: Acréscimo da função para listar time-periods de lista de hosts em arquivo.
# Data da Alteração...: 28/05/2018
# Motivo..............: Acréscimo da função para editar time-periods de lista de hosts em arquivo. 
#						Acréscimo validação da existência da lista de servidores.
# Data da Alteração...: 29/05/2018
# Motivo..............: Acréscimo da função para listar os time-periods dos hosts de um hostgroup
#						Acréscimo da função para modificar os time-periods dos hosts de um hostgroup
# Data da Alteração...: 07/06/2018
# Motivo..............: Ajuste nas mensagens de informação aos usuários
# 						Correção do BUG relacionado a realização do export na alteração de time-period por hosgroup mesmo quando o hosgroup não possui membros.
#						Acréscimo da função para listar os contactgroups de um host, uma lista de hosts ou hostgroups
# Data da Alteração...: 08/06/2018
# Motivo..............: Acréscimo da função para remover os contactgroups de um host, uma lista de hosts ou hostgroups
# Data da Alteração...: 11/06/2018
# Motivo..............: Acréscimo da função para remover os contactgroups dos serviços de um host, uma lista de hosts ou hostgroups
#
#*****************************************************************************************************************************************************

# Menu de Ajuda
help () {

    cat <<EOF

Descrição do Script
        
  Script para editar as propriedades dos hosts, hostgroups e serviços relacionados.
 
Parâmetros

    -h  : Exibe este menu de ajuda
    -o  : Opção de modificação. Opções disponíveis:
		- lista_hostgroups_host: Lista todos os hostgroups associados com o host.
		- lista_hosts_hostgroup: Lista todos os hosts pertencentes a um hostgroup.
		- limpa_hostgroups_host: Remove todos os host_groups de um host.
		- limpa_hosts_hostgroup: Remove todos os hosts de um hostgroup
		- adiciona_hosts_hostgroup: Adiciona uma lista de hosts provenientes de arquivo a um hostgroup
		- lista_servicos: Lista todos os serviços do host.
		- lista_time_periods: Lista o time-period (do host, lista de hosts ou hostgoups, dependendo da opção -t) e serviços associados.
		- altera_time_periods: Altera o time-period (do host, lista de hosts ou hostgoups, dependendo da opção -t) e dos serviços associados.
		- lista_contactgroups: Lista contactgroups (do host, lista de hosts ou hostgoups, dependendo da opção -t).
		- remove_contactgroup: Remove o contactgroup passado por parâmetro (do host, lista de hosts ou hostgoups, dependendo da opção -t). Caso não seja informado um nome de contratgroups, será restaurado o padrão (opmonadmins).
		- remove_contactgroup_servicos: Remove o contactgroup passado por parâmetro (do host, lista de hosts ou hostgoups, dependendo da opção -t). Caso seja informado o nome contactgroups 'REMOVE_ALL', todos os contactgroups serão removidos e será restaurado o padrão (opmonadmins)
					
    -p  : Nome do Time-period
    -t  : Tipo de consulta: host, lista (arquivo com nome de vários hosts, um por linha) ou hostgroup
    -g  : Grupo de hosts. Este item é exclusivo para utilização com as opções relacionadas a hosgroup
    -n  : Nome do servidor, caminho do arquivo ou hostgroup (dependendo do tipo de execução escolhido)
 
Exemplos de Utilização
  
   Listar os hostgroups de um host:
   /root/scripts/manage_hosts.sh -o lista_hostgroups_host -n 'CentOS-6-PRD'
  
   Listar os hosts de um hostgroup:
   /root/scripts/manage_hosts.sh -o lista_hosts_hostgroup -n 'Virtualization'
  
   Remover todos os hostgroups de um host:
   /root/scripts/manage_hosts.sh -o limpa_hostgroups_host -n 'CentOS-6-PRD'
  
   Remover todos os hosts de um hostgroup:
   /root/scripts/manage_hosts.sh -o limpa_hosts_hostgroup -n 'Virtualization'
  
   Adicionar uma lista de hosts passada por parâmetro a um hostgroup:
   /root/scripts/manage_hosts.sh -o adiciona_hosts_hostgroup -n '/tmp/adiciona_hosts.txt' -g 'Virtualization'
  
   Listar os serviços de um host:
   /root/scripts/manage_hosts.sh -o lista_servicos -n 'CentOS-6-PRD'
  
   Listar os time-periods de um host e serviços associados:
   /root/scripts/manage_hosts.sh -o lista_time_periods -t host -n 'Centos-7-PRD'
  
   Listar os time-periods de uma lista de hosts utilizando um arquivo:
   /root/scripts/manage_hosts.sh -o lista_time_periods -t lista -n '/tmp/servidores.txt'
  
   Listar os time-periods dos hosts (e serviços) pertencentes a um hostgroup:
   /root/scripts/manage_hosts.sh -o lista_time_periods -t hostgroup -n 'PRD'
  
   Alterar o time-period de um host e serviços associados:
   /root/scripts/manage_hosts.sh -o altera_time_periods -t host -n 'CentOS-6-PRD' -p 24x7
  
   Alterar o time-period de uma lista de host utilizando um arquivo:
   /root/scripts/manage_hosts.sh -o altera_time_periods -t lista -n '/tmp/servidores.txt' -p workhours
  
   Alterar os time-periods dos hosts (e serviços) pertencentes a um hostgroup:
   /root/scripts/manage_hosts.sh -o altera_time_periods -t hostgroup -n 'HML' -p workhours\n"
  
   Listar os contactgroups de um host e serviços associados:
   /root/scripts/manage_hosts.sh -o lista_contactgroups -t host -n 'CentOS-6-PRD'

   Listar os contactgroups de uma lista de host (e serviços associados) utilizando um arquivo:
   /root/scripts/manage_hosts.sh -o lista_contactgroups -t lista -n '/tmp/servidores.txt'

   Listar os contactgroups dos hosts de um hostgroup:
   /root/scripts/manage_hosts.sh -o lista_contactgroups -t hostgroup -n 'HML'
  
   Remover o contactgroup 'Filiais' do host 'CentOS-6-PRD'
   /root/scripts/manage_hosts.sh -o remove_contactgroup -t host -n 'CentOS-6-PRD' -g 'Filiais'

   Remover todos os contactgroups do host 'CentOS-6-PRD'. Neste caso, será adicionado o contacgroup 'opmonadmins':
   /root/scripts/manage_hosts.sh -o remove_contactgroup -t host -n 'CentOS-6-PRD'

   Remover o contactgroup 'Filiais' de todos os hosts do hostgroup:
   /root/scripts/manage_hosts.sh -o remove_contactgroup -t hostgroup -n 'PRD' -g 'Filiais'

   Remover todos os contactgroups do hostgroup. Neste caso, será adicionado o contacgroup 'opmonadmins':
   /root/scripts/manage_hosts.sh -o remove_contactgroup -t hostgroup -n 'PRD' 
  
   Remover o contactgroup 'Filiais' dos serviços de um host:
   /root/scripts/manage_hosts.sh -o remove_contactgroup_servicos -t host -n 'CentOS-6-HML' -g 'Filiais' 

   Remover todos os contactgroups dos serviços de um host. Neste caso, será adicionado o contacgroup 'opmonadmins':
   /root/scripts/manage_hosts.sh -o remove_contactgroup_servicos -t host -n 'CentOS-6-HML' -g 'REMOVE_ALL' 
  
   Remover o contactgroup 'Filiais' dos serviços de uma lista de servidores:
   /root/scripts/manage_hosts.sh -o remove_contactgroup_servicos -t lista -n '/tmp/servidores.txt' -g 'Filiais' 

   Remover todos os contactgroups dos serviços de uma lista host. Neste caso, será adicionado o contacgroup 'opmonadmins':
   /root/scripts/manage_hosts.sh -o remove_contactgroup_servicos -t lista -n '/tmp/servidores.txt' -g 'REMOVE_ALL' 

   Remover o contactgroup 'Filiais' dos serviços de todos os hosts do hostgroup:
   /root/scripts/manage_hosts.sh -o remove_contactgroup_servicos -t hostgroup -n 'PRD' -g 'Filiais'

   Remover todos os contactgroups dos serviços dos hosts do hostgroup. Neste caso, será adicionado o contacgroup 'opmonadmins':
   /root/scripts/manage_hosts.sh -o remove_contactgroup_servicos -t hostgroup -n 'PRD' -g 'REMOVE_ALL' 
  
EOF

  exit
}


# Menu de validacao de entradas
while getopts ":o:g:p:n:t:hd" Option
do
  case $Option in
    o )
      OPCAO=$OPTARG
      ;;
    p )
      PERIOD=$OPTARG
      ;;
    n )
      NOME=$OPTARG
      ;;
    t )
      TIPO=$OPTARG
      ;;
    g )
      GROUP=$OPTARG
      ;;
    h )
      help
      ;;
  esac
done


# Função que executa o export das configurações.
EXECUTA_EXPORT(){
	
	# Realizando o export das novas configurações
	echo -e "\nInciando o export: \n"
	/usr/local/opmon/utils/opmon-export.php
	echo -e "\nExport Finalizado!\n"
	
}


# Função que remove todos os hostgroups de um host.
REMOVER_HOSTGROUPS() {
	
	# Capturando o hostname enviado por Parâmetro
	NOME_HOST=$1
	
	# Obtendo o ID  do host
	ID_HOST=`mysql -N -u root -e "SELECT host_id FROM nagios_hosts where host_name='${NOME_HOST}'" opcfg `

	# Validando se o host foi encontrado
	[ -z ${ID_HOST} ] && echo -e "\nO host '${NOME_HOST}' não foi encontrado!! \n" && exit
	
	# Mensagem para o usuário
	echo -e "\nRemovendo todos os hostgroups do host '${NOME_HOST}' ... \n"
	
	# Removendo os hostsgroups do servidor utilizando o ID coletado na consulta anterior
	mysql -u root -e "DELETE FROM nagios_hostgroup_membership WHERE host_id='${ID_HOST}'" opcfg
	
	# Mensagens para o usuário:
	echo -e "Todos os Hostgroups do host '${NOME_HOST}' removidos conforme o solicitado.\n"

 }


 # Função que remove todos os hosts de um hostgroup.
REMOVER_HOSTS_HOSTGROUP() {
	
	# Capturando o host_group enviado por Parâmetro
	NOME_HOST=$1
	
	# Obtendo o ID  do hostgroup
	ID_HOSTGROUP=`mysql -N -u root -e "SELECT hostgroup_id FROM nagios_hostgroups where hostgroup_name='${NOME_HOST}'" opcfg `

	# Validando se o host foi encontrado
	[ -z ${ID_HOSTGROUP} ] && echo -e "\nO hostgroup '${NOME_HOST}' não foi encontrado! \n"  && exit
	
	# Mensagem para o usuário
	echo -e "\nRemovendo todos os hosts do hostgroup ${NOME_HOST} ... \n"
	
	# Removendo os hostsgroups do servidor utilizando o ID coletado na consulta anterior
	mysql -u root -e "DELETE FROM nagios_hostgroup_membership WHERE hostgroup_id='${ID_HOSTGROUP}'" opcfg
	
	# Mensagens para o usuário:
	echo -e "Todos os hosts do hostgroup ${NOME_HOST} foram removidos.\n"
 }


# Lista todos os hostgroups do host
LIST_HOSTGROUPS_HOST() {
	
	# Capturando o hostname enviado por Parâmetro
	NOME_HOST=$1
	
	# Obtendo o ID  do host
	ID_HOST=`mysql -N -u root -e "SELECT host_id FROM nagios_hosts where host_name='${NOME_HOST}'" opcfg `

	# Validando se o host foi encontrado
	[ -z ${ID_HOST} ] && echo -e "\nO host ${NOME_HOST} não foi encontrado! \n" && exit
	
	# Obtendo a lista de nomes e IDs hostgroups na qual o host faz parte
	LISTA_IDS_HOSTGROUPS=`mysql -N -u root -e "SELECT hostgroup_id FROM nagios_hostgroup_membership where host_id='${ID_HOST}'" opcfg`
	
	# Estes comandos são utilizados para verificação se o host faz parte de mais de pelo menos um hostgroup
	QUANTIDADE_HOSTGROUPS=`echo -e "${LISTA_IDS_HOSTGROUPS}" | wc -l`
	if [ ${QUANTIDADE_HOSTGROUPS} -lt 2 ]
	then
        # Validando se o host não pertence a nenhum hostgroup
		[ -z ${LISTA_IDS_HOSTGROUPS} ] && echo -e "\nEste host não faz parte de nenhum hostgroup. \n" && exit
	fi;
	
	# Mensagem para o usuário
	echo -e "\nLista de Hostgroups do Host ${NOME_HOST}:\n"
	
	# Loop para exibição do nome de todos os host_groups
	for LINHA in ${LISTA_IDS_HOSTGROUPS}; do 
		
		# Coletando o nome do host_group
		LISTA_HOSTNAME_HOSTGROUP=`mysql -N -u root -e "SELECT hostgroup_name FROM nagios_hostgroups WHERE hostgroup_id='${LINHA}'" opcfg`

		# Exibindo o hostgroup na tela
		echo "${LISTA_HOSTNAME_HOSTGROUP}" ; 
	done 	
	
	# Apenas para melhorar a formatação de apresentação para o usuário
	echo ""
}


# Função para listar todos os hosts pertencentes a um hostgroup
LIST_HOSTS_HOSTGROUP() {
	
	# Capturando o hostname enviado por Parâmetro
	NOME_HOSTGROUP=$1
	
        # Obtendo o ID  do hostgroup
	ID_HOSTGROUP=`mysql -N -u root -e "SELECT hostgroup_id FROM nagios_hostgroups where hostgroup_name='${NOME_HOSTGROUP}'" opcfg `

	# Validando se o hostgroup foi encontrado
	[ -z ${ID_HOSTGROUP} ] && echo -e "\nO hostgroup '${NOME_HOSTGROUP}' não foi encontrado! \n" && exit
	
	
	# Obtendo a lista de IDs hosts que pertencem ao hostgroup
	LISTA_IDS_HOSTS=`mysql -N -u root -e "SELECT host_id FROM nagios_hostgroup_membership where hostgroup_id='${ID_HOSTGROUP}'" opcfg`
	
	# Estes comandos são utilizados para verificação se o hostgroup tem pelo menos um host
	QUANTIDADE_HOSTS=`echo -e "${LISTA_IDS_HOSTS}" | wc -l`
	if [ ${QUANTIDADE_HOSTS} -lt 2 ]
	then
        # Validando se o hostgroup não tem hosts associados
		[ -z ${LISTA_IDS_HOSTS} ] && echo -e "\nNão existem hosts associados a este Hostgroup! \n" && exit
	fi;
	
	# Mensagem para o usuário
	echo -e "\nLista de Hosts pertencentes ao hostgroup '${NOME_HOSTGROUP}':\n"
	 
	# Loop para exibição do nome de todos os host_groups
	for LINHA in ${LISTA_IDS_HOSTS}; do 
		
		# Coletando o nome do host
		COLETA_HOSTNAME=`mysql -N -u root -e "SELECT host_name FROM nagios_hosts where host_id='${LINHA}'" opcfg`
                
		# Exibindo o hostgroup na tela
		echo "${COLETA_HOSTNAME}" ; 
	done 	
	
	# Apenas para melhorar a formatação de apresentação para o usuário
	echo ""
}


# Função para adicionar uma lista de servidores a um hostgroup
ADICIONA_HOSTS_HOSTGROUP(){

    # Capturando o hostname e o time-period enviados por Parâmetros
	ARQUIVO_HOSTS=$1
	NOME_HOSTGROUP=$2
	
	# validando se a lista de hosts existe.
	[ ! -e ${ARQUIVO_HOSTS} ] && echo -e "\nO arquivo '${ARQUIVO_HOSTS}' não foi encontrado!\n" && exit
        
        # Obtendo o ID  do hostgroup
	ID_HOSTGROUP=`mysql -N -u root -e "SELECT hostgroup_id FROM nagios_hostgroups where hostgroup_name='${NOME_HOSTGROUP}'" opcfg `

	# Validando se o hostgroup foi encontrado
	[ -z ${ID_HOSTGROUP} ] && echo -e "\nHostgroup não encontrado! \n" && exit
        
        # Mensagem para o usuário
        echo -e "\n\n *** ->> Adicionando os hosts do arquivo '${ARQUIVO_HOSTS}' ao hosgroup '${NOME_HOSTGROUP}' <<- ***\n\n"
        
	# Loop para inserir todos os hosts no hosgroup
	while read LINE
	do
		# Obtendo o ID  do host
		ID_HOST=`mysql -N -u root -e "SELECT host_id FROM nagios_hosts where host_name='${LINE}'" opcfg `

		# Validando se o host foi encontrado
		if [ -z ${ID_HOST} ] 
		then
            echo -e "\nO Host '${LINE}' não foi encontrado! \n"
			
        # Se o host foi encontrado, então o procedimento continua
		else
			
			# Validando se o host já pertence ao hostgroup
			VALIDA_HOST=`mysql -N -u root -e "SELECT count(*) FROM nagios_hostgroup_membership WHERE hostgroup_id='${ID_HOSTGROUP}' AND host_id='${ID_HOST}'" opcfg`
			
			# Se não foi encontrado o host no hosgroup
			if [ ${VALIDA_HOST} -eq 0 ] 
			then
                            
                # Mensagem para o usuário
                echo -e "Adicionando o host '${LINE}' ao hostgroup '${NOME_HOSTGROUP}'"
                
                # Inserindo o servidor no hostgroup
                mysql -N -u root -e "INSERT INTO nagios_hostgroup_membership ( hostgroup_id, host_id ) VALUES ( ${ID_HOSTGROUP} , ${ID_HOST} )" opcfg

			# Se o host já fizer parte do hostgroup
			else

                # Informando ao usuário que o host já faz parte do hostgroup
                echo -e "\nO Host '${LINE}' já faz parte do hostgroup '${NOME_HOSTGROUP}'! \n"

             fi
		fi
			
	# Direcionando o arquivo passado por parâmetro para ser utilizado no loop
	done < ${ARQUIVO_HOSTS}
}


# Lista todos os serviços do host
LIST_SERVICES() {
	
	# Capturando o hostname enviado por Parâmetro
	NOME_HOST=$1
	
	# Obtendo o ID  do host
	ID_HOST=`mysql -N -u root -e "SELECT host_id FROM nagios_hosts where host_name='${NOME_HOST}'" opcfg `

	# Validando se o host foi encontrado
	[ -z ${ID_HOST} ] && echo -e "\nO host '${NOME_HOST}' não foi encontrado! \n" && exit
	
	# Obtendo a lista de IDs dos serviços que estão associados ao host
	LISTA_IDS_SERVICES=`mysql -N -u root -e "SELECT service_id FROM nagios_services where host_id='${ID_HOST}'" opcfg`
	
	# Mensagem para o usuário
	echo -e "\nLista de serviços do Host ${NOME_HOST}:\n"
	
	# Loop para exibição do nome de todos os serviços
	for LINHA in ${LISTA_IDS_SERVICES}; do 
		
		# Coletando o nome do serviço
		LISTA_SERVICE_NAME=`mysql -N -u root -e "SELECT service_description FROM nagios_services WHERE service_id='${LINHA}'" opcfg`

		# Exibindo o nome do serviço na tela
		echo "${LISTA_SERVICE_NAME}" ; 
	done 	
	
	# Apenas para melhorar a formatação de apresentação para o usuário
	echo ""
}


# Função para listar os serviços de um host ou lista de hosts (a partir de um arquivo).
LISTA_TIME_PERIODS() {
	
	# Capturando o hostname (ou lista dependendo da opção selecionada) e definido o tipo de execução solicitada
	NOME=$1
	TIPO_EXECUCAO=$2
	
	# Verificando se foi passado algum tipo de consulta
	[ -z ${TIPO_EXECUCAO} ] && echo -e "\nNenhum Tipo de consulta definida!\n" && exit
	
	# Verificando se o tipo escolhido foi host
	if [ ${TIPO_EXECUCAO} = "host" ]
	then
        
		# Obtendo o ID  do host
		ID_HOST=`mysql -N -u root -e "SELECT host_id FROM nagios_hosts where host_name='${NOME}'" opcfg `

		# Validando se o host foi encontrado
		[ -z ${ID_HOST} ] && echo -e "\nO Host '${NOME}' não foi encontrado!\n" && exit
		
		# Executando a função que lista os dados do host
		LISTA_TIME_PERIODS_HOST ${NOME} ${ID_HOST}
        exit;
		
	# Verificando se o tipo escolhido foi lista de hosts
	elif [ ${TIPO_EXECUCAO} = "lista" ]
	then

		# validando se a lista existe.
		[ ! -e ${NOME} ] && echo -e "\nO arquivo '${NOME}' não foi encontrado! \n" && exit
		
		# Loop para verificar todos os hosts do arquivo
		while read LINE
		do
			# Obtendo o ID  do host
			ID_HOST=`mysql -N -u root -e "SELECT host_id FROM nagios_hosts where host_name='${LINE}'" opcfg `

			# Validando se o host foi encontrado
			if [ -z ${ID_HOST} ] 
			then
				echo -e "\nO Host '${LINE}' não foi encontrado!\n"
			
			# Se o host foi encontrado, então a função é invocada
			else
				# Executando a função 
				LISTA_TIME_PERIODS_HOST ${LINE} ${ID_HOST}
			fi
			
		# Direcionando o arquivo passado por parâmetro para ser utilizado no loop	
		done < ${NOME}
		
        exit;
		
	# Verificando se o tipo escolhido foi hostgroups
	elif [ ${TIPO_EXECUCAO} = "hostgroup" ]
	then
		
		# Obtendo o ID  do hostgroup
		ID_HOSTGROUP=`mysql -N -u root -e "SELECT hostgroup_id FROM nagios_hostgroups WHERE hostgroup_name='${NOME}'" opcfg `
		
		# Validando se o host foi encontrado
		[ -z ${ID_HOSTGROUP} ] && echo -e "\nO Hostgroup '${NOME}' não foi encontrado! \n" && exit
		
		# Obtendo a lista de IDs dos hosts que estão associados ao hostgrops
		LISTA_IDS_HOSTS=`mysql -N -u root -e "SELECT host_id FROM nagios_hostgroup_membership WHERE hostgroup_id='${ID_HOSTGROUP}'" opcfg`
		
		# Validando se exitem hosts associados ao hosgroup informado
		[ -z ${LISTA_IDS_HOSTS} ] && echo -e "\nO Hostgroup '${NOME}' não possui hosts associados! \n" && exit
		
		# Listando os time-periods da lista obtida na consulta anterior
		for LINHA in ${LISTA_IDS_HOSTS}; do 
		
			# Coletando o nome do serviço
			COLETA_HOSTNAME=`mysql -N -u root -e "SELECT host_name FROM nagios_hosts WHERE host_id='${LINHA}'" opcfg`
			
			# Executando a função listar o host
			LISTA_TIME_PERIODS_HOST ${COLETA_HOSTNAME} ${LINHA}
		done 	

	# A opção não foi definida corretamente
	else
        echo -e "\nValor da opção '-t' desconhecido!\n"
        exit; 
	fi
}


# Lista todos os time-periods de um único host e serviços associados
LISTA_TIME_PERIODS_HOST() {
	
	# Capturando o hostname e o time-period enviados por Parâmetros
	NOME_HOST=$1
	ID_HOST=$2

	# Verificando o time-period do host
	ID_TIME_PERIOD_HOST=`mysql -N -u root -e "SELECT check_period FROM nagios_hosts where host_id='${ID_HOST}'" opcfg `
	NOME_TIME_PERIOD_HOST=`mysql -N -u root -e "SELECT timeperiod_name FROM nagios_timeperiods WHERE timeperiod_id='${ID_TIME_PERIOD_HOST}'" opcfg`
	
	# Informação do host 
	echo -e "\n\n *** ->> Time-period do Host <<- ***\n"
	echo -e "${NOME_HOST}: ${NOME_TIME_PERIOD_HOST}\n"

	# Obtendo a lista de IDs dos serviços que estão associados ao host
	LISTA_IDS_SERVICES=`mysql -N -u root -e "SELECT service_id FROM nagios_services where host_id='${ID_HOST}'" opcfg`
	
	# Mensagem para o usuário
	echo -e " *** ->> Time-period dos Serviços do Host ${NOME_HOST}: <<- ***\n"
	
	# Loop para exibição do nome de todos os serivços
	for LINHA in ${LISTA_IDS_SERVICES}; do 
		
		# Coletando o nome do serviço
		LISTA_SERVICE_NAME=`mysql -N -u root -e "SELECT service_description FROM nagios_services WHERE service_id='${LINHA}'" opcfg`
		ID_TIME_PERIOD_SERVICE=`mysql -N -u root -e "SELECT check_period FROM nagios_services WHERE service_id='${LINHA}'" opcfg`
		NOME_TIME_PERIOD=`mysql -N -u root -e "SELECT timeperiod_name FROM nagios_timeperiods WHERE timeperiod_id='${ID_TIME_PERIOD_SERVICE}'" opcfg`

		# Exibindo o nome do serviço na tela
		echo "${LISTA_SERVICE_NAME}: ${NOME_TIME_PERIOD}"; 
	done 	
	
	# Apenas para melhorar a formatação de apresentação para o usuário
	echo -e "\n"

}


# Função para alterar os timeperiods de um host ou lista de hosts (a partir de um arquivo) e serviços associados.
ALTERA_TIME_PERIODS() {
	
	# Capturando o hostname (ou lista dependendo da opção selecionada) e definido o tipo de execução solicitada
	NOME=$1
	NOME_TIME_PERIOD=$2
	TIPO_EXECUCAO=$3
	
	# Validando se o tipo de consulta foi definida
	[ -z ${TIPO_EXECUCAO} ] && echo -e "\nNenhum Tipo de consulta definida! \n" && exit

	# Obtendo o ID  do time-period
	ID_TIME_PERIOD=`mysql -N -u root -e "SELECT timeperiod_id FROM nagios_timeperiods WHERE timeperiod_name='${NOME_TIME_PERIOD}'" opcfg`
	
	# Validando se o time-period foi encontrado
	[ -z ${ID_TIME_PERIOD} ] && echo -e "\nO time-period '${NOME_TIME_PERIOD}' não foi encontrado! \n" && exit

	# Alterando se o tipo escolhido foi host
	if [ ${TIPO_EXECUCAO} = "host" ]
	then
        
		# Obtendo o ID  do host
		ID_HOST=`mysql -N -u root -e "SELECT host_id FROM nagios_hosts where host_name='${NOME}'" opcfg `

		# Validando se o host foi encontrado
		[ -z ${ID_HOST} ] && echo -e "\nO host '${NOME}' não encontrado! \n" && exit
		
		# Mensagem para o usuário
		echo -e "\n\n *** ->> Host '${NOME}' <<- ***\n\n"
		
		# Executando a função que lista os dados do host
		ALTERA_TIME_PERIODS_HOST ${ID_HOST} ${ID_TIME_PERIOD}
		
		
	# Alterando se o tipo escolhido foi lista de hosts
	elif [ ${TIPO_EXECUCAO} = "lista" ]
	then

		# validando se a lista existe.
		[ ! -e ${NOME} ] && echo -e "\nO arquivo '${NOME}' não foi encontrado! \n" && exit
		
		# Loop para verificar todos os hosts do arquivo
		while read LINE
		do
			# Obtendo o ID  do host
			ID_HOST=`mysql -N -u root -e "SELECT host_id FROM nagios_hosts where host_name='${LINE}'" opcfg `

			# Validando se o host foi encontrado
			if [ -z ${ID_HOST} ] 
			then
				echo -e "\n\n *** ->> O Host '${LINE}' não foi encontrado! <<- ***\n\n"
			
			# Se o host foi encontrado, então a função é invocada
			else
			
				# Mensagem para o usuário
				echo -e "\n\n *** ->> Host '${LINE}' <<- ***\n\n"
				
				# Executando a função 
				ALTERA_TIME_PERIODS_HOST ${ID_HOST} ${ID_TIME_PERIOD}
			fi
			
		# Direcionando o arquivo passado por parâmetro para ser utilizado no loop	
		done < ${NOME}
		
	# Alterando se o tipo escolhido foi lista de hosts
	elif [ ${TIPO_EXECUCAO} = "hostgroup" ]
	then
		
		# Obtendo o ID  do host
		ID_HOSTGROUP=`mysql -N -u root -e "SELECT hostgroup_id FROM nagios_hostgroups WHERE hostgroup_name='${NOME}'" opcfg `
		
		# Validando se o host foi encontrado
		[ -z ${ID_HOSTGROUP} ] && echo -e "\nO Hostgroup '${NOME}' não foi encontrado!  \n" && exit
		
		# Obtendo a lista de IDs dos hosts que estão associados ao hostgrops
		LISTA_IDS_HOSTS=`mysql -N -u root -e "SELECT host_id FROM nagios_hostgroup_membership WHERE hostgroup_id='${ID_HOSTGROUP}'" opcfg`
		
		# Validando se exitem hosts associados ao hosgroup informado
		[ -z ${LISTA_IDS_HOSTS} ] && echo -e "\nO Hostgroup '${NOME}' não possui hosts associados! \n" && exit		
		
		# Listando os time-periods da lista obtida na consulta anterior
		for LINHA in ${LISTA_IDS_HOSTS}; do 
		
			# Coletando o nome do serviço
			COLETA_HOST_NAME=`mysql -N -u root -e "SELECT host_name FROM nagios_hosts WHERE host_id='${LINHA}'" opcfg`
			
			# Mensagem para o usuário
			echo -e "\n\n *** ->> Host '${COLETA_HOST_NAME}' <<- ***\n\n"
				
			# Executando a função para alterar o time-period do host
			ALTERA_TIME_PERIODS_HOST ${LINHA} ${ID_TIME_PERIOD}
			
		done 

	# A opção não foi definida corretamente
	else
        echo -e "\nValor da opção '-t' desconhecido!\n"
        exit; 
	fi
}


# Função que altera o time-period de um host e todos os serviços relacionados.
ALTERA_TIME_PERIODS_HOST() {
	
	# Capturando o hostname e o time-period enviados por Parâmetros
	ID_HOST=$1
	ID_TIME_PERIOD=$2
	
	# Mensagem para o usuário
	echo -e "Modificando o time-period do host ...\n"

	# Alterando time-period do Host
	mysql -N -u root -e "UPDATE nagios_hosts SET check_period='${ID_TIME_PERIOD}' WHERE host_id='${ID_HOST}'" opcfg 

	# Obtendo a lista de IDs dos serviços que estão associados ao host
	LISTA_IDS_SERVICES=`mysql -N -u root -e "SELECT service_id FROM nagios_services where host_id='${ID_HOST}'" opcfg`
	
	# Mensagem para o usuário
	echo -e "Modificando os time-periods dos Serviços ...\n"

	# Loop para exibição do nome de todos os serivços
	for LINHA in ${LISTA_IDS_SERVICES}; do 
		
		# Exibindo o nome do serviço para o usuário
		SERVICO=`mysql -N -u root -e "SELECT service_description FROM nagios_services WHERE service_id='${LINHA}'" opcfg`
		echo ${SERVICO}
		
		# Modificando o time-period do serviço
		mysql -N -u root -e "UPDATE nagios_services SET check_period='${ID_TIME_PERIOD}' WHERE service_id='${LINHA}'" opcfg 

	done 	

}


# Função para listar os contactgroups de um host,lista de hosts (a partir de um arquivo) ou hostgrop.
LISTA_CONTACTGROUP() {
	
	# Capturando o hostname (ou lista dependendo da opção selecionada) e definido o tipo de execução solicitada
	NOME=$1
	TIPO_EXECUCAO=$2
	
	# Verificando se foi passado algum tipo de consulta
	[ -z ${TIPO_EXECUCAO} ] && echo -e "\nNenhum Tipo de consulta definida! \n" && exit
	
	# Verificando se o tipo escolhido foi host
	if [ ${TIPO_EXECUCAO} = "host" ]
	then
        
		# Obtendo o ID  do host nagios_contactgroups
		ID_HOST=`mysql -N -u root -e "SELECT host_id FROM nagios_hosts where host_name='${NOME}'" opcfg `

		# Validando se o host foi encontrado
		[ -z ${ID_HOST} ] && echo -e "\nO Host '${NOME}' não foi encontrado! \n" && exit
		
		# Executando a função que lista os contactgroups de um host
		LISTA_CONTACTGROUPS_HOST ${NOME} ${ID_HOST}
        exit;
		
	# Verificando se o tipo escolhido foi lista de hosts
	elif [ ${TIPO_EXECUCAO} = "lista" ]
	then

		# validando se a lista existe.
		[ ! -e ${NOME} ] && echo -e "\nO arquivo '${NOME}' não foi encontrado! \n" && exit
		
		# Loop para verificar todos os hosts do arquivo
		while read LINE
		do
			# Obtendo o ID  do host
			ID_HOST=`mysql -N -u root -e "SELECT host_id FROM nagios_hosts where host_name='${LINE}'" opcfg `

			# Validando se o host foi encontrado
			if [ -z ${ID_HOST} ] 
			then
				echo -e "\nO Host '${LINE}' não foi encontrado! \n"
			
			# Se o host foi encontrado, então a função é invocada
			else
				# Executando a função 
				LISTA_CONTACTGROUPS_HOST ${LINE} ${ID_HOST}
			fi
			
		# Direcionando o arquivo passado por parâmetro para ser utilizado no loop	
		done < ${NOME}
		
        exit;
		
	# Verificando se o tipo escolhido foi hostgroups
	elif [ ${TIPO_EXECUCAO} = "hostgroup" ]
	then

		# Obtendo o ID  do hostgroup
		ID_HOSTGROUP=`mysql -N -u root -e "SELECT hostgroup_id FROM nagios_hostgroups where hostgroup_name='${NOME}'" opcfg`

		# Verificando se a quantidade de IDs encontrados
		VALIDA_ID_HOSTGROUP=`echo ${ID_HOSTGROUP} | wc -w`
		
		# Validando se o hostgroup foi encontrado
		if [ ${VALIDA_ID_HOSTGROUP} -lt 1 ]
		then
			# Validando se o hostgroup foi encontrado
			echo -e "\n'${NOME}' não foi encontrado! \n" && exit
		fi;
		
		# Obtendo a lista de IDs dos hosts que estão associados ao hostgrops
		LISTA_IDS_HOSTS=`mysql -N -u root -e "SELECT host_id FROM nagios_hostgroup_membership WHERE hostgroup_id='${ID_HOSTGROUP}'" opcfg`
		
		# Identificando a quantidade de hosts no hosgroup
		QUANTIDADE_ID_HOSTS=`echo -e ${LISTA_IDS_HOSTS} | wc -w`
		
		# Validando o valor retornado
		if [ ${QUANTIDADE_ID_HOSTS} -lt 1 ]
		then
			# Validando se o hostgroup possui hosts associados
			echo -e "\nO Hostgroup '${NOME}' não possui hosts associados!" && exit
		fi;
		
		# Listando os time-periods da lista obtida na consulta anterior
		for LINHA in ${LISTA_IDS_HOSTS}; do 
		
			# Coletando o nome do serviço
			COLETA_HOSTNAME=`mysql -N -u root -e "SELECT host_name FROM nagios_hosts WHERE host_id='${LINHA}'" opcfg`
			
			# Executando a função listar o host
			LISTA_CONTACTGROUPS_HOST ${COLETA_HOSTNAME} ${LINHA}
		done 	

	# A opção não foi definida corretamente
	else
        echo -e "\nValor da opção '-t' desconhecido!\n"
        exit; 
	fi
}


# Lista todos os time-periods de um único host e serviços associados
LISTA_CONTACTGROUPS_HOST() {
	
	# Capturando o hostname e o time-period enviados por Parâmetros
	NOME_HOST=$1
	ID_HOST=$2

	# Obtendo a lista de nomes e IDs hostgroups na qual o host faz parte
	LISTA_IDS_CONTACTGROUPS=`mysql -N -u root -e "SELECT contactgroup_id FROM nagios_host_contactgroups WHERE host_id='${ID_HOST}'" opcfg`
	
	echo -e "\n\n *** ->> Host '${NOME_HOST}' <<- ***\n\n"
	echo -e "\nContactgroups do Host:\n"
	
	# Loop para exibição do nome de todos os host_groups
	for LINHA in ${LISTA_IDS_CONTACTGROUPS}; do 
		
		# Coletando o nome do contactgroup
		NOME_CONTACTGROUP=`mysql -N -u root -e "SELECT contactgroup_name FROM nagios_contactgroups WHERE contactgroup_id='${LINHA}'" opcfg`

		# Exibindo o contactgroup na tela
		echo "${NOME_CONTACTGROUP}" ; 
	done 
		
	echo -e "\nContactgroups dos serviços: \n"
	
	# Executando a função que lista os contactgroups dos serviços do host associado.
	LISTA_CONTACTGROUPS_SERVICES ${NOME_HOST} ${ID_HOST}

}


# Função que Lista todos os contactgroups de todos os serviços associados a um host
LISTA_CONTACTGROUPS_SERVICES() {
	
	# Capturando o hostname e o time-period enviados por Parâmetros
	NOME_HOST=$1
	ID_HOST=$2

	# Obtendo a lista de IDs dos serviços que estão associados ao host
	LISTA_IDS_SERVICES=`mysql -N -u root -e "SELECT service_id FROM nagios_services where host_id='${ID_HOST}' ORDER BY  service_description" opcfg`

	# Loop para exibição do nome de todos os host_groups
	for LINHA in ${LISTA_IDS_SERVICES}; do 
		
		# Coletando o nome do serviço
		SERVICE_NAME=`mysql -N -u root -e "SELECT service_description FROM nagios_services WHERE service_id='${LINHA}'" opcfg`

		# Exibindo o nome do serviço na tela
		echo -e "${SERVICE_NAME}:"
		
		# Chamando a função que lista os contactgroups do serviço
		CONTACTGROUPS_SERVICE "${SERVICE_NAME}" "${LINHA}"
	done 	

}


# Função que lista todos os contactgroups de um serviço
CONTACTGROUPS_SERVICE() {
	
	# Capturando o nome e o id do serviço passados por parâmetros
	NOME_SERVICO=$1
	ID_SERVICO=$2
	
	# Obtendo a lista de nomes e IDs hostgroups na qual o host faz parte
	LISTA_IDS_CONTACTGROUPS_SERVICOS=`mysql -N -u root -e "SELECT contactgroup_id FROM nagios_service_contactgroups WHERE service_id='${ID_SERVICO}'" opcfg`
	
	# Verificando a quantidade de contactgroups associados ao seviço
	QUANTIDADE_IDS=`echo ${LISTA_IDS_CONTACTGROUPS_SERVICOS} | wc -w`

	# Validando se existem contactgroups associados
	if [ ${QUANTIDADE_IDS} -gt 0 ] 
	then
	
		# Loop para exibição do nome de todos os host_groups
		for LINHA in ${LISTA_IDS_CONTACTGROUPS_SERVICOS}; do 
		
			# Coletando o nome do contactgroup
			NOME_CONTACTGROUP_SERVICO=`mysql -N -u root -e "SELECT contactgroup_name FROM nagios_contactgroups WHERE contactgroup_id='${LINHA}'" opcfg`

			# Exibindo o contactgroup na tela
			echo "${NOME_CONTACTGROUP_SERVICO}" ; 
			
		done 	
	else
		
		# Informando ao usuário que o serviço não tem contactgroup associado.
		echo -e "Nenhum contactgroup associado."
		
	fi
	
	# Apenas para melhorar a formatação de apresentação para o usuário
	echo ""
}

# Modifica as checagens de um host, lista de hosts ou hosgroup
REMOVE_CONTACTGROUPS (){

	# Recebendo os parâmetros enviados por parâmetro
	NOME=$1
	TIPO_EXECUCAO=$2
	NOME_CONTACTGROUP=$3
	
	# Variáveis globais
	ID_CONTACTGROUP=""
	
	
	# Validando se foi informado algum contactgroup group
	FLAG_CONTACTGROUPS=`echo ${NOME_CONTACTGROUP} | wc -w`
	
	# Obtendo o ID do contactgroup, caso tenha sido informado um nome
	if [ ${FLAG_CONTACTGROUPS} -gt 0 ]
	then
		# Obtendo o ID  do contactgroup
		ID_CONTACTGROUP=`mysql -N -u root -e "SELECT contactgroup_id FROM nagios_contactgroups WHERE contactgroup_name='${NOME_CONTACTGROUP}'" opcfg`
		
		# Validando se o contactgroup foi encontrado
		QUANTIDADE_IDS_CONTACTGROUP=`echo ${ID_CONTACTGROUP} | wc -w`
		
		# Informando ao usuário se o contactgroup não foi encontrado.
		if [ ${QUANTIDADE_IDS_CONTACTGROUP} -lt 1 ]
		then
			# Validando se o contactgroup foi encontrado
			echo -e "\nO contactgroup ${NOME_CONTACTGROUP} não foi encontrado!\n" && exit
		fi;
	fi;
	
	
	# Validando o tipo de consulta que deve ser realizada
	if [ ${TIPO_EXECUCAO} = "host" ]
	then
		
		# Obtendo o ID  do host nagios_contactgroups
		ID_HOST=`mysql -N -u root -e "SELECT host_id FROM nagios_hosts WHERE host_name='${NOME}'" opcfg `
		
		# Validando se o host foi encontrado
		[ -z ${ID_HOST} ] && echo -e "\nO Host '${NOME}' não foi encontrado! \n" && exit
		
		# Executando a função que lista os contactgroups de um host
		REMOVE_CONTACTGROUPS_HOST ${NOME} ${ID_HOST} ${FLAG_CONTACTGROUPS} ${ID_CONTACTGROUP}

		
	# Verificando se o tipo escolhido foi lista de hosts
	elif [ ${TIPO_EXECUCAO} = "lista" ]
	then
		
		# validando se a lista existe.
		[ ! -e ${NOME} ] && echo -e "\nO arquivo '${NOME}' não foi encontrado! \n" && exit
		
		# Loop para verificar todos os hosts do arquivo
		while read LINE
		do
			# Obtendo o ID  do host
			ID_HOST=`mysql -N -u root -e "SELECT host_id FROM nagios_hosts where host_name='${LINE}'" opcfg `

			# Validando se o host foi encontrado
			if [ -z ${ID_HOST} ] 
			then
				echo -e "\nO Host '${LINE}' não foi encontrado!\n"
			
			# Se o host foi encontrado, então a função é invocada
			else
				# Executando a função de remção de contacgroup do host
				REMOVE_CONTACTGROUPS_HOST ${LINE} ${ID_HOST} ${FLAG_CONTACTGROUPS} ${ID_CONTACTGROUP}
				
			fi
			
		# Direcionando o arquivo passado por parâmetro para ser utilizado no loop	
		done < ${NOME}
	
	# Verificando se o tipo escolhido foi hostgroups
	elif [ ${TIPO_EXECUCAO} = "hostgroup" ]
	then
	
		# Obtendo o ID  do hostgroup
		ID_HOSTGROUP=`mysql -N -u root -e "SELECT hostgroup_id FROM nagios_hostgroups where hostgroup_name='${NOME}'" opcfg`

		# Verificando se a quantidade de IDs encontrados
		VALIDA_ID_HOSTGROUP=`echo ${ID_HOSTGROUP} | wc -w`
		
		# Validando se o hostgroup foi encontrado
		if [ ${VALIDA_ID_HOSTGROUP} -lt 1 ]
		then
			# Validando se o hostgroup foi encontrado
			echo -e "\nO hostgroup '${NOME}' não foi encontrado! \n" && exit
		fi;
		
		# Obtendo a lista de IDs dos hosts que estão associados ao hostgrops
		LISTA_IDS_HOSTS=`mysql -N -u root -e "SELECT host_id FROM nagios_hostgroup_membership WHERE hostgroup_id='${ID_HOSTGROUP}'" opcfg`
		
		# Identificando a quantidade de hosts no hosgroup
		QUANTIDADE_ID_HOSTS=`echo -e ${LISTA_IDS_HOSTS} | wc -w`
		
		# Validando o valor retornado
		if [ ${QUANTIDADE_ID_HOSTS} -lt 1 ]
		then
			# Validando se o hostgroup possui hosts associados
			echo -e "\nO Hostgroup '${NOME}' não possui hosts associados! \n" && exit
		fi;
		
		# Listando os time-periods da lista obtida na consulta anterior
		for LINHA in ${LISTA_IDS_HOSTS}; do 
		
			# Coletando o nome do serviço
			COLETA_HOSTNAME=`mysql -N -u root -e "SELECT host_name FROM nagios_hosts WHERE host_id='${LINHA}'" opcfg`
			
			# Executando a função de remção de contacgroup do host
			REMOVE_CONTACTGROUPS_HOST ${COLETA_HOSTNAME} ${LINHA} ${FLAG_CONTACTGROUPS} ${ID_CONTACTGROUP}
		done 

	# A opção não foi definida corretamente
	else
        echo -e "\nValor da opção '-t' desconhecido!\n"
        exit; 
	fi	
}


# Função que remove o contactgroup de um host
REMOVE_CONTACTGROUPS_HOST(){
	
	# Capturando os valores passados por parâmetro
	NOME_HOST=$1
	ID_DO_HOST=$2
	FLAG_CONTACTGROUPS=$3
	ID_CONTACTGROUP=$4

	# Caso não tenha sido informado um contactgroup, serão limpos todos os contactgroupse será adicionado o opmon-admins
	if [ ${FLAG_CONTACTGROUPS} -eq 0 ]
	then
		# Removendo todos os contactgroups relacionados ao host
		mysql -u root -e "DELETE FROM nagios_host_contactgroups WHERE host_id='${ID_DO_HOST}'" opcfg

		# Inserindo o contactgroup opmon-admins ao host
        mysql -N -u root -e "INSERT INTO nagios_host_contactgroups ( host_id, contactgroup_id ) VALUES ( ${ID_DO_HOST} , '1' )" opcfg
		echo -e "\nRemovidos todos os contactgroups do host '${NOME_HOST}'. Restaurando o contactgroup 'opmon-admins'. "
	
	# Se o contactgroup foi informado, o mesmo será removido
	else
		
		# Removendo o contactgroups relacionado ao host
		mysql -u root -e "DELETE FROM nagios_host_contactgroups WHERE contactgroup_id='${ID_CONTACTGROUP}'" opcfg
		echo -e "\nRemovido o contactgroup '${NOME_CONTACTGROUP}' do host '${NOME_HOST}'."

	fi;
}


# Função utilizada para remover contactgroups dos serviços
REMOVER_CONTACTGROUPS_SERVICOS(){
	
	# Capturando os dados enviados por Parâmetros
	NOME=$1
	TIPO_EXECUCAO=$2
	NOME_CONTACTGROUP=$3

	# Variáveis globais
	ID_CONTACTGROUP=""
	
	# Verificando se foi passado algum tipo de consulta
	[ -z ${TIPO_EXECUCAO} ] && echo -e "\nNenhum Tipo de consulta definida! \n" && exit

	
	# Validando se foi informado algum contactgroup group
	FLAG_CONTACTGROUPS=`echo ${NOME_CONTACTGROUP} | egrep -x REMOVE_ALL | wc -w`
	
	# Obtendo o ID do contactgroup, caso tenha sido informado um nome
	if [ ${FLAG_CONTACTGROUPS} -eq 0 ]
	then
		# Obtendo o ID  do contactgroup
		ID_CONTACTGROUP=`mysql -N -u root -e "SELECT contactgroup_id FROM nagios_contactgroups WHERE contactgroup_name='${NOME_CONTACTGROUP}'" opcfg`
		
		# Validando se o contactgroup foi encontrado
		QUANTIDADE_IDS_CONTACTGROUP=`echo ${ID_CONTACTGROUP} | wc -w`
		
		# Informando ao usuário se o contactgroup não foi encontrado.
		if [ ${QUANTIDADE_IDS_CONTACTGROUP} -lt 1 ]
		then
			# Validando se o hostgroup foi encontrado
			echo -e "\nO contactgroup '${NOME_CONTACTGROUP}' não foi encontrado!\n" && exit
		fi;
	fi;
	
	# Validando o tipo de consulta que deve ser realizada
	if [ ${TIPO_EXECUCAO} = "host" ]
	then
		
		# Obtendo o ID  do host nagios_contactgroups
		ID_HOST=`mysql -N -u root -e "SELECT host_id FROM nagios_hosts WHERE host_name='${NOME}'" opcfg `
		
		# Validando se o host foi encontrado
		[ -z ${ID_HOST} ] && echo -e "\nO Host '${NOME}' não foi encontrado!\n" && exit
		

		# Obtendo a lista de IDs dos serviços que estão associados ao host
		LISTA_IDS_SERVICES=`mysql -N -u root -e "SELECT service_id FROM nagios_services where host_id='${ID_HOST}' ORDER BY  service_description" opcfg`
		
		# Informando o usuário de acordo com a opção de remoção
		if [ ${FLAG_CONTACTGROUPS} -gt 0 ]
			then
				echo -e "\nRemovendo todos os contactgroups dos serviços do host '${NOME}': \n"
			else
				echo -e "\nRemovendo o contactgroup '${NOME_CONTACTGROUP}' dos serviços do host '${NOME}': \n"
			fi;
		
		# Loop para exibição do nome de todos os host_groups
		for LINHA in ${LISTA_IDS_SERVICES}; do 
		
			# Coletando o nome do serviço
			SERVICE_NAME=`mysql -N -u root -e "SELECT service_description FROM nagios_services WHERE service_id='${LINHA}'" opcfg`

			# Exibindo o nome do serviço na tela
			echo -e "${SERVICE_NAME}"
		
			# Chamando a função que remove o(s) contactgroup(s) do(s) serviço(s)
			REMOVE_CONTACTGROUP_SERVICOS_HOST "${NOME}" "${LINHA}" "${SERVICE_NAME}" "${FLAG_CONTACTGROUPS}" "${ID_CONTACTGROUP}" "${NOME_CONTACTGROUP}"
		done 
		
	# Verificando se o tipo escolhido foi lista de hosts
	elif [ ${TIPO_EXECUCAO} = "lista" ]
	then

		# validando se a lista existe.
		[ ! -e ${NOME} ] && echo -e "\nO arquivo '${NOME}' não foi encontrado!\n" && exit
		
		# Loop para verificar todos os hosts do arquivo
		while read NOME_HOST_LIDO
		do
			# Obtendo o ID  do host
			ID_HOST=`mysql -N -u root -e "SELECT host_id FROM nagios_hosts where host_name='${NOME_HOST_LIDO}'" opcfg `

			# Validando se o host foi encontrado
			if [ -z ${ID_HOST} ] 
			then
				echo -e "\n O Host '${NOME_HOST_LIDO}' não foi encontrado!\n"
			
			# Se o host foi encontrado, então são coletados os IDs dos serviços
			else
				
				# Obtendo a lista de IDs dos serviços que estão associados ao host
				LISTA_IDS_SERVICES=`mysql -N -u root -e "SELECT service_id FROM nagios_services where host_id='${ID_HOST}' ORDER BY service_description" opcfg`
				
				
				# Informando o usuário de acordo com a opção de remoção
				if [ ${FLAG_CONTACTGROUPS} -gt 0 ]
				then
					echo -e "\nRemovendo todos os contactgroups dos serviços do host '${NOME_HOST_LIDO}': \n"
				else
					echo -e "\nRemovendo o contactgroup '${NOME_CONTACTGROUP}' dos serviços do host '${NOME_HOST_LIDO}': \n"
				fi;
				
				
				# Loop para exibição do nome de todos os host_groups
				for LINHA in ${LISTA_IDS_SERVICES}; do 
		
					# Coletando o nome do serviço
					SERVICE_NAME=`mysql -N -u root -e "SELECT service_description FROM nagios_services WHERE service_id='${LINHA}'" opcfg`

					# Exibindo o nome do serviço na tela
					echo -e "${SERVICE_NAME}"
		
					# Chamando a função que remove o(s) contactgroup(s) do(s) serviço(s)
					REMOVE_CONTACTGROUP_SERVICOS_HOST "${NOME_HOST_LIDO}" "${LINHA}" "${SERVICE_NAME}" "${FLAG_CONTACTGROUPS}" "${ID_CONTACTGROUP}" "${NOME_CONTACTGROUP}"
				done 		
			fi
			
		# Direcionando o arquivo passado por parâmetro para ser utilizado no loop	
		done < ${NOME}
		
	# Verificando se o tipo escolhido foi hostgroups
	elif [ ${TIPO_EXECUCAO} = "hostgroup" ]
	then
		
		# Obtendo o ID  do hostgroup
		ID_HOSTGROUP=`mysql -N -u root -e "SELECT hostgroup_id FROM nagios_hostgroups where hostgroup_name='${NOME}'" opcfg`

		# Verificando se a quantidade de IDs encontrados
		VALIDA_ID_HOSTGROUP=`echo ${ID_HOSTGROUP} | wc -w`
		
		# Validando se o hostgroup foi encontrado
		if [ ${VALIDA_ID_HOSTGROUP} -lt 1 ]
		then
			# Validando se o hostgroup foi encontrado
			echo -e "\nO hostgroup '${NOME}' não foi encontrado!\n" && exit
		fi;
		
		# Obtendo a lista de IDs dos hosts que estão associados ao hostgrops
		LISTA_IDS_HOSTS=`mysql -N -u root -e "SELECT host_id FROM nagios_hostgroup_membership WHERE hostgroup_id='${ID_HOSTGROUP}'" opcfg`
		
		# Identificando a quantidade de hosts no hosgroup
		QUANTIDADE_ID_HOSTS=`echo -e ${LISTA_IDS_HOSTS} | wc -w`
		
		# Validando o valor retornado
		if [ ${QUANTIDADE_ID_HOSTS} -lt 1 ]
		then
			# Validando se o hostgroup possui hosts associados
			echo -e "\nO Hostgroup '${NOME}' não possui hosts associados!\n" && exit
		fi;
		
		# Listando os time-periods da lista obtida na consulta anterior
		for ID_COLETADO_HOST in ${LISTA_IDS_HOSTS}; do 
		
			# Coletando o nome do serviço
			COLETA_HOSTNAME=`mysql -N -u root -e "SELECT host_name FROM nagios_hosts WHERE host_id='${ID_COLETADO_HOST}'" opcfg`
			
			
			# Obtendo a lista de IDs dos serviços que estão associados ao host
			LISTA_IDS_SERVICES=`mysql -N -u root -e "SELECT service_id FROM nagios_services where host_id='${ID_COLETADO_HOST}' ORDER BY service_description" opcfg`
				
				
			# Informando o usuário de acordo com a opção de remoção
			if [ ${FLAG_CONTACTGROUPS} -gt 0 ]
			then
				echo -e "\nRemovendo todos os contacgroups dos serviços do host '${COLETA_HOSTNAME}': \n"
			else
				echo -e "\nRemovendo o contactgroup '${NOME_CONTACTGROUP}' dos serviços do host '${COLETA_HOSTNAME}': \n"
			fi;
				
				
			# Loop para exibição do nome de todos os host_groups
			for LINHA in ${LISTA_IDS_SERVICES}; do 
		
				# Coletando o nome do serviço
				SERVICE_NAME=`mysql -N -u root -e "SELECT service_description FROM nagios_services WHERE service_id='${LINHA}'" opcfg`

				# Exibindo o nome do serviço na tela
				echo -e "${SERVICE_NAME}"
		
				# Chamando a função que remove o(s) contactgroup(s) do(s) serviço(s)
				REMOVE_CONTACTGROUP_SERVICOS_HOST "${COLETA_HOSTNAME}" "${LINHA}" "${SERVICE_NAME}" "${FLAG_CONTACTGROUPS}" "${ID_CONTACTGROUP}" "${NOME_CONTACTGROUP}"
			done 		
		done 

	# A opção não foi definida corretamente
	else
        echo -e "\nValor da opção '-t' desconhecida!\n"
        exit; 
	fi		
}

# Remove o contactgroup de um serviço. Se o flag estiver sinalizado que não foi nenhum contacgroup, todos os contactgroups do serviço será removido.
REMOVE_CONTACTGROUP_SERVICOS_HOST(){
	
	# Capturando os valores passados por parâmetro
	NOME_HOST=$1
	ID_DO_SERVICO=$2
	NOME_SERVICO=$3
	FLAG_CONTACTGROUPS=$4
	ID_CONTACTGROUP=$5
	CONTACTGROUP_NAME=$6

	# Caso não tenha sido informado um contactgroup, serão limpos todos os contactgroupse será adicionado o opmon-admins
	if [ ${FLAG_CONTACTGROUPS} -gt 0 ]
	then
		# Removendo todos os contactgroups relacionados ao host
		mysql -u root -e "DELETE FROM nagios_service_contactgroups WHERE service_id='${ID_DO_SERVICO}'" opcfg

		# Inserindo o contactgroup opmon-admins ao host
        mysql -N -u root -e "INSERT INTO nagios_service_contactgroups ( service_id, contactgroup_id ) VALUES ( ${ID_DO_SERVICO} , '1' )" opcfg
	
	# Se o contactgroup foi informado, o mesmo será removido
	else
		
		# Removendo o contactgroups informado do serviço.
		mysql -u root -e "DELETE FROM nagios_service_contactgroups WHERE contactgroup_id='${ID_CONTACTGROUP}' AND service_id='${ID_DO_SERVICO}'" opcfg

	fi;
}


# Validando as opções selecionadas
[ -z ${OPCAO} ] && echo -e "\n *** ->> Nenhuma Opção definida! <<- ***\n" && exit
[ -z ${NOME} ] && echo -e "\n *** ->> Não foi informada nenhuma opção de NOME! <<- ***\n" && exit


# Verificando qual opção informado
case ${OPCAO} in
        limpa_hostgroups_host)			REMOVER_HOSTGROUPS ${NOME} ; EXECUTA_EXPORT ;;
        limpa_hosts_hostgroup)          REMOVER_HOSTS_HOSTGROUP ${NOME} ; EXECUTA_EXPORT ;;
        adiciona_hosts_hostgroup)       ADICIONA_HOSTS_HOSTGROUP ${NOME} ${GROUP}; EXECUTA_EXPORT ;;
        altera_time_periods)	        ALTERA_TIME_PERIODS ${NOME} ${PERIOD} ${TIPO} ; EXECUTA_EXPORT ;;
		lista_time_periods)				LISTA_TIME_PERIODS ${NOME} ${TIPO} ;;
		lista_servicos)					LIST_SERVICES ${NOME} ;;
		lista_hostgroups_host)			LIST_HOSTGROUPS_HOST ${NOME};;
		lista_hosts_hostgroup)          LIST_HOSTS_HOSTGROUP ${NOME};;
		lista_contactgroups)          	LISTA_CONTACTGROUP ${NOME} ${TIPO} ;;
		remove_contactgroup)           	REMOVE_CONTACTGROUPS ${NOME} ${TIPO} ${GROUP} ; EXECUTA_EXPORT ;;
		remove_contactgroup_servicos)	REMOVER_CONTACTGROUPS_SERVICOS ${NOME} ${TIPO} ${GROUP} ; EXECUTA_EXPORT ;;
		*)  			           		echo -e "\nValor da opção '-o' desconhecido! \n" ;;
esac