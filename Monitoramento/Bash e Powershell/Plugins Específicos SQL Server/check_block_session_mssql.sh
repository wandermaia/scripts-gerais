#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/check_block_session_mssql.sh
# Sistema.............: Opmon
# Data da Criação.....: 16/10/2018
# Criado por..........: Wander Maia da Silva
#*****************************************************************************************************************************************************
# Descricao...........: Plugin para verificação número de sessões bloqueadas a um tempo maior do que o informado.
# Entrada.............: Dados para acesso e limites de alerta
# Saida...............: Quantidade de sessões bloqueadas acima do tempo informado.
# Linha do Plugin.....: /usr/local/opmon/libexec/custom/check_block_session_mssql.sh -S $ARG1$ -u $ARG2$ -p $ARG3$ -t $ARG4$ -w $ARG5$ -c $ARG6$
# Execução Manual.....: /usr/local/opmon/libexec/custom/check_block_session_mssql.sh -S 127.0.0.1 -u usuario -p 'senha' -t '60000' -w 1 -c 2
#*****************************************************************************************************************************************************

# Menu de Ajuda
help () {

    cat <<EOF

Descrição do Plugin
			  
	Plugin para verificação número de sessões bloqueadas a um tempo maior do que o informado.
 
Parâmetros

	-h  : Exibe este menu de ajuda
	-S  : Nome do Servidor previamente cadastrado no arquivo /etc/freetds.conf
	-u  : Usuário para acesso ao SQL Server
	-p  : Senha do Usuário do SQL Server
	-t  : Tempo de bloqueio da sessão (em ms)
	-w  : Valor de warning para a quantidade de sessões bloqueadas a um tempo maior do que o limite informado
	-c  : Valor de critical para a quantidade de sessões bloqueadas a um tempo maior do que o limite informado

Exemplo de Utilização
  
	/usr/local/opmon/libexec/custom/check_block_session_mssql.sh -S 127.0.0.1 -u usuario -p 'senha' -t '60000' -w 1 -c 2
	
EOF

	exit
}

# Menu de validacao de entradas
while getopts ":S:u:p:t:w:c:hd" Option
do
  case $Option in
    w )
      WARNING=$OPTARG
      ;;
    c )
      CRITICAL=$OPTARG
      ;;
    S )
      SERVER=$OPTARG
      ;;
    u )
      USUARIO=$OPTARG
      ;;
    p )
      PASSWORD=$OPTARG
      ;;
    t )
      TEMPO=$OPTARG
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
[ -z ${TEMPO} ] && echo -e "\n *** ->> Necessário o parâmetro com valor de tempo de bloqueio <<- ***" && help
[ -z ${WARNING} ] && echo -e "\n *** ->> Necessário o parâmetro com o valor de Warning <<- ***" && help
[ -z ${CRITICAL} ] && echo -e "\n *** ->> Necessário o parâmetro com o valor de Critical <<- ***" && help

# Verificando a quantidade de sessões bloqueadas a mais tempo do que o informado.
NUMERO_SESSOES_BLOQUEADAS=`bsqldb -q -U ${USUARIO} -P ${PASSWORD} -S ${SERVER} -t \| <<EOF
                USE MASTER
                SELECT COUNT(*)
				FROM sys.dm_os_waiting_tasks 
				WHERE blocking_session_id <> 0 AND wait_duration_ms > '${TEMPO}'
EOF`


# Verificando os limites de alerta
if [ ${NUMERO_SESSOES_BLOQUEADAS} -lt ${WARNING} ]
then
        echo -e "Não existem sessões bloqueadas. | NUMERO_SESSOES_BLOQUEADAS=${NUMERO_SESSOES_BLOQUEADAS};${WARNING};${CRITICAL};; "
        exit 0;
		
elif [ ${NUMERO_SESSOES_BLOQUEADAS} -lt ${CRITICAL} ]
then
        echo -e "A quantidade de sessões bloqueadas está em alerta! Existem ${NUMERO_SESSOES_BLOQUEADAS} sessões bloeadas a um tempo maior do que ${TEMPO} ms | NUMERO_SESSOES_BLOQUEADAS=${NUMERO_SESSOES_BLOQUEADAS};${WARNING};${CRITICAL};; "
        exit 1;

# Valor Ok
else
        echo -e "A quantidade de sessões bloqueadas está em Crítica! Existem ${NUMERO_SESSOES_BLOQUEADAS} sessões bloeadas a um tempo maior do que ${TEMPO} ms | NUMERO_SESSOES_BLOQUEADAS=${NUMERO_SESSOES_BLOQUEADAS};${WARNING};${CRITICAL};; "
        exit 2;
fi

#Saida de erro
echo "Erro desconhecido!"
exit 3;