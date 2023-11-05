#!/usr/bin/python3

"""
Nome do Script: /usr/lib/zabbix/externalscripts/check_acknowledged_zabbix.py
Sistema: Zabbix
Criado por: Wander Maia da Silva
Data da Criação: 02/10/2020
Descrição: Script para a Verificação do prazo de validade do reconhecimento com base na severidade do problema
Entrada: Dados para acesso à API do Zabbix
Saida: Reconhecimentos validados e os que houverem extrapolado o tempo de reconhecimento serão removidos
Linha do Plugin: ./check_acknowledged.py -s 'localhost' -u 'zabbix_user' -p 'zabbix_password'
Exemplo uso na cron: */5 * * * * /usr/lib/zabbix/externalscripts/check_acknowledged.py -s 'localhost' -u 'zabbix_user' -p 'zabbix_password' >> /var/log/check_acknowledged.log 2>&1

"""


# Bibliotecas para o menu de opções, API do Zabbix e trabalhar com horario.
import argparse
from zabbix_api import ZabbixAPI
from datetime import datetime



"""
Variáveis Globais para utilização no script

As vaŕiáveis de tempo de limite referem-se ao valor máximo de tempo (em segundos) que o problema pode ficar reconhecido. Se este tempo
for extrapolado, o reconhecimento será removido. Abaixo seguem os códigos das severidades e os valores de referência:
0 - Não Classificada - 96 horas (345600 Segundos)
1 - Informação - 48 horas (172800 segundos)
2 - Atenção - 24 horas (86400 segundos)
3 - Média - 12 horas (43200 segundos)
4 - Alta - 4 horas (14400 segundos)
5 - Desastre - 30 Minutos (1800 segundos)


"""
tempoLimiteNotClassified = 345600
tempoLimiteInformation = 172800
tempoLimiteWarning = 86400
tempoLimiteAverage = 43200
tempoLimiteHigh = 14400
tempoLimiteDisaster = 1800





# Criando o parser para validar as opções do script e apresentar a ajuda
parser = argparse.ArgumentParser(description="""Script para a Verificação do prazo de validade do reconhecimento com base na severidade do problema

O scritp verifica todos os alertas que estão reconhecidos e compara a hora de reconhecimento com a hora atual. Se passar do valor 
estipulado para a severididade do alerta, o mesmo terá seu reconhecimento removido e voltará para a tela do operador.

    """)

# Definindo os argumentos
parser.add_argument("-s", "--server", action = 'store', dest = 'serverName', type=str, required = True,
                    help="Server Zabbix para conexão. Exemplos: 192.168.56.195, localhost ou Zabbix.domain.local")
parser.add_argument("-u", "--user", action = 'store', dest = 'userName', type=str, required = True,
                    help="Nome do usuário para conexão na API do Zabbix")
parser.add_argument("-p", "--password", action = 'store', dest = 'userPassword', type=str, required = True,
                    help="Senha do usuario para conexão na API do Zabbix")

# Passandos os parâmetros para a variável adequada
args = parser.parse_args()


# Montando a URL da API e segregando os valores de acesso
zabbix_server = "http://{}/zabbix".format(args.serverName)
username = args.userName
password = args.userPassword



# Instanciando a conexao com a API
conexao = ZabbixAPI(server = zabbix_server)
conexao.login(username, password)





"""
Função para validar se o reconhecimento extrapolou o tempo padrão baseado na severidade. 
Serã utilizados os valores definidos nas variáveis globais.

"""
def verificaValidadeReconhecimento(tempoReconhecido,eventID,codigoSeverity,problemName):
    
    # Variável de apoio para cálculo do reconhecimento
    tempoMaximoReconhecimento = 0
    mensagem = "Tempo de reconhecimento excedido para a severidade do alerta."

    # Definindo o tempo de expiração com base na severidade recebida
    if codigoSeverity == '0':
        tempoMaximoReconhecimento = tempoLimiteNotClassified
    elif codigoSeverity == '1':
        tempoMaximoReconhecimento = tempoLimiteInformation
    elif codigoSeverity == '2':
        tempoMaximoReconhecimento = tempoLimiteWarning
    elif codigoSeverity == '3':
        tempoMaximoReconhecimento = tempoLimiteAverage
    elif codigoSeverity == '4':
        tempoMaximoReconhecimento = tempoLimiteHigh
    elif codigoSeverity == '5':
        tempoMaximoReconhecimento = tempoLimiteDisaster
    else:
        print("erro no código de severidade")
        exit (2)

    """
    Removendo o reconhecimento, caso o tempo máximo tenha sido extrapolado
    É exibida uma mensagem para o usuário informando o alerta removido.

    """
    if  tempoReconhecido > tempoMaximoReconhecimento:
        conexao.event.acknowledge({"eventids": eventID , "action": 4 , "message": "{}".format(mensagem)})
        conexao.event.acknowledge({"eventids": eventID , "action": 16 })
        print(datetime.now())
        print("Removido o reconhecimento do poblema '{}' (ID={}), com a mensagem: '{}'".format(problemName,eventID,mensagem))




"""
Função que coleta a hora (em epoch) do último reconhecimento aplicado no problema. Recebe uma lista dos dicionários de informações dos reconhecimentos.
"""
def verificaUltimoReconhecimento(reconhecimentos):
    
    # lista de apoio para armazenar os horários dos reconhecimentos
    horaReconhecimentos = []


    """

    O item 'reconhecimentos' é um dicionário contendo os reconhecimentos associados à trigger que gerou o problema.
    Para segregar os valores, foi utilizada List Comprehension para coletar apenas os ids dos reconhecimentos, hora (em epoch) e ação realizada de cada evento.
    A saída é uma lista de tuplas (geradas ordem crescente) no formato (id,hora,ação)
    Utilizamos apenas o horário do evento mais recente que contém reconhecimento (action = 6)

    """
    idReconhecimentos =  [(int(item['acknowledgeid']),int(item['clock']),int(item['action'])) for item in reconhecimentos ]


    """
    Segregando os horários apenas dos eventos de reconhecimento. 
    Quando é executado apenas o reconhecimento, o código é 6. Mas se houver alteração de severidade, o código passa a ser o 14
    Ainda há a situação de quando o incidente está sendo forçado a fechar. Neste caso, o código do reconhecimento vai para 15. 
    Este último caso foi adicionado apenas para que o script não apresente erro, pois problema entra em estado de "Closing"  e 
    será finalizado forçadamente em seguida. Na checagem subsequente, se o alerta persistir, o problea será um novo e terá um novo ID,
    iniciando todo o processo novamente.

    """
    for item in idReconhecimentos:
        if item[2] == 6 or item[2] == 14 or item[2] == 15:
            horaReconhecimentos.append(item[1])


    # Ordenando e retornando o horário do reconhecimento mais atual
    horaReconhecimentos.sort()
    return horaReconhecimentos[-1]




"""

Função principal do script. Ele realiza coleta dos problemas do ambiente, verifica quais estão reconhecidos e encaminha para as
demais funções, que realizaram as validações de tempo de reconhecimento com base na severidade e realizaram a remoção do reconhecimento
se o tempo definido estiver sido extrapolado.

"""

# Coletando os problemas do ambiente neste momento (ele gera uma lista de dicionários) e a hora atual (em formato epoch)
problemas = conexao.problem.get({"output": "extend", "acknowledged": "true", "selectAcknowledges": "extend", "sortfield": "eventid"})
horaAtualEpoch = int(datetime.now().strftime('%s'))

# Verificando cada um dos problemas
for problema in problemas:

    # Identificando se o problema está reconhecido.
    if (problema['acknowledged'] == "1"):

        """
        O item 'acknowledges' é um dicionário contendo os reconhecimentos associados à trigger que gerou o problema.
        Para segregar os valores, é utilizada a função 'verificaUltimoReconhecimento', que recebe este dicionário como parâmetro
        e retorna o valor da hora (em epoch) do último reconhecimento.
        Utilizamos apenas o horário do evento mais recente que contém reconhecimento (action = 6)
        """
        horaReconhecimentoEpoch = verificaUltimoReconhecimento(problema['acknowledges'])

        # Calculando o tempo que o problema está reconhecido
        tempoReconhecido = horaAtualEpoch - horaReconhecimentoEpoch


        """ 
        A função verificaValidadeReconhecimento é utilizada para validar se o reconhecimento já extrapolou o horário determinado. 
        O limite é definido com base na severidade do alerta, comparando com valores pré-definidos nas variáveis globais definidas no início deste script.
        
        """
        verificaValidadeReconhecimento(tempoReconhecido,problema['eventid'],problema['severity'],problema['name'])

