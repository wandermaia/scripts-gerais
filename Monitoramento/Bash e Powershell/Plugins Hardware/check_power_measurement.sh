#/bin/bash

#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/check_power_consumption_measurement.sh
# Sistema.............: OpMon
# Data da Criacao.....: 20/02/2018
# Criado por..........: Wander Maia da Silva
#*****************************************************************************************************************************************************
# Descricao...........: Plugin para verificação dos valores de potência do medidor de Consumo de Energia
# Entrada.............: URL do medido e valores para os limites de alerta em kW.
# Saida...............: Dados de consumo de potência extraídos do medidor.
# Linha do Plugin.....: /usr/local/opmon/libexec/custom/check_power_consumption_measurement.sh -p $ARG1$ -w $ARG2$ -c $ARG3$ 
# Execução Manual.....: /usr/local/opmon/libexec/custom/check_power_consumption_measurement.sh -p 'http://127.0.0.1/Operation.html' -w '-20' -c '0'
#*****************************************************************************************************************************************************

# Menu de Ajuda
help () {
  echo -e  "\n *** -> Descrição do Plugin<- *** \n" 
  echo -e  " Plugin para verificação dos valores de potência do medidor de Consumo de Energia"
  echo -e  " Utiliza valores crescentes para gerar os alertas (quanto maior o valor, pior) de potência de Energia Consumida.\n"
  echo -e  " *** -> Parametros: <- *** \n" 
  echo -e  " -p  : URL do medidor para coleta dos dados"
  echo -e  " -w  : Valor de warning (potência em kW) para consumo total"
  echo -e  " -c  : Valor de critical (potência em kW) para consumo total\n"
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

# Coletando os dados a partir da URL do medidor e salvando no arquivo de texto para segregar os valores.
lynx -dump "${WEB_PAGE}" > /tmp/energia.txt

# Abaixo segue o exemplo da saída do arquivo gerado pela coleta
# [root@monitoramento custom]# cat /tmp/energia.txt
    # ION UTE S.J.TADEUMGMGA5USJTD01PSE MANGA 5
   # Device Time: 2018-02-20 11:32:14 Timezone: GMT -03:00
     # * Operation
     # * [1]Consumption
     # * [2]Power Quality
     # * [3]Setup

            # Voltage              Current                Power
      # Vln avg 82946.45 V      I avg     6.63 A   kW total   1423.47 kW
       # Vln a  82701.77 V       I a      6.49 A     kW a     464.80 kW
       # Vln b  82856.61 V       I b      6.60 A     kW b     466.70 kW
       # Vln c  83280.95 V       I c      6.78 A     kW c     491.98 kW
      # Vll avg 143666.84 V      I4        N/A A  kVA total  1625.41 kVA
      # Vll a-b 143449.92 V    I unbal    2.41 %    kVA a     537.01 kVA
      # Vll b-c 144050.22 V                         kVA b     546.68 kVA
      # Vll c-a 143500.42 V     Power Factor        kVA c     565.04 kVA
      # V unbal   0.40 %    PF sign total 87.58 % kVAR total -784.65 kVAR
                            # PF sign a   86.55 %   kVAR a   -254.26 kVAR
           # Frequency        PF sign b   85.37 %   kVAR b   -271.45 kVAR
       # Freq    60.02 Hz     PF sign c   87.07 %   kVAR c   -258.93 kVAR

   # Meter Type 8600 [4]Power Measurement
   # Firmware Version 8600V321
   # Template 8300_FAC-9S_V1.3.0.0.0
   # Serial Number PT-0902A238-01 © 2003 Power Measurement

# References

   # 1. http://127.0.0.1/Consumption.html
   # 2. http://127.0.0.1/PowerQuality.html
   # 3. http://127.0.0.1/Setup.html
   # 4. http://www.pwrm.com/

# Função que gera o Performance Data
function PERFORMANCE () {

  echo -e "$1 | KW_TOTAL=${KW_TOTAL}kW;${WARNING};${CRITICAL};; KW_A=${KW_A}kW;;;; KW_B=${KW_B}kW;;;; KW_C=${KW_C}kW;;;; KVA_TOTAL=${KVA_TOTAL}kVA;;;; KVA_A=${KVA_A}kVA;;;; KVA_B=${KVA_B}kVA;;;; KVA_C=${KVA_C}kVA;;;; KVAR_TOTAL=${KVAR_TOTAL}kVAR;;;; KVAR_A=${KVAR_A}kVAR;;;; KVAR_B=${KVAR_B}kVAR;;;; KVAR_C=${KVAR_C}kVAR;;;; "
}   

# Segregando as métricas para verificação dos limites e geração do performance data.
KW_TOTAL=`cat /tmp/energia.txt | head -n 9 | tail -n 1 | awk '{print $11}'`
KW_A=`cat /tmp/energia.txt | head -n 10 | tail -n 1 | awk '{print $11}'`
KW_B=`cat /tmp/energia.txt | head -n 11 | tail -n 1 | awk '{print $11}'`
KW_C=`cat /tmp/energia.txt | head -n 12 | tail -n 1 | awk '{print $11}'`
KVA_TOTAL=`cat /tmp/energia.txt | head -n 13 | tail -n 1 | awk '{print $10}'`
KVA_A=`cat /tmp/energia.txt | head -n 14 | tail -n 1 | awk '{print $11}'`
KVA_B=`cat /tmp/energia.txt | head -n 15 | tail -n 1 | awk '{print $7}'`
KVA_C=`cat /tmp/energia.txt | head -n 16 | tail -n 1 | awk '{print $9}'`
KVAR_TOTAL=`cat /tmp/energia.txt | head -n 17 | tail -n 1 | awk '{print $12}'`
KVAR_A=`cat /tmp/energia.txt | head -n 18 | tail -n 1 | awk '{print $8}'`
KVAR_B=`cat /tmp/energia.txt | head -n 19 | tail -n 1 | awk '{print $9}'`
KVAR_C=`cat /tmp/energia.txt | head -n 20 | tail -n 1 | awk '{print $11}'`


# Validando os limites de alerta e gerando mensagens juntamente com o performance data.
if ((`bc <<< "${KW_TOTAL} < ${WARNING}" `))
then
	PERFORMANCE "O consumo de potência está ok! kW total: ${KW_TOTAL} kW"
	exit 0;

elif ((`bc <<< "${KW_TOTAL} < ${CRITICAL}" `))
then
	PERFORMANCE  "O consumo de potência está em Alerta! kW total: ${KW_TOTAL} kW"
	exit 1;
else
	PERFORMANCE  "O consumo de potência está Crítico! kW total: ${KW_TOTAL} kW"
	exit 2;
fi

#Saida de erro
echo "Erro desconhecido!"
exit 3;