#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/check_gaveta_storm_v3700.sh
# Sistema.............: Opmon
# Data da Criacao.....: 15/06/2018
# Criado por..........: Wander Maia da Silva
#*****************************************************************************************************************************************************
# Descricao...........: Verifica se existem discos com falha ou degradação no storage.
# Entrada.............: Dados para acesso ao storage.
# Saida...............: Informação sobre estado geral dos discos
# Linha do Plugin.....: /usr/local/opmon/libexec/custom/check_gaveta_storm_v3700.sh -H $HOSTADDRESS$ -u $ARG1$ -s $ARG2$
# Execução Manual.....: /usr/local/opmon/libexec/custom/check_gaveta_storm_v3700.sh -H 127.0.0.1 -u usuario -s 'senha'
#*****************************************************************************************************************************************************

# Menu de Ajuda
help () {
  echo -e  "\n *** -> Descrição do Plugin<- *** \n"
  echo -e  " Plugin para verificar se existem controladoras ou gavetas com falha ou degradação no Storage IBM\n"
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
COLETA_GAVETAS=`/usr/bin/sshpass -p ${SENHA} /usr/bin/ssh -o StrictHostKeyChecking=no ${USUARIO}@"${HOST}" "lsenclosurecanister -delim :"`

# Segregando o status das controladoras
STATUS_CONTROLADORAS=`echo -e "${COLETA_GAVETAS}" | awk -F ':' '{print $3}'`

# Verificando os status das controladoras
QTD_OFFLINE=`echo -e "${COLETA_GAVETAS}" | grep offline | wc -l`
QTD_DEGRADED=`echo -e "${COLETA_GAVETAS}" | grep degraded | wc -l`
QTD_ONLINE=`echo -e "${COLETA_GAVETAS}" | grep online | wc -l`

# Comparando os valores de alerta
if [ ${QTD_OFFLINE} -eq 0 ] && [ ${QTD_DEGRADED} -eq 0  ]
then
        echo "Não existem controladoras ou gavetas com erro. | OFFLINE=${QTD_OFFLINE};;;; DEGRADED=${QTD_DEGRADED};;;; ONLINE=${QTD_ONLINE};;;; "
        exit 0;

else
        echo "Existem Controladoras ou gavetas com erro! | OFFLINE=${QTD_OFFLINE};;;; DEGRADED=${QTD_DEGRADED};;;; ONLINE=${QTD_ONLINE};;;; "
        exit 2;
fi

#Saida de erro
echo "Erro desconhecido!"
exit 3;