#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: script-pod-resources.sh
# Sistema.............: EKS/Kubernetes
# Criado por..........: Wander Maia da Silva
# Data da Criação.....: 27/10/2021
# Descrição...........: Script para gerar um arquivo csv contendo os recursos de todos os pods
# Entrada.............: Não necessário
# Saída...............: Arquivo CSV contendo os dados dos pods (cpu e memória)
#*****************************************************************************************************************************************************

# Menu de Ajuda
help () {

        cat <<EOF

Descrição do Script

        Script para gerar um arquivo csv contendo os recursos de todos os pods, separados por container.
        O script pode realizar a varredura em todos os namespaces ou em um específico (através do parâmetro -n) coletando os dados de recursos consumidos por cada pod encontrado. 
        
Parâmetros

        -h  : Exibe este menu de ajuda
        -n  : Nome do namespace. Pode ser passado o nome do namespace ou 'all' para coletar de todos.

Pré-requisitos

        É necessário que as configurações de acesso tenham sido realizadas previamente, pois o script utiliza o comando kubectl para sua execução.

Exemplo de Utilização

        Realização da coleta dos recursos de todos os pods em todos os namespaces
        ./script-pod-resources.sh -n all

        Realização da coleta dos recursos de todos os pods apenas do namespace kube-system
        ./script-pod-resources.sh -n kube-system

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


# Validando se deve ser realizada a coleta de todos os namespaces ou um específico
LISTA_PODS=''
if [[ ${NAMESPACE} == "all" ]]
then
        # Coletando os recursos existentes de todos os pods
        LISTA_PODS=`kubectl get pod -A | grep -v NAMESPACE | grep -v 'kube-system'`

else
        validaNamespace=`kubectl get namespace | grep -w "${NAMESPACE}" | wc -l`
        if ((`bc <<< "${validaNamespace} != 1" `))
        then
                echo -e "\nO namespace '${NAMESPACE}' não foi encontrado! Verifique se o nome está correto. \n" && exit
        fi

        # Coletando os recursos existentes de todos os pods
        LISTA_PODS=`kubectl get pod -A | grep -v NAMESPACE | grep "${NAMESPACE}"`
fi


# Definição do arquivo e criação do cabeçalho
ARQUIVO_EXPORT=`echo -e "export-pods-resources-${NAMESPACE}-$(date +%Y%m%d).csv"`
echo -e "Namespace;Pod;Container Name;CPU (milicore);Memory (Megabyte);CPU Request (milicore);Memory Request (Megabyte) ;CPU Limit (milicore);Memory Limit (Megabyte)" > ${ARQUIVO_EXPORT}


# Alterando a quebra de linha
BKP_IFS=${IFS}
IFS='
'
# Coleta dos dados de cada pod e inserção no arquivo csv.
for POD in $(echo -e "${LISTA_PODS}"); do
        namespacePod=`echo -e "${POD}" | awk '{print $1}'`
        nomePod=`echo -e "${POD}" | awk '{print $2}'`
        echo -e "Coletando dados pod '${nomePod}'"

        # Loop para coletar os recursos de cada container existente dentro do pod
        consultaRecursos=`kubectl top pod "${nomePod}" -n "${namespacePod}" --containers | grep -v 'CPU(cores)'`
        getPodJson=`kubectl get pods "${nomePod}" -n "${namespacePod}" -o json `
        echo -e "consultaRecursos:"
        echo -e "${consultaRecursos}"

        for container in  $(echo -e "${consultaRecursos}"); do
                nomeContainer=`echo -e "${container}" | awk '{print $2}'`
                valorCpu=`echo -e "${container}" | awk '{print $3}'`
                valorMemoria=`echo -e "${container}" | awk '{print $4}'`
                
                # Coletando os valores de limites e requests para os containers
                requestCPU=`echo -E "$getPodJson" | jq ".spec.containers[] | select(.name == \"$nomeContainer\") | .resources.requests.cpu" | sed s/\"/\/g | sed s/m/\/g`
                echo -e "requestCPU pre: ${requestCPU}"
                [ "${requestCPU}" == "null" ] && requestCPU="00"
                echo -e "requestCPU ${requestCPU}"
                
                
                requestMemoria=`echo -E "$getPodJson" | jq ".spec.containers[] | select(.name == \"$nomeContainer\") | .resources.requests.memory"  | sed s/\"/\/g | sed s/Mi/\/g`
                echo -e "requestMemoria pre:  ${requestMemoria}"
                [ "${requestMemoria}" == "null" ] && requestMemoria="000"   
                echo -e "requestMemoria ${requestMemoria}"
                
                
                limiteCPU=`echo -E "$getPodJson" | jq ".spec.containers[] | select(.name == \"$nomeContainer\") | .resources.limits.cpu"  | sed s/\"/\/g`      
                # Essas próximas duas linhas foram necessárias para quando o limite de cpu for maior do que 1 core (1000m).
                echo -e "limiteCPU coletado: ${limiteCPU}"
                cartacterM=`echo "${limiteCPU}" | grep 'm' | wc -l`
                if [ -n ${limiteCPU} ] && [ $cartacterM -lt 1 ];then limiteCPU="$((${limiteCPU} * 1000))m";fi
                echo -e "limiteCPU pre: ${limiteCPU}"
                [ "${limiteCPU}" == "null" ] && limiteCPU="00"
                limiteCPU=`echo -e ${limiteCPU} | sed s/m/\/g`
                echo -e "limiteCPU ${limiteCPU}"
                

                limiteMemoria=`echo -E "$getPodJson" | jq ".spec.containers[] | select(.name == \"$nomeContainer\") | .resources.limits.memory"  | sed s/\"/\/g | sed s/Mi/\/g`
                echo -e "limiteMemoria pre: ${limiteMemoria}"
                [ "${limiteMemoria}" == "null" ] && limiteMemoria="000"
                echo -e "limiteMemoria ${limiteMemoria}"
                
                
                echo -e "${namespacePod};${nomePod};${nomeContainer};${valorCpu::-1};${valorMemoria::-2};${requestCPU};${requestMemoria};${limiteCPU};${limiteMemoria}" >> ${ARQUIVO_EXPORT}
        done
done

# Restaurando o valor da quebra de linha
IFS=${BKP_IFS}

