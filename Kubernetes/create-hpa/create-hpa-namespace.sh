#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: create-hpa-namespace.sh
# Sistema.............: EKS/Kubernetes
# Criado por..........: Wander Maia da Silva
# Data da Criação.....: 06/08/2023
# Data da Modificação.: -
# Modificação.........: -
# Descrição...........: Realiza a criação de arquivos yaml de HPA para todos os deployments do namespace informado.
# Entrada.............: Nome do Namespace
# Saída...............: Arquivos yaml dos HPAs dos deployments do namespace.
#*****************************************************************************************************************************************************

# Menu de Ajuda
help () {

        cat <<EOF

Descrição do Script

        Realiza a criação de arquivos yaml de HPA para todos os deployments do namespace informado.
        O script realiza a varredura em todos os deployments e pega o nome e quantidade de PODs atual, utilizando esse valor como o mínimo do HPA.
        É utilizado um modelo base de criação do HPA e criada uma pasta com o nome do namespace contendo todos os arquivos yamls gerados.
        
Parâmetros

        -h  : Exibe este menu de ajuda
        -n  : Nome do namespace

Pré-requisitos

        É necessário que as configurações de acesso tenham sido realizadas previamente, pois o script utiliza o comando kubectl para sua execução.

Exemplo de Utilização

        Criação dos HPAs de todos os deployments do namespace meu-namespace
        ./create-hpa-namespace.sh -n 'meu-namespace'

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

# Pasta para armazenamento dos yamls. Se ela não existir, será criada.
pastaHpas=`echo -e "hpas-${NAMESPACE}"`
if [ ! -d "${pastaHpas}" ]; then
        mkdir -p ${pastaHpas}
fi

# Gerando o HPA para cada deployment com base no modelo e ajustando os campos.
nomesDeploymentsNamespace=`kubectl get deployment -n ${NAMESPACE} | grep -iv AVAILABLE | awk '{print $1}' `
for deployment in ${nomesDeploymentsNamespace}; do
        
        minimoReplicas=`kubectl get deployment ${deployment} -n ${NAMESPACE} | grep -v NAME | awk '{print $2}' | awk -F '/' '{print $2}'`
        maximoReplicas=`echo "${minimoReplicas} * 2" | bc`

        echo -e "\nDeployment: ${deployment}"
        echo -e "\nMínimo réplicas: ${minimoReplicas}, Máximo de réplicas: ${maximoReplicas}"
        caminhoArquivoHpa=`echo -e "${pastaHpas}/hpa-${deployment}.yaml"`
        cp hpa-modelo.yaml ${caminhoArquivoHpa}
        sed -i "s/nome-deployment/${deployment}/" ${caminhoArquivoHpa}
        sed -i "s/nome-namespace/${NAMESPACE}/" ${caminhoArquivoHpa}
        sed -i "s/minimoReplicas/${minimoReplicas}/" ${caminhoArquivoHpa}
        sed -i "s/maximoReplicas/${maximoReplicas}/" ${caminhoArquivoHpa}
        echo -e "Arquivo gerado: ${caminhoArquivoHpa}\n"

done
