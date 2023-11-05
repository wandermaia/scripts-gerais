#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/check_cpu_by_ssh.sh
# Sistema.............: OpMon
# Data da Criacao.....: 01/03/2018
# Criado por..........: Wander Maia da Silva
#*****************************************************************************************************************************************************
# Descricao...........: Verifica o percentual de utilização do CPU, conectando por ssh.
# Entrada.............: Dados para acesso e valores de alarme
# Saida...............: Percentual de utilização do CPU.
# Linha do Plugin.....: /usr/local/opmon/libexec/custom/check_cpu_by_ssh.sh -H $HOSTADDRESS$ -u $ARG1$ -s $ARG2$ -w $ARG3$ -c $ARG4$
# Execução Manual.....: /usr/local/opmon/libexec/custom/check_cpu_by_ssh.sh -H 127.0.0.1 -u usuario -s 'senha' -w 95 -c 98
#*****************************************************************************************************************************************************

# Menu de Ajuda
help () {
  echo -e  "\n *** -> Descrição do Plugin <- *** \n"
  echo -e  " Plugin para verificação do percentual de utilização do CPU, conectando por ssh."
  echo -e  " Utiliza valores crescentes para gerar os alertas (quanto maior o valor, pior).\n"
  echo -e  " *** -> Parametros: <- *** \n"
  echo -e  " -H  : IP do host que será monitorado"
  echo -e  " -u  : Usuário para a conexão por ssh"
  echo -e  " -s  : Senha do Usuário para a conexão"
  echo -e  " -w  : Valor de warning (valor em percentual)"
  echo -e  " -c  : Valor de critical (valor em percentual)\n"
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

  echo -e "$1 | CPU_UTILIZATION=${CPU_UTILIZATION}%;${WARNING};${CRITICAL};; PERCENTUAL_USER=${PERCENTUAL_USER}%;;;; PERCENTUAL_NICE=${PERCENTUAL_NICE}%;;;; PERCENTUAL_SYSTEM=${PERCENTUAL_SYSTEM}%;;;; PERCENTUAL_IOWAIT=${PERCENTUAL_IOWAIT}%;;;; PERCENTUAL_STEAL=${PERCENTUAL_STEAL}%;;;; PERCENTUAL_IDLE=${PERCENTUAL_IDLE}%;;;;  "
}

# Realizando a coleta de CPU do servidor. O valor retornado é o percentual de CPU idle.
COLETA_COMANDO=`/usr/bin/sshpass -p ${SENHA} ssh -o StrictHostKeyChecking=no ${USUARIO}@${HOST} "/usr/bin/sar -u 1 5 | grep -iE 'Average|Média'"`


# exemplo da saída do comando no servidor:
# Linux 2.6.18-164.el5 (server)         03/02/2018
#
# 12:09:39 PM       CPU     %user     %nice   %system   %iowait    %steal     %idle
# 12:09:40 PM       all      1.50      0.00      0.63      0.38      0.00     97.50
# 12:09:41 PM       all      4.24      0.00      2.12      0.50      0.00     93.13
# 12:09:42 PM       all      2.00      0.00      0.62      0.12      0.00     97.25
# Average:          all      2.58      0.00      1.12      0.33      0.00     95.96
#
# Salvando na variável, a saída do comando fica da seguinte forma:
#
# Average:          all      9.78      0.00      2.58      0.50      0.00     87.15

# segregando os valores:
PERCENTUAL_USER=`echo ${COLETA_COMANDO} | awk '{print $3}' `
PERCENTUAL_NICE=`echo ${COLETA_COMANDO} | awk '{print $4}' `
PERCENTUAL_SYSTEM=`echo ${COLETA_COMANDO} | awk '{print $5}' `
PERCENTUAL_IOWAIT=`echo ${COLETA_COMANDO} | awk '{print $6}' `
PERCENTUAL_STEAL=`echo ${COLETA_COMANDO} | awk '{print $7}' `
PERCENTUAL_IDLE=`echo ${COLETA_COMANDO} | awk '{print $8}' `

# Calculando a utilização CPU
CPU_UTILIZATION=`echo "scale=2; 100 - ${PERCENTUAL_IDLE}" | bc`

# Validando os limites de alerta e gerando mensagens juntamente com o performance data.
if ((`bc <<< "${CPU_UTILIZATION} < ${WARNING}" `))
then
        PERFORMANCE "Percentual de CPU está OK! CPU: ${CPU_UTILIZATION}% "
        exit 0;

elif ((`bc <<< "${CPU_UTILIZATION} < ${CRITICAL}" `))
then
        PERFORMANCE "Percentual de CPU está Alerta! CPU: ${CPU_UTILIZATION}% "
        exit 1;
else
        PERFORMANCE "Percentual de CPU está Crítico! CPU: ${CPU_UTILIZATION}% "
        exit 2;
fi

#Saida de erro
echo "Erro desconhecido!"
exit 3;