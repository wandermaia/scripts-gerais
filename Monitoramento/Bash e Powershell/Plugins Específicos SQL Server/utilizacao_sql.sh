#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/utilizacao_sql.sh
# Sistema.............: Opmon
# Data da Criacao.....: 07/11/2016
# Criado por..........: Wander Maia da Silva
#*****************************************************************************************************************************************************
# Descricao...........: Verificar o espaço utilizado no banco de dados
# Entrada.............: Dados para acesso e valores de alarme
# Saida...............: Espaço utilizado pelo banco de dados.
# Link Referência.....: https://dataginger.com/2013/06/28/sql-server-understanding-sp_spaceused-results-for-database-size-information/
# Linha do Plugin.....: /usr/local/opmon/libexec/custom/utilizacao_sql.sh -H $HOSTADDRESS$ -p $ARG1$ -u $ARG2$ -s $ARG3$ -w $ARG4$ -c $ARG5$ -b $ARG6$
# Execução Manual.....: /usr/local/opmon/libexec/custom/utilizacao_sql.sh -H 127.0.0.1 -p 1433 -u usuario -s senha -w 90 -c 95 -b database -a 0
#*****************************************************************************************************************************************************

# Menu de Ajuda
help () {
  echo -e  "\n *** -> Descrição do Plugin<- *** \n" 
  echo -e  " Plugin para verificação do espaço utilizados pelo banco de dados no SQL Server."
  echo -e  " Utiliza valores crescentes para gerar os alertas (quanto maior o valor, pior).\n"
  echo -e  " *** -> Parametros: <- *** \n" 
  echo -e  " -H  : IP do host que será monitorado"
  echo -e  " -p  : Porta de acesso para conexão ao SQLServer"
  echo -e  " -u  : Usuário do SQLServer"
  echo -e  " -s  : Senha do Usuário do SQL Server"
  echo -e  " -b  : Nome do Banco de Dados"
  echo -e  " -a  : Ativar alerta para os operadores (0 para sim e 1 para não)"
  echo -e  " -w  : Valor de warning"
  echo -e  " -c  : Valor de critical \n"
  exit 0
}

# Menu de validacao de entradas
while getopts ":w:c:a:H:p:u:s:b:hd" Option
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
    b )
      BANCO=$OPTARG
      ;;
    a )
      ALERTA=$OPTARG
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
[ -z $BANCO ] && echo -e "\n *** ->> Necessário o parâmetro com o Nome do Banco de Dados <<- ***" && help
[ -z $ALERTA ] && echo -e "\n *** ->> Necessário o parâmetro informando se devem ser gerados alertas <<- ***" && help

# Validando as opções de alerta
if [ ${ALERTA} != 0 ] && [ ${ALERTA} != 1 ]
then
        echo "Erro! Parâmetro errado para o item de geração de alertas!";
        exit 3;
fi;


# Realizando a consulta dos dados no SQL Server utilizando a procedure de sistema sp_spaceused
CONSULTA=`echo -e "use ${BANCO} EXEC sp_spaceused \ngo" | tsql -H $HOST -p $PORTA -U $USUARIO -P $SENHA -o fhq`

# Validando a consulta foi realizada com sucesso
LINHAS=`echo ${CONSULTA} | wc -l`
if [ -z $LINHAS ]
then
        echo "Erro desconhecido! Resposta nula da query!";
        exit 3;
fi;

# Segregando os dados obtidos através da consulta ao banco de dados
TOTAL_DB_SIZE=`echo "${CONSULTA}" | head -n 1 |  awk '{print $2}'`
UNALLOCATED_SPACE=`echo "${CONSULTA}" | head -n 1 | awk '{print $4}'`
RESERVED=`echo "${CONSULTA}" | head -n 2 | tail -n 1 | awk '{print $1}'`
DATA=`echo "${CONSULTA}" | head -n 2 | tail -n 1 |  awk '{print $3}'`
INDEX_SIZE=`echo "${CONSULTA}" | head -n 2 | tail -n 1 |  awk '{print $5}'`
UNUSED=`echo "${CONSULTA}" | head -n 2 | tail -n 1 | awk '{print $7}'`

# Convertendo para MB as informações que a procedure retorna em KB.
RESERVED=`echo "scale=2; ${RESERVED} / 1024 " | bc`
DATA=`echo "scale=2; ${DATA} / 1024 " | bc`
INDEX_SIZE=`echo "scale=2; ${INDEX_SIZE} / 1024 " | bc`
UNUSED=`echo "scale=2; ${UNUSED} / 1024 " | bc`

# Calculando o tamanho do arquivo de LOG
SIZE_LOG=`echo "scale=2; ${TOTAL_DB_SIZE} - ( ${RESERVED} + ${UNALLOCATED_SPACE} ) " | bc`

# Calculando o percentual de espaço alocado:
PERCENTUAL_ALOCADO=`echo "scale=2; ( ${RESERVED} / ( ${RESERVED} + ${UNALLOCATED_SPACE} ) ) * 100" | bc`


# Saída do performance data sem a geração de alertas no monitoramento
if [ ${ALERTA} == 1 ]
then
	echo "Métricas de utilização de Espaço no Banco de Dados! Tamanho Total do Banco de Dados: ${TOTAL_DB_SIZE} MB | PERCENTUAL_ALOCADO=${PERCENTUAL_ALOCADO}%;$WARNING;$CRITICAL;; TOTAL_DB_SIZE=${TOTAL_DB_SIZE}MB;;;; SIZE_LOG=${SIZE_LOG}MB;;;; DATA=${DATA}MB;;;; INDEX_SIZE=${INDEX_SIZE}MB;;;; UNUSED_SPACE=${UNUSED}MB;;;; UNALLOCATED_SPACE=${UNALLOCATED_SPACE}MB;;;; RESERVED=${RESERVED}MB;;;; "
	exit 0;
fi


# Comparando os valores de alerta
if ((`bc <<< "${PERCENTUAL_ALOCADO} < ${WARNING}" `))
then
	echo "Percentual alocado do banco ${BANCO} está Ok! PERCENTUAL_ALOCADO: ${PERCENTUAL_ALOCADO}% | PERCENTUAL_ALOCADO=${PERCENTUAL_ALOCADO}%;$WARNING;$CRITICAL;; TOTAL_DB_SIZE=${TOTAL_DB_SIZE}MB;;;; SIZE_LOG=${SIZE_LOG}MB;;;; DATA=${DATA}MB;;;; INDEX_SIZE=${INDEX_SIZE}MB;;;; UNUSED_SPACE=${UNUSED}MB;;;; UNALLOCATED_SPACE=${UNALLOCATED_SPACE}MB;;;; RESERVED=${RESERVED}MB;;;; "
	exit 0;

elif ((`bc <<< "${PERCENTUAL_ALOCADO} < ${CRITICAL}" `))
then
	echo "Percentual alocado do banco ${BANCO} está em alerta! PERCENTUAL_ALOCADO: ${PERCENTUAL_ALOCADO}% | PERCENTUAL_ALOCADO=${PERCENTUAL_ALOCADO}%;$WARNING;$CRITICAL;; TOTAL_DB_SIZE=${TOTAL_DB_SIZE}MB;;;; SIZE_LOG=${SIZE_LOG}MB;;;; DATA=${DATA}MB;;;; INDEX_SIZE=${INDEX_SIZE}MB;;;; UNUSED_SPACE=${UNUSED}MB;;;; UNALLOCATED_SPACE=${UNALLOCATED_SPACE}MB;;;;  RESERVED=${RESERVED}MB;;;; "
	exit 1;
else
	echo "Percentual alocado do banco ${BANCO} está em estado Crítico! PERCENTUAL_ALOCADO: ${PERCENTUAL_ALOCADO}% | PERCENTUAL_ALOCADO=${PERCENTUAL_ALOCADO}%;$WARNING;$CRITICAL;; TOTAL_DB_SIZE=${TOTAL_DB_SIZE}MB;;;; SIZE_LOG=${SIZE_LOG}MB;;;; DATA=${DATA}MB;;;; INDEX_SIZE=${INDEX_SIZE}MB;;;; UNUSED_SPACE=${UNUSED}MB;;;; UNALLOCATED_SPACE=${UNALLOCATED_SPACE}MB;;;;  RESERVED=${RESERVED}MB;;;; "
	exit 2;
fi

#Saida de erro
echo "Erro desconhecido!"
exit 3;


###################################################################################################################################################

# Abaixo segue um exemplo da saída da execução da procedure utilizada nesse plugin:
#
# database_name	database_size	unallocated space
# Datase		839023.50 MB	142458.71 MB
#
# reserved		data			index_size	unused
# 682247976 KB	638554200 KB	43236896 KB	456880 KB


