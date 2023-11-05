#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/check_mssql_job.sh
# Sistema.............: Opmon
# Data da Criação.....: 07/03/2017
# Criado por..........: Wander Maia da Silva
# Alterado por .......: Wander Maia da Silva
# Data da Alteração...: 03/04/2017
# Motivo da Alteração.: Adequação na query. Alguns resultados não estavam sendo extraídos da forma correta.
#*****************************************************************************************************************************************************
# Descricao...........: Plugin para verificação do status da última execução de jobs no SQL Server.
# Entrada.............: Dados para acesso e nome do job
# Saida...............: Status da última execução do job
# Linha do Plugin.....: /usr/local/opmon/libexec/custom/check_mssql_job.sh -S $ARG1$ -u $ARG2$ -p $ARG3$ -j $ARG4$ -a $ARG5$
# Execução Manual.....: /usr/local/opmon/libexec/custom/check_mssql_job.sh -S 127.0.0.1 -u usuario -p 'senha' -j 'job' -a 1
#*****************************************************************************************************************************************************


# Menu de Ajuda
help () {
  echo -e  "\n *** -> Descrição do Plugin<- *** \n"
  echo -e  " Plugin para verificação do status da última execução de jobs no SQL Server."
  echo -e  " Gera alertas se houve algum erro na última execução do job. Jobs desabilatados são ignorados e não geram alertas.\n"
  echo -e  " *** -> Parametros: <- *** \n"
  echo -e  " -S  : SERVER previamente cadastrado no arquivo /etc/freetds.conf"
  echo -e  " -u  : Usuário do SQL Server"
  echo -e  " -p  : Senha do Usuário do SQL Server"
  echo -e  " -j  : Nome do job para verificação"
  echo -e  " -a  : Gerar alerta se o Job estiver em execução. (0 para sim e 1 para não)\n"
  exit 0
}

# Menu de validacao de entradas
while getopts ":S:u:p:j:a:hd" Option
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
        j )
      JOB_NAME=$OPTARG
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
[ -z ${SERVER} ] && echo -e "\n *** ->> Necessário o parâmetro com o nome do SERVER <<- ***" && help
[ -z ${USUARIO} ] && echo -e "\n *** ->> Necessário o parâmetro com o usuário do SQL Server <<- ***" && help
[ -z ${PASSWORD} ] && echo -e "\n *** ->> Necessário o parâmetro com a senha de acesso ao SQL Server <<- ***" && help
[ -z ${ALERTA} ] && echo -e "\n *** ->> Necessário o parâmetro informando se devem ser gerados alertas para o job em execução <<- ***" && help

# Validando as opções de alerta
if [ ${ALERTA} != 0 ] && [ ${ALERTA} != 1 ]
then
        echo "Erro! Parâmetro errado para o item de geração de alertas!";
        exit 3;
fi;


# Função para verificar se o job está em execução (0 para inativo)
ATIVO () {

        # Consultando os jobs em execução
        CONSULTA_EXECUCAO=`echo -e "SELECT C.name FROM msdb.dbo.sysjobactivity A WITH(NOLOCK) LEFT JOIN msdb.dbo.sysjobhistory B WITH(NOLOCK) ON A.job_history_id = B.instance_id JOIN msdb.dbo.sysjobs C WITH(NOLOCK) ON  A.job_id = C.job_id WHERE A.session_id = ( SELECT TOP 1 session_id FROM msdb.dbo.syssessions WITH(NOLOCK) ORDER BY agent_start_date DESC ) AND A.start_execution_date IS NOT NULL AND A.stop_execution_date IS NULL \ngo" | tsql -S ${SERVER} -U ${USUARIO} -P ${PASSWORD} -o fhq`

        # Verificando se o job está entre os que estão em execuçãoe retornando o resultado.
        EXECUTANDO=`echo ${CONSULTA_EXECUCAO} | grep ${JOB_ID} | wc -l`

        # Job em execução.
        if [ ${EXECUTANDO} -ne 0 ];then
        echo -e "Job ${JOB_NAME} em execução. Verificar! | STATUS=4;1;2;0;4";
        exit 2;
        fi;
}



# Verificando se o Job está habilitado
ENABLE=`bsqldb -q -U ${USUARIO} -P ${PASSWORD} -S ${SERVER} -t \| <<EOF
                use msdb
                SELECT enabled from msdb.dbo.sysjobs where name = '${JOB_NAME}'
EOF`

# Validando o nome do job estava correto para realizar a consulta
if [ -z ${ENABLE} ];then
        echo "O Job '${JOB_NAME}' não foi encontrado!";
        exit 1;
fi;


# Verificando se o Job está desabilitado
if [ ${ENABLE} -eq 0 ];then
        echo "O Job '${JOB_NAME}' está desabilitado.";
        exit 2;
fi;


# Realizando a coleta dos dados sobre o Job
CONSULTA_GERAL=`echo -e "SELECT top 1 h.run_status, h.job_id, msdb.dbo.agent_datetime(h.run_date, h.run_time) as 'RunDateTime'
from msdb.dbo.sysjobs j WITH(NOLOCK) INNER JOIN msdb.dbo.sysjobhistory h WITH(NOLOCK) ON j.job_id = h.job_id
where j.name = '"${JOB_NAME}"' order by 1 desc \ngo" | tsql -S ${SERVER} -U ${USUARIO} -P ${PASSWORD} -o fhq`

# exemplo do retorno da query:
# run_status                            job_id                                                          RunDateTime
#       1                       D034F3A1-94C3-4456-8BA2-BEA0B4AD0480    2017-03-31 04:00:00.000

# Segregando os resultados
STATUS_JOB=`echo -e "$CONSULTA_GERAL" | awk '{print $1}'`
JOB_ID=`echo -e "$CONSULTA_GERAL" | awk '{print $2}'`
DATE_LAST_EXECUTION=`echo -e "$CONSULTA_GERAL" | awk '{print $3}'`
HOUR_LAST_EXECUTION=`echo -e "$CONSULTA_GERAL" | awk '{print $4}'`

# Validando a consulta realizada
if [ -z ${STATUS_JOB} ];then
        echo "Erro no histórico de execução do job '${JOB_NAME}'!";
        exit 1;
fi;

# Caso seja necessário alertar job em execução
if [ ${ALERTA} -eq 0 ];then
        ATIVO
fi;


# Validando o status do job
case ${STATUS_JOB} in
      0) echo -e "Job '${JOB_NAME}' iniciado as ${HOUR_LAST_EXECUTION} do dia ${DATE_LAST_EXECUTION} e FALHOU! | STATUS=${STATUS_JOB};;;0;5" ; exit 2 ;;
      1) echo -e "Job '${JOB_NAME}' iniciado as ${HOUR_LAST_EXECUTION} do dia ${DATE_LAST_EXECUTION} e executado com sucesso! | STATUS=${STATUS_JOB};;;0;5" ; exit 0 ;;
      2) echo -e "Job '${JOB_NAME}' iniciado as ${HOUR_LAST_EXECUTION} do dia ${DATE_LAST_EXECUTION} em reexecução! | STATUS=${STATUS_JOB};;;0;5" ; exit 1 ;;
      3) echo -e "Job '${JOB_NAME}' foi Cancelado! | STATUS=${STATUS_JOB};;;0;5" ; exit 1 ;;
      4) echo -e "Job '${JOB_NAME}' iniciado as ${HOUR_LAST_EXECUTION} do dia ${DATE_LAST_EXECUTION} em execução! | STATUS=1;1;2;0;4" ; exit 0 ;;
      *) echo -e "Erro no histórico de execução do Job! \nNome do Job: '${JOB_NAME}' | STATUS=5;;;0;5 "; exit 1 ;;
   esac

echo "Erro desconhecido!"
exit 3;