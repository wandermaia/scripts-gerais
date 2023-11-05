#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/check_uptime_by_ssh.sh
# Sistema.............: OpMon
# Data da Criação.....: 01/03/2018
# Criado por..........: Wander Maia da Silva
# Alterado por........: Wander Maia da Silva
# Data alteração......: 13/04/2018
# Motivo Alteração....: Ajuste devido a string gerada ser diferente se o uptime for menor do que dois dias.
#*****************************************************************************************************************************************************
# Descricao...........: Verifica o uptime servidor por SSH. Necessário instalar o sshpass e o bc para que o plugin funcione corretamente.
# Entrada.............: Dados para acesso e valores de alarme
# Saida...............: Tempo (em minutos que o servidor está ativo).
# Linha do Plugin.....: /usr/local/opmon/libexec/custom/check_uptime_by_ssh.sh -H $HOSTADDRESS$ -u $ARG1$ -p $ARG2$ -w $ARG3$ -c $ARG4$
# Execução Manual.....: /usr/local/opmon/libexec/custom/check_uptime_by_ssh.sh -H 127.0.0.1 -u usuario -s 'senha' -w 5 -c 10
#*****************************************************************************************************************************************************

# Menu de Ajuda
help () {
  echo -e  "\n *** -> Descrição do Plugin <- *** \n"
  echo -e  " Plugin para verificação do uptime do servidor por SSH. Necessário instalar o sshpass e o bc para que o plugin funcione corretamente."
  echo -e  " Utiliza valores decrescentes para gerar os alertas (quanto menor o valor, pior).\n"
  echo -e  " *** -> Parametros: <- *** \n"
  echo -e  " -H  : IP do host que será monitorado"
  echo -e  " -u  : Usuário para a conexão por ssh"
  echo -e  " -s  : Senha do Usuário para a conexão"
  echo -e  " -w  : Valor de warning (valor referente ao tempo em minutos que o servidor está ligado)"
  echo -e  " -c  : Valor de critical (valor referente ao tempo em minutos que o servidor está ligado)\n"
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

  echo -e "$1 | UPTIME=${UPTIME}Min;${WARNING};${CRITICAL};; "
}

# echo -e "Usuário: ${USUARIO}"
# echo -e "Senha: ${SENHA}"
# echo -e "Host: ${HOST}"

# Realizando a coleta dos dados de memória do servidor
COLETA_COMANDO=`/usr/bin/sshpass -p ${SENHA} ssh -o StrictHostKeyChecking=no ${USUARIO}@${HOST} "/usr/bin/uptime"`

#echo -e "${COLETA_COMANDO}"

# Exemplo das saídas possíveis do comando:
#
# 13:52:57 up 36 days,  3:38,  0 users,  load average: 0.93, 1.23, 1.48
# 16:13:13 up 17:30,  3 users,  load average: 0.10, 0.44, 1.00
#  09:50:32 up 1 day, 11:07,  3 users,  load average: 4.63, 4.82, 4.96
#
# Quando o servidor tem uptime menor do que um dia, ele não exibe essa informação. Assim, precisamos validar isso para realizar a segregação
# dos valores de forma correta.

# Validando se o uptime do servidor é maior do que um dia
UPTIME_MAIOR_QUE_UM_DIA=`echo ${COLETA_COMANDO} | grep -iE 'days|day' | wc -l`

# echo -e "UPTIME_MAIOR_QUE_UM_DIA ${UPTIME_MAIOR_QUE_UM_DIA}"

# Segregando os valores do uptime (de acordo com a validação realizada acima) para conversão posterior
if ((`bc <<< "${UPTIME_MAIOR_QUE_UM_DIA} > 0" `))
then
                DIAS_UPTIME=`echo ${COLETA_COMANDO} | awk '{print $3}'`
                HORAS_UPTIME=`echo ${COLETA_COMANDO} | awk '{print $5}' | awk -F':' '{print $1}'`
                MINUTOS_UPTIME=`echo ${COLETA_COMANDO} | awk '{print $5}' | awk -F':' '{print $2}' | sed 's/,//g'`
else
                DIAS_UPTIME=0
                HORAS_UPTIME=`echo ${COLETA_COMANDO} | awk '{print $3}' | awk -F':' '{print $1}'`
                MINUTOS_UPTIME=`echo ${COLETA_COMANDO} | awk '{print $3}' | awk -F':' '{print $2}' | sed 's/,//g'`
fi

# echo -e "DIAS_UPTIME ${DIAS_UPTIME} HORAS_UPTIME ${HORAS_UPTIME} MINUTOS_UPTIME ${MINUTOS_UPTIME} "

# Calculando o tempo ativo em minutos
TOTAL_MINUTOS_DIAS=`echo "${DIAS_UPTIME} * 24 * 60" | bc`
TOTAL_MINUTOS_HORAS=`echo "${HORAS_UPTIME} * 60" | bc`

# echo -e "TOTAL_MINUTOS_DIAS ${TOTAL_MINUTOS_DIAS} TOTAL_MINUTOS_HORAS ${TOTAL_MINUTOS_HORAS}"

# Calculando o uptime em minutos
UPTIME=`echo " ( ${TOTAL_MINUTOS_DIAS} + ${TOTAL_MINUTOS_HORAS} ) + ${MINUTOS_UPTIME} " | bc`

# echo -e "UPTIME ${UPTIME}"

# Validando os limites de alerta e gerando mensagens juntamente com o performance data.
if ((`bc <<< "${UPTIME} > ${WARNING}" `))
then
        PERFORMANCE "Servidor ativo a ${DIAS_UPTIME} dias, ${HORAS_UPTIME} horas e ${MINUTOS_UPTIME} minutos."
        exit 0;

elif ((`bc <<< "${UPTIME} > ${CRITICAL}" `))
then
        PERFORMANCE "Servidor ativo a ${MINUTOS_UPTIME} minutos."
        exit 1;
else
        PERFORMANCE "Servidor ativo a ${MINUTOS_UPTIME} minutos."
        exit 2;
fi

#Saida de erro
echo "Erro desconhecido!"
exit 3;