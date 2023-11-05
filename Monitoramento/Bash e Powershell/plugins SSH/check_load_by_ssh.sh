#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/check_load_by_ssh.sh
# Sistema.............: OpMon
# Data da Criacao.....: 02/03/2018
# Criado por..........: Wander Maia da Silva
#*****************************************************************************************************************************************************
# Descricao...........: Verifica o load servidor por SSH. Necessário instalar o sshpass e o bc para que o plugin funcione corretamente.
# Entrada.............: Dados para acesso e valores de alarme
# Saida...............: Load do servidor
# Linha do Plugin.....: /usr/local/opmon/libexec/custom/check_load_by_ssh.sh -H $HOSTADDRESS$ -u $ARG1$ -s $ARG2$ -w $ARG3$ -c $ARG4$
# Execução Manual.....: /usr/local/opmon/libexec/custom/check_load_by_ssh.sh -H 127.0.0.1 -u usuario -s 'senha' -w 5,4,3 -c 7,6,5
#*****************************************************************************************************************************************************

# Menu de Ajuda
help () {
  echo -e  "\n *** -> Descrição do Plugin <- *** \n" 
  echo -e  " Plugin para verificação do load do servidor por SSH. Necessário instalar o sshpass e o bc para que o plugin funcione corretamente."
  echo -e  " Utiliza valores crescentes para gerar os alertas (quanto maior o valor, pior).\n"
  echo -e  " *** -> Parametros: <- *** \n" 
  echo -e  " -H  : IP do host que será monitorado"
  echo -e  " -u  : Usuário para a conexão por ssh"
  echo -e  " -s  : Senha do Usuário para a conexão"
  echo -e  " -w  : Valor de warning (valor no formado x,y,z referente as métricas load)"
  echo -e  " -c  : Valor de critical (valor no formado x,y,z referente as métricas load)\n"
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
[ -z ${HOST} ] && echo -e "\n *** ->> Necessário o parâmetro com o IP do Host <<- ***" && help
[ -z ${USUARIO} ] && echo -e "\n *** ->> Necessário o parâmetro com o usuário <<- ***" && help
[ -z ${SENHA} ] && echo -e "\n *** ->> Necessário o parâmetro com a senha de acesso<<- ***" && help
[ -z ${WARNING} ] && echo -e "\n *** ->> Necessário o parâmetro Warning <<- ***" && help
[ -z ${CRITICAL} ] && echo -e "\n *** ->> Necessário o parâmetro Critical <<- ***" && help


# Função que gera o Performance Data
function PERFORMANCE () {

  echo -e "$1 | Load-1=${LOAD_1};${WARNING_1};${CRITICAL_1};; Load-5=${LOAD_5};${WARNING_5};${CRITICAL_5};; Load-15=${LOAD_15};${WARNING_15};${CRITICAL_15};;"
}  

# Realizando a coleta dos dados de memória do servidor
COLETA_COMANDO=`/usr/bin/sshpass -p ${SENHA} ssh -o StrictHostKeyChecking=no ${USUARIO}@${HOST} "uptime"`

# Exemplo da saída do comando:
# 13:52:57 up 36 days,  3:38,  0 users,  load average: 0.93, 1.23, 1.48

# Segregando os valores do load
LOAD_1=`echo ${COLETA_COMANDO} | awk -F 'average:' '{print $2}' | awk '{print $1}' | sed 's/,//g'`
LOAD_5=`echo ${COLETA_COMANDO} | awk -F 'average:' '{print $2}' | awk '{print $2}' | sed 's/,//g'`
LOAD_15=`echo ${COLETA_COMANDO} |  awk -F 'average:' '{print $2}' | awk '{print $3}'`

# -w 5,4,3 -c 7,6,5
# Segregando os valores de Warning
WARNING_1=`echo ${WARNING} | awk -F ',' '{print $1}' | sed 's/ //g'`
WARNING_5=`echo ${WARNING} | awk -F ',' '{print $2}' | sed 's/ //g'`
WARNING_15=`echo ${WARNING} | awk -F ',' '{print $3}' | sed 's/ //g'`

# Segregando os valores de Critical
CRITICAL_1=`echo ${CRITICAL} | awk -F ',' '{print $1}' | sed 's/ //g'`
CRITICAL_5=`echo ${CRITICAL} | awk -F ',' '{print $2}' | sed 's/ //g'`
CRITICAL_15=`echo ${CRITICAL} | awk -F ',' '{print $3}' | sed 's/ //g'`


# Validando os limites de alerta e gerando mensagens juntamente com o performance data.
if ((`bc <<< "${LOAD_1} < ${WARNING_1}"`)) && ((`bc <<< "${LOAD_5} < ${WARNING_5}"`)) && ((`bc <<< "${LOAD_15} < ${WARNING_15}"`))
then
	PERFORMANCE "Load do Servidor está OK! Load-1: ${LOAD_1} Load-5: ${LOAD_5} Load-15: ${LOAD_15}"
	exit 0;

elif ((`bc <<< "${LOAD_1} < ${CRITICAL_1}"`)) && ((`bc <<< "${LOAD_5} < ${CRITICAL_5}"`)) && ((`bc <<< "${LOAD_15} < ${CRITICAL_15}"`))
then
	PERFORMANCE "Load do Servidor está em alerta! Load-1: ${LOAD_1} Load-5: ${LOAD_5} Load-15: ${LOAD_15}"
	exit 1;
else
	PERFORMANCE "Load do Servidor está Crítico! Load-1: ${LOAD_1} Load-5: ${LOAD_5} Load-15: ${LOAD_15}"
	exit 2;
fi

#Saida de erro
echo "Erro desconhecido!"
exit 3;