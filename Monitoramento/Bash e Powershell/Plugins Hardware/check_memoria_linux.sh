#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/check_memoria_linux.sh
# Sistema.............: OpMon
# Data da Criacao.....: 05/04/2018
# Criado por..........: Wander Maia da Silva
#*****************************************************************************************************************************************************
# Descricao...........: Verifica o consumo de memória Real do servidor por SNMP. Necessário instalar o bc para que o plugin funcione corretamente.
# Entrada.............: Dados para acesso e valores de alarme
# Saida...............: Valores dos contatdores de memória do servidor.
# Linha do Plugin.....: /usr/local/opmon/libexec/custom/check_memoria_linux.sh -H $HOSTADDRESS$ -C $_HOSTCOMMUNITY$ -w $ARG1$ -c $ARG2$
# Execução Manual.....: /usr/local/opmon/libexec/custom/check_memoria_linux.sh -H 127.0.0.1 -C comunidade_snmp -w 90 -c 95
#*****************************************************************************************************************************************************

# Menu de Ajuda
help () {
  echo -e  "\n *** -> Descrição do Plugin <- *** \n" 
  echo -e  " Plugin para verificação do consumo de memória do servidor por SNMP. Necessário instalar o bc para que o plugin funcione corretamente."
  echo -e  " Utiliza valores crescentes para gerar os alertas (quanto maior o valor, pior).\n"
  echo -e  " *** -> Parametros: <- *** \n" 
  echo " -w  : warning"
  echo " -c  : critical"
  echo " -C  : Comunidade SNMP"
  echo " -H  : Host a ser monitorado"
  echo -e "\n"
  exit 0
}

# Menu de validacao de entradas
while getopts ":w:c:C:H:h:hd" Option
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
[ -z ${HOST} ] && echo -e "\n *** ->> Necessario o parametro com o arquivo do link <<- ***" && help
[ -z ${WARNING} ] && echo -e "\n *** ->> Necessario o parametro Warning <<- ***" && help
[ -z ${CRITICAL} ] && echo -e "\n *** ->> Necessario o parametro Critical <<- ***" && help
[ -z ${COMUNIDADE} ] && echo -e "\n *** ->> Necessario o parametro Comunidade <<- ***" && help

# Função que gera o Performance Data
function PERFORMANCE () {

  echo -e "$1 | PERCENTUAL_UTILIZADO=${RESULTADO}%;${WARNING};${CRITICAL};; MEMORIA_UTILIZADA=${USADO_MB}MB;;;; MEMORIA_LIVRE=${LIVRE_MB}MB;;;;"
}  

# Coleta dos valores de memoria total free, memoria em buffer e memoria em cached
TOTAL1=`snmpwalk -c ${COMUNIDADE} -v 1 ${HOST} memAvailReal.0 | cut -d" " -f4`
TOTAL2=`snmpwalk -c ${COMUNIDADE} -v 1 ${HOST} memBuffer.0 | cut -d" " -f4`
TOTAL3=`snmpwalk -c ${COMUNIDADE} -v 1 ${HOST} memCached.0 | cut -d" " -f4`

# Calculo de memoria livre real
LIVRE=$(echo "${TOTAL1} + ${TOTAL2} + ${TOTAL3}" | bc)
LIVRE_MB=`echo "scale=2; ${LIVRE} / 1024" | bc`

# Coleta do valor total de memoria
TOTAL=`snmpwalk -c ${COMUNIDADE} -v 1 ${HOST} memTotalReal.0 | cut -d" " -f4`
TOTAL_MB=`echo "scale=2; ${TOTAL} / 1024" | bc`

# Calculo de utilizacao real de memoria
USADO=$(echo "${TOTAL} - ${LIVRE}" | bc)
USADO_MB=`echo "scale=2; ${USADO} / 1024" | bc`

# Resultado (percentual) da memoria real utilizada
RESULTADO=$(echo "${USADO} * 100 / ${TOTAL}"  | bc)

# Validando os limites de alerta e gerando mensagens juntamente com o performance data.
if ((`bc <<< "${RESULTADO} < ${WARNING}" `))
then
        PERFORMANCE "O consumo de memória está ok! Memória Utilizada: ${RESULTADO}% (${USADO_MB} MB / ${TOTAL_MB} MB)"
        exit 0;
elif ((`bc <<< "${RESULTADO} < ${CRITICAL}" `))
then
        PERFORMANCE "O consumo de memória está em Alerta! Memória Utilizada: ${RESULTADO}% (${USADO_MB} MB / ${TOTAL_MB} MB)"
        exit 1;
else
        PERFORMANCE "O consumo de memória está em Crítico! Memória Utilizada: ${RESULTADO}% (${USADO_MB} MB / ${TOTAL_MB} MB)"
        exit 2;
fi

#Saida de erro
echo "Erro desconhecido!"
exit 3;

# Physical Memory disk usage 48.91 % (3.7GB/7.6GB)
