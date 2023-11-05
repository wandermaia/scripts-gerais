#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/check_status_sync_dg.sh
# Sistema.............: Opmon
# Data da Criacao.....: 11/05/2018
# Criado por..........: Wander Maia da Silva
#*****************************************************************************************************************************************************
# Descricao...........: Verifica o Status da sincronização do DG
# Entrada.............: Dados para acesso
# Saida...............: Status da Sincronização do DG.
# Linha do Plugin.....: /usr/local/opmon/libexec/custom/check_status_sync_dg.sh -b $ARG1$ -u $ARG2$ -s $ARG3$
# Execução Manual.....: /usr/local/opmon/libexec/custom/check_status_sync_dg.sh -b server -u usuario -s senha
#*****************************************************************************************************************************************************

# Menu de Ajuda
help () {
  echo -e  "\n *** -> Descrição do Plugin <- *** \n" 
  echo -e  " Plugin para verificação do Status da sincronização do DG.\n"
  echo -e  " *** -> Parametros: <- *** \n" 
  echo -e  " -b  : Nome da conexão no tnsnames.ora para realizar a conexão ao banco."
  echo -e  " -u  : Usuário do Oracle"
  echo -e  " -s  : Senha do Usuário do Oracle.\n"
  exit 0
}

# Menu de validacao de entradas
while getopts "b:u:s:hd" Option
do
  case $Option in
    b )
      BANCO=$OPTARG
      ;;
    u )
      USUARIO=$OPTARG
      ;;
    s )
      SENHA=$OPTARG
      ;;
    h ) 
      help
      ;;
  esac
done

# Check parameter
[ -z ${BANCO} ] && echo -e "\n *** ->> Necessário o parâmetro com o nome da conexão cadastrada no arquivo tnsnames.ora <<- ***" && help
[ -z ${USUARIO} ] && echo -e "\n *** ->> Necessário o parâmetro com o usuário do Oracle <<- ***" && help
[ -z ${SENHA} ] && echo -e "\n *** ->> Necessário o parâmetro com a senha de acesso ao Oracle <<- ***" && help

# Verificando a Fila de Mensagens da Getrak
COLETA=`echo "select CASE WHEN (((sysdate - dtime) * 24 * 60 * 60) < 60) THEN 'OK' ELSE 'GAP' END SITUAC from contab.dg_checkpoint;" | /usr/bin/sqlplus -s ${USUARIO}/${SENHA}@${BANCO}`

# Segregando o Status da sincronização
STATUS=`echo ${COLETA} '{print $3}' | grep OK | wc -l`

# Validando os limites de alerta e gerando mensagens juntamente com o performance data.
if ((`bc <<< "${STATUS} == 1" `))
then
        echo "A sincronização do DG está ok! | STATUS=${STATUS};;;;"
        exit 0;
else
        echo "Erro na sincronização do DG! | STATUS=${STATUS};;;;"
        exit 2;
fi

#Saida de erro
echo "Erro desconhecido!"
exit 3;