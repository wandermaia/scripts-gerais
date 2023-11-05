#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/check_http_200.sh
# Sistema.............: OpMon
# Data da Criacao.....: 13/04/2018
# Criado por..........: Wander Maia da Silva
#*****************************************************************************************************************************************************
# Descricao...........: Verifica o código de retorno da URL informada por parâmetro.
# Entrada.............: URL para verificação
# Saida...............: Código de Saída e status de alerta.
# Linha do Plugin.....: /usr/local/opmon/libexec/custom/check_http_200.sh -u $ARG1$
# Execução Manual.....: /usr/local/opmon/libexec/custom/check_http_200.sh -u "http://127.0.0.1/main.php?modulo=login&organizacao=riccicliente&site=123"
#*****************************************************************************************************************************************************

# Menu de Ajuda
help () {
  echo -e  "\n *** -> Descrição do Plugin <- *** \n" 
  echo -e  " Plugin para verificação do código de retorno da URL informada por parâmetro."
  echo -e  " *** -> Parametros: <- *** \n" 
  echo -e  " -u  : URL para verificação.\n"
  exit 0
}

# Menu de validacao de entradas
while getopts "u:hd" Option
do
  case $Option in
    u )
      URL=$OPTARG
      ;;
    h ) 
      help
      ;;
  esac
done

# Check parameter
[ -z ${URL} ] && echo -e "\n *** ->> Necessário o parâmetro com a URL que será verificada. <<- ***" && help

# Coletando o código de Retorno. Exemplo de saída ok: HTTP/1.1 200 OK
CODIGO_RETORNO=`curl -Is --connect-timeout 5 ${URL} | grep HTTP`

# Validando o código de retorno
RETORNO=`echo ${CODIGO_RETORNO} | grep 'HTTP/1.1 200 OK' | wc -l`

# Verificando se está em alerta 
if [ ${RETORNO} -gt 0 ]
then
	echo "Código de Retorno ok! CODIGO_RETORNO: ${CODIGO_RETORNO}"
	exit 0;
else
	echo "Código de Retorno Crítico! CODIGO_RETORNO: ${CODIGO_RETORNO}"
	exit 2;
fi

#Saida de erro
echo "Erro desconhecido!"
exit 0;