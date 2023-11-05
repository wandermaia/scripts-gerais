#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/check_cpu_storm_v3700.sh
# Sistema.............: Opmon
# Data da Criacao.....: 18/06/2018
# Criado por..........: Wander Maia da Silva
#*****************************************************************************************************************************************************
# Descricao...........: Verifica o percentual de utilização de CPU do storage IBM.
# Entrada.............: Dados para acesso ao storage e limites de alerta.
# Saida...............: Informação sobre o consumo de CPU do equipamento.
# Linha do Plugin.....: /usr/local/opmon/libexec/custom/check_cpu_storm_v3700.sh -H $HOSTADDRESS$ -u $ARG1$ -s $ARG2$ -w $ARG3$ -c $ARG4$
# Execução Manual.....: /usr/local/opmon/libexec/custom/check_cpu_storm_v3700.sh -H 127.0.0.1 -u usuario -s 'senha' -w 90 -c 95
#*****************************************************************************************************************************************************


# Menu de Ajuda
help () {
  echo -e  "\n *** -> Descrição do Plugin<- *** \n"
  echo -e  " Plugin para verificar o percentual de utilização de CPU no Storage IBM"
  echo -e  " Utiliza valores crescentes (quanto maior, pior) do percentual de utilização da CPU para gerar os alertas. \n"
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
COLETA_CPU=`/usr/bin/sshpass -p ${SENHA} /usr/bin/ssh -o StrictHostKeyChecking=no ${USUARIO}@"${HOST}" "lssystemstats -filtervalue stat_name=cpu_pc"`

# Segregando o número de IOPS
PERCENTUAL_CPU=`echo -e "${COLETA_CPU}" | tail -n 1 | awk '{print $2}'`

# Comparando os valores de alerta
if ((`bc <<< "${PERCENTUAL_CPU} < ${WARNING}" `))
then
        echo "O utilização de CPU está ok! Utilização CPU: ${PERCENTUAL_CPU}% | UTILIZACAO_CPU=${PERCENTUAL_CPU}%;${WARNING};${CRITICAL};0;100 "
        exit 0;

elif ((`bc <<< "${PERCENTUAL_CPU} < ${CRITICAL}" `))
then
        echo "O utilização de CPU está em alerta! Utilização CPU: ${PERCENTUAL_CPU}% | UTILIZACAO_CPU=${PERCENTUAL_CPU}%;${WARNING};${CRITICAL};0;100 "
        exit 1;
else
        echo "O utilização de CPU está crítico! Utilização CPU: ${PERCENTUAL_CPU}% | UTILIZACAO_CPU=${PERCENTUAL_CPU}%;${WARNING};${CRITICAL};0;100 "
        exit 2;
fi

#Saida de erro
echo "Erro desconhecido!"
exit 3;