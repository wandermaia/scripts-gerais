#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: script-export-namespace.sh
# Sistema.............: EKS/Kubernetes
# Criado por..........: Wander Maia da Silva
# Data da Criação.....: 06/09/2021
# Data da Modificação.: 19/05/2022
# Modificação.........: Alterado o comando de export dos recursos para que o arquivo seja gerado utilizando a última confiuguração aplicada.
# Descrição...........: Realiza o export de todos os itens do namespace informado em formato yaml
# Entrada.............: Nome do Namespace
# Saída...............: Arquivos yaml relacionados aos recursos existentes.
#*****************************************************************************************************************************************************

# Menu de Ajuda
help () {

        cat <<EOF

Descrição do Script

        Realiza o export de todos os itens do namespace informado em formato yaml.
        O script realiza a varredura em todos os recursos (configmap, depoloyment, secret, etc.) do namespace informado e gera um export
        em formato yaml para todos os recursos encontrados.
        
Parâmetros

        -h  : Exibe este menu de ajuda
        -n  : Nome do namespace

Pré-requisitos

        É necessário que as configurações de acesso tenham sido configuradas previamente, pois o script utiliza o comando kubectl para sua execução.

Exemplo de Utilização

        Realização do export (na pasta atual) do namespace meu-namespace
        ./script-export-namespace.sh -n 'meu-namespace'

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

# Pasta para armazenamento dos backups
pastaExport=`echo -e "${NAMESPACE}_export-$(date +%Y%m%d)"`
mkdir "${pastaExport}"



# Coletando os recursos existentes para o namespace informado e realizado o backup de cada um.
recursosNamespace=`kubectl get -o=name pvc,configmap,serviceaccount,secret,ingress,service,deployment,statefulset,hpa,job,cronjob -n ${NAMESPACE}`
for recurso in ${recursosNamespace}; do
        tipoRecurso=`echo -e "${recurso}" | awk -F '/' '{print $1}' | awk -F '.' '{print $1}'`
        nomeRecurso=`echo -e "${recurso}" | awk -F '/' '{print $2}'`
        echo -e "[ ${NAMESPACE} ] - recurso: ${recurso}, nome: ${nomeRecurso} , tipo: ${tipoRecurso}"
        
        # Se a pasta para armazenar o recurso não existir, ela será criada
        if [ ! -d "${tipoRecurso}" ]; then
                mkdir -p ${pastaExport}/${tipoRecurso}
        fi
        #kubectl get -o=yaml ${recurso} -n ${NAMESPACE} > "${pastaExport}/${tipoRecurso}/${nomeRecurso}.yaml"
        kubectl apply view-last-applied ${recurso} -n ${NAMESPACE} > "${pastaExport}/${tipoRecurso}/${nomeRecurso}.yaml"
done
