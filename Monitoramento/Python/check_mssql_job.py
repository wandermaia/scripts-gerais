#!/usr/bin/python3
#*****************************************************************************************************************************************************
# Nome do Script......: /usr/local/opmon/libexec/custom/check_mssql_job.py
# Sistema.............: OpMon
# Criado por..........: Wander Maia da Silva
# Data da Criação.....: 03/06/2019
# Descrição...........: Plugin para verificação do status da última execução do job SQL Server.
# Entrada.............: Dados para acesso ao banco de dados e nome do job
# Saida...............: Status da última execução do job informado
# Linha do Plugin.....: /usr/local/opmon/libexec/custom/check_mssql_job.py -s $ARG1$ -d $ARG2$ -u $ARG3$ -p $ARG4$ -j $ARG5$
# Execução Manual.....: /usr/local/opmon/libexec/custom/check_mssql_job.py -s 'conexao' -d 'msdb' -u 'usuario' -p 'senha' -j 'job_name'
#*****************************************************************************************************************************************************

# Biblioteca para o menu de opções
import argparse

# Biblioteca para conexão ao SQL Server
import pyodbc 

# Criando o parser para validar as opções
parser = argparse.ArgumentParser(description='Plugin para a Verificação de seviços diferentes entre dois contactgroups informados.')

# Definindo os argumentos
parser.add_argument("-s", "--server", action = 'store', dest = 'serverName', type=str, required = True,
                    help="Server para conexão (previamente cadastrado no arquivo /etc/freetds.conf)")
parser.add_argument("-d", "--database", action = 'store', dest = 'dbName', type=str, required = True,
                    help="Nome do banco de dados")
parser.add_argument("-u", "--user", action = 'store', dest = 'userName', type=str, required = True,
                    help="Nome do usuário para conexão ao banco de dados")
parser.add_argument("-p", "--password", action = 'store', dest = 'userPassword', type=str, required = True,
                    help="Senha do usuario do banco de dados")
parser.add_argument("-j", "--job", action = 'store', dest = 'jobName', type=str, required = True,
                    help="Nome do Job para verificação")

# Passandos os parâmetros para a variável adequada
args = parser.parse_args()


# Segregando os dados para conexão ao banco de dados
server = args.serverName
database = args.dbName
username = args.userName
password = args.userPassword
jobName = args.jobName

# Configurando a string de conexão ao banco de dados com as informações fornecidas
cnxn = pyodbc.connect('DRIVER={ODBC Driver 17 for SQL Server};SERVER='+server+';DATABASE='+database+';UID='+username+';PWD='+ password)
cursor = cnxn.cursor()


# Verificando se o job está habilitado.
# -- 0 Disable
# -- 1 Enable
cursor.execute("""
            SELECT enabled from msdb.dbo.sysjobs 
            where name = '{}'
                """.format(jobName)) 

habilitado = cursor.fetchone() 

if habilitado == 0:
    performanceData("O Job '{}' está desabilitado!".format(jobName))
    exit(2)



# Verficando o horário e o status da última execução do job.
cursor.execute("""DECLARE @JOBNAME VARCHAR(100);
                  SET @JOBNAME = '{}' 
                  EXEC dbo.sp_help_job 
                  @JOB_NAME = @JOBNAME,
                  @job_aspect='JOB'""".format(jobName)) 

dadosExecucao = cursor.fetchone() 


# Segregando a data da execução (20190602) e realizando o slicing para segregar os dados
anoExecucao = (str(dadosExecucao[19])[0:4])
mesExecucao = (str(dadosExecucao[19])[4:6])
diaExecucao = (str(dadosExecucao[19])[6:])

# Segregando a hora da execução (230000) e realizando o slicing para segregar os dados
horaExecucao = (str(dadosExecucao[20])[0:2])
minutosExecucao = (str(dadosExecucao[20])[2:4])

# Segregando o status da última execução
# last_run_outcome: Valor que represena o resultado da última execução do job. Abaixo seguem os valores de cada status:
# 0 = falha
# 1 = foi bem-sucedida
# 3 = cancelada
# 5 = desconhecido
statusExecucao = dadosExecucao[21]


# Função que gera o performance data
def performanceData(mensagem):
    print ("{} | STATUS={};;;;".format(mensagem, statusExecucao))


# Validando os limites de alerta
if statusExecucao == 1:
    performanceData("O Job '{}' foi executado com sucesso! Última execução: {}-{}-{}, as {}:{} horas.".format(jobName, diaExecucao, mesExecucao,anoExecucao,horaExecucao,minutosExecucao))
    exit(0)
elif statusExecucao == 0:
    performanceData("O Job '{}' falhou! Última execução: {}-{}-{}, as {}:{} horas.".format(jobName, diaExecucao, mesExecucao,anoExecucao,horaExecucao,minutosExecucao))
    exit(2)
elif statusExecucao == 3:
    performanceData("O Job '{}' foi cancelado! Última execução: {}-{}-{}, as {}:{} horas.".format(jobName, diaExecucao, mesExecucao,anoExecucao,horaExecucao,minutosExecucao))
    exit(1)
else:
    performanceData("Status do Job '{}' Desconhecido! Última execução: {}-{}-{}, as {}:{} horas.".format(jobName, diaExecucao, mesExecucao,anoExecucao,horaExecucao,minutosExecucao))
    exit(0)


# Caso apresente algum erro diferente
print("Erro desconhecido!")
exit (3)