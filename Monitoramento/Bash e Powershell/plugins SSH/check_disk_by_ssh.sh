#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/check_disk_by_ssh.sh
# Sistema.............: OpMon
# Data da Criacao.....: 01/03/2018
# Criado por..........: Wander Maia da Silva
#*****************************************************************************************************************************************************
# Descricao...........: Verifica o percentual de utilização do filesystem do servidor por SSH. Necessário instalar o sshpass e o bc para que o plugin funcione corretamente.
# Entrada.............: Dados para acesso e valores para geração dos alertas.
# Saida...............: Dados de utilização do disco.
# Linha do Plugin.....: /usr/local/opmon/libexec/custom/check_disk_by_ssh.sh -H $HOSTADDRESS$ -u $ARG1$ -s $ARG2$ -w $ARG3$ -c $ARG4$ -d $ARG5$
# Execução Manual.....: /usr/local/opmon/libexec/custom/check_disk_by_ssh.sh -H 127.0.0.1 -u usuario -s 'senha' -w 85 -c 90 -d '/'
#*****************************************************************************************************************************************************

# Menu de Ajuda
help () {
  echo -e  "\n *** -> Descrição do Plugin <- *** \n"
  echo -e  " Plugin para verificação do percentual de utilização do filesystem do servidor por SSH. Necessário instalar o sshpass e o bc para que o plugin funcione corretamente."
  echo -e  " Utiliza valores crescentes para gerar os alertas (quanto maior o valor, pior).\n"
  echo -e  " *** -> Parametros: <- *** \n"
  echo -e  " -H  : IP do host que será monitorado"
  echo -e  " -u  : Usuário para a conexão por ssh"
  echo -e  " -s  : Senha do Usuário para a conexão"
  echo -e  " -d  : Nome do Disco"
  echo -e  " -w  : Valor de warning (em percentual)"
  echo -e  " -c  : Valor de critical (em percentual)\n"
  exit 0
}

# Menu de validacao de entradas
while getopts ":w:c:H:u:s:d:hd" Option
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
    d )
      DISCO=$OPTARG
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
[ -z ${DISCO} ] && echo -e "\n *** ->> Necessário o parâmetro com o filesystem<<- ***" && help
[ -z ${WARNING} ] && echo -e "\n *** ->> Necessário o parâmetro Warning <<- ***" && help
[ -z ${CRITICAL} ] && echo -e "\n *** ->> Necessário o parâmetro Critical <<- ***" && help


# Função que gera o Performance Data
function PERFORMANCE () {

  echo -e "$1 | PERCENTUAL=${PERCENTUAL_USADO}%;${WARNING};${CRITICAL};; USADO=${USADO}MB;;;; "
}

# Realizando a coleta dos dados de memória do servidor
COLETA_COMANDO=`/usr/bin/sshpass -p ${SENHA} ssh -o StrictHostKeyChecking=no ${USUARIO}@${HOST} "/bin/df -m ${DISCO}"`

# Exemplo da saída do comando em inglês:
# Filesystem 1M-blocks Used Available Use% Mounted on /dev/mapper/VolGroup00-LogVol03 29758 3702 24521 14% /
# Exemplo da saída do comando em Português:
# Sist. Arq. 1M-blocos Usad Dispon. Uso% Montado em /dev/mapper/VolGroup00-LogVol00 15840 10208 4816 68% /

# Validando se o retorno do comando está em português para que a segregação dos valores ocorra de forma correta.
RETORNO_EM_PORTUGUES=`echo ${COLETA_COMANDO} | grep -iE 'Sist.' | wc -l`

# Segregando os valores do do disco de acordo com a validação do idioma realizada acima
if ((`bc <<< "${RETORNO_EM_PORTUGUES} > 0" `))
then
				USADO=`echo ${COLETA_COMANDO} | awk '{print $11}'`
				PERCENTUAL_USADO=`echo ${COLETA_COMANDO} | awk '{print $13}' | sed 's/%//g'`
else
				USADO=`echo ${COLETA_COMANDO} | awk '{print $10}'`
				PERCENTUAL_USADO=`echo ${COLETA_COMANDO} | awk '{print $12}' | sed 's/%//g'`
fi


# Validando os limites de alerta e gerando mensagens juntamente com o performance data.
if ((`bc <<< "${PERCENTUAL_USADO} < ${WARNING}" `))
then
        PERFORMANCE "Utilização do Disco OK! Percentual Usado: ${PERCENTUAL_USADO}%"
        exit 0;

elif ((`bc <<< "${PERCENTUAL_USADO} < ${CRITICAL}" `))
then
        PERFORMANCE "Utilização do Disco em Alerta! Percentual Usado: ${PERCENTUAL_USADO}%"
        exit 1;
else
        PERFORMANCE "Utilização do Disco está Crítico! Percentual Usado: ${PERCENTUAL_USADO}%"
        exit 2;
fi

#Saida de erro
echo "Erro desconhecido!"
exit 3;