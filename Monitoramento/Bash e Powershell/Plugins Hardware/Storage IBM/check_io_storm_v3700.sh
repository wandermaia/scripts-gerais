#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/check_io_storm_v3700.sh
# Sistema.............: Opmon
# Data da Criacao.....: 15/06/2018
# Criado por..........: Wander Maia da Silva
#*****************************************************************************************************************************************************
# Descricao...........: Verifica a quantidade de IOPS do storage.
# Entrada.............: Dados para acesso ao storage e limites de alerta.
# Saida...............: Informação sobre o consumo de IO do equipamento.
# Linha do Plugin.....: /usr/local/opmon/libexec/custom/check_io_storm_v3700.sh -H $HOSTADDRESS$ -u $ARG1$ -s $ARG2$ -w $ARG3$ -c $ARG4$
# Execução Manual.....: /usr/local/opmon/libexec/custom/check_io_storm_v3700.sh -H 127.0.0.1 -u usuario -s 'senha' -w 1000 -c 1500
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
  echo -e  " -w  : Valor de warning (percentual de utilização)"
  echo -e  " -c  : Valor de critical (percentual de utilização) \n"
  exit 0
}

# Menu de validacao de entradas
while getopts ":w:c:H:u:s:hd" Option
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
[ -z ${WARNING} ] && echo -e "\n *** ->> Necessário o parâmetro Warning <<- ***" && help
[ -z ${CRITICAL} ] && echo -e "\n *** ->> Necessário o parâmetro Critical <<- ***" && help

# Realizando a coleta dos dados sobre IO.
COLETA_IO=`/usr/bin/sshpass -p ${SENHA} /usr/bin/ssh -o StrictHostKeyChecking=no ${USUARIO}@"${HOST}" "lssystemstats -filtervalue stat_name=fc_io"`

# Segregando o número de IOPS
NUMERO_IOPS=`echo -e "${COLETA_IO}" | tail -n 1 | awk '{print $2}'`

# Comparando os valores de alerta
if [ ${NUMERO_IOPS} -lt ${WARNING} ]
then
        echo "O Número de IOPS está ok! NUMERO_IOPS: ${NUMERO_IOPS} IOPS | NUMERO_IOPS=${NUMERO_IOPS}IOPS;${WARNING};${CRITICAL};; "
        exit 0;

elif [ ${NUMERO_IOPS} -lt ${CRITICAL} ]
then
        echo "O Número de IOPS está em alerta! NUMERO_IOPS: ${NUMERO_IOPS} IOPS | NUMERO_IOPS=${NUMERO_IOPS}IOPS;${WARNING};${CRITICAL};; "
        exit 1;
else
        echo "O Número de IOPS está Crítico! NUMERO_IOPS: ${NUMERO_IOPS} IOPS | NUMERO_IOPS=${NUMERO_IOPS}IOPS;${WARNING};${CRITICAL};; "
        exit 2;
fi

#Saida de erro
echo "Erro desconhecido!"
exit 3;