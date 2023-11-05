#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/check_temperatura_chassi_dell.sh
# Sistema.............: Opmon
# Data da Criacao.....: 18/01/2018
# Criado por..........: Wander Maia da Silva
#*****************************************************************************************************************************************************
# Descricao...........: Verifica a temperutura do chassi dell por SNMP.
# Entrada.............: Dados para acesso e valores para limites de alerta.
# Saida...............: Valor da temperutura e o status conforme os valores informados.
# Linha do Plugin.....: /usr/local/opmon/libexec/custom/check_temperatura_chassi_dell.sh -H $HOSTADDRESS$ -C $_HOSTCOMMUNITY$ -w $ARG1$ -c $ARG2$
# Execução Manual.....: /usr/local/opmon/libexec/custom/check_temperatura_chassi_dell.sh -H 127.0.0.1 -C public -w 25 -c 30
#*****************************************************************************************************************************************************

# Menu de Ajuda
help () {
  echo -e  "\n *** -> Descrição do Plugin <- *** \n" 
  echo -e  " Plugin para verificação da temperutura do chassi dell por SNMP."
  echo -e  " Utiliza valores crescentes para gerar os alertas (quanto maior o valor, pior).\n"
  echo -e  " *** -> Parametros: <- *** \n" 
  echo -e  " -H  : IP do Chassi"
  echo -e  " -C  : Comunidade SNMP cadastrada no equipamento"
  echo -e  " -w  : Valor de warning (número inteiro em graus ceusius)"
  echo -e  " -c  : Valor de critical (número inteiro em em graus ceusius)\n"
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
[ -z $HOST ] && echo -e "\n *** ->> Necessário o parâmetro com o IP do Host <<- ***" && help
[ -z $COMUNIDADE ] && echo -e "\n *** ->> Necessário o parâmetro com a comunidade SNMP <<- ***" && help
[ -z $WARNING ] && echo -e "\n *** ->> Necessário o parâmetro Warning <<- ***" && help
[ -z $CRITICAL ] && echo -e "\n *** ->> Necessário o parâmetro Critical <<- ***" && help


# Verificando a Fila de Mensagens da Getrak
TEMPERATURA=`snmpget -v 2c -c ${COMUNIDADE} -Ovq ${HOST} SNMPv2-SMI::enterprises.674.10892.2.3.1.10.0`

# Verificando os valores da fila total
if [ ${TEMPERATURA} -lt ${WARNING} ]
then
        echo -e  "Temperatura do Chassi está ok! Temperatura: ${TEMPERATURA}ºC | TEMPERATURA=${TEMPERATURA}C;$WARNING;$CRITICAL;0; "
        exit 0;

# verificando o valor de Warning
elif [ ${TEMPERATURA} -lt ${CRITICAL} ]
then
        echo "Temperatura do Chassi está em Alerta! Temperatura: ${TEMPERATURA}ºC | TEMPERATURA=${TEMPERATURA}C;$WARNING;$CRITICAL;0; "
        exit 1;

# Crítico
else
        echo "Temperatura do Chassi está Crítica! Temperatura: ${TEMPERATURA}ºC | TEMPERATURA=${TEMPERATURA}C;$WARNING;$CRITICAL;0; "
        exit 2;
fi

#Saida de erro
echo "Erro desconhecido!"
exit 3;