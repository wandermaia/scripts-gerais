#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/check_io_datafile_mssql.sh
# Sistema.............: Opmon
# Data da Criação.....: 13/04/2017
# Criado por..........: Wander Maia da Silva
#*****************************************************************************************************************************************************
# Descricao...........: Plugin para verificação de métricas de IO em um datafile específico. Este plugin não gera alerta é apenas para relatório.
# Entrada.............: Dados para acesso, nome do banco e nome do datafile
# Saida...............: Dados de io referentes ao datafile informado.
# Linha do Plugin.....: /usr/local/opmon/libexec/custom/check_io_datafile_mssql.sh -S $ARG1$ -u $ARG2$ -p $ARG3$ -b $ARG4$ -d $ARG5$
# Execução Manual.....: /usr/local/opmon/libexec/custom/check_io_datafile_mssql.sh -S 127.0.0.1 -u usuario -p senha -b 'databse' -d 'datafile'
#*****************************************************************************************************************************************************


# Menu de Ajuda
help () {
  echo -e  "\n *** -> Descrição do Plugin<- *** \n"
  echo -e  " Plugin para verificação de métricas de IO em um datafile específico."
  echo -e  " Este plugin não gera alerta é deverá ser utilizado apenas para confecção de relatórios e/ou análises de desempenho.\n"
  echo -e  " *** -> Parametros: <- *** \n"
  echo -e  " -S  : SERVER previamente cadastrado no arquivo /etc/freetds.conf"
  echo -e  " -u  : Usuário do SQL Server"
  echo -e  " -p  : Senha do Usuário do SQL Server"
  echo -e  " -b  : Nome do banco de dados"
  echo -e  " -d  : Nome (lógico) do datafile que será verficado. \n"
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
[ -z $SERVER ] && echo -e "\n *** ->> Necessário o parâmetro com o nome do SERVER <<- ***" && help
[ -z $USUARIO ] && echo -e "\n *** ->> Necessário o parâmetro com o usuário do SQL Server <<- ***" && help
[ -z $PASSWORD ] && echo -e "\n *** ->> Necessário o parâmetro com a senha de acesso ao SQL Server <<- ***" && help
[ -z $BANCO ] && echo -e "\n *** ->> Necessário o parâmetro informando o nome do banco <<- ***" && help
[ -z $DATAFILE ] && echo -e "\n *** ->> Necessário o parâmetro informando o nome do datafile <<- ***" && help



# Coletando os valores iniciais de IO.
IO_INICIAL[0]=`echo -e "select vfs.num_of_writes, vfs.num_of_bytes_written, vfs.num_of_reads, vfs.num_of_bytes_read from sys.master_files mf join sys.dm_io_virtual_file_stats(NULL, NULL) vfs on mf.database_id=vfs.database_id and mf.file_id=vfs.file_id where db_name(mf.database_id)= '"${BANCO}"' and mf.name = '"${DATAFILE}"' \ngo" | tsql -S ${SERVER} -U ${USUARIO} -P ${PASSWORD} -o fhq`

# Validando a consulta foi realizada com sucesso
VALIDA_CONSULTA=`echo ${IO_INICIAL[0]} | wc -w`
if [ ${VALIDA_CONSULTA} -lt 4 ]
then
        echo "Erro no resultado da query! Verifique os dados Informados.";
        exit 3;
fi;

# Aguardando 10 segundos para realizar a nova coleta e calcular a média
sleep 10

# Coletando os valores finais de IO.
IO_FINAL[0]=`echo -e "select vfs.num_of_writes, vfs.num_of_bytes_written, vfs.num_of_reads, vfs.num_of_bytes_read from sys.master_files mf join sys.dm_io_virtual_file_stats(NULL, NULL) vfs on mf.database_id=vfs.database_id and mf.file_id=vfs.file_id where db_name(mf.database_id)= '"${BANCO}"' and mf.name = '"${DATAFILE}"' \ngo" | tsql -S ${SERVER} -U ${USUARIO} -P ${PASSWORD} -o fhq`

# Segregando os dados iniciais no array da seguinte forma: [1] - num_of_writes, [2] num_of_bytes_written, [3] num_of_reads , [4] num_of_bytes_read
IO_INICIAL[1]=`echo ${IO_INICIAL[0]} | awk '{print $1}'`
IO_INICIAL[2]=`echo ${IO_INICIAL[0]} | awk '{print $2}'`
IO_INICIAL[3]=`echo ${IO_INICIAL[0]} | awk '{print $3}'`
IO_INICIAL[4]=`echo ${IO_INICIAL[0]} | awk '{print $4}'`

# Segregando os dados finais no array da seguinte forma: [1] - num_of_writes, [2] num_of_bytes_written, [3] num_of_reads , [4] num_of_bytes_read
IO_FINAL[1]=`echo ${IO_FINAL[0]} | awk '{print $1}'`
IO_FINAL[2]=`echo ${IO_FINAL[0]} | awk '{print $2}'`
IO_FINAL[3]=`echo ${IO_FINAL[0]} | awk '{print $3}'`
IO_FINAL[4]=`echo ${IO_FINAL[0]} | awk '{print $4}'`

# Calculando a média por segundo
NUM_OF_WRITES=`echo "scale=2; ( ${IO_FINAL[1]} - ${IO_INICIAL[1]} ) / 10 " | bc`
NUM_OF_BYTES_WRITTEN=`echo "scale=2; ( ${IO_FINAL[2]} - ${IO_INICIAL[2]} ) / 10 " | bc`
NUM_OF_READS=`echo "scale=2; ( ${IO_FINAL[3]} - ${IO_INICIAL[3]} ) / 10 " | bc`
NUM_OF_BYTES_READ=`echo "scale=2; ( ${IO_FINAL[4]} - ${IO_INICIAL[4]} ) / 10  " | bc`


# Comandos para verificações
# echo -e "Coleta dos dados: \n \n ${IO_INICIAL[0]} \nNúmero de linhas: ${VALIDA_CONSULTA}"
# echo -e "\n\n Valores iniciais segregados: num_of_writes: ${IO_INICIAL[1]} num_of_bytes_written: ${IO_INICIAL[2]} num_of_reads: ${IO_INICIAL[3]} num_of_bytes_read: ${IO_INICIAL[4]}"
# echo -e "\n\n Valores finais segregados: num_of_writes: ${IO_FINAL[1]} num_of_bytes_written: ${IO_FINAL[2]} num_of_reads: ${IO_FINAL[3]} num_of_bytes_read: ${IO_FINAL[4]}"
# echo -e "\n\n Valores por segundo: NUM_OF_WRITES: ${NUM_OF_WRITES} NUM_OF_BYTES_WRITTEN: ${NUM_OF_BYTES_WRITTEN} NUM_OF_READS: ${NUM_OF_READS} NUM_OF_KBYTES_READ: ${NUM_OF_BYTES_READ} \n \n"

# Saída do plugin contendo o performance data
echo "Métricas de IO no datafile ${DATAFILE} do banco de dados  ${BANCO}: NUM_OF_WRITES: ${NUM_OF_WRITES} w/s, NUM_OF_BYTES_WRITTEN: ${NUM_OF_BYTES_WRITTEN}Bw/s, NUM_OF_READS: ${NUM_OF_READS}r/s, NUM_OF_BYTES_READ: ${NUM_OF_BYTES_READ}Br/s | NUM_OF_WRITES=${NUM_OF_WRITES}r/s;;;; NUM_OF_BYTES_WRITTEN=${NUM_OF_BYTES_WRITTEN}Bw/s;;;; NUM_OF_READS=${NUM_OF_READS}r/s;;;; NUM_OF_BYTES_READ=${NUM_OF_BYTES_READ}Br/s;;;;"
exit 0;

#Saida de erro
echo "Erro desconhecido!"
exit 3;