#/bin/bash

#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/check_temperatura_pro_digital.sh
# Sistema.............: OpMon
# Data da Criacao.....: 19/03/2018
# Criado por..........: Wander Maia da Silva
#*****************************************************************************************************************************************************
# Descricao...........: Plugin para verificação da temperatura e umidade nos medidores da Prodigital
# Entrada.............: URL do medidor e valores para os limites de temperatura e umidade
# Saida...............: Valor de temperatura e umidade
# Linha do Plugin.....: /usr/local/opmon/libexec/custom/check_temperatura_pro_digital.sh -p $ARG1$ -w $ARG2$ -c $ARG3$ 
# Execução Manual.....: /usr/local/opmon/libexec/custom/check_temperatura_pro_digital.sh -p 'http://127.0.0.1/8stats.htm' -w '25' -c '30'
#*****************************************************************************************************************************************************

# Menu de Ajuda
help () {
  echo -e  "\n *** -> Descrição do Plugin<- *** \n" 
  echo -e  " Plugin para verificação da temperatura e umidade nos medidores da Prodigital"
  echo -e  " Utiliza valores crescentes (temperatura) para gerar os alertas (quanto maior o valor, pior).\n"
  echo -e  " *** -> Parametros: <- *** \n" 
  echo -e  " -p  : URL do medidor para coleta dos dados"
  echo -e  " -w  : Valor de warning (graus celsius)"
  echo -e  " -c  : Valor de critical (graus celsius)\n"
  exit 0
}

# Menu de validacao de entradas
while getopts ":w:c:p:hd" Option
do
  case $Option in
    w )
      WARNING=$OPTARG
      ;;
    c )
      CRITICAL=$OPTARG
      ;;
    p )
      WEB_PAGE=$OPTARG
      ;;
    h ) 
      help
      ;;
  esac
done

# Check parameter
[ -z $WEB_PAGE ] && echo -e "\n *** ->> Necessário o parâmetro com a URL do medidor <<- ***" && help
[ -z $WARNING ] && echo -e "\n *** ->> Necessário o parâmetro Warning <<- ***" && help
[ -z $CRITICAL ] && echo -e "\n *** ->> Necessário o parâmetro Critical <<- ***" && help

# Coletando os dados a partir da URL do medidor
COLETA_PAGINA=`links -dump http://127.0.0.1/8stats.htm | sed -e 's/<[^>]*>//g'`

# Segregando os valores de temperatura e Umidade.
TEMPERATURA=`echo ${COLETA_PAGINA} | awk -F 'name=R>' '{print $2}' | awk -F 'Temperatura' '{print $2}' | awk '{print $1}' | sed -e 's/\+//g'`
UMIDADE=`echo ${COLETA_PAGINA} | awk -F 'Umidade relativa do ar' '{print $2}'  | awk '{print $1}'`

# Função que gera o Performance Data
function PERFORMANCE () {

  echo -e "$1 | TEMPERATURA=${TEMPERATURA}°C;${WARNING};${CRITICAL};; UMIDADE=${UMIDADE}%;;;; "
}   

# Validando os limites de alerta e gerando mensagens juntamente com o performance data.
if ((`bc <<< "${TEMPERATURA} < ${WARNING}" `))
then
	PERFORMANCE "A temperatura do Datacenter ok! TEMPERATURA: ${TEMPERATURA}°C"
	exit 0;

elif ((`bc <<< "${TEMPERATURA} < ${CRITICAL}" `))
then
	PERFORMANCE "A temperatura do Datacenter em Alerta! TEMPERATURA: ${TEMPERATURA}°C"
	exit 1;
else
	PERFORMANCE "A temperatura do Datacenter está Crítico! TEMPERATURA: ${TEMPERATURA}°C"
	exit 2;
fi

#Saida de erro
echo "Erro desconhecido!"
exit 3;