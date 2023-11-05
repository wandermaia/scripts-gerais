#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/check_datafile_latency_mssql.sh
# Sistema.............: Opmon
# Data da Criação.....: 09/08/2018
# Criado por..........: Wander Maia da Silva
#*****************************************************************************************************************************************************
# Descricao...........: Plugin para verificação de métricas de latência em um datafile específico.
# Entrada.............: Dados para acesso, nome do banco e nome do datafile
# Saida...............: Dados de latência referentes ao datafile informado.
# Linha do Plugin.....: /usr/local/opmon/libexec/custom/check_datafile_latency_mssql.sh -S $ARG1$ -u $ARG2$ -p $ARG3$ -b $ARG4$ -d $ARG5$
# Execução Manual.....: /usr/local/opmon/libexec/custom/check_datafile_latency_mssql.sh -S 127.0.0.1 -u usuario -p 'senha' -b 'database' -d 'nome_datafile'
#*****************************************************************************************************************************************************


# Menu de Ajuda
help () {

    cat <<EOF

Descrição do Plugin
			  
	Plugin para verificação de métricas de latência em um datafile específico do SQL Server. As métricas monitoradas são:
	
	num_of_reads 			Número de leituras emitidas no arquivo. 
	num_of_bytes_read 		Número total de bytes lidos no arquivo. 
	io_stall_read_ms 		Tempo total, em milissegundos, que os usuários aguardaram pelas leituras emitidas no arquivo. 
	num_of_writes 			Número de gravações feitas no arquivo. 
	num_of_bytes_written	Número total de bytes gravados no arquivo. 
	io_stall_write_ms		Tempo total, em milissegundos, que os usuários aguardaram até o término das gravações no arquivo. 
	io_stall				Tempo total, em milissegundos, que os usuários aguardaram até o término de E/S no arquivo. 
 
Parâmetros

	-S  : SERVER previamente cadastrado no arquivo /etc/freetds.conf
	-u  : Usuário do SQL Server
	-p  : Senha do Usuário do SQL Server
	-b  : Nome do banco de dados
	-d  : Nome (lógico) do datafile que será verficado.
	
Exemplo de execução

	/usr/local/opmon/libexec/custom/check_datafile_latency_mssql.sh -S 127.0.0.1 -u usuario -p 'senha' -b 'database' -d 'nome_datafile'
 
EOF

	exit 0
}

# Menu de validacao de entradas
while getopts ":S:u:p:b:d:hd" Option
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
    d )
      DATAFILE=$OPTARG
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
[ -z ${DATAFILE} ] && echo -e "\n *** ->> Necessário o parâmetro informando o nome do datafile <<- ***" && help

# Coletando os dados de latência do datafile
CONSULTA=`bsqldb -q -U ${USUARIO} -P ${PASSWORD} -S ${SERVER} -t \| <<EOF
				
		USE MASTER
		select vfs.io_stall, vfs.num_of_reads, vfs.num_of_bytes_read, vfs.io_stall_read_ms, 
		vfs.num_of_writes, vfs.num_of_bytes_written, vfs.io_stall_write_ms
		from sys.master_files mf join sys.dm_io_virtual_file_stats(NULL, NULL) vfs 
		on mf.database_id=vfs.database_id and mf.file_id=vfs.file_id 
		where db_name(mf.database_id)= '${BANCO}' and mf.name = '${DATAFILE}'
				
EOF`

# Validando a consulta foi realizada com sucesso
VALIDA_CONSULTA=`echo ${CONSULTA} | wc -w`

if [ ${VALIDA_CONSULTA} -lt 1 ]
then
        echo "Erro no resultado da query! Verifique os dados Informados.";
        exit 3;
fi;


# Segregando os valores encontrados pela consulta
IO_STALL_INICIAL=`echo ${CONSULTA} | awk -F "|" '{print $1}'`
NUM_OF_READS_INICIAL=`echo ${CONSULTA} | awk -F "|" '{print $2}'`
NUM_OF_BYTES_READ_INICIAL=`echo ${CONSULTA} | awk -F "|" '{print $3}'`
IO_STALL_READ_MS_INICIAL=`echo ${CONSULTA} | awk -F "|" '{print $4}'`
NUM_OF_WRITES_INICIAL=`echo ${CONSULTA} | awk -F "|" '{print $5}'`
NUM_OF_BYTES_WRITTEN_INICIAL=`echo ${CONSULTA} | awk -F "|" '{print $6}'`
IO_STALL_WRITE_MS_INICIAL=`echo ${CONSULTA} | awk -F "|" '{print $7}'`


# Aguardando o 10 segundos para realizar a nova coleta.
sleep 10

# Coletando os dados de latência do datafile
CONSULTA=`bsqldb -q -U ${USUARIO} -P ${PASSWORD} -S ${SERVER} -t \| <<EOF
				
		USE MASTER
		select vfs.io_stall, vfs.num_of_reads, vfs.num_of_bytes_read, vfs.io_stall_read_ms, 
		vfs.num_of_writes, vfs.num_of_bytes_written, vfs.io_stall_write_ms
		from sys.master_files mf join sys.dm_io_virtual_file_stats(NULL, NULL) vfs 
		on mf.database_id=vfs.database_id and mf.file_id=vfs.file_id 
		where db_name(mf.database_id)= '${BANCO}' and mf.name = '${DATAFILE}'
				
EOF`


# Validando a consulta foi realizada com sucesso
VALIDA_CONSULTA=`echo ${CONSULTA} | wc -w`

if [ ${VALIDA_CONSULTA} -lt 1 ]
then
        echo "Erro no resultado da query! Verifique os dados Informados.";
        exit 3;
fi;


# Segregando os valores encontrados pela consulta
IO_STALL_FINAL=`echo ${CONSULTA} | awk -F "|" '{print $1}'`
NUM_OF_READS_FINAL=`echo ${CONSULTA} | awk -F "|" '{print $2}'`
NUM_OF_BYTES_READ_FINAL=`echo ${CONSULTA} | awk -F "|" '{print $3}'`
IO_STALL_READ_MS_FINAL=`echo ${CONSULTA} | awk -F "|" '{print $4}'`
NUM_OF_WRITES_FINAL=`echo ${CONSULTA} | awk -F "|" '{print $5}'`
NUM_OF_BYTES_WRITTEN_FINAL=`echo ${CONSULTA} | awk -F "|" '{print $6}'`
IO_STALL_WRITE_MS_FINAL=`echo ${CONSULTA} | awk -F "|" '{print $7}'`


# Calculando o Valor Final
IO_STALL=`echo "scale=2; ( ${IO_STALL_FINAL} - ${IO_STALL_INICIAL} ) / 10 " | bc`
NUM_OF_READS=`echo "scale=2; ( ${NUM_OF_READS_FINAL} - ${NUM_OF_READS_INICIAL} ) / 10 " | bc`
NUM_OF_BYTES_READ=`echo "scale=2; ( ${NUM_OF_BYTES_READ_FINAL} - ${NUM_OF_BYTES_READ_INICIAL} ) / 10 " | bc`
IO_STALL_READ_MS=`echo "scale=2; ( ${IO_STALL_READ_MS_FINAL} - ${IO_STALL_READ_MS_INICIAL} ) / 10 " | bc`
NUM_OF_WRITES=`echo "scale=2; ( ${NUM_OF_WRITES_FINAL} - ${NUM_OF_WRITES_INICIAL} ) / 10 " | bc`
NUM_OF_BYTES_WRITTEN=`echo "scale=2; ( ${NUM_OF_BYTES_WRITTEN_FINAL} - ${NUM_OF_BYTES_WRITTEN_INICIAL} ) / 10 " | bc`
IO_STALL_WRITE_MS=`echo "scale=2; ( ${IO_STALL_WRITE_MS_FINAL} - ${IO_STALL_WRITE_MS_INICIAL} ) / 10 " | bc`


# Função que gera o Performance Data
function PERFORMANCE () {

  echo -e "$1 | NUM_OF_READS=${NUM_OF_READS};;;; NUM_OF_BYTES_READ=${NUM_OF_BYTES_READ}B/s;;;; IO_STALL_READ_MS=${IO_STALL_READ_MS}ms;;;; NUM_OF_WRITES=${NUM_OF_WRITES};;;; NUM_OF_BYTES_WRITTEN=${NUM_OF_BYTES_WRITTEN}B/s;;;; IO_STALL_WRITE_MS=${IO_STALL_WRITE_MS}ms;;;; IO_STALL=${IO_STALL}ms;;;; "
}

# Exibindo os valores das coletas
PERFORMANCE "Métricas de IO do arquivo '${DATAFILE}' do banco '${BANCO}'. "
exit 0