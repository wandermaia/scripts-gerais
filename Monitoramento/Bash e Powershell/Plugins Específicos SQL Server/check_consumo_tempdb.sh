#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/check_consumo_tempdb.sh
# Sistema.............: Opmon
# Data da Criação.....: 18/10/2018
# Criado por..........: Wander Maia da Silva
#*****************************************************************************************************************************************************
# Descricao...........: Plugin para verificação da quantidade de querys que estão consumindo tempdb.
# Entrada.............: Dados para acesso e limites de alerta
# Saida...............: Quantidade de querys que estão consumindo um valor maior do que o limite.
# Linha do Plugin.....: /usr/local/opmon/libexec/custom/check_consumo_tempdb.sh -S $ARG1$ -u $ARG2$ -p $ARG3$ -w $ARG4$ -c $ARG5$
# Execução Manual.....: /usr/local/opmon/libexec/custom/check_consumo_tempdb.sh -S 127.0.0.1 -u usuario -p 'senha' -w 1 -c 2
#*****************************************************************************************************************************************************

# Menu de Ajuda
help () {

    cat <<EOF

Descrição do Plugin
			  
	Plugin para verificação da quantidade de querys que estão consumindo tempdb.
 
Parâmetros

	-h  : Exibe este menu de ajuda
	-S  : Nome do Servidor previamente cadastrado no arquivo /etc/freetds.conf
	-u  : Usuário para acesso ao SQL Server
	-p  : Senha do Usuário do SQL Server
	-w  : Valor de warning para a quantidade de sessões bloqueadas a um tempo maior do que o limite informado
	-c  : Valor de critical para a quantidade de sessões bloqueadas a um tempo maior do que o limite informado

Exemplo de Utilização
  
	/usr/local/opmon/libexec/custom/check_consumo_tempdb.sh -S 127.0.0.1 -u usuario -p 'senha' -w 1 -c 2
	
EOF

	exit
}

# Menu de validacao de entradas
while getopts ":S:u:p:w:c:hd" Option
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
    h )
      help
      ;;
  esac
done

# Check parameter
[ -z ${SERVER} ] && echo -e "\n *** ->> Necessário o parâmetro com o nome do SERVER <<- ***" && help
[ -z ${USUARIO} ] && echo -e "\n *** ->> Necessário o parâmetro com o usuário do SQL Server <<- ***" && help
[ -z ${PASSWORD} ] && echo -e "\n *** ->> Necessário o parâmetro com a senha de acesso ao SQL Server <<- ***" && help
[ -z ${WARNING} ] && echo -e "\n *** ->> Necessário o parâmetro com o valor de Warning <<- ***" && help
[ -z ${CRITICAL} ] && echo -e "\n *** ->> Necessário o parâmetro com o valor de Critical <<- ***" && help

# Verificando a quantidade de sessões bloqueadas a mais tempo do que o informado.
NUMERO_SESSOES_CONSUMIDORAS=`bsqldb -q -U ${USUARIO} -P ${PASSWORD} -S ${SERVER} -t \| <<EOF

			USE tempdb
			
			select count(*)
			from      (Select session_id, request_id,
			sum(internal_objects_alloc_page_count +   user_objects_alloc_page_count) as task_alloc,
			sum (internal_objects_dealloc_page_count + user_objects_dealloc_page_count) as task_dealloc
				from sys.dm_db_task_space_usage
				group by session_id, request_id) as t1,
				sys.dm_exec_requests as t2,
				sys.sysprocesses as t3
			where
			t3.loginame <> '' and
			t1.session_id = t2.session_id and
			(t1.request_id = t2.request_id) and
			t1.session_id = t3.spid and
				t1.session_id > 50
			and db_name (t3.dbid) = 'tempdb'
			and t1.task_alloc  * (8.0/1024.0) > 2048

EOF`


# Verificando os limites de alerta
if [ ${NUMERO_SESSOES_CONSUMIDORAS} -lt ${WARNING} ]
then
        echo -e "Não existem sessões com alto consumo de tempdb. | NUMERO_SESSOES_CONSUMIDORAS=${NUMERO_SESSOES_CONSUMIDORAS};${WARNING};${CRITICAL};; "
        exit 0;
		
elif [ ${NUMERO_SESSOES_CONSUMIDORAS} -lt ${CRITICAL} ]
then
        echo -e "A quantidade de sessões consumido mais do que 2048 do TempDB está em alerta!  Numero de Sessões: ${NUMERO_SESSOES_CONSUMIDORAS} | NUMERO_SESSOES_CONSUMIDORAS=${NUMERO_SESSOES_CONSUMIDORAS};${WARNING};${CRITICAL};; "
        exit 1;

# Valor Ok
else
        echo -e "A quantidade de sessões consumido mais do que 2048 do TempDB está Crítica!  Numero de Sessões: ${NUMERO_SESSOES_CONSUMIDORAS} | NUMERO_SESSOES_CONSUMIDORAS=${NUMERO_SESSOES_CONSUMIDORAS};${WARNING};${CRITICAL};; "
        exit 2;
fi

#Saida de erro
echo "Erro desconhecido!"
exit 3;