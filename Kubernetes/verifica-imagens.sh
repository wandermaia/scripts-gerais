#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: verifica-imagens.sh
# Sistema.............: EKS
# Criado por..........: Wander Maia da Silva
# Data da Criação.....: 06/09/2021
# Descrição...........: Verifica a versão das imagens utilizadas nos deployments
# Entrada.............: Nome do Namespace
# Saída...............: Arquivo csv contendo os nomes dos depoyments e versões das imagens de containers utilizadas.
#*****************************************************************************************************************************************************

# Menu de Ajuda
help () {

        cat <<EOF

Descrição do Script

        Verifica as versões das imagens dos deployments.
        
Parâmetros

        -h  : Exibe este menu de ajuda
        -n  : Nome do namespace

Pré-requisitos

        É necessário que as configurações de acesso tenham sido configuradas previamente, pois o script utiliza o comando kubectl para sua execução.

Exemplo de Utilização

        Validação das versões das imagens dos deployments (na pasta atual) do namespace meu-namespace
        ./verifica-imagens.sh -n 'meu-namespace'

EOF

        exit
}


# Menu de validacao de entradas
while getopts "n:hd" Option
do
  case $Option in
    n )
      NAMESPACE=$OPTARG
      ;;
    h )
      help
      ;;
  esac
done


# Realizando as validações relacionadas ao namespace para execução das atividades.
[ -z ${NAMESPACE} ] && echo -e  "\nA opção '-n' não pode ser nula! \n" && help && exit

validaNamespace=`kubectl get namespace | grep -w "${NAMESPACE}" | wc -l`

if ((`bc <<< "${validaNamespace} != 1" `))
then
        echo -e "\nO namespace '${NAMESPACE}' não foi encontrado! Verifique se o nome está correto. \n" && exit
fi

# Criação do arquivo CSV e o cabeçalho
ARQUIVO="imagens-versions.csv"
echo -e "Image;DeploymentName;Version" > ${ARQUIVO}


# Coletando os deployments do namespace
deployments=`kubectl get deployment -n ${NAMESPACE} | grep -v NAME | awk '{print $1}'`

# Segregando os dados encontrados e adicionando ao csv
for deployment in ${deployments}; do
        image=`kubectl describe deployment ${deployment} -n ${NAMESPACE} | grep Image | awk '{print $2}'`
        echo -e "Deployment: '${deployment}',  Imagem: '${image}'"
        name=`echo -e "${image}" | awk -F '/' '{print $4}' | awk -F ':' '{print $1}'`
        version=`echo -e "${image}" | awk -F ':' '{print $2}'`
        echo -e "${image};${deployment};${version}" >> ${ARQUIVO}
done