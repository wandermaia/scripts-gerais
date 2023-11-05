#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/check_session_pga_memory.sh
# Sistema.............: OpMon
# Data da Criação.....: 03/07/2020
# Criado por..........: Wander Maia da Silva
#*****************************************************************************************************************************************************
# Descricao...........: Plugin para verificação da quantidade de sessões pga.
# Entrada.............: Dados para acesso, limites de alerta e se deve gerar alerta ou não
# Saida...............: Quantidade total de sessões da pga
# Linha do Plugin.....: /usr/local/opmon/libexec/custom/check_session_pga_memory.sh -S $ARG1$ -u $ARG2$ -p $ARG3$ -w $ARG4$ -c $ARG5$ -a $ARG6$
# Execução Manual.....: /usr/local/opmon/libexec/custom/check_session_pga_memory.sh -S 'server' -u usuario -p 'senha' -w 2 -c 3 -a 1
#*****************************************************************************************************************************************************

# Menu de Ajuda
help () {

    cat <<EOF

			*** -> Descrição do Plugin<- ***
		
 Plugin para verificação da quantidade total de sessões da pga
 
			*** -> Parametros: <- ***
 
 -S  : Servidor cadastrado no tnsnames.ora
 -u  : Usuário para conexão no Oracle
 -p  : Senha do Usuário do Oracle
 -a  : Opção para definir se vai gerar alertas ou não
 -w  : Valor para warning
 -c  : Valor para crítico
 
EOF

	exit 0
}

# Menu de validacao de entradas
while getopts ":S:u:p:a:w:c:hd" Option
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
    a )
      ALERTA=$OPTARG
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
[ -z ${SERVER} ] && echo -e "\n *** ->> Necessário o parâmetro com o nome do servidor do Oracle <<- ***" && help
[ -z ${USUARIO} ] && echo -e "\n *** ->> Necessário o parâmetro com o usuário do Oracle <<- ***" && help
[ -z ${PASSWORD} ] && echo -e "\n *** ->> Necessário o parâmetro com a senha de acesso ao Oracle <<- ***" && help
[ -z ${WARNING} ] && echo -e "\n *** ->> Necessário o parâmetro de warning <<- ***" && help
[ -z ${ALERTA} ] && echo -e "\n *** ->> Necessário o parâmetro definindo se vai gerar alerta <<- ***" && help
[ -z ${CRITICAL} ] && echo -e "\n *** ->> Necessário o parâmetro de critical <<- ***" && help


# Realizando a coleta
CONSULTA=`sqlplus -s /nolog <<EOF
CONNECT ${USUARIO}/${PASSWORD}@${SERVER}

select name, sum(value) from v\\$sesstat ss, v\\$statname sn where ss.statistic# = sn.statistic# and name = 'session pga memory' group by name;

EOF`


# Segregando o valor a partir da consulta realizada
sumSessionPgaMemory=`echo -e "${CONSULTA}" | grep 'session pga memory'| awk '{print $4}'`


# Função que gera o Performance Data
function PERFORMANCE () {

  echo "$1 | SUM_SESSION_PGA_MEMORY=${sumSessionPgaMemory};${WARNING};${CRITICAL};; "
}



# Saída do performance data sem a geração de alertas no monitoramento
if [ ${ALERTA} == 1 ]
then
        PERFORMANCE "Soma das sessões da PGA: ${sumSessionPgaMemory}"
        exit 0;
fi


#echo -e "coleta resultado Limpo: ${numeroObjetosInvalidos}"

# Verificando os valores da fila total
if [ ${sumSessionPgaMemory} -lt ${WARNING} ]
then
        PERFORMANCE "Soma das sessões da PGA está ok! Total da soma: ${sumSessionPgaMemory}"
        exit 0;

# verificando o valor de Warning
elif [ ${sumSessionPgaMemory} -lt ${CRITICAL} ]
then
        PERFORMANCE "Soma das sessões da PGA está em alerta! Total da soma: ${sumSessionPgaMemory}"
        exit 1;

# Crítico
else
        PERFORMANCE "Soma das sessões da PGA está em Crítica! Total da soma: ${sumSessionPgaMemory}"
        exit 2;
fi

#Saida de erro
echo "Erro desconhecido!"
exit 3;