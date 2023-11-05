#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/check_objetos_invalidos.sh
# Sistema.............: OpMon
# Data da Criação.....: 04/07/2018
# Criado por..........: Wander Maia da Silva
#*****************************************************************************************************************************************************
# Descricao...........: Plugin para verificação dos objetos inválidos no oracle
# Entrada.............: Dados para acesso e exclusão (quando aplicável)
# Saida...............: Quantidade de objetos inválidos
# Linha do Plugin.....: /usr/local/opmon/libexec/custom/check_objetos_invalidos.sh -S $ARG1$ -u $ARG2$ -p $ARG3$ -e $ARG4$ -w $ARG5$ -c $ARG6$
# Execução Manual.....: /usr/local/opmon/libexec/custom/check_objetos_invalidos.sh -S server -u usuario -p 'senha' -e 'objeto_exclusado' -w 2 -c 3
#*****************************************************************************************************************************************************

# Menu de Ajuda
help () {

    cat <<EOF

			*** -> Descrição do Plugin<- ***
		
 Plugin para verificação da quantidade de objetos inválidos no oracle.
 Gera alertas se houver algum objeto inválido.
 
			*** -> Parametros: <- ***
 
 -S  : Servidor cadastrado no tnsnames.ora
 -u  : Usuário para conexão no Oracle
 -p  : Senha do Usuário do Oracle
 -e  : Nome do Objeto para exclusão
 -w  : Quantidade de objetos para alerta
 -c  : Qunatidade de objetos para crítico
 
EOF

	exit 0
}

# Menu de validacao de entradas
while getopts ":S:u:p:e:w:c:hd" Option
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
    e )
      EXCLUSAO=$OPTARG
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
[ -z ${CRITICAL} ] && echo -e "\n *** ->> Necessário o parâmetro de critical <<- ***" && help

echo -e "exclusão: ${EXCLUSAO}"

# Realizando a coleta da quantidade de objetos inválidos AND OBJECT_NAME!='${EXCLUSAO}'
CONSULTA=`sqlplus -s /nolog <<EOF
CONNECT ${USUARIO}/${PASSWORD}@${SERVER}
SELECT OBJECT_NAME FROM DBA_OBJECTS WHERE STATUS!='VALID';
EXIT;
EOF`


# Removendo os cabeçalhos da resposta e aplicando as exceções.
numeroObjetosInvalidos=`echo -e "${CONSULTA}" | grep -ivE 'OBJECT_NAME|---|LIB_BD' | sed '/^$/d' | wc -l`


# Verificando os valores da fila total
if [ ${numeroObjetosInvalidos} -lt ${WARNING} ]
then
        echo -e  "O número de objetos inválidos está ok! Número de Objetos inválidos: ${numeroObjetosInvalidos} | OBJETOS_INVALIDOS=${numeroObjetosInvalidos};${WARNING};${CRITICAL};;"
        exit 0;

# verificando o valor de Warning
elif [ ${numeroObjetosInvalidos} -lt ${CRITICAL} ]
then
        echo -e  "O número de objetos inválidos está em alerta! Número de Objetos inválidos: ${numeroObjetosInvalidos} | OBJETOS_INVALIDOS=${numeroObjetosInvalidos};${WARNING};${CRITICAL};;"
        exit 1;

# Crítico
else
        echo -e  "O número de objetos inválidos está crítico! Número de Objetos inválidos: ${numeroObjetosInvalidos} | OBJETOS_INVALIDOS=${numeroObjetosInvalidos};${WARNING};${CRITICAL};;"
        exit 2;
fi

#Saida de erro
echo "Erro desconhecido!"
exit 3;