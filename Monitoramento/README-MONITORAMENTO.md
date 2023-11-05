# Scripts-Gerais - Monitoramento

Os scripts de monitoramento foram divididos em três pastas: 'Bash e Powershell', 'Gerencia OpMon' e 'Python'


## **Bash e Powershell**

Nessa pasta estão contidos os plugins utilizados no OpMon e foram criados em bash ou powershell. 

Como o OpMon é um sistema de monitoramento "Nagios Like", estes plugins devem funcionar em qualquer outro sistema baseado no Nagios.

Foram criadas algumas subpastas para facilitar a procura dos plugins.

> **OBSERVAÇÕES:**
> 
> Informações complementares foram adicionadas dentro de cada script.


## **Gerencia OpMon**

Os scripts bash presentes nessa pasta são um pouco maiores do que os da pasta de plugins.

No época em que eles foram criados, as opções disponíveis na API do OpMon ainda eram bastante limitadas e, por isso, a api não foi utilizada.

As operações realizadas por eles são executadas diretamente nas tabelas do banco de dados.

## **Python**

Esta pasta contém os scripts criados em python tanto para o OpMon, quanto para o Zabbix. Alguns são de monitoramento e outros são para alguma atividade relacionada ao gerenciamento dos sistemas.


