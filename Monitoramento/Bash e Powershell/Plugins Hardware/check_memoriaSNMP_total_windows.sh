#/bin/sh

#==========================================================================================================================#
# /usr/local/opmon/libexec/custom/check_memoriaSNMP_total_windows.sh                                                       #
# Plugin para monitorar o percentual de uso de memória total no Windows                                                    #
#==========================================================================================================================#
# Autor: Wander Maia da Silva                                                                                              #
# Versão: 1.0                                                                                                              #
# Data: 03/06/2016                                                                                                         #
#==========================================================================================================================#
# Exemplo de execução manual: /usr/local/opmon/libexec/custom/check_memoriaSNMP_total_windows.sh 192.168.100.42 90 95      #
# Formato do plugin para inclusão no opmon																                   #
# /usr/local/opmon/libexec/custom/check_memoriaSNMP_total_windows.sh $HOSTADDRESS$ $ARG1$ $ARG2$                           #
#==========================================================================================================================#

# Variáveis recebidas como parâmetro pelo script
SERVER=$1   	               # Variável para armazenamento servidor
WARNING=$2                     # Variável para armazenar o valor de alerta
CRITICAL=$3  	               # Variável para armazenar o valor de crítico

# Comando para coleta do valor de utilização da memória
MEMORIA=`/usr/local/opmon/libexec/opservices/check_snmp_storage.pl -H ${SERVER} -C public -m Mem -s -w 90 -c 95 | awk '{print $5}' | awk -F "%" '{print $1}'`


# Verificando se o valor está de acordo com os parâmetros informados
if [ $MEMORIA -lt $WARNING ]
then
        echo -e  "Utilização de Memória Total OK! ${MEMORIA}% | Memoria_Total=${MEMORIA}%;$WARNING;$CRITICAL;0;100"
        exit 0;
# Alerta
elif [ $MEMORIA -lt $CRITICAL ]
then
        echo -e  "Utilização de Memória Total em Alerta! ${MEMORIA}% | Memoria_Total=${MEMORIA}%;$WARNING;$CRITICAL;0;100"
        exit 1;

# Crítico
elif [ $MEMORIA -ge $CRITICAL ]
then
        echo -e "Utilização de Memória Total em Crítico! ${MEMORIA}% | Memoria_Total=${MEMORIA}%;$WARNING;$CRITICAL;0;100"
        exit 2;
fi

#Saida de erro
echo "Erro desconhecido!"
exit 3;