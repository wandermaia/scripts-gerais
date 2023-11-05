#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/check_index_fragmentation_mssql.sh
# Sistema.............: Opmon
# Data da Criação.....: 20/08/2018
# Criado por..........: Wander Maia da Silva
#*****************************************************************************************************************************************************
# Descricao...........: Plugin para verificação da quantidade de índices fragmentados em um banco de dados.
# Entrada.............: Dados para acesso, nome do banco, número de páginas, percentual de fragmentação e limites de alertas
# Saida...............: Quantidade de índices fragmentados
# Linha do Plugin.....: /usr/local/opmon/libexec/custom/check_index_fragmentation_mssql.sh -S $ARG1$ -u $ARG2$ -p $ARG3$ -b $ARG4$ -n $ARG5$ -f $ARG6$ -w $ARG7$ -c $ARG8$
# Execução Manual.....: /usr/local/opmon/libexec/custom/check_index_fragmentation_mssql.sh -S 127.0.0.1 -u usuario -p 'senha' -b 'database' -n 1000 -f 30 -w 5 -c 10
#*****************************************************************************************************************************************************


# Menu de Ajuda
help () {

    cat <<EOF

Descrição do Plugin
			  
	Plugin para verificação da quantidade de índices fragmentados em um banco de dados.
 
Parâmetros

	-S  : SERVER previamente cadastrado no arquivo /etc/freetds.conf
	-u  : Usuário do SQL Server
	-p  : Senha do Usuário do SQL Server
	-b  : Nome do banco de dados
	-n  : Número de páginas de dados de um índice a partir do qual será incluído na análise da fragmentação
	-f  : Percentual de fragmentação para análise da fragmentação
	-w  : Valor para limite de warning
	-c  : Valor para limite de critical
	
Exemplo de Utilização:

	/usr/local/opmon/libexec/custom/check_index_fragmentation_mssql.sh -S 127.0.0.1 -u usuario -p 'senha' -b 'database' -n 1000 -f 30 -w 5 -c 10
 
EOF

	exit 0
}

# Menu de validacao de entradas
while getopts ":S:u:p:b:n:f:w:c:hd" Option
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
    b )
      BANCO=$OPTARG
      ;;
    n )
      NUMERO_PAGINAS=$OPTARG
      ;;
    f )
      FRAGMENTACAO=$OPTARG
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
[ -z ${BANCO} ] && echo -e "\n *** ->> Necessário o parâmetro informando o nome do banco <<- ***" && help
[ -z ${NUMERO_PAGINAS} ] && echo -e "\n *** ->> Necessário o parâmetro informando o número de páginas de dados <<- ***" && help
[ -z ${FRAGMENTACAO} ] && echo -e "\n *** ->> Necessário o parâmetro informando o percentual de fragmentação dos índices <<- ***" && help
[ -z ${WARNING} ] && echo -e "\n *** ->> Necessário o parâmetro informando o valor de warning <<- ***" && help
[ -z ${CRITICAL} ] && echo -e "\n *** ->> Necessário o parâmetro informando o valor de critical <<- ***" && help

# Coletando os dados de latência do datafile
NUMERO_INDICES_FRAGMENTADOS=`bsqldb -q -U ${USUARIO} -P ${PASSWORD} -S ${SERVER} -t \| <<EOF
				
		USE ${BANCO}
		SELECT count (*)
		FROM sys.dm_db_index_physical_stats(db_id(),null,null,null,null) A
		join sys.indexes B on a .object_id = B.Object_id and A.index_id = B.index_id 
		where page_count > ${NUMERO_PAGINAS} and avg_fragmentation_in_percent > ${FRAGMENTACAO}
				
EOF`

# Validando a NUMERO_INDICES_FRAGMENTADOS foi realizada com sucesso
VALIDA_CONSULTA=`echo ${NUMERO_INDICES_FRAGMENTADOS} | wc -w`

if [ ${VALIDA_CONSULTA} -lt 1 ]
then
        echo "Erro no resultado da query! Verifique os dados Informados.";
        exit 3;
fi;


# Verificando os limites de alerta
if [ ${NUMERO_INDICES_FRAGMENTADOS} -lt ${WARNING} ]
then
        echo -e "O número de índices fragmentados está OK! Total de índices fragmentados: ${NUMERO_INDICES_FRAGMENTADOS} | NUMERO_INDICES_FRAGMENTADOS=${NUMERO_INDICES_FRAGMENTADOS};${WARNING};${CRITICAL};; "
        exit 0;
		
elif [ ${NUMERO_INDICES_FRAGMENTADOS} -lt ${CRITICAL} ]
then
        echo -e "O número de índices fragmentados está em alerta! Total de índices fragmentados: ${NUMERO_INDICES_FRAGMENTADOS} | NUMERO_INDICES_FRAGMENTADOS=${NUMERO_INDICES_FRAGMENTADOS};${WARNING};${CRITICAL};; "
        exit 1;

# Valor Ok
else
        echo -e "O número de índices fragmentados está em Crítico! Total de índices fragmentados: ${NUMERO_INDICES_FRAGMENTADOS} | NUMERO_INDICES_FRAGMENTADOS=${NUMERO_INDICES_FRAGMENTADOS};${WARNING};${CRITICAL};; "
        exit 2; 
fi

#Saida de erro
echo "Erro desconhecido!"
exit 3;