#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/check_resource_semaphore_mssql.sh
# Sistema.............: Opmon
# Data da Criação.....: 09/08/2018
# Criado por..........: Wander Maia da Silva
#*****************************************************************************************************************************************************
# Descricao...........: Plugin para verificação se está havendo concorrência de recursos com base no resource_semaphore.
# Entrada.............: Dados para acesso e limites de alerta.
# Saida...............: Quantidade de waits do tipo resource_semaphore
# Linha do Plugin.....: /usr/local/opmon/libexec/custom/check_resource_semaphore_mssql.sh -S $ARG1$ -u $ARG2$ -p $ARG3$ -w $ARG4$ -c $ARG5$
# Execução Manual.....: /usr/local/opmon/libexec/custom/check_resource_semaphore_mssql.sh -S 127.0.0.1 -u usuario -p 'senha' -w 1 -c 1
#*****************************************************************************************************************************************************


# Menu de Ajuda
help () {

    cat <<EOF

Descrição do Plugin
			  
	Plugin para verificação se está havendo concorrência de recursos com base no resource_semaphore.
 
Parâmetros

	-S  : SERVER previamente cadastrado no arquivo /etc/freetds.conf
	-u  : Usuário do SQL Server
	-p  : Senha do Usuário do SQL Server
	-w  : Valor para alerta
	-c  : Valor para crítico
 
EOF

	exit
}

# Menu de validacao de entradas
while getopts ":S:u:p:w:c:hd" Option
do
  case $Option in
    S )
      SERVER=$OPTARG
      ;;
    u )
      USUARIO=$OPTARG
      ;;
    p )
      PASSWORD=$OPTARG
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
[ -z ${SERVER} ] && echo -e "\n *** ->> Necessário o parâmetro com o nome do SERVER <<- ***" && help
[ -z ${USUARIO} ] && echo -e "\n *** ->> Necessário o parâmetro com o usuário do SQL Server <<- ***" && help
[ -z ${PASSWORD} ] && echo -e "\n *** ->> Necessário o parâmetro com a senha de acesso ao SQL Server <<- ***" && help
[ -z ${WARNING} ] && echo -e "\n *** ->> Necessário o parâmetro informando o parâmetro de alerta <<- ***" && help
[ -z ${CRITICAL} ] && echo -e "\n *** ->> Necessário o parâmetro informando o parâmetro de crítico <<- ***" && help


# Coletando os dados de latência do datafile
CONSULTA=`bsqldb -q -U ${USUARIO} -P ${PASSWORD} -S ${SERVER} -t \| <<EOF
				
				USE master
				SELECT COUNT(*) FROM SYSPROCESSES where lastwaittype='RESOURCE_SEMAPHORE'
				
EOF`

# Validando a consulta foi realizada com sucesso
VALIDA_CONSULTA=`echo ${CONSULTA} | wc -w`
if [ ${VALIDA_CONSULTA} -lt 1 ]
then
        echo "Erro no resultado da query! Verifique os dados Informados.";
        exit 3;
fi;


# Verificando os limites de alerta
if [ ${CONSULTA} -lt ${WARNING} ]
then
        echo -e "Não existem waits do tipo RESOURCE_SEMAPHORE! NUMERO_RESOURCE_SEMAPHORE: ${CONSULTA} | NUMERO_RESOURCE_SEMAPHORE=${CONSULTA};${WARNING};${CRITICAL};; "
        exit 0;
		
elif [ ${CONSULTA} -lt ${CRITICAL} ]
then
        echo -e "A quantidade de waits do tipo RESOURCE_SEMAPHORE está em alerta! NUMERO_RESOURCE_SEMAPHORE: ${CONSULTA} | NUMERO_RESOURCE_SEMAPHORE=${CONSULTA};${WARNING};${CRITICAL};; "
        exit 1;

# Valor Ok
else
        echo -e "A quantidade de waits do tipo RESOURCE_SEMAPHORE está crítica! NUMERO_RESOURCE_SEMAPHORE: ${CONSULTA} | NUMERO_RESOURCE_SEMAPHORE=${CONSULTA};${WARNING};${CRITICAL};; "
        exit 2; 
fi

#Saida de erro
echo "Erro desconhecido!"
exit 3;