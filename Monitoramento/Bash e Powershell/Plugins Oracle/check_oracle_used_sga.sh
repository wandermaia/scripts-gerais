#!/bin/bash127.0.0.1
#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/check_oracle_used_sga.sh
# Sistema.............: OpMon
# Data da Criação.....: 02/07/2020
# Criado por..........: Wander Maia da Silva
#*****************************************************************************************************************************************************
# Descricao...........: Plugin para verificação da quantidade usada da sga em MB.
# Entrada.............: Dados para acesso, limites de alerta e se deve gerar alerta ou não
# Saida...............: Quantidade usada (em MB) da SGA
# Linha do Plugin.....: /usr/local/opmon/libexec/custom/check_oracle_used_sga.sh -S $ARG1$ -u $ARG2$ -p $ARG3$ -w $ARG4$ -c $ARG5$ -a $ARG6$
# Execução Manual.....: /usr/local/opmon/libexec/custom/check_oracle_used_sga.sh -S 'server' -u usuario -p 'senha' -w 2 -c 3 -a 0
#*****************************************************************************************************************************************************

# Menu de Ajuda
help () {

    cat <<EOF

			*** -> Descrição do Plugin<- ***
		
 Plugin para verificação da quantidade usada da sga em MB.
 
			*** -> Parametros: <- ***
 
 -S  : Servidor cadastrado no tnsnames.ora
 -u  : Usuário para conexão no Oracle
 -p  : Senha do Usuário do Oracle
 -a  : Opção para definir se vai gerar alertas ou não
 -w  : Valor para warning (em MB)
 -c  : Valor para crítico (em MB)
 
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
SET HEAD OFF
SET AUTOPRINT OFF
SET TERMOUT OFF
SET SERVEROUTPUT ON

SELECT Round(Sum(bytes/1024/1024),0) USED FROM V\\$SGAINFO WHERE name != 'Free SGA Memory Available' AND resizeable = 'Yes';

EOF`


# Removendo as quebras de linhas e tabulações da resposta
sgaUsed=`echo -e "${CONSULTA}" | sed '/^$/d' | awk '{print $1}'`


# Função que gera o Performance Data
function PERFORMANCE () {

  echo "$1 | SGA_USED=${sgaUsed}MB;${WARNING};${CRITICAL};; "
}



# Saída do performance data sem a geração de alertas no monitoramento
if [ ${ALERTA} == 1 ]
then
        PERFORMANCE "Quantidade usada da SGA: ${sgaUsed} MB."
        exit 0;
fi


#echo -e "coleta resultado Limpo: ${numeroObjetosInvalidos}"

# Verificando os valores da fila total
if [ ${sgaUsed} -lt ${WARNING} ]
then
        PERFORMANCE "Quantidade usada da SGA está ok! Quantidade Usada da SGA: ${sgaUsed} MB."
        exit 0;

# verificando o valor de Warning
elif [ ${sgaUsed} -lt ${CRITICAL} ]
then
        PERFORMANCE "Quantidade usada da SGA está em alerta! Quantidade Usada da SGA: ${sgaUsed} MB."
        exit 1;

# Crítico
else
        PERFORMANCE "Quantidade usada da SGA está crítica! Quantidade Usada da SGA: ${sgaUsed} MB."
        exit 2;
fi

#Saida de erro
echo "Erro desconhecido!"
exit 3;