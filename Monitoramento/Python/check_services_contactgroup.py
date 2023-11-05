#!/usr/bin/python3
#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/check_services_contactgroup.py
# Sistema.............: OpMon
# Criado por..........: Wander Maia da Silva
# Data da Criação.....: 01/04/2019
# Descrição...........: Plugin para monitoramento de serviços diferentes entre dois contactgroups
# Entrada.............: Dados para acesso ao banco de dados, nomes dos contactgroups e valores de alarme
# Saida...............: Quantidade de serviços que existem no contactgoup de origem e não existem no destino.
# Linha do Plugin.....: ./check_services_contactgroup.py -s $ARG1$ -b $ARG2$ -u $ARG3$ -p $ARG4$ -o $ARG5$ -d $ARG6$ -w $ARG7$ -c $ARG8$
# Execução Manual.....: ./check_services_contactgroup.py -s 'localhost' -b 'databse' -u 'usuario' -p 'senha' -o contactgroupOrigem -d contactgroupDestino -w 1 -c 2
#*****************************************************************************************************************************************************
# Ex.: isValid (método/função), numberDaysWeek (variável), Customer (classe)
# Constantes: por padrão todas as letras do identificador devem ser escritas em maiúscula – e separadas por underline (_) caso seja composto 

# Biblioteca para o menu de opções
import argparse

# Módulo necessário para conectar ao mysql
import mysql.connector
from mysql.connector import errorcode

# Variáveis Globais
# Variáveis que vão receber os contactgroups
idContactgroupOrigem = ''
idContactgroupDestino = ''
totalServicosDiferentes = 0
acumladorIDsServicos = ""


# Criando o parser para validar as opções
parser = argparse.ArgumentParser(description='Plugin para a Verificação de seviços diferentes entre dois contactgroups informados.')

# Definindo os argumentos
parser.add_argument("-s", "--server", action = 'store', dest = 'serverName', type=str, required = True,
                    help="Server para conexão (previamente cadastrado no arquivo /etc/freetds.conf)")
parser.add_argument("-b", "--banco", action = 'store', dest = 'dbName', type=str, required = True,
                    help="Nome do banco de dados")
parser.add_argument("-u", "--user", action = 'store', dest = 'userName', type=str, required = True,
                    help="Nome do usuário para conexão ao banco de dados")
parser.add_argument("-o", "--origem", action = 'store', dest = 'contactgroupOrigem', type=str, required = True,
                    help="Nome do contactgroup de origem")
parser.add_argument("-d", "--destino", action = 'store', dest = 'contactgroupDestino', type=str, required = True,
                    help="Nome do contactgroup de destino")
parser.add_argument("-p", "--password", action = 'store', dest = 'userPassword', type=str, required = True,
                    help="Senha do usuario do banco de dados")
parser.add_argument("-w", "--warning", type=int, action = 'store', dest = 'warning', required = True,
                    help="Valor (inteiro) de warning para o tamanho da fila do QAgente")
parser.add_argument("-c", "--critical", type=int, action = 'store', dest = 'critical', required = True,
                    help="Valor (inteiro) de Critical para o tamanho da fila do QAgente")
# Passandos os parâmetros para a variável adequada
args = parser.parse_args()


# Função para execução de query o banco de dados
def getQueryResult(servidor,banco,usuario,senha,queryText):
    try:
        mySQLConnection = mysql.connector.connect(
            host=servidor,
            user=usuario,
            password=senha,
            database=banco)
        
        # Criando o cursor
        cursor = mySQLConnection.cursor(prepared=True)
        
        # Executando a query recebida por parâmetro da função
        cursor.execute(queryText)
        
        # Gravando as informações coletadas
        record = cursor.fetchall()

    
    except mysql.connector.Error as error:
        print("\nErro ao conectar no banco:\n\n{}".format(error))
    
    finally:
        # Fechando a conexão do banco de dados.
        if (mySQLConnection.is_connected()):
            cursor.close()
            mySQLConnection.close()
    
    return record



# Função que gera o performance data
def performanceData(mensagem):
    print ("{} | TOTAL_DIFF_SERVICES={};{};{};;".format(mensagem, totalServicosDiferentes, args.warning, args.critical))



# Coletando os IDs dos contactgroups
resultadoQueryIDContactgroupOrigem = getQueryResult(args.serverName,args.dbName,args.userName,args.userPassword,
                             "SELECT contactgroup_id FROM nagios_contactgroups WHERE contactgroup_name='{}'".format(args.contactgroupOrigem))

resultadoQueryIDContactgroupDestino = getQueryResult(args.serverName,args.dbName,args.userName,args.userPassword,
                             "SELECT contactgroup_id FROM nagios_contactgroups WHERE contactgroup_name='{}'".format(args.contactgroupDestino))


# Validando se os contactgroups foram encontrados
if len(resultadoQueryIDContactgroupOrigem) == 0:
    print ("O Contactgroup '{}' não foi encontrado.".format(args.contactgroupOrigem))
    exit(2)
if len(resultadoQueryIDContactgroupDestino) == 0:
    print ("O Contactgroup '{}' não foi encontrado.".format(args.contactgroupDestino))
    exit(2)


# segregando os IDs dos contactgroups
idContactgroupOrigem = resultadoQueryIDContactgroupOrigem[0][0]
idContactgroupDestino = resultadoQueryIDContactgroupDestino[0][0]


# Obtendo a lista de IDs de serviços que estão aparesentados para cada um dos contactgroups
idsServicosContactgroupOrigem = getQueryResult(args.serverName,args.dbName,args.userName,args.userPassword,
                             "SELECT service_id FROM nagios_service_contactgroups WHERE contactgroup_id='{}'".format(idContactgroupOrigem))

idsServicosContactgroupDestino = getQueryResult(args.serverName,args.dbName,args.userName,args.userPassword,
                             "SELECT service_id FROM nagios_service_contactgroups WHERE contactgroup_id='{}'".format(idContactgroupDestino))


# Validando os IDs dos serviços do contactgroup de origem para todos os do destino
for linhaOrigem in idsServicosContactgroupOrigem:
    idServicoOrigem = linhaOrigem[0]

    """Variável de controle para saber se o serviço está apresentado para o contato de destino. 
    O loop abaixo vai percorrer a lista de serviços que está apresentada pelo secundário e verificar se o serviço do contactgroup
    em análise apresenta pelo menos uma ocorrência na lista. Em caso afirmativo, no fim ele vai incrementar a variável global.
    """
    existeServico = 0

    # Loop para verificação se o serviço do contactgroup de origem está apresentado para o de desino
    for linhaDestino in idsServicosContactgroupDestino:
        idServicoDestino = linhaDestino[0]

        # Validando se o contactgroup foi encontrado
        if  idServicoOrigem == idServicoDestino:
            existeServico += 1

    # Validando se foi encontrada alguma ocorrência do id do serviço na lista do contactgroup de destino
    if existeServico < 1:
        # Incrementando o contatdor de serviços apresentados para ambos
        totalServicosDiferentes += 1
        acumladorIDsServicos = "'{}' {}".format(idServicoOrigem,acumladorIDsServicos)




# Validando os limites de alerta
if totalServicosDiferentes >= args.critical:
    performanceData("O número de serviços diferentes está crítico! TOTAL_DIFF_SERVICES: '{}'. IDs dos Serviços: {} ".format(totalServicosDiferentes, acumladorIDsServicos))
    exit(2)
elif totalServicosDiferentes >= args.warning:
    performanceData("O número de serviços diferentes está em alerta! TOTAL_DIFF_SERVICES: '{}'. IDs dos Serviços: {} ".format(totalServicosDiferentes, acumladorIDsServicos))
    exit(1)
else:
    performanceData("O número de serviços diferentes está ok! TOTAL_DIFF_SERVICES: '{}'".format(totalServicosDiferentes))
    exit(0)


# Saida de erro
print("Erro desconhecido!")
exit (3)
