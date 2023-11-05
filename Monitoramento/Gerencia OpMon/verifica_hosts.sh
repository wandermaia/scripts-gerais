#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /root/scripts/verifica_hosts.sh
# Sistema.............: OpMon
# Criado por..........: Wander Maia da Silva
# Data da Criação.....: 29/01/2019
# Descrição...........: Verifica se os IPs da lista informada por parâmetro estão incluídos no monitoramento
# Entrada.............: Lista de IPs
# Saída...............: IPs Validados de IPs
#*****************************************************************************************************************************************************
# Data da Alteração...: 20/02/2019
# Motivo..............: Acréscimo da função para validar ping e SNMP com base nas comunidades previamente cadastradas no OpMon.
#*****************************************************************************************************************************************************

# Menu de Ajuda
help () {

    cat <<EOF

Descrição do Script

        Script para verificar se os IPs da lista informada por parâmetro estão incluídos no monitoramento.
        Também são validadas as respostas a ping e o SNMP com as comunidades cadastradas no OpMon

Parâmetros

        -h  : Exibe este menu de ajuda
        -f  : Caminho absoluto do arquivo onde contém a lista de IPs (deve ser um CSV separado por ponto e vírgula ';' no formato 'Hostname;IP')

Exemplo de Utilização

        Validar se os servidores da lista estão no monitoramento, se respondem a ping e/ou SNMP:
        /root/scripts/verifica_hosts.sh -f '/tmp/lista_ips.txt'

EOF

        exit
}

# Menu de validacao de entradas
while getopts "f:hd" Option
do
  case $Option in
    f )
      FILE=$OPTARG
      ;;
    h )
      help
      ;;
  esac
done

# Criando o  aquivo de saída
REPORT="/tmp/validacao_ips.csv"

# OID referente à consulta do SYSNAME do SNMP. Este OID será utilizado para realizar a consulta SNMP de teste.
OID='1.3.6.1.2.1.1.5'

# Limpando o conteúdo do arquivo, caso ele exista
echo 'Hostname;IP;Monitored;ping;SNMP;SO' > ${REPORT}

# validando se a lista de hosts para validação existe
[ -z ${FILE} ] && echo -e  "\nA opção '-f' não pode ser nula! \n" && help && exit
[ ! -e ${FILE} ] && echo -e "\nO arquivo '${FILE}' não foi encontrado! \n" && exit

# Realizando a coleta das comunidades de SNMP para verificação posterior
mysql -N -u root -e "SELECT snmp_version,community,community_id FROM snmp_communities ORDER BY community_id DESC" opcfg > /tmp/COMMUNITIES_SNMP.txt


# Função para validar o ping
function validaPing () {
        IP=$1

        # Fazendo o teste de ping
        PACOTES_RECEBIDOS=`ping "${IP}" -c 3 | grep received | awk '{print $4}'`

                # Resultado final da função
        if [ ${PACOTES_RECEBIDOS} -gt 0 ]
        then
                echo 'Yes'
        else
                echo 'No'
        fi

}

# Função para validar o SNMP
function validaSnmp () {

        # Ip do Host para teste
        IP=$1

        # Flag utilizado na validação
        FLAG_VALIDA=0
        DADOS_SNMP=''

        # Lendo as linhas do arquivo
        while read comunidade
        do
                # Segregando os valores de nome e IP do host da linha do arquivo
                VERSION=`echo -e "${comunidade}" | awk '{print $1}'`
                COMMUNITY_NAME=`echo -e "${comunidade}" | awk '{print $2}'`

                # Executar apenas se ainda não foi encontrada nenhuma comunidade. Se foi encontrada, vai passar direto.
                if [ ${FLAG_VALIDA} -eq 0 ]
                then

                        # snmpwalk -t 1 -v2c 192.168.56.153 -c testeC 1.3.6.1.2.1.1.5
                        # Testando a consulta de sysname e verificando se foi executada com sucesso
                        snmpwalk -t 1 -v "${VERSION}" "${IP}" -c "${COMMUNITY_NAME}" 1.3.6.1.2.1.1.5 &> /dev/null

                        # Validando se a consulta foi executada com sucesso
                        RESPONDE=$?
                        if [ ${RESPONDE} -eq 0 ]
                        then

                                # CPU_UTILIZATION=`echo "scale=2; 100 - ${PERCENTUAL_IDLE}" | bc`
                                FLAG_VALIDA=`echo $(( ${FLAG_VALIDA} + 1 ))`
                                DADOS_SNMP=`echo -e " ${COMMUNITY_NAME} ${VERSION}"`

                        fi
                fi
        done < /tmp/COMMUNITIES_SNMP.txt


        # Resultado final da função
        if [ ${FLAG_VALIDA} -gt 0 ]
        then
                echo -e "Yes ${DADOS_SNMP}"
        else
                echo "No"

        fi

}

# Informando para o usuário o início da operação
echo -e "\nIniciando a Verificação dos hosts presentes na lista '${FILE}'\n"

# Verificando os IPs cadastrados no OpMon
LISTA_IPS_OPMON=`mysql -N -u root -e "SELECT address FROM nagios_hosts" opcfg `

# Lendo as linhas do arquivo
while read linha
do
        # Segregando os valores de nome e IP do host da linha do arquivo
        nomeHost=`echo -e "${linha}" | awk -F ';' '{print $1}'`
        IP=`echo -e "${linha}" | awk -F ';' '{print $2}'`

        #echo -e "Host: '${nomeHost}', IP: '${IP}'"

        # Verificando se o IP do host está na lista dos equipamentos incluídos no OpMon
        INSERIDO=`echo -e "${LISTA_IPS_OPMON}" | grep ${IP} | wc -l `

        # Variável para SO

        SISTEMA_OPERACIONAL=''

        # Validando se o host e o serviço foram encontrados
        if [ ${INSERIDO} -gt 0 ]
        then

                # Validando se responde a ping e/ou SNMP
                RESPONDE_PING=`validaPing ${IP}`
                VALIDA_SNMP=`validaSnmp ${IP}`

                echo -e "VALIDA_SNMP: ${VALIDA_SNMP}"

                RESPONDE_SNMP=`echo -e "${VALIDA_SNMP}" | awk '{print $1}'`
                COMMUNITY_NAME=`echo -e "${VALIDA_SNMP}" | awk '{print $2}'`
                VERSION=`echo -e "${VALIDA_SNMP}" | awk '{print $3}'`

                echo -e "COMMUNITY_NAME ${COMMUNITY_NAME} VERSION ${VERSION}"

                echo -e "RESPONDE_SNMP: ${RESPONDE_SNMP}"

                # Validanddo o SO se responder a SNMP
                if [ ${RESPONDE_SNMP} == 'Yes' ]
                then

                    # Coletando o SO
                    COLETA_SO=`snmpwalk -v "${VERSION}" "${IP}" -c "${COMMUNITY_NAME}" SNMPv2-MIB::sysDescr.0`

                    # Validando se o SO é Linux, Windows ou Outro
                    WINDOWS=`echo -e "${COLETA_SO}" | grep -iE "Windows" | wc -l`
                    LINUX=`echo -e "${COLETA_SO}" | grep -iE "Linux" | wc -l`
                    VMWARE=`echo -e "${COLETA_SO}" | grep -iE "VMware" | wc -l`
                    SWITCH=`echo -e "${COLETA_SO}" | grep -iE "Switch|Alcatel-Lucent|Cisco IOS" | wc -l`


                    # Configurando a variável
                    if [ ${WINDOWS} -gt 0 ]
                    then
                        SISTEMA_OPERACIONAL="Windows"

                    elif [ ${SWITCH} -gt 0 ]
                    then
                        SISTEMA_OPERACIONAL="SWITCH"

                    elif [ ${LINUX} -gt 0 ]
                    then
                        SISTEMA_OPERACIONAL="Linux"

                    elif [ ${VMWARE} -gt 0 ]
                    then

                        SISTEMA_OPERACIONAL="VMware"

                    else
                        SISTEMA_OPERACIONAL="Outro"

                    fi

                fi




                echo -e "O host '${nomeHost}' (IP ${IP}) está no monitoramento. Responde ping: ${RESPONDE_PING}, Responde SNMP: ${RESPONDE_SNMP}, Sistema Operacional: ${SISTEMA_OPERACIONAL}"
                echo -e "${linha};Yes;${RESPONDE_PING};${RESPONDE_SNMP};${SISTEMA_OPERACIONAL}" >> ${REPORT}
        else

                # Validando se responde a ping e/ou SNMP
                RESPONDE_PING=`validaPing ${IP}`
                VALIDA_SNMP=`validaSnmp ${IP}`

                echo -e "VALIDA_SNMP: ${VALIDA_SNMP}"

                RESPONDE_SNMP=`echo -e "${VALIDA_SNMP}" | awk '{print $1}'`
                COMMUNITY_NAME=`echo -e "${VALIDA_SNMP}" | awk '{print $2}'`
                VERSION=`echo -e "${VALIDA_SNMP}" | awk '{print $3}'`

                echo -e "COMMUNITY_NAME ${COMMUNITY_NAME} VERSION ${VERSION}"
                echo -e "RESPONDE_SNMP: ${RESPONDE_SNMP}"

                # Validanddo o SO se responder a SNMP
                if [ ${RESPONDE_SNMP} == 'Yes' ]
                then

                    # Coletando o SO
                    COLETA_SO=`snmpwalk -v "${VERSION}" "${IP}" -c "${COMMUNITY_NAME}" SNMPv2-MIB::sysDescr.0`

                    # Validando se o SO é Linux, Windows ou Outro VMware
                    WINDOWS=`echo -e "${COLETA_SO}" | grep -iE "Windows" | wc -l`
                    LINUX=`echo -e "${COLETA_SO}" | grep -iE "Linux" | wc -l`
                    VMWARE=`echo -e "${COLETA_SO}" | grep -iE "VMware" | wc -l`
                    SWITCH=`echo -e "${COLETA_SO}" | grep -iE "Switch|Alcatel-Lucent|Cisco IOS" | wc -l`

                    # Configurando a variável
                    if [ ${WINDOWS} -gt 0 ]
                    then
                        SISTEMA_OPERACIONAL="Windows"

                    elif [ ${SWITCH} -gt 0 ]
                    then
                        SISTEMA_OPERACIONAL="SWITCH"

                    elif [ ${LINUX} -gt 0 ]
                    then
                        SISTEMA_OPERACIONAL="Linux"

                    elif [ ${VMWARE} -gt 0 ]
                    then

                        SISTEMA_OPERACIONAL="VMware"

                    else
                        SISTEMA_OPERACIONAL="Outro"

                    fi
                fi

                echo -e "Erro! O host '${nomeHost}' (IP ${IP}) não está no monitoramento. Responde ping: ${RESPONDE_PING}, Responde SNMP: ${RESPONDE_SNMP}"
                echo -e "${linha};Yes;${RESPONDE_PING};${RESPONDE_SNMP};${SISTEMA_OPERACIONAL}" >> ${REPORT}
        fi

done < ${FILE}

echo -e "\nA lista de validação está no arquivo (formato CSV): '${REPORT}'.\n"