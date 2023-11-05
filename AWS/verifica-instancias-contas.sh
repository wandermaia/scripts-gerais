#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: verifica-instancias-contas.sh
# Sistema.............: AWS (CLI)
# Criado por..........: Wander Maia da Silva
# Data da Criação.....: 08/02/2023
# Descrição...........: Verifica as instâncias presentes em cada conta de um ambiente segregado por conta.
# Entrada.............: Nenhum dado necessário.
# Saída...............: Cria pasta coleta e gera um arquivo por conta da AWS contendo as informações das instâncias
#*****************************************************************************************************************************************************

# Menu de Ajuda
help () {

        cat <<EOF

Descrição do Script

        Verifica as instâncias nas contas da AWS, salva os dados de cada conta em um arquivo e gera um resumo em tela.
        
Parâmetros

        -h  : Exibe este menu de ajuda

Pré-requisitos

        É necessário que as configurações de acesso à AWS tenham sido previamente realizadas, pois o script utiliza o comando aws cli para sua execução.

Exemplo de Utilização

        Verificação de todas as instâncias
        ./verifica-instancias-contas.sh

EOF

        exit
}


# Menu de validacao de entradas
while getopts "hd" Option
do
  case $Option in
    h )
      help
      ;;
  esac
done


# Pasta onde ficarão os arquivos
pastaExport=`echo -e "coleta-$(date +%Y%m%d)"`
mkdir "${pastaExport}"

# Neste ponto devem ser adicionadas as contas configuradas. Elas tem que ter o mesmo nome que consta no profile configurado no arquivo config do CLI.
CONTAS=( 'conta01' 'conta02' 'conta03' )

for CONTA in ${CONTAS[@]}
do
  echo -e "Coletando na conta ${CONTA}"
  aws ec2 describe-instances --query "Reservations[*].Instances[*].{Instance:InstanceId,State:State.Name,Platform:Platform,InstanceType:InstanceType,PrivateIpAddress:PrivateIpAddress,Subnet:SubnetId,Name:Tags[?Key=='Name']|[0].Value}" --output table --profile ${CONTA} > ${pastaExport}/instancias_conta_${CONTA}.txt
done

TOTAL_INSTANCIAS=`egrep -iR 'i-' ${pastaExport} | wc -l`
INSTANCIAS_WINDOWS=`egrep -iR 'i-' ${pastaExport} | grep windows | wc -l`
INSTANCIAS_LINUX=`egrep -iR 'i-' ${pastaExport} | grep None | wc -l`
INSTANCIAS_EM_EXECUCAO=`egrep -iR 'i-' ${pastaExport} | grep running | wc -l`
INSTANCIAS_PARADAS=`egrep -iR 'i-' ${pastaExport} | grep stopped | wc -l`

echo -e "\nResultado: \n"

echo -e "TOTAL_INSTANCIAS: ${TOTAL_INSTANCIAS}"
echo -e "INSTANCIAS_WINDOWS: ${INSTANCIAS_WINDOWS}"
echo -e "INSTANCIAS_LINUX: ${INSTANCIAS_LINUX}"
echo -e "INSTANCIAS_EM_EXECUCAO: ${INSTANCIAS_EM_EXECUCAO}"
echo -e "INSTANCIAS_PARADAS: ${INSTANCIAS_PARADAS}"
