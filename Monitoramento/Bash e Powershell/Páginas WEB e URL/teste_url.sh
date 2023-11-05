#/bin/bash

wget -q -nv --delete-after "$1"
a=$?

if [ $a -eq 0 ];then
        echo "Site no ar!  | site=1;;;;; ";
        exit 0;
fi;

if [ $a -eq 1 ];then
        echo "Site fora do ar! Verificar! | site=0;;;;; ";
        exit 2;
fi;

echo "Erro desconhecido!";
exit 3;