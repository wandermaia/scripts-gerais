#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/check_memory_by_ssh.sh
# Sistema.............: OpMon
# Data da Criacao.....: 01/03/2018
# Criado por..........: Wander Maia da Silva
#*****************************************************************************************************************************************************
# Descricao...........: Verifica o consumo de memória do servidor por SSH. Necessário instalar o sshpass e o bc para que o plugin funcione corretamente.
# Entrada.............: Dados para acesso e valores de alarme
# Saida...............: Valores dos contatdores de memória do servidor.
# Linha do Plugin.....: /usr/local/opmon/libexec/custom/check_memory_by_ssh.sh -H $HOSTADDRESS$ -u $ARG1$ -s $ARG2$ -w $ARG3$ -c $ARG4$
# Execução Manual.....: /usr/local/opmon/libexec/custom/check_memory_by_ssh.sh -H 127.0.0.1 -u usuario -s 'senha' -w 95 -c 98
#*****************************************************************************************************************************************************

# Menu de Ajuda
help () {
  echo -e  "\n *** -> Descrição do Plugin <- *** \n" 
  echo -e  " Plugin para verificação do consumo de memória do servidor por SSH. Necessário instalar o sshpass e o bc para que o plugin funcione corretamente."
  echo -e  " Utiliza valores crescentes para gerar os alertas (quanto maior o valor, pior).\n"
  echo -e  " *** -> Parametros: <- *** \n" 
  echo -e  " -H  : IP do host que será monitorado"
  echo -e  " -u  : Usuário para a conexão por ssh"
  echo -e  " -s  : Senha do Usuário para a conexão"
  echo -e  " -w  : Valor de warning (valor referente percentual utilizado)"
  echo -e  " -c  : Valor de critical (valor referente percentual utilizado)\n"
  exit 0
}

# Menu de validacao de entradas
while getopts ":w:c:H:u:s:hd" Option
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
[ -z ${HOST} ] && echo -e "\n *** ->> Necessário o parâmetro com o IP do Host <<- ***" && help
[ -z ${USUARIO} ] && echo -e "\n *** ->> Necessário o parâmetro com o usuário <<- ***" && help
[ -z ${SENHA} ] && echo -e "\n *** ->> Necessário o parâmetro com a senha de acesso<<- ***" && help
[ -z ${WARNING} ] && echo -e "\n *** ->> Necessário o parâmetro Warning <<- ***" && help
[ -z ${CRITICAL} ] && echo -e "\n *** ->> Necessário o parâmetro Critical <<- ***" && help


# Função que gera o Performance Data
function PERFORMANCE () {

  echo -e "$1 | PERCENTUAL_MEMORIA_UTILIZADA=${PERCENTUAL_MEMORIA_UTILIZADA}%;${WARNING};${CRITICAL};; MEMORIA_FISICA_MB=${MEMORIA_FISICA_MB}MB;;;; MEMORIA_UTILIZADA_REAL_MB=${MEMORIA_UTILIZADA_REAL_MB}MB;;;; PERCENTUAL_SWAP_UTILIZADA=${PERCENTUAL_SWAP_UTILIZADA}%;;;; SWAP_UTILIZADA_MB=${SWAP_UTILIZADA_MB}MB;;;;"
}  

# Realizando a coleta dos dados de memória do servidor
COLETA_MEMORIA=`/usr/bin/sshpass -p ${SENHA} ssh -o StrictHostKeyChecking=no ${USUARIO}@${HOST} "cat /proc/meminfo | egrep 'MemTotal|MemFree|Buffers|Cached|SwapTotal|SwapFree'"`

# Exemplo da saída do comando:
# MemTotal: 26756500 kB MemFree: 1047072 kB Buffers: 287152 kB Cached: 19665896 kB SwapCached: 288356 kB SwapTotal: 18876364 kB SwapFree: 17671716 kB

# Segregando os valores dos contadores de memória
MEM_TOTAL_KB=`echo ${COLETA_MEMORIA} | awk '{print $2}'`
MEM_FREE_KB=`echo ${COLETA_MEMORIA} | awk '{print $5}'`
BUFFERS_KB=`echo ${COLETA_MEMORIA} | awk '{print $8}'`
CACHED_KB=`echo ${COLETA_MEMORIA} | awk '{print $11}'`
SWAP_CACHED_KB=`echo ${COLETA_MEMORIA} | awk '{print $14}'`
SWAP_TOTAL_KB=`echo ${COLETA_MEMORIA} | awk '{print $17}'`
SWAP_FREE_KB=`echo ${COLETA_MEMORIA} | awk '{print $20}'`

# Calculando a memória Física utilizada (tanto pelo sistema quanto cache e buffer)
MEMORIA_FISICA_KB=`echo "${MEM_TOTAL_KB} - ${MEM_FREE_KB}"  | bc`

# Convertendo em megabytes para ser utilizad no performance data
MEMORIA_FISICA_MB=`echo "scale=2; ${MEMORIA_FISICA_KB} / 1024" | bc`

# Cálculo da memória real utilizada
MEMORIA_UTILIZADA_KB=`echo "${MEMORIA_FISICA_KB} - ${BUFFERS_KB} - ${CACHED_KB}"  | bc`

# Convertendo a memória utilizada para megabyte para ser utilizada no performance data
MEMORIA_UTILIZADA_REAL_MB=`echo "scale=2; ${MEMORIA_UTILIZADA_KB} / 1024" | bc`

# Calculando o percentual de memória utilizada
PERCENTUAL_MEMORIA_UTILIZADA=`echo "scale=2; ( ${MEMORIA_UTILIZADA_KB} / ${MEM_TOTAL_KB} ) * 100" | bc`

# Cálculo da memória SWAP utilizada
SWAP_UTILIZADA_KB=`echo "${SWAP_TOTAL_KB} - ${SWAP_FREE_KB} - ${SWAP_CACHED_KB}"  | bc`

# Convertendo a SWAP utilizada para megabyte para ser utilizada no performance data
SWAP_UTILIZADA_MB=`echo "scale=2; ${SWAP_UTILIZADA_KB} / 1024" | bc`

# Calculando o percentual de swap utilizada.
PERCENTUAL_SWAP_UTILIZADA=`echo "scale=2; ( ${SWAP_UTILIZADA_KB} / ${SWAP_TOTAL_KB} ) * 100" | bc`

# Validando os limites de alerta e gerando mensagens juntamente com o performance data.
if ((`bc <<< "${PERCENTUAL_MEMORIA_UTILIZADA} < ${WARNING}" `))
then
	PERFORMANCE "O consumo de memória está ok! Percentual Utilizado: ${PERCENTUAL_MEMORIA_UTILIZADA}%"
	exit 0;

elif ((`bc <<< "${PERCENTUAL_MEMORIA_UTILIZADA} < ${CRITICAL}" `))
then
	PERFORMANCE "O consumo de memória está em Alerta! Percentual Utilizado: ${PERCENTUAL_MEMORIA_UTILIZADA}%"
	exit 1;
else
	PERFORMANCE "O consumo de memória está em Crítico! Percentual Utilizado: ${PERCENTUAL_MEMORIA_UTILIZADA}%"
	exit 2;
fi

#Saida de erro
echo "Erro desconhecido!"
exit 3;