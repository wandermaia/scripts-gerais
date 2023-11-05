#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/batch_requests.sh
# Sistema.............: Opmon
# Data da Criacao.....: 29/08/2016
# Criado por..........: Wander Maia da Silva
#*****************************************************************************************************************************************************
# Descricao...........: Verificar o número de Batch-Requests por segundo
# Entrada.............: Dados para acesso e valores de alarme
# Saida...............: Número de Batch-Requests por segund
# Linha do Plugin.....: /usr/local/opmon/libexec/custom/batch_requests.sh -H $HOSTADDRESS$ -p $ARG1$ -u $ARG2$ -s $ARG3$ -w $ARG4$ -c $ARG5$
# Execução Manual.....: /usr/local/opmon/libexec/custom/batch_requests.sh -H 127.0.0.1 -p 1433 -u usuario -s senha -w 1000 -c 2000
#*****************************************************************************************************************************************************

# Menu de Ajuda
help () {
  echo -e  "\n *** -> Descrição do Plugin<- *** \n" 
  echo -e  " Plugin para verificação do número de Batch-Requests por segundo no SQLServer."
  echo -e  " Utiliza valores crescentes para gerar os alertas (quanto maior o valor, pior).\n"
  echo -e  " *** -> Parametros: <- *** \n" 
  echo -e  " -H  : IP do host que será monitorado"
  echo -e  " -p  : Porta de acesso para conexão ao SQLServer"
  echo -e  " -u  : Usuário do SQLServer"
  echo -e  " -s  : Senha do Usuário do SQLServer"
  echo -e  " -w  : Valor de warning"
  echo -e  " -c  : Valor de critical \n"
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
      PORTA=$OPTARG
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
[ -z $HOST ] && echo -e "\n *** ->> Necessário o parâmetro com o IP do Host <<- ***" && help
[ -z $PORTA ] && echo -e "\n *** ->> Necessário o parâmetro com a porta de conexão do SQLServer <<- ***" && help
[ -z $USUARIO ] && echo -e "\n *** ->> Necessário o parâmetro com o usuário do SQLServer <<- ***" && help
[ -z $SENHA ] && echo -e "\n *** ->> Necessário o parâmetro com a senha de acesso ao SQLServer <<- ***" && help
[ -z $WARNING ] && echo -e "\n *** ->> Necessário o parâmetro Warning <<- ***" && help
[ -z $CRITICAL ] && echo -e "\n *** ->> Necessário o parâmetro Critical <<- ***" && help

# Verifica se o número de Batch-Requests por segundo pelo SQLServer
BATCH_REQUESTS=`echo -e "DECLARE @BatchRequests BIGINT; SELECT @BatchRequests = cntr_value FROM sys.dm_os_performance_counters WHERE counter_name = 'Batch Requests/sec'; WAITFOR DELAY '00:00:10'; SELECT (cntr_value - @BatchRequests) / 10 FROM sys.dm_os_performance_counters WHERE counter_name = 'Batch Requests/sec'; \ngo" | tsql -H $HOST -p $PORTA -U $USUARIO -P $SENHA -o fhq`

# Validando a consulta foi realizada com sucesso
if [ -z $BATCH_REQUESTS ]
then
        echo "Erro desconhecido! Resposta nula da query!";
        exit 3;
fi;

# Comparando os valores de alerta
if [ $BATCH_REQUESTS -lt $WARNING ]
then
	echo "Quantidade de Batch Requests/sec está Ok! Número de Batch Requests/sec= $BATCH_REQUESTS | Batch-Requests/sec=$BATCH_REQUESTS;$WARNING;$CRITICAL"
	exit 0;

elif [ $BATCH_REQUESTS -lt $CRITICAL ]
then
	echo "Quantidade de Batch Requests/sec está em Alerta! Número de Batch Requests/sec= $BATCH_REQUESTS | Batch-Requests/sec=$BATCH_REQUESTS;$WARNING;$CRITICAL"
	exit 1;
else
	echo "Quantidade de Batch Requests/sec está Crítico! Número de Batch Requests/sec= $BATCH_REQUESTS | Batch-Requests/sec=$BATCH_REQUESTS;$WARNING;$CRITICAL"
	exit 2;
fi

#Saida de erro
echo "Erro desconhecido!"
exit 3;