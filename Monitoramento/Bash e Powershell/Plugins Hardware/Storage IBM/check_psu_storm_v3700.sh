#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/check_psu_storm_v3700.sh
# Sistema.............: Opmon
# Data da Criacao.....: 15/06/2018
# Criado por..........: Wander Maia da Silva
#*****************************************************************************************************************************************************
# Descrição...........: Verifica o status das fontes no Storage IBM.
# Entrada.............: Dados para acesso ao storage.
# Saída...............: Informação sobre se as fontes estão disponíveis.
# Linha do Plugin.....: /usr/local/opmon/libexec/custom/check_psu_storm_v3700.sh -H $HOSTADDRESS$ -u $ARG1$ -s $ARG2$
# Execução Manual.....: /usr/local/opmon/libexec/custom/check_psu_storm_v3700.sh -H 127.0.0.1 -u usuario -s 'senha'
#*****************************************************************************************************************************************************

# Menu de Ajuda
help () {
  echo -e  "\n *** -> Descrição do Plugin<- *** \n"
  echo -e  " Plugin para verificar o status das fontes no Storage IBM\n"
  echo -e  " *** -> Parametros: <- *** \n"
  echo -e  " -H  : IP do Storage"
  echo -e  " -u  : Usuário para acesso ao Storage"
  echo -e  " -s  : Senha do Usuário\n"
  exit 0
}

# Menu de validacao de entradas
while getopts ":H:u:s:hd" Option
do
  case $Option in
    H )
      HOST=$OPTARG
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
[ -z ${HOST} ] && echo -e "\n *** ->> Necessário o parâmetro com o IP do Storage <<- ***" && help
[ -z ${USUARIO} ] && echo -e "\n *** ->> Necessário o parâmetro com o usuário de acesso ao Storage<<- ***" && help
[ -z ${SENHA} ] && echo -e "\n *** ->> Necessário o parâmetro com a senha de acesso <<- ***" && help

# Verificando as fontes que não estão ligadas
COLETA_OFFLINE_PSU=`/usr/bin/sshpass -p ${SENHA} /usr/bin/ssh -o StrictHostKeyChecking=no ${USUARIO}@"${HOST}" "lsenclosurepsu -filtervalue status=offline"`

# Verificando as fontes degradadas
COLETA_DEGRADED_PSU=`/usr/bin/sshpass -p ${SENHA} /usr/bin/ssh -o StrictHostKeyChecking=no ${USUARIO}@"${HOST}" "lsenclosurepsu -filtervalue status=degraded"`

# Verificando as fontes online
COLETA_ONLINE_PSU=`/usr/bin/sshpass -p ${SENHA} /usr/bin/ssh -o StrictHostKeyChecking=no ${USUARIO}@"${HOST}" "lsenclosurepsu -filtervalue status=online"`

# Calculando a quantidade de fontes com falha, degradadas e ok
QTD_OFFLINE_PSU=`echo -e "${COLETA_OFFLINE_PSU}" | wc -w`
QTD_DEGRADED_PSU=`echo -e "${COLETA_DEGRADED_PSU}" | wc -w`
QTD_ONLINE_PSU_CABECALHO=`echo -e "${COLETA_ONLINE_PSU}" | wc -l`

# Desconsiderando a linha de cabeçalho
QTD_ONLINE_PSU=$( echo "${QTD_ONLINE_PSU_CABECALHO} - 1 " | bc)

# Comparando os valores de alerta
if [ ${QTD_OFFLINE_PSU} -eq 0 ] && [ ${QTD_DEGRADED_PSU} -eq 0  ]
then
        echo "Todas as fontes estão ok! | QTD_OFFLINE_PSU=${QTD_OFFLINE_PSU};;;; QTD_DEGRADED_PSU=${QTD_DEGRADED_PSU};;;; QTD_ONLINE_PSU=${QTD_ONLINE_PSU};;;; "
        exit 0;

else
        echo "Fonte com erro! | QTD_OFFLINE_PSU=${QTD_OFFLINE_PSU};;;; QTD_DEGRADED_PSU=${QTD_DEGRADED_PSU};;;; QTD_ONLINE_PSU=${QTD_ONLINE_PSU};;;; "
        exit 2;
fi

#Saida de erro
echo "Erro desconhecido!"
exit 3;