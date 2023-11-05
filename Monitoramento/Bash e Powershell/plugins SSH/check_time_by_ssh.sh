#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/check_time_by_ssh.sh
# Sistema.............: OpMon
# Data da Criacao.....: 02/03/2018
# Criado por..........: Wander Maia da Silva
#*****************************************************************************************************************************************************
# Descricao...........: Verifica a diferença entre a hora do servidor e o monitoramento.
# Entrada.............: Dados para acesso e valores de alarme
# Saida...............: Diferença da hora (em segundos) entre o servidor e o Monitoramento
# Linha do Plugin.....: /usr/local/opmon/libexec/custom/check_time_by_ssh.sh -H $HOSTADDRESS$ -u $ARG1$ -s $ARG2$ -w $ARG3$ -c $ARG4$
# Execução Manual.....: /usr/local/opmon/libexec/custom/check_time_by_ssh.sh -H 127.0.0.1 -u usuario -s 'senha' -w 60 -c 90
#*****************************************************************************************************************************************************

# Menu de Ajuda
help () {
  echo -e  "\n *** -> Descrição do Plugin <- *** \n" 
  echo -e  " Plugin para verificação da diferença entre a hora do servidor e o monitoramento por SSH. Necessário instalar o sshpass e o bc para que o plugin funcione corretamente."
  echo -e  " Utiliza valores crescentes para gerar os alertas (quanto maior o valor, pior).\n"
  echo -e  " *** -> Parametros: <- *** \n" 
  echo -e  " -H  : IP do host que será monitorado"
  echo -e  " -u  : Usuário para a conexão por ssh"
  echo -e  " -s  : Senha do Usuário para a conexão"
  echo -e  " -w  : Valor de warning (tempo em segundos)"
  echo -e  " -c  : Valor de critical (tempo em segundos)\n"
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

  echo -e "$1 | DIFERENCA_TEMPO=${VALIDA_DIFERENCA}s;${WARNING};${CRITICAL};; "
}  

# Realizando a coleta dos dados de memória do servidor
HORA_SERVIDOR=`/usr/bin/sshpass -p ${SENHA} ssh -o StrictHostKeyChecking=no ${USUARIO}@${HOST} "date +%s"`

# Coletando a hora atual em formato epoch - sshpass -p 'X@dM5eRV1d0r3s' ssh root@192.168.0.21 "sar -u 1 5"
HORA_ATUAL=`date +%s`

# Diferença entre dos servidor para o OpMon
DIFERENCA=`echo "${HORA_ATUAL} - ${HORA_SERVIDOR}"  | bc`

# Validando se a diferença é maior ou menor do que 0, em caso afirmativo, convertendo para uma diferença positiva.
if ((`bc <<< "${DIFERENCA} < 0 " `))
then
	VALIDA_DIFERENCA=`echo "${DIFERENCA} * (-1)" | bc`
else
	VALIDA_DIFERENCA=`echo ${DIFERENCA}`
fi


# Validando os limites de alerta e gerando mensagens juntamente com o performance data.
if ((`bc <<< "${VALIDA_DIFERENCA} < ${WARNING}" `))
then
	PERFORMANCE "A diferença de horário entre o servidor e o OpMon está ok! Diferença: ${DIFERENCA}s"
	exit 0;

elif ((`bc <<< "${VALIDA_DIFERENCA} < ${CRITICAL}" `))
then
	PERFORMANCE "A diferença de horário entre o servidor e o OpMon está em Alerta! Diferença: ${DIFERENCA}s"
	exit 1;
else
	PERFORMANCE "A diferença de horário entre o servidor e o OpMon está Crítico! Diferença: ${DIFERENCA}s"
	exit 2;
fi

#Saida de erro
echo "Erro desconhecido!"
exit 3;