#/bin/sh

#=========================================================================================================================#
# /usr/local/opmon/script/check_container_docker.sh                      											      #
# Plugin para monitorar CPU ou Memória do docker informado 			   													  #
#=========================================================================================================================#
# Autor: Wander Maia da Silva                                                                                             #
# Versão: 1.0                                                                                                             #
# Data: 30/05/2016                                                                                                        #
#=========================================================================================================================#
# Exemplo de execução manual: /usr/local/opmon/script/check_container_docker.sh -C docker_oauth_1 -t 1 -w 80 -c 90        #
# Formato do plugin para inclusão no opmon																				  #
# /usr/local/opmon/script/check_container_docker.sh -C $ARG1$ -t $ARG2$ -w $ARG3$ -c $ARG4$								  #
#=========================================================================================================================#

# Inicialização das variáveis necessárias para a execução no script
PERCENT=""						# Variável para receber o percentual
VALOR=0							# Variável para receber o valor sem simbolo.
EXTENSO=""						# Variável utilizada para armazenar o tipo de coleta (CPU ou Memória) por extenso.

# Menu de Ajuda
help () {
  echo -e "\n"
  echo " *** -> Lista de Parâmetros: <- *** "
  echo " -w  : warning"
  echo " -c  : critical"
  echo " -C  : Container"
  echo " -t  : Tipo (1 para CPU e 2 para Memória)"
  echo -e "\n"
  exit 0
}

# Menu de validacao de entradas
while getopts ":w:c:p:C:t:hd" Option
do
  case $Option in
    w )
      WARNING=$OPTARG
      ;;
    c )
      CRITICAL=$OPTARG
      ;;
    t )
      TIPO=$OPTARG
          ;;
    C )
      CONTAINER=$OPTARG
          ;;
    h )
      help
      ;;
  esac
done

# Check parameter
[ -z $CONTAINER ] && echo -e "\n *** ->> Necessário o parâmetro com o nome do Container <<- ***" && help
[ -z $WARNING ] && echo -e "\n *** ->> Necessário o parâmetro Warning <<- ***" && help
[ -z $CRITICAL ] && echo -e "\n *** ->> Necessário o parâmetro Critical <<- ***" && help
[ -z $TIPO ] && echo -e "\n *** ->> Necessário o parâmetro com o tipo (CPU ou Memória) <<- ***" && help
[ $TIPO -ne 1 ] && [ $TIPO -ne 2 ] && echo -e "\n *** ->> Parâmetro de Tipo Inválido! <<- ***" && help


# Comando para coleta dos dados. A saída é no formato:
#CONTAINER           CPU %               MEM USAGE/LIMIT     MEM %               NET I/O
#docker_oauth_1      60.12%              1.387 GB/2.147 GB   64.59%              9.063 GB/3.826 GB
COLETA=`docker stats --no-stream $CONTAINER | tail -n 1`

# Estrutura para definir se serão utilizados os valores de memória ou CPU
if [ $TIPO -eq 1 ]
then
        #Coletando o valor da CPU
		PERCENT=`echo -e "$COLETA" | awk '{print $2}'`
		VALOR=`echo "${PERCENT}" | sed 's/\%//g'`
		EXTENSO='CPU'

else
        #Coletando o valor da Memória
		PERCENT=`echo -e "$COLETA" | awk '{print $6}'`
		VALOR=`echo "${PERCENT}" | sed 's/\%//g'`
		EXTENSO='Memoria'
fi

# Verificando se o valor está de acordo com os parâmetros informados
if ((`bc <<< "${VALOR} < ${WARNING}" `))
then
        echo -e  "$EXTENSO do container $CONTAINER OK! Utilização de ${EXTENSO}= $PERCENT | ${EXTENSO}_${CONTAINER}=$PERCENT;$WARNING;$CRITICAL;; "
        exit 0;

elif ((`bc <<< "${VALOR} < ${CRITICAL}" `))
then
        echo -e  "$EXTENSO do container $CONTAINER em Alerta! Utilização de ${EXTENSO}= $PERCENT | ${EXTENSO}_${CONTAINER}=$PERCENT;$WARNING;$CRITICAL;; "
        exit 1;

# Crítico
elif ((`bc <<< "${VALOR} >= ${CRITICAL}" `))
then
        echo "$EXTENSO do container $CONTAINER Crítico! Utilização de ${EXTENSO}= $PERCENT | ${EXTENSO}_${CONTAINER}=$PERCENT;$WARNING;$CRITICAL;; "
        exit 2;
fi

#Saida de erro
echo "Erro desconhecido!"
exit 3;