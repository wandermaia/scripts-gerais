#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/check_disk_storm_v3700.sh
# Sistema.............: Opmon
# Data da Criacao.....: 15/06/2018
# Criado por..........: Wander Maia da Silva
#*****************************************************************************************************************************************************
# Descricao...........: Verifica se existem discos com falha ou degradação no storage.
# Entrada.............: Dados para acesso ao storage.
# Saida...............: Informação sobre estado geral dos discos
# Linha do Plugin.....: /usr/local/opmon/libexec/custom/check_disk_storm_v3700.sh -H $HOSTADDRESS$ -u $ARG1$ -s $ARG2$
# Execução Manual.....: /usr/local/opmon/libexec/custom/check_disk_storm_v3700.sh -H 127.0.0.1 -u usuario -s 'senha'
#*****************************************************************************************************************************************************

# Menu de Ajuda
help () {
  echo -e  "\n *** -> Descrição do Plugin<- *** \n"
  echo -e  " Plugin para verificar se existem discos com falha ou degradação no Storage IBM\n"
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

# Verificando se existem discos com falha
COLETA_FAILED_DRIVES=`/usr/bin/sshpass -p ${SENHA} /usr/bin/ssh -o StrictHostKeyChecking=no ${USUARIO}@"${HOST}" "lsdrive -filtervalue use=failed"`

# Verificando se existem discos degradados
COLETA_DEGRADED_DRIVES=`/usr/bin/sshpass -p ${SENHA} /usr/bin/ssh -o StrictHostKeyChecking=no ${USUARIO}@"${HOST}" "lsdrive -filtervalue status=degraded"`

# Calculando a quantidade de drives com falha ou degradados
QTD_FAILED_DRIVES=`echo -e "${COLETA_FAILED_DRIVES}" | wc -l`
QTD_DEGRADED_DRIVES=`echo -e "${COLETA_DEGRADED_DRIVES}" | wc -l`

# Corrindo a linha do retorno. Mesmo sem resposta, a contagem apresenta uma linha. Quanto tem resposta, é necessário remover o cabeçalho.
QTD_FAILED_DRIVES=`echo " ${QTD_FAILED_DRIVES} - 1 " | bc`
QTD_DEGRADED_DRIVES=`echo " ${QTD_DEGRADED_DRIVES} - 1 " | bc`

# Comparando os valores de alerta
if [ ${QTD_FAILED_DRIVES} -eq 0 ] && [ ${QTD_DEGRADED_DRIVES} -eq 0  ]
then
        echo "Não existem drives com erro. FAILED_DRIVES=${QTD_FAILED_DRIVES}  DEGRADED_DRIVES=${QTD_DEGRADED_DRIVES} | FAILED_DRIVES=${QTD_FAILED_DRIVES};;;; DEGRADED_DRIVES=${QTD_DEGRADED_DRIVES};;;; "
        exit 0;

else
        echo "Existem Drives com erro!  FAILED_DRIVES=${QTD_FAILED_DRIVES}  DEGRADED_DRIVES=${QTD_DEGRADED_DRIVES} | FAILED_DRIVES=${QTD_FAILED_DRIVES};;;; DEGRADED_DRIVES=${QTD_DEGRADED_DRIVES};;;; "
        exit 2;
fi

#Saida de erro
echo "Erro desconhecido!"
exit 3;