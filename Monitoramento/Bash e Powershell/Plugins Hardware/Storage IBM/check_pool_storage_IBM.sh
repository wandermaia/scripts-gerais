#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/check_pool_storage_IBM.sh
# Sistema.............: Opmon
# Data da Criacao.....: 05/10/2016
# Criado por..........: Wander Maia da Silva
#*****************************************************************************************************************************************************
# Descricao...........: Verifica o percentual de utilização dos Storages.
# Entrada.............: Dados para acesso, nome do pool e valores de alarme.
# Saida...............: Estado de utilização do pool informado.
# Linha do Plugin.....: /usr/local/opmon/libexec/custom/check_pool_storage_IBM.sh -H $ARG1$ -u $ARG2$ -s $ARG3$ -p $ARG4$ -w $ARG5$ -c $ARG6$
# Execução Manual.....: /usr/local/opmon/libexec/custom/check_pool_storage_IBM.sh -H 127.0.0.1 -u usuario -s 'senha' -p 'pool' -w 90 -c 95
#*****************************************************************************************************************************************************

# Menu de Ajuda
help () {
  echo -e  "\n *** -> Descrição do Plugin<- *** \n"
  echo -e  " Plugin para verificar o percentual de utilização de um determinado pool no Storage IBM"
  echo -e  " Utiliza valores crescentes (quanto maior, pior) do percentual de utilização dos pools para gerar os alertas. \n"
  echo -e  " *** -> Parametros: <- *** \n"
  echo -e  " -H  : IP do Storage"
  echo -e  " -u  : Usuário para acesso ao Storage"
  echo -e  " -s  : Senha do Usuário"
  echo -e  " -p  : Nome do pool que será consultado"
  echo -e  " -w  : Valor de warning (percentual de utilização)"
  echo -e  " -c  : Valor de critical (percentual de utilização) \n"
  exit 0
}

# Menu de validacao de entradas
while getopts ":w:c:H:p:u:s:hd" Option
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
      POOL=$OPTARG
      ;;
    u )
      USUARIO=$OPTARG
      ;;
    s )
      SENHA=$OPTARG
      ;;
    h )
      help
      ;;
  esac
done

# Check parameter
[ -z $HOST ] && echo -e "\n *** ->> Necessário o parâmetro com o IP do Storage <<- ***" && help
[ -z $POOL ] && echo -e "\n *** ->> Necessário o parâmetro com o nome do Pool <<- ***" && help
[ -z $USUARIO ] && echo -e "\n *** ->> Necessário o parâmetro com o usuário de acesso ao Storage<<- ***" && help
[ -z $SENHA ] && echo -e "\n *** ->> Necessário o parâmetro com a senha de acesso <<- ***" && help
[ -z $WARNING ] && echo -e "\n *** ->> Necessário o parâmetro Warning <<- ***" && help
[ -z $CRITICAL ] && echo -e "\n *** ->> Necessário o parâmetro Critical <<- ***" && help

# Coleta as informações dos pools do storage
/usr/bin/sshpass -p ${SENHA} /usr/bin/ssh ${USUARIO}@"${HOST}" "svcinfo lsmdiskgrp" > /tmp/pool_${POOL}_${HOST}.txt

# Validando a consulta foi realizada com sucesso
LINHAS=`cat /tmp/pool_${POOL}_${HOST}.txt | wc -l `
if [ -z $LINHAS ]
then
        echo "Erro desconhecido! Resposta nula na coleta dos dados!";
        exit 3;
fi;

# Segregando os valores do pool
PERCENTUAL_UTILIZADO=`cat /tmp/pool_${POOL}_${HOST}.txt | grep -w ${POOL} | awk '{print $12}'`
CAPACIDADE=`cat /tmp/pool_${POOL}_${HOST}.txt | grep -w ${POOL} | awk '{print $6}'`
ESPACO_LIVRE=`cat /tmp/pool_${POOL}_${HOST}.txt | grep -w ${POOL} | awk '{print $8}'`
ESPACO_UTILIZADO=`cat /tmp/pool_${POOL}_${HOST}.txt | grep -w ${POOL} | awk '{print $10}'`

# Comparando os valores de alerta
if [ $PERCENTUAL_UTILIZADO -lt $WARNING ]
then
        echo "Utilização do Pool ${POOL} está OK! PERCENTUAL_UTILIZADO: ${PERCENTUAL_UTILIZADO}%, CAPACIDADE: ${CAPACIDADE} , ESPACO_LIVRE: ${ESPACO_LIVRE} e  ESPACO_UTILIZADO: ${ESPACO_UTILIZADO} | PERCENTUAL_UTILIZADO=${PERCENTUAL_UTILIZADO}%;$WARNING;$CRITICAL;; "
        exit 0;

elif [ $PERCENTUAL_UTILIZADO -lt $CRITICAL ]
then
        echo "Utilização do Pool ${POOL} está em Alerta! PERCENTUAL_UTILIZADO: ${PERCENTUAL_UTILIZADO}%, CAPACIDADE: ${CAPACIDADE} , ESPACO_LIVRE: ${ESPACO_LIVRE} e  ESPACO_UTILIZADO: ${ESPACO_UTILIZADO} | PERCENTUAL_UTILIZADO=${PERCENTUAL_UTILIZADO}%;$WARNING;$CRITICAL;; "
        exit 1;
else
        echo "Utilização do Pool ${POOL} está Crítica! PERCENTUAL_UTILIZADO: ${PERCENTUAL_UTILIZADO}%, CAPACIDADE: ${CAPACIDADE} , ESPACO_LIVRE: ${ESPACO_LIVRE} e  ESPACO_UTILIZADO: ${ESPACO_UTILIZADO} | PERCENTUAL_UTILIZADO=${PERCENTUAL_UTILIZADO}%;$WARNING;$CRITICAL;; "
        exit 2;
fi

#Saida de erro
echo "Erro desconhecido!"
exit 3;