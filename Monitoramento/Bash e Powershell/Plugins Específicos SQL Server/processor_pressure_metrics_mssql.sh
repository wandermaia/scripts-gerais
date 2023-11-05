#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/processor_pressure_metrics_mssql.sh
# Sistema.............: Opmon
# Data da Criacao.....: 10/11/2016
# Criado por..........: Wander Maia da Silva
#*****************************************************************************************************************************************************
# Descricao...........: Plugin para verificação das métricas Batch Requests, Compilações e Recompilações por segundo no SQL Server.
# Entrada.............: Dados para acesso e valores para definição dos alertas.
# Saida...............: Média de Batch Requests, Full Scans por segundo, Compilações e Recompilações por segundo e percentual de compilações e recompilações
# Linha do Plugin.....: /usr/local/opmon/libexec/custom/processor_pressure_metrics_mssql.sh -S $ARG1$ -u $ARG2$ -s $ARG3$ -w $ARG4$ -c $ARG5$ -a $ARG6$
# Execução Manual.....: /usr/local/opmon/libexec/custom/processor_pressure_metrics_mssql.sh -S 127.0.0.1 -u usuario -s 'senha' -w 10 -c 15 -a 1
#*****************************************************************************************************************************************************

# Menu de Ajuda
help () {

    cat <<EOF

Descrição do Script
			  
	Plugin para verificação das métricas Batch Requests, Full Scans, Compilações e Recompilações por segundo no SQL Server.
 
Parâmetros

	-S  : Servidor configurado no freetds
	-u  : Usuário do SQL Server
	-s  : Senha do Usuário do SQL Server
	-a  : Ativar alerta para os operadores (0 para sim e 1 para não)
	-w  : Valor (percentual) de warning
	-c  : Valor (percentual) de critical
  
Exemplos de Utilização
  
	/usr/local/opmon/libexec/custom/processor_pressure_metrics_mssql.sh -S 127.0.0.1 -u usuario -s 'senha' -w 10 -c 15 -a 1
	
EOF

	exit 0
}

# Menu de validacao de entradas
while getopts ":w:c:S:u:a:s:hd" Option
do
  case $Option in
    w )
      WARNING=$OPTARG
      ;;
    c )
      CRITICAL=$OPTARG
      ;;
    S )
      SERVIDOR=$OPTARG
      ;;
    u )
      USUARIO=$OPTARG
      ;;
    s )
      SENHA=$OPTARG
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
[ -z ${SERVIDOR} ] && echo -e "\n *** ->> Necessário o parâmetro com o nome do Servidor no arquivo /etc/freetds <<- ***" && help
[ -z ${USUARIO} ] && echo -e "\n *** ->> Necessário o parâmetro com o usuário do SQLServer <<- ***" && help
[ -z ${SENHA} ] && echo -e "\n *** ->> Necessário o parâmetro com a senha de acesso ao SQLServer <<- ***" && help
[ -z ${WARNING} ] && echo -e "\n *** ->> Necessário o parâmetro Warning <<- ***" && help
[ -z ${CRITICAL} ] && echo -e "\n *** ->> Necessário o parâmetro Critical <<- ***" && help
[ -z ${ALERTA} ] && echo -e "\n *** ->> Necessário o parâmetro informando se devem ser gerados alertas <<- ***" && help

# Validando as opções de alerta
if [ ${ALERTA} != 0 ] && [ ${ALERTA} != 1 ]
then
        echo "Erro! Parâmetro errado para o item de geração de alertas!";
        exit 3;
fi;

# Verifica se o número de Batch-Requests por segundo pelo SQLServer
CONSULTA=`bsqldb -q -U ${USUARIO} -P ${SENHA} -S ${SERVIDOR} -t \| <<EOF
    USE master
    DECLARE @BatchRequests BIGINT; 
	DECLARE @Compilations BIGINT; 
	DECLARE @Recompilations BIGINT; 
	DECLARE @FullScan BIGINT; 
	SELECT @FullScan = cntr_value FROM sys.dm_os_performance_counters WHERE counter_name= 'Full Scans/sec'; 
	SELECT @BatchRequests = cntr_value FROM sys.dm_os_performance_counters WHERE counter_name = 'Batch Requests/sec'; 
	SELECT @Compilations = cntr_value FROM sys.dm_os_performance_counters WHERE counter_name = 'SQL Compilations/sec'; 
	SELECT @Recompilations = cntr_value FROM sys.dm_os_performance_counters WHERE counter_name = 'SQL Re-Compilations/sec'; 
	WAITFOR DELAY '00:00:10'; 
	SELECT (cntr_value - @FullScan) / 10 AS 'Full Scans/sec' FROM sys.dm_os_performance_counters WHERE counter_name = 'Full Scans/sec'; 
	SELECT (cntr_value - @BatchRequests) / 10 AS 'Batch Requests/sec' FROM sys.dm_os_performance_counters WHERE counter_name = 'Batch Requests/sec'; 
	SELECT (cntr_value - @Compilations) / 10 AS 'SQL Compilations/sec' FROM sys.dm_os_performance_counters WHERE counter_name = 'SQL Compilations/sec'; 
	SELECT (cntr_value - @Recompilations) / 10 AS 'SQL Re-Compilations/sec' FROM sys.dm_os_performance_counters WHERE counter_name = 'SQL Re-Compilations/sec';
EOF`

# Validando a consulta foi realizada com sucesso
LINHAS=`echo ${CONSULTA} | wc -l`
if [ ${LINHAS} -eq 0 ]
then
        echo "Erro desconhecido! Resposta nula da query!";
        exit 3;
fi;

# Segregando os valores retornados pela consulta
FULL_SCAN=`echo -e "$CONSULTA" | head -n 1 | awk '{print $1}'`
BATCH_REQUESTS=`echo -e "$CONSULTA" | head -n 2 | tail -n 1 | awk '{print $1}'`
COMPILATIONS=`echo -e "$CONSULTA" | head -n 3 | tail -n 1 | awk '{print $1}'`
RECOMPILATIONS=`echo -e "$CONSULTA" | tail -n 1 | awk '{print $1}'`

# Calculando o percentual de compilações.
if ((`bc <<< "${BATCH_REQUESTS} < 1 " `)) 
then
	PERCENTUAL_COMPILACOES=0
else
	PERCENTUAL_COMPILACOES=`echo "scale=2; ${COMPILATIONS} / ${BATCH_REQUESTS} * 100 " | bc`
fi;

# Calculando o percentual de recompilações
if ((`bc <<< "${PERCENTUAL_COMPILACOES} < 1 " `)) 
then
	PERCENTUAL_RECOMPILACOES=0
else
	PERCENTUAL_RECOMPILACOES=`echo "scale=2; ${RECOMPILATIONS} / ${COMPILATIONS} * 100 " | bc`
fi;

# Função que gera o Performance Data
function PERFORMANCE () {

  echo -e "$1 | BATCH_REQUESTS_SEC=${BATCH_REQUESTS};;;; FULL_SCAN_SEC=${FULL_SCAN};;;; COMPILATIONS_SEC=${COMPILATIONS};;;; RECOMPILATIONS_SEC=${RECOMPILATIONS};;;;  PERCENTUAL_COMPILACOES=${PERCENTUAL_COMPILACOES}%;${WARNING};${CRITICAL};; PERCENTUAL_RECOMPILACOES=${PERCENTUAL_RECOMPILACOES}%;${WARNING};${CRITICAL};; "
}

# Saída do performance data sem a geração de alertas no monitoramento
if [ ${ALERTA} == 1 ]
then
        PERFORMANCE "Métricas para identificação de problemas na utilização de CPU! BATCH_REQUESTS: ${BATCH_REQUESTS}, FULL_SCAN_SEC: ${FULL_SCAN} PERCENTUAL_COMPILACOES: ${PERCENTUAL_COMPILACOES}%, PERCENTUAL_RECOMPILACOES: ${PERCENTUAL_RECOMPILACOES}%"
        exit 0;
fi

# Comparando os valores de alerta
if ((`bc <<< "${PERCENTUAL_COMPILACOES} <= ${WARNING}" `)) && ((`bc <<< "${PERCENTUAL_RECOMPILACOES} <= ${WARNING}" `))
then
        PERFORMANCE "Relação de CPU Health está em OK! BATCH_REQUESTS: ${BATCH_REQUESTS}, FULL_SCAN_SEC: ${FULL_SCAN} PERCENTUAL_COMPILACOES: ${PERCENTUAL_COMPILACOES}%, PERCENTUAL_RECOMPILACOES: ${PERCENTUAL_RECOMPILACOES}%"
        exit 0;

elif ((`bc <<< "${PERCENTUAL_COMPILACOES} >= ${CRITICAL}" `)) || ((`bc <<< "${PERCENTUAL_RECOMPILACOES} >= ${CRITICAL}" `))
then
        PERFORMANCE "Relação de CPU Health está Crítica! BATCH_REQUESTS: ${BATCH_REQUESTS}, FULL-SCAN_SEC: ${FULL_SCAN} PERCENTUAL_COMPILACOES: ${PERCENTUAL_COMPILACOES}%, PERCENTUAL_RECOMPILACOES: ${PERCENTUAL_RECOMPILACOES}%"
        exit 2;
else
        PERFORMANCE "Relação de CPU Health está em Alerta! BATCH_REQUESTS: ${BATCH_REQUESTS}, FULL_SCAN_SEC: ${FULL_SCAN} PERCENTUAL_COMPILACOES: ${PERCENTUAL_COMPILACOES}%, PERCENTUAL_RECOMPILACOES: ${PERCENTUAL_RECOMPILACOES}%"
        exit 1;
fi

#Saida de erro
echo "Erro desconhecido!"
exit 3;