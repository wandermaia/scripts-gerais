# Scripts-Gerais - Kubernetes

Esta pasta contém os scripts utilizados para coletar informações do kubernetes.

Todos os scripts foram escritos em bash e utilizam o comando `kubectl` para interagir com o kubernetes.

A pasta `create-hpa` contém, além do script para criar os HPAs (Horizontal Pod Autoscaling) dos deployments de um namespace, três arquivos adicionais: `hpa-modelo.yaml`, `hpa-modelo-memoria-percentual.yaml` e `hpa-modelo-memoria-valor.yaml`. 

Abaixo seguem as descrições dos arquivos.

- ***hpa-modelo.yaml:*** Arquivo de base utilizado pelo script para gerar os yamls dos hpas.
- ***hpa-modelo-memoria-percentual.yaml:*** Arquivo de exemplo do HPA quando for necessário utilizar percentual de utilização de memória. 
- ***hpa-modelo.yaml:*** Arquivo de exemplo do HPA quando for necessário utilizar um valor fixo de utilização de memória. 



> **OBSERVAÇÕES:**
> 
> Informações complementares foram adicionadas dentro de cada script.

