#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /root/scripts/manage_contactgroups_hosts.sh
# Sistema.............: OpMon
# Criado por..........: Wander Maia da Silva
# Data da Criação.....: 27/03/2019
# Descrição...........: Remove todos os contatctgroups do host, deixando apenas o opmonadmin
# Entrada.............: Não necessário.
#*****************************************************************************************************************************************************

# Menu de Ajuda
help () {

    cat <<EOF

Descrição do Script
        
  Script para remover todos os contactgroups dos hosts cadastrados do OpMon. Será adicionado apenas o opmonadmin como dono host.
 
Parâmetros

  -h  : Exibe este menu de ajuda
  -o  : Opção de modificação. Opções disponíveis:
      - remove_contactgroups: para remover todos os contactgroups e deixar apenas o grupo opmon-admins como responsável do host
      - lista_contactgroups: lista todos os contactgroups associados a cada host.

 
Exemplos de Utilização

   Listando todos os conctact groups de cada host
   /root/scripts/manage_contactgroups_hosts.sh -o lista_contactgroups

   Configurando apenas o opmonadmin como responsável de todos os hosts:
   /root/scripts/manage_contactgroups_hosts.sh -o remove_contactgroups
  
EOF

  exit
}


# Menu de validacao de entradas
while getopts "o:hd" Option
do
  case $Option in
    o )
      OPCAO=$OPTARG
      ;;
    h )
      help
      ;;
  esac
done

# Validando as opções selecionadas
[ -z ${OPCAO} ] && echo -e "\nNão foi informada nenhuma opção para o parâmetro '-o'!\n" && exit



# Função que executa o export das configurações.
EXECUTA_EXPORT(){
	
	# Realizando o export das novas configurações
	echo -e "\nInciando o export: \n"
	/usr/local/opmon/utils/opmon-export.php
	echo -e "\nExport Finalizado!\n"
	
}



# Função que remove todos os contactgroups de um host e substiui pelo grupo opmon-admins
removeContactGroups(){

    # Obtendo a lista de IDs de todos os hosts
    LISTA_IDS_HOSTS=`mysql -N -u root -e "select host_id from opcfg.nagios_hosts;" opcfg`

    # Coletando o hostname e chamando a função de remoção de contactgroups para todos os hosts encontrados
    for LINHA in ${LISTA_IDS_HOSTS}; do 

	    # Coletando o nome do servidor
	    COLETA_HOSTNAME=`mysql -N -u root -e "SELECT host_name FROM nagios_hosts WHERE host_id='${LINHA}'" opcfg`
			
	    # Executando a função listar o host
	    removeContactgroupsHost ${COLETA_HOSTNAME} ${LINHA}
    done 	

    # Informando o término da operação
    echo -e "\nRemovidos todos os contactgroups e adicionado apenas opmonadmin em todos os hosts!"
}



# Função que remove o contacFLAG_CONTACTGROUPS=$3 um host
removeContactgroupsHost(){
	
    # Capturando os valores passados por parâmetro
    NOME_HOST=$1
    ID_DO_HOST=$2

    # Removendo todos os contactgroups relacionados ao host
    mysql -u root -e "DELETE FROM nagios_host_contactgroups WHERE host_id='${ID_DO_HOST}'" opcfg

    # Inserindo o contactgroup opmon-admins ao host
    mysql -N -u root -e "INSERT INTO nagios_host_contactgroups ( host_id, contactgroup_id ) VALUES ( ${ID_DO_HOST} , '1' )" opcfg
    echo -e "Removidos todos os contactgroups do host '${NOME_HOST}'. Restaurando o contactgroup 'opmon-admins'."

}



# Função para listar todos os contactgroups cadastrados para todos hosts.
listaContactGroups(){
    
    # Obtendo a lista de IDs de todos os hosts
    LISTA_IDS_HOSTS=`mysql -N -u root -e "select host_id from opcfg.nagios_hosts;" opcfg`

    # Coletando o hostname e chamando a função de remoção de contactgroups para todos os hosts encontrados
    for LINHA in ${LISTA_IDS_HOSTS}; do 

	    # Coletando o nome do servidor
	    COLETA_HOSTNAME=`mysql -N -u root -e "SELECT host_name FROM nagios_hosts WHERE host_id='${LINHA}'" opcfg`
			
	    # Executando a função listar o host
	    listaContactgroupsHost ${COLETA_HOSTNAME} ${LINHA}
    done 	

}


# Função para listar todos os contactgroups de um host
listaContactgroupsHost(){
	
	# Capturando o hostname e o time-period enviados por Parâmetros
	NOME_HOST=$1
	ID_HOST=$2

	# Obtendo a lista de nomes e IDs hostgroups na qual o host faz parte
	LISTA_IDS_CONTACTGROUPS=`mysql -N -u root -e "SELECT contactgroup_id FROM nagios_host_contactgroups WHERE host_id='${ID_HOST}'" opcfg`

  # Variável para salvar o nome de todos os contacgroups relacionados ao host
  CONTACTGROUPS=""

	
	# Loop para exibição do nome de todos os host_groups
	for LINHA in ${LISTA_IDS_CONTACTGROUPS}; do 
		
		# Coletando o nome do contactgroup
		NOME_CONTACTGROUP=`mysql -N -u root -e "SELECT contactgroup_name FROM nagios_contactgroups WHERE contactgroup_id='${LINHA}'" opcfg`

		# Exibindo o contactgroup na tela
		CONTACTGROUPS=`echo -e "'${NOME_CONTACTGROUP}' ${CONTACTGROUPS} " `
	done 

    # Exibindo os contactgroups do host para o usuário
    echo -e "Contactgroups do Host '${NOME_HOST}': ${CONTACTGROUPS}"


}


# Verificando qual opção informado
case ${OPCAO} in
    remove_contactgroups)            removeContactGroups ; EXECUTA_EXPORT ;;
    lista_contactgroups)             listaContactGroups ;;
    *)                               echo -e "\nValor da opção '-o' desconhecida!\n" ;;
esac

