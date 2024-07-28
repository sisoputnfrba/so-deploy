#!/bin/bash

if [ "$#" -lt 2 ]; then
  echo "Uso: $0 <CLAVE> <VALOR>"
  exit 1
fi

CLAVE=${1:?}
VALOR=${2:?}

echo -e "\nModificando archivos de configuración...\n"

grep -Rl "^\s*$CLAVE\s*=" \
  | grep -E '\.config|\.cfg' \
  | tee >(xargs -n1 sed -i "s|^\($CLAVE\s*=\).*|\1$VALOR|")

echo -e "\nLos .config han sido modificados correctamente\n"
