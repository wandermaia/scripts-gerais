#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/uptime_switch_cisco.sh
# Sistema.............: OpMon
# Data da Criacao.....: 22/03/2018
# Criado por..........: Wander Maia da Silva
#*****************************************************************************************************************************************************
# Descricao...........: Verifica o Up Time do switch cisco por SNMP.
# Entrada.............: Dados para acesso e valores de alarme
# Saida...............: Valor de Uptime
# Linha do Plugin.....: /usr/local/opmon/libexec/custom/uptime_switch_cisco.sh -H $HOSTADDRESS$ -C $_HOSTCOMMUNITY$ -w $ARG1$ -c $ARG2$
# Execução Manual.....: /usr/local/opmon/libexec/custom/uptime_switch_cisco.sh -H 127.0.0.1 -C comunidade_snmp -w 10 -c 5
#*****************************************************************************************************************************************************

# Menu de Ajuda
help () {
  echo -e  "\n *** -> Descrição do Plugin <- *** \n" 
  echo -e  " Plugin para verificação do Up Time do switch cisco por SNMP."
  echo -e  " Utiliza valores decrescentes para gerar os alertas (quanto menor o valor, pior).\n"
  echo -e  " *** -> Parametros: <- *** \n" 
  echo -e  " -H  : IP do host que será monitorado"
  echo -e  " -C  : Comunidade SNMP configurada no equipamento"
  echo -e  " -w  : Valor de warning (em minutos)"
  echo -e  " -c  : Valor de critical (em minutos)\n"
  exit 0
}

# Menu de validacao de entradas
while getopts ":w:c:H:C:hd" Option
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
    C )
      COMUNIDADE=$OPTARG
      ;;
    h ) 
      help
      ;;
  esac
done

# Check parameter
[ -z ${HOST} ] && echo -e "\n *** ->> Necessário o parâmetro com o IP do Host <<- ***" && help
[ -z ${COMUNIDADE} ] && echo -e "\n *** ->> Necessário o parâmetro com A Comunidade SNMP <<- ***" && help
[ -z ${WARNING} ] && echo -e "\n *** ->> Necessário o parâmetro Warning <<- ***" && help
[ -z ${CRITICAL} ] && echo -e "\n *** ->> Necessário o parâmetro Critical <<- ***" && help


# Função que gera o Performance Data
function PERFORMANCE () {

  echo -e "$1 | UPTIME=${UPTIME}Min;${WARNING};${CRITICAL};; "
}  

# Realizando a coleta de CPU do servidor. O valor retornado é o percentual de CPU idle.
COLETA_COMANDO=`/usr/bin/snmpget -v 2c -c ${COMUNIDADE} -Ovq  ${HOST} DISMAN-EVENT-MIB::sysUpTimeInstance`

# segregando os valores coletados
DIAS_UPTIME=`echo ${COLETA_COMANDO} | awk -F ':' '{print $1}'`
HORAS_UPTIME=`echo ${COLETA_COMANDO} | awk -F ':' '{print $2}'`
MINUTOS_UPTIME=`echo ${COLETA_COMANDO} | awk -F ':' '{print $3}'`


# Calculando o tempo ativo em minutos
TOTAL_MINUTOS_DIAS=`echo "${DIAS_UPTIME} * 24 * 60" | bc`
TOTAL_MINUTOS_HORAS=`echo "${HORAS_UPTIME} * 60" | bc`

# Calculando o uptime em minutos
UPTIME=`echo " ( ${TOTAL_MINUTOS_DIAS} + ${TOTAL_MINUTOS_HORAS} ) + ${MINUTOS_UPTIME} " | bc`


# Validando os limites de alerta e gerando mensagens juntamente com o performance data.
if ((`bc <<< "${UPTIME} > ${WARNING}" `))
then
	PERFORMANCE "Uptime Ok! Servidor ativo a ${DIAS_UPTIME} dias, ${HORAS_UPTIME} horas e ${MINUTOS_UPTIME} minutos."
	exit 0;

elif ((`bc <<< "${UPTIME} > ${CRITICAL}" `))
then
	PERFORMANCE "Uptime em Alerta! Servidor ativo a ${DIAS_UPTIME} dias, ${HORAS_UPTIME} horas e ${MINUTOS_UPTIME} minutos."
	exit 1;
else
	PERFORMANCE "Uptime Crítico! Servidor ativo a ${DIAS_UPTIME} dias, ${HORAS_UPTIME} horas e ${MINUTOS_UPTIME} minutos."
	exit 2;
fi

#Saida de erro
echo "Erro desconhecido!"
exit 3;

