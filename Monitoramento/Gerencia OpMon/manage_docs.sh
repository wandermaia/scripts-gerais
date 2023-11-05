#!/bin/bash
#*****************************************************************************************************************************************************
# Nome do Script......: /root/scripts/manage_docs.sh
# Sistema.............: OpMon
# Criado por..........: Wander Maia da Silva
# Data da Criação.....: 04/02/2019
# Descrição...........: Edita as documentações de hosts ou serviços.
# Entrada.............: Dados do serviço, host e/ou dados dos parâmetros que serão modificados.
#*****************************************************************************************************************************************************

# Menu de Ajuda
help () {

    cat <<EOF

Descrição do Script
        
  Script para editar as documentações de hosts e serviços
 
Parâmetros

  -h  : Exibe este menu de ajuda
  -t  : Tipo. Pode ser host ou lista
  -o  : Opção de modificação. Opções disponíveis:
      - list_docs: Lista todas as documentações de um host informado.
      - del_docs: Apaga todas as documentações de um host e serviços associados.
      - add_doc_host: Adiciona a documentação a uma lista de hosts passada por parâmetro (deve estar no formato: host|"descrição Procedimento")
      - add_doc_service: Adiciona a documentação a uma lista de serviços passada por parâmetro (deve estar no formato: host|serviço|"descrição Procedimento")
  -n  : Nome do servidor ou caminho do arquivo (dependendo da opção -o)


Exemplos de Utilização
  
  Listar todas as documentações relacionadas a um host
  /root/scripts/manage_docs.sh -t host -o list_docs -n 'CentOS-7-PRD'

  Apagar todas as documentações relacionadas a um host
  /root/scripts/manage_docs.sh -t host -o del_docs -n 'CentOS-7-PRD'
  
  Inserir a documentação para uma lista de hosts (cada linha do arquivo deve estar no formato: host|"descrição Procedimento". Se for utilizada quebra de linha, a mesma deve ser representada pelo caractere '§')
  /root/scripts/manage_docs.sh -t lista -o add_doc_host -n '/tmp/hosts.txt'

  Inserir a documentação para uma lista de serviços (cada linha do arquivo deve estar no formato: host|serviço|"descrição Procedimento". Se for utilizada quebra de linha, a mesma deve ser representada pelo caractere '§')
  /root/scripts/manage_docs.sh -t lista -o add_doc_service -n '/tmp/servicos.txt'


EOF

  exit
}

# Menu de validacao de entradas
while getopts "o:n:i:t:hd" Option
do
  case $Option in
    o )
      OPCAO=$OPTARG
      ;;
    n )
      NOME=$OPTARG
      ;;
    t )
      TIPO=$OPTARG
      ;;
    h )
      help
      ;;
  esac
done


# Função que executa as operações relacionadas a serviços de hosts. operacoesEmHosts ${NOME} ${OPCAO} ;;
operacoesEmHosts(){

  # Capturando os dados enviados por Parâmetros
  nomeHost=$1
  opcaoExecucao=$2
  
  # Coletando o ID do host
  idHost=`mysql -N -u root -e "SELECT host_id FROM nagios_hosts where host_name='${nomeHost}'" opcfg `

  # Validando se o host foi encontrado
  [ -z ${idHost} ] && echo -e "O Host '${nomeHost}' não foi encontrado!" && exit
  
  case ${opcaoExecucao} in
    list_docs)              listaDocsHost "${nomeHost}" "${idHost}"  ;;
    del_docs)               removeDocsHost "${nomeHost}" "${idHost}" ;;
    *)                      echo -e "\nValor da opção '-o' desconhecida!\n" ;;
  esac
}

# Função que lista as documentações de um Host específico
listaDocsHost () {
  host_name=$1
  host_id=$2

  # Validando se o host possui documentação cadastrada
  existeDocHost=`mysql -N -u root -e "SELECT id FROM opdocs_list WHERE host_id='${host_id}'" opmon4`
  quantidadeDocsHost=`echo -e ${existeDocHost} | wc -w`
  [ ${quantidadeDocsHost} -lt 1 ] && echo -e "O Host '${host_name}' não possui documentação cadastrada!" && exit

  # Realizando a listagem dos serviços do Host
  echo -e "\nDocumentações cadastradas para o Hots '${host_name}':\n"
  mysql -N -u root -e "SELECT description,text FROM opdocs_list WHERE host_id='${host_id}' order by description" opmon4

}

# Função que lista as documentações de um Host específico
removeDocsHost () {

  host_name=$1
  host_id=$2
  # Removendo todas as documentações do host informado
  mysql -u root -e "DELETE FROM opdocs_list WHERE host_id='${host_id}'" opmon4
  echo -e "\nDocumentações cadastradas para o Hots '${host_name}' removidas!\n"

}

# Função que executa as operações relacionadas a lista de serviços operacoesEmservices ${NOME} ${OPCAO} ;;
operacoesEmLista (){
  
  caminhoArquivo=$1
  opcaoExecucao=$2
  
  
  # validando se a lista existe.
  [ ! -e ${caminhoArquivo} ] && echo -e "\nO arquivo '${caminhoArquivo}' não foi encontrado! \n" && exit
  
  # Lendo as linhas do arquivo
  while read linha
  do
    
    # Coletando o ID do host e serviço
    nomeHost=`echo "${linha}" | awk -F '|' '{print $1}'`
    idHost=`mysql -N -u root -e "SELECT host_id FROM nagios_hosts where host_name='${nomeHost}'" opcfg `

    # Validando se o host e o serviço foram encontrados
    if [ ! -z ${idHost} ]
    then
      
      # Validando a operação solicitada
      case ${opcaoExecucao} in
        add_doc_host)           adicionaDocumentacaohosts "${nomeHost}" "${idHost}" "${linha}" ;;
        add_doc_service)        adicionaDocumentacaoServices "${nomeHost}" "${idHost}" "${linha}" ;;
        *)                      echo -e "\nValor da opção '-o' desconhecida!\n" ; exit ;;
      esac      
    else
      echo -e "O host '${nomeHost}' não foi encontrado!"
    fi
    
  done < ${caminhoArquivo}

}


# Função que adiciona a documentação nos hosts informados
adicionaDocumentacaohosts () {

  nomeHostLinha=$1
  idHostLinha=$2
  linhaDados=$3

  # Segregando o texto da documentação e convertendo o caractere § para quebra de linha
  documentacaoHost=`echo ${linhaDados} | awk -F '|' '{print $2}' | sed 's/§/\\n/g'`

  # Validando ser o serviço já possui documentação cadastrada
   existeDocHost=`mysql -N -u root -e "SELECT COUNT(*) FROM opdocs_list WHERE host_id='${idHostLinha}' AND service_id is NULL" opmon4`

  # Se a documentação do host não existir, ela será criada. Caso contrário, será atualizada.
  if [ ${existeDocHost} -lt 1 ]
  then
    mysql -N -u root -e "INSERT INTO opdocs_list ( host_id, description, text) VALUES ( '${idHostLinha}' , '${nomeHostLinha}', '${documentacaoHost}' )" opmon4
    echo -e "Documentação do host '${nomeHostLinha}' inserida!"
  else
    mysql -N -u root -e "UPDATE opdocs_list SET text='${documentacaoHost}' WHERE host_id='${idHostLinha}' AND service_id is NULL" opmon4
    echo -e "Documentação do host '${nomeHostLinha}' foi atualizada!"
  fi;

}


# Função que adiciona a documentação nos serviços informados
adicionaDocumentacaoServices () {

  nomeHostLinha=$1
  idHostLinha=$2
  linhaDados=$3

  # Segregando o nome do serviço e identificando o ID do serviço
  nomeServico=`echo -e "${linhaDados}" | awk -F '|' '{print $2}'`
  idServico=`mysql -N -u root -e "SELECT service_id FROM nagios_services WHERE host_id='${idHostLinha}' AND service_description='${nomeServico}'" opcfg `


  # Validando se o serviço informado existe
  quantidadeIDsServicos=`echo -e ${idServico} | wc -w`
  if [ ${quantidadeIDsServicos} -lt 1 ]
  then
    echo -e "\nO Serviço '${nomeServico}' do host '${nomeHostLinha}' não foi encontrado! \n" && exit
  else

    # Segregando a documentação
    documentacaoService=`echo -e "${linhaDados}" | awk -F '|' '{print $3}' | sed 's/§/\\n/g'`

    # Validando ser o serviço já possui documentação cadastrada
    existeDocService=`mysql -N -u root -e "SELECT COUNT(*) FROM opdocs_list WHERE host_id='${idHostLinha}' AND service_id='${idServico}'" opmon4`

    # Se a documentação do serviço não existir, ela será criada. Caso contrário, será atualizada.
    if [ ${existeDocService} -lt 1 ]
    then
      mysql -N -u root -e "INSERT INTO opdocs_list ( host_id, service_id, description, text) VALUES ( '${idHostLinha}' , '${idServico}', '${nomeHostLinha} - ${nomeServico}', '${documentacaoService}')" opmon4
      echo -e "\nDocumentação do serviço '${nomeServico}' do host '${nomeHostLinha}' inserida! \n"
    else
      mysql -N -u root -e "UPDATE opdocs_list SET text='${documentacaoService}' WHERE host_id='${idHostLinha}' AND service_id='${idServico}' " opmon4
      echo -e "\nDocumentação do serviço '${nomeServico}' do host '${nomeHostLinha}' foi atualizada! \n"
    fi;

  fi;

}

# Validando as opções selecionadas
[ -z ${TIPO} ] && echo -e "\nNão foi informada nenhuma opção para o parâmetro '-t'!\n" && exit
[ -z ${NOME} ] && echo -e "\nNão foi informada nenhuma opção para o parâmetro '-n'!\n" && exit

# Verificando qual opção informado
case ${TIPO} in
    host)                operacoesEmHosts ${NOME} ${OPCAO} ;;
    lista)               operacoesEmLista ${NOME} ${OPCAO} ;;
    *)                   echo -e "\nValor da opção '-t' desconhecida!\n" ;;
esac
