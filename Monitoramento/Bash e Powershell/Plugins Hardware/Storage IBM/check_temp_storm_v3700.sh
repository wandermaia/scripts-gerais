#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/check_temp_storm_v3700.sh
# Sistema.............: Opmon
# Data da Criacao.....: 15/06/2018
# Criado por..........: Wander Maia da Silva
#*****************************************************************************************************************************************************
# Descricao...........: Verifica a temperatura do Storage Stormwize 3700 IBM.
# Entrada.............: Dados para acesso ao storage e limites de alerta.
# Saida...............: Informação sobre a temperatura atual do equipamento
# Linha do Plugin.....: /usr/local/opmon/libexec/custom/check_temp_storm_v3700.sh -H $HOSTADDRESS$ -u $ARG1$ -s $ARG2$ -w $ARG3$ -c $ARG4$
# Execução Manual.....: /usr/local/opmon/libexec/custom/check_temp_storm_v3700.sh -H 127.0.0.1 -u usuario -s 'senha' -w 23 -c 24
#*****************************************************************************************************************************************************


# Menu de Ajuda
help () {
  echo -e  "\n *** -> Descrição do Plugin<- *** \n"
  echo -e  " Plugin para verificar a temperatura do Storage Stormwize 3700 IBM."
  echo -e  " Utiliza valores crescentes (quanto maior, pior) da temperatura para gerar os alertas. \n"
  echo -e  " *** -> Parametros: <- *** \n"
  echo -e  " -H  : IP do Storage"
  echo -e  " -u  : Usuário para acesso ao Storage"
  echo -e  " -s  : Senha do Usuário"
  echo -e  " -w  : Valor de warning (em graus celsius)"
  echo -e  " -c  : Valor de critical (em graus celsius) \n"
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

# Realizando a coleta dos dados sobre IO
COLETA_TEMPERATURA=`/usr/bin/sshpass -p ${SENHA} /usr/bin/ssh -o StrictHostKeyChecking=no ${USUARIO}@"${HOST}" "lssystemstats -filtervalue stat_name=temp_c "`

# Segregando o valor da temperatura atual
TEMPERATURA=`echo -e "${COLETA_TEMPERATURA}" | tail -n 1 | awk '{print $2}'`

# Comparando os valores de alerta
if [ ${TEMPERATURA} -lt ${WARNING} ]
then
        echo "A temperatura está ok! TEMPERATURA: ${TEMPERATURA}°C | TEMPERATURA=${TEMPERATURA}°C;${WARNING};${CRITICAL};; "
        exit 0;

elif [ ${TEMPERATURA} -lt ${CRITICAL} ]
then
        echo "A temperatura está em alerta! TEMPERATURA: ${TEMPERATURA}°C | TEMPERATURA=${TEMPERATURA}°C;${WARNING};${CRITICAL};; "
        exit 1;
else
        echo "A temperatura está crítica! TEMPERATURA: ${TEMPERATURA}°C | TEMPERATURA=${TEMPERATURA}°C;${WARNING};${CRITICAL};; "
        exit 2;
fi

#Saida de erro
echo "Erro desconhecido!"
exit 3;