#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/check_process_by_snmp.sh
# Sistema.............: Opmon
# Data da Criacao.....: 14/09/2017
# Criado por..........: Wander Maia da Silva
#*****************************************************************************************************************************************************
# Descricao...........: Verifica o número de instâncias em execução de um processo por SNMP.
# Entrada.............: IP do servidor, nome do processo, comunidade SNMP e limites de alertas.
# Saida...............: Número de instâncias em execução do processo informado.
# Linha do Plugin.....: /usr/local/opmon/libexec/custom/check_process_by_snmp.sh -H $HOSTADDRESS$ -C $ARG1$ -p $ARG2$ -w $ARG3$ -c $ARG4$
# Execução Manual.....: /usr/local/opmon/libexec/custom/check_process_by_snmp.sh -H 127.0.0.1 -C comunidade_snmp -p httpd -w 200 -c 300
#*****************************************************************************************************************************************************


# Menu de Ajuda
help () {
  echo -e  "\n *** -> Descrição do Plugin <- *** \n" 
  echo -e  " Plugin que verifica o número de instâncias em execução de um processo por SNMP."
  echo -e  " Utiliza valores crescentes para gerar os alertas (quanto maior o valor, pior).\n"
  echo -e  " *** -> Parametros: <- *** \n" 
  echo -e  " -H  : IP do host que será monitorado"
  echo -e  " -C  : Comunidade SNMP"
  echo -e  " -p  : Nome do processo"
  echo -e  " -w  : Valor de warning"
  echo -e  " -c  : Valor de critical \n"
  exit 0
}

# Menu de validacao de entradas
while getopts ":w:c:H:p:C:hd" Option
do
  case $Option in
    w )
      WARNING=$OPTARG
      ;;
    c )
      CRITICAL=$OPTARG
      ;;
    H )
      HOST=$OPTARG
      ;;
    p )
      PROCESSO=$OPTARG
      ;;
    C )
      COMUNIDADE=$OPTARG
      ;;
    h ) 
      help
      ;;
  esac
done

# Check parameter
[ -z $HOST ] && echo -e "\n *** ->> Necessário o parâmetro com o IP do Host <<- ***" && help
[ -z $PROCESSO ] && echo -e "\n *** ->> Necessário o parâmetro com o nome do processo <<- ***" && help
[ -z $COMUNIDADE ] && echo -e "\n *** ->> Necessário o parâmetro com a comunidade SNMP <<- ***" && help
[ -z $WARNING ] && echo -e "\n *** ->> Necessário o parâmetro Warning <<- ***" && help
[ -z $CRITICAL ] && echo -e "\n *** ->> Necessário o parâmetro Critical <<- ***" && help


# /usr/bin/snmpwalk -v1 -On -c public 127.0.0.1 .1.3.6.1.2.1.25.4.2.1.2 | grep httpd | wc -l

# OID para a consulta SNMP
OID=".1.3.6.1.2.1.25.4.2.1.2"

# Coletando a quantidade de instâncias do processo informado
NUMERO_PROCESSOS=`/usr/bin/snmpwalk -v1 -On -c ${COMUNIDADE} ${HOST} ${OID} | grep ${PROCESSO} | wc -l`

# Verificando os os limites de alerta
if [ ${NUMERO_PROCESSOS} -lt ${WARNING} ]
then
        echo -e "A quantidade de processos está OK. ${NUMERO_PROCESSOS} processos ${PROCESSO} em execução | NUMERO_PROCESSOS=${NUMERO_PROCESSOS};$WARNING;$CRITICAL;; "
        exit 0;

# verificando o valor de Warning
elif [ ${NUMERO_PROCESSOS} -lt ${CRITICAL} ]
then
        echo -e "A quantidade de processos está em alerta! ${NUMERO_PROCESSOS} processos ${PROCESSO} em execução | NUMERO_PROCESSOS=${NUMERO_PROCESSOS};$WARNING;$CRITICAL;; "
        exit 1;

# Crítico
else
        echo -e "A quantidade de processos está em Crítica! ${NUMERO_PROCESSOS} processos ${PROCESSO} em execução | NUMERO_PROCESSOS=${NUMERO_PROCESSOS};$WARNING;$CRITICAL;; "
        exit 2;
fi

#Saida de erro
echo "Erro desconhecido!"
exit 3;
