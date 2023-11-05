#!/usr/bin/python3
#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/check_hosts_contactgroup.py
# Sistema.............: OpMon
# Criado por..........: Wander Maia da Silva
# Data da Criação.....: 02/04/2019
# Descrição...........: Plugin para monitoramento de hosts com outros contactgroups além do opmonadmin
# Entrada.............: Dados para acesso ao banco de dados, nomes dos contactgroups e valores de alarme
# Saida...............: Quantidade de hosts que tem mais de um contactgroup como responsável.
# Linha do Plugin.....: ./check_hosts_contactgroup.py -s $ARG1$ -b $ARG2$ -u $ARG3$ -p $ARG4$ -w $ARG5$ -c $ARG6$
# Execução Manual.....: ./check_hosts_contactgroup.py -s 'localhost' -b 'banco' -u 'usuario' -p 'senha' -w 1 -c 2
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
totalHostsVariosContactgroups = 0
acumladorHostname = ""


# Criando o parser para validar as opções
parser = argparse.ArgumentParser(description='Plugin para a Verificação da Fila do QAgente do Qualitor!')

# Definindo os argumentos
parser.add_argument("-s", "--server", action = 'store', dest = 'serverName', type=str, required = True,
                    help="Server para conexão. Exemplo: localhost")
parser.add_argument("-b", "--banco", action = 'store', dest = 'dbName', type=str, required = True,
                    help="Nome do banco de dados")
parser.add_argument("-u", "--user", action = 'store', dest = 'userName', type=str, required = True,
                    help="Nome do usuário para conexão ao banco de dados")
parser.add_argument("-p", "--password", action = 'store', dest = 'userPassword', type=str, required = True,
                    help="Senha do usuario do banco de dados")
parser.add_argument("-w", "--warning", type=int, action = 'store', dest = 'warning', required = True,
                    help="Valor (inteiro) de warning para o tamanho da fila do QAgente")
parser.add_argument("-c", "--critical", type=int, action = 'store', dest = 'critical', required = True,
                    help="Valor (inteiro) de Critical para o tamanho da fila do QAgente")
# Passandos os parâmetros para a variável adequada
args = parser.parse_args()


# Função para execução de query no banco de dados
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


# Coletando os IDs dos hosts
resultadoQuerylistaIDsHosts = getQueryResult(args.serverName,args.dbName,args.userName,args.userPassword,
                             "SELECT host_id,host_name FROM nagios_hosts")


# Loop para a verificação de todos os hostids
for linha in resultadoQuerylistaIDsHosts:
    
    # Segregando o hostame e hostid
    hostId = linha[0]
    hostname = linha[1]
    
    # Validando a quantidade de contactgroups cadastrados para o host
    qtdContacgroupsHost = getQueryResult(args.serverName,args.dbName,args.userName,args.userPassword,
                             "SELECT COUNT(*) FROM nagios_host_contactgroups WHERE host_id='{}'".format(hostId))
    
    # Validando se o contactgroup opmon-admins está cadastrado no host
    validaOpmonAdmins = getQueryResult(args.serverName,args.dbName,args.userName,args.userPassword,
                             "SELECT COUNT(*) FROM nagios_host_contactgroups WHERE host_id='{}' and contactgroup_id = 1".format(hostId))

    # Validando se o host possui mais de um contactgroup e, em caso afirmativo, incrementando o contador e salvando o hostname
    if (qtdContacgroupsHost[0][0] > 1) or (validaOpmonAdmins[0][0] < 1) :
        totalHostsVariosContactgroups += 1
        acumladorHostname = "'{}' {}".format(hostname,acumladorHostname)


# Função que gera o performance data
def performanceData(mensagem):
    print ("{} | TOTAL_HOSTS={};{};{};;".format(mensagem, totalHostsVariosContactgroups, args.warning, args.critical))


# Validando os limites de alerta
if totalHostsVariosContactgroups >= args.critical:
    performanceData("O quantidade de hosts com configuração inadequada de contactgroup está crítico! TOTAL_HOSTS: '{}'. Hosts: {}".format(totalHostsVariosContactgroups, acumladorHostname))
    exit(2)
elif totalHostsVariosContactgroups >= args.warning:
    performanceData("O quantidade de hosts com configuração inadequada de contactgroup está em alerta! TOTAL_HOSTS: '{}'. Hosts: {}".format(totalHostsVariosContactgroups, acumladorHostname))
    exit(1)
else:
    performanceData("O quantidade de hosts com configuração inadequada de contactgroup está ok! TOTAL_HOSTS: '{}'.".format(totalHostsVariosContactgroups))
    exit(0)


# Saida de erro
print("Erro desconhecido!")
exit (3)
