#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/check_WS.sh
# Sistema.............: Opmon
# Data da Criacao.....: 14/02/2017
# Criado por..........: Wander Maia da Silva
#*****************************************************************************************************************************************************
# Descricao...........: Plugin para verificação da disponibilidade e tempo de acesso ao webservice informado.
# Entrada.............: ENDPOINT e a REQUEST (xml) do Web Service, além dos limites de alerta.
# Saida...............: HTTP code e informação do status do serviço.
# Linha do Plugin.....: /usr/local/opmon/libexec/custom/check_WS.sh -W $ARG1$ -R $ARG2$ -w $ARG3$ -c $ARG4$
# Execução Manual.....: /usr/local/opmon/libexec/custom/check_WS.sh -W https://apps.correios.com.br/SigepMasterJPA/AtendeClienteService/AtendeCliente?wsdl -R /usr/local/opmon/libexec/custom/consultaCEP.xml -w 1800 -c 2000
#*****************************************************************************************************************************************************

# Menu de Ajuda
help () {
  echo -e  "\n *** -> Descrição do Plugin<- *** \n" 
  echo -e  " Plugin para verificação da disponibilidade do webservice informado."
  echo -e  " Utiliza como entrada o endereço do webservice e o arquivo de xml utilizado na consulta.\n"
  echo -e  " *** -> Parametros: <- *** \n" 
  echo -e  " -W  : URL do Web service"
  echo -e  " -R  : arquivo de request (xml)"
  echo -e  " -w  : Valor de warning (tempo da consulta em milissegundos)"
  echo -e  " -c  : Valor de critical (tempo da consulta em milissegundos) \n"
  exit 0
}

# Menu de validacao de entradas
while getopts ":W:R:w:c:hd" Option
do
  case $Option in
    W )
      ENDPOINT=$OPTARG
      ;;
    R )
      REQUEST=$OPTARG
      ;;
    w )
      WARNING=$OPTARG
      ;;
    c )
      CRITICAL=$OPTARG
      ;;
    h ) 
      help
      ;;
  esac
done

# Check parameter
[ -z $ENDPOINT ] && echo -e "\n *** ->> Necessário o parâmetro com a URL do Web Service <<- ***" && help
[ -z $REQUEST ] && echo -e "\n *** ->> Necessário o parâmetro com o xml request <<- ***" && help
[ -z $WARNING ] && echo -e "\n *** ->> Necessário o parâmetro Warning <<- ***" && help
[ -z $CRITICAL ] && echo -e "\n *** ->> Necessário o parâmetro Critical <<- ***" && help

# Tempo inicial em epoch e nanossegundos
TEMPO_INICIAL=`date +%s.%N`

# Consulta ao Web Service monitorando o tempo
HTTP_CODE=`curl -s -w %{http_code} -H "Content-Type:text/xml; charset=utf-8" -d @${REQUEST} ${ENDPOINT} -o /dev/null`

# Tempo Final em epoch e nanossegundos
TEMPO_FINAL=`date +%s.%N`

# Verificando o tempo de execução em milissegundos
TEMPO_EXECUCAO=`echo "scale=3; ( ${TEMPO_FINAL} - ${TEMPO_INICIAL} ) / 0.001" | bc`


# Função que gera o Performance Data
function PERFORMANCE () {
  echo -e "$1 | TEMPO_DE_RESPOSTA=${TEMPO_EXECUCAO}ms;;;; HTTP_CODE=${HTTP_CODE};;;; "
}


# Validação do Status do Web Service. $HTTP_CODE contém o HTTP_CODE da chamada ao WS.
if [ $HTTP_CODE -eq 200 ]
then
	# Comparando os valores do tempo de resposta da consulta ao webservice
	if ((`bc <<< "${TEMPO_EXECUCAO} < ${WARNING}" `))
	then
		PERFORMANCE "Web Service disponível e tempo de resposta OK! TEMPO_DE_RESPOSTA=${TEMPO_EXECUCAO}ms HTTP_CODE=${HTTP_CODE}"
		exit 0;
	
	# Verificando se o o tempo de resposta está em alerta
	elif ((`bc <<< "${TEMPO_EXECUCAO} < ${CRITICAL}" `))
	then
		PERFORMANCE "Web Service disponível e tempo de resposta em Alerta! TEMPO_DE_RESPOSTA=${TEMPO_EXECUCAO}ms HTTP_CODE=${HTTP_CODE}"
		exit 1;
	
	# Verificando se o o tempo de resposta está em Crítico
	else
		PERFORMANCE "Web Service disponível e tempo de resposta Crítico! TEMPO_DE_RESPOSTA=${TEMPO_EXECUCAO}ms HTTP_CODE=${HTTP_CODE}"
		exit 2;
	fi

# Se o web service	estiver indisponível
else
	PERFORMANCE "Web Service Indisponível! HTTP_CODE=${HTTP_CODE}"
	exit 2;
fi

#Saida de erro
echo "Erro desconhecido!"
exit 3;