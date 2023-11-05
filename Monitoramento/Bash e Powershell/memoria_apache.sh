#/bin/bash
#===============================================================#
# /usr/local/opmon/libexec/custom/memoria_apache.sh 			#
# Plugin para monitoramento de Memoria consumida pelo Apache  	#
#============================================================== #
# Autor  : Wander Maia da Silva						    		#
# Version : 1.0  												#
# Data    : 12/04/2016   										#
#===============================================================#

# Menu de Ajuda
help () {
  echo -e "\n"
  echo " *** -> Parametros: <- *** " 
  echo " -w  : warning"
  echo " -c  : critical"
  echo " -H  : Host a ser monitorado"
  echo -e "\n"
  exit 0
}

# Menu de validacao de entradas
while getopts ":w:c:H:h:hd" Option
do
  case $Option in
    w )
      WARNING=$OPTARG
      ;;
    c )
      CRITICAL=$OPTARG
      ;;
    H )
      HOST=$OPTARG
      ;;
    h ) 
      help
      ;;
  esac
done

# Check parameter
[ -z $HOST ] && echo -e "\n *** ->> Necessário o parâmetro do host que será monitorado <<- ***" && help
[ -z $WARNING ] && echo -e "\n *** ->> Necessário o parametro Warning <<- ***" && help
[ -z $CRITICAL ] && echo -e "\n *** ->> Necessário o parametro Critical <<- ***" && help

# Coleta dos valores de memoria total free, memoria em buffer e memoria em cached
result=`cat /tmp/memoria_apache_$HOST.txt`

# Transformando o resultado em uma única linha
result=`echo $result | head -n 1`

# Extraindo os dados da memória
MEMORIA=`echo "${result}" | awk '{print $2}'`

# Extraindo a média.
AVERAGE=`echo "${result}" | awk '{print $4}'`

# Validacao do resultado
if [ $(echo "$MEMORIA < $WARNING" | bc) ]
then
        echo "Memoria Apache: $MEMORIA MB, Média: $AVERAGE MB | Memoria_Apache=$MEMORIA,MB;$WARNING;$CRITICAL;; Average=$AVERAGE;;;;"
        exit 0;
		
elif [ $(echo "$MEMORIA < $CRITICAL" | bc) ]
then
        echo "Memoria Apache: $MEMORIA MB, Média: $AVERAGE MB | Memoria_Apache=$MEMORIA,MB;$WARNING;$CRITICAL;; Average=$AVERAGE;;;;"
        exit 1;
		
elif [ $(echo "$MEMORIA > $CRITICAL" | bc) ]
then
        echo "Memoria Apache: $MEMORIA MB, Média: $AVERAGE MB | Memoria_Apache=$MEMORIA,MB;$WARNING;$CRITICAL;; Average=$AVERAGE;;;;"
        exit 2;
fi

#Saida de erro
echo "Erro desconhecido!"
exit 3;