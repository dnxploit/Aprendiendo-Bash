#!/bin/bash

# Colores
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

function ctrl_c(){
  echo -e "\n\n${redColour}[!] Saliendo...${endColour}\n"
  tput cnorm && exit 1
}

# Ctrl + C
trap ctrl_c INT

# URL principal de donde se obtienen las máquinas
main_url="https://htbmachines.github.io/bundle.js"

# Menu de ayuda para el usuario
function helpPanel() {
  echo -e "\n${yellowColour}[+]${endColour} ${grayColour}Uso: ${endColour}"
  echo -e "\t${turquoiseColour}Busqueda y filtrado de máquinas:${endColour}"
  echo -e "\t\t${purpleColour}m)${endColour} ${grayColour}Buscar por nombre de la máquina${endColour}"
  echo -e "\t\t${purpleColour}i)${endColour} ${grayColour}Buscar por la dirección IP de la máquina${endColour}"
  echo -e "\t\t${purpleColour}d)${endColour} ${grayColour}Buscar por dificultad de la máquina${endColour}"
  echo -e "\t\t${purpleColour}o)${endColour} ${grayColour}Buscar por el sistema operativo de la máquina${endColour}"
  echo -e "\t\t${purpleColour}s)${endColour} ${grayColour}Buscar por skils de la máquina${endColour}"
  echo -e "\t\t${purpleColour}r)${endColour} ${grayColour}Obtener resolución de la máquina${endColour}"
  echo -e "\t${turquoiseColour}Opciones del script:${endColour}"
  echo -e "\t\t${purpleColour}h)${endColour} ${grayColour}Mostrar panel de ayuda${endColour}"
  echo -e "\t\t${purpleColour}u)${endColour} ${grayColour}Descargar u actualizar archivos necesarios${endColour}\n"
}

# Actualizar los archivos
function updateFiles() {

  # Si no existe el archivo se descarga, en el caso contrario comprobamos si hay actualizaciones
  if [ ! -f bundle.js ]; then 
    tput civis

    echo -e "\n${yellowColour}[+]${endColour} ${grayColour}Descargando archivos necesarios...${endColour}"

    curl -s $main_url > bundle.js
    js-beautify bundle.js | sponge bundle.js

    echo -e "\n${yellowColour}[+]${endColour} ${grayColour}Todos los archivos han sido descargados.${endColour}"

    tput cnorm
  else
    tput civis

    echo -e "\n${yellowColour}[+]${endColour} ${grayColour}Comprobando si hay actualizaciones pendientes...${endColour}"

    curl -s $main_url > bundle_temp.js
    js-beautify bundle_temp.js | sponge bundle_temp.js

    md5_temp_value="$(md5sum bundle_temp.js | awk '{print $1}')"
    md5_original_value="$(md5sum bundle.js | awk '{print $1}')"
    
    # Mediante md5 se compara el archivo en la web con el local
    if [ "$md5_temp_value" == "$md5_original_value" ]; then
      echo -e "\n${yellowColour}[+]${endColour} ${grayColour}Actualmente no hay actualizaciones disponibles${endColour}"
      rm bundle_temp.js
    else
      echo -e "\n${yellowColour}[+]${endColour} ${grayColour}Se han encontrado actualizaciones${endColour}"
      sleep 1

      rm bundle.js && mv bundle_temp.js bundle.js

      echo -e "\n${yellowColour}[+]${endColour} ${grayColour}Los archivos han sido actualizados${endColour}"

      tput cnorm
    fi
  fi
}

# Buscador de máquinas por nombre
function searchMachine() {
  machineName="$1"

  machineProperties="$(cat bundle.js | awk "/name: \"$machineName\"/,/resuelta:/" | grep -vE "id:|sku:|resuelta:" | sed "s/^ *//" | tr -d '"' | tr -d ',')"

  if [ "$machineProperties" ]; then
    echo -e "\n${yellowColour}[+]${endColour} ${grayColour}Listando las propiedades de la maquina${endColour} ${blueColour}$machineName${endColour}${grayColour}:${endColour}\n"
    echo -e "$machineProperties"
  else
    echo -e "\n${redColour}[!] Maquina no encontrada${endColour}\n"
  fi
}

# Obtener nombre de la máquina por IP
function searchIP() {
  ipAddress="$1"

  machineName=$(cat bundle.js | grep "ip: \"$ipAddress\"" -B 4 | grep "name: " | awk 'NF{print $NF}' | tr -d '"' | tr -d ',')

  if [ "$machineName" ]; then
    echo -e "\n${yellowColour}[+]${endColour} ${grayColour}La IP${endColour} ${blueColour}$ipAddress${endColour} ${grayColour}corresponde a la maquina${endColour} ${blueColour}$machineName${endColour}\n"
  else
    echo -e "\n${redColour}[!] Maquina no encontrada${endColour}\n"
  fi
}

# Obtener resolución de la máquina
function getResolution() {
  machineName="$1"

  resolutionLink="$(cat bundle.js | awk "/name: \"$machineName\"/,/resuelta:/" | grep -vE "id:|sku:|resuelta:" | sed "s/^ *//" | tr -d '"' | tr -d ',' | grep youtube | awk 'NF{print $NF}')"

  if [ "$resolutionLink" ]; then
    echo -e "\n${yellowColour}[+]${endColour} ${grayColour}Puedes encontrar la resolución de la maquina en el siguiente enlace:${endColour} ${blueColour}$resolutionLink${endColour}\n"
  else
    echo -e "\n${redColour}[!] La máquina proporcionada no cuenta con una resolución o no existe${endColour}\n"
  fi
}

# Listamos todas las máquinas de una misma dificultad
function getMachinesByDifficulty() {
  difficulty="$1"

  machines="$(cat bundle.js | grep "dificultad: \"$difficulty\"" -B 5 -i | grep "name: " | awk 'NF{print $NF}' | tr -d '"' | tr -d ',' | column)"

  if [ "$machines" ]; then
    echo -e "\n${yellowColour}[+]${endColour} ${grayColour}Esta són todas las máquinas de dificultad${endColour} ${redColour}$difficulty${endColour}${grayColour}:${endColour}\n"
    echo -e "$machines\n"
  else
    echo -e "\n${redColour}[!] No se han encontrado máquinas o la dificultad no existe${endColour}"
  fi
}

function getMachinesByOS() {
  os="$1"

  machines="$(cat bundle.js | grep "so: \"$os\"" -B 4 -i | grep "name: " | awk 'NF{print $NF}' | tr -d '"' | tr -d ',' | column)"

  if [ "$machines" ]; then
    echo -e "\n${yellowColour}[+]${endColour} ${grayColour}Esta són todas las máquinas de sistema operativo${endColour} ${redColour}$os${endColour}${grayColour}:${endColour}\n"
    echo -e "$machines\n"
  else
    echo -e "\n${redColour}[!] No se han encontrado máquinas o el sistema operativo no existe${endColour}"
  fi
}

function getMachinesBySkill() {
  skill="$1"

  machines="$(cat bundle.js | grep "skills: " -B 6 | grep "$skill" -i -B 6 | grep "name: " | awk 'NF{print $NF}' | tr -d '"' | tr -d ',' | column)"
  if [ "$machines" ]; then
    echo -e "\n${yellowColour}[+]${endColour} ${grayColour}Esta són todas las máquinas con técnicas${endColour} ${redColour}$skill${endColour}${grayColour}:${endColour}\n"
    echo -e "$machines\n"
  else
    echo -e "\n${redColour}[!] No se han encontrado máquinas${endColour}"
  fi
}

function getMachinesByOSAndDifficulty() {
  os="$1"
  difficulty="$2"

  machines="$(cat bundle.js | grep "so: \"$os\"" -C 4 | grep "dificultad: \"$difficulty\"" -B 5 | grep "name: " | awk 'NF{print $NF}' | tr -d '"' | tr -d ',' | column)"
  if [ "$machines" ]; then
    echo -e "\n${yellowColour}[+]${endColour} ${grayColour}Esta són todas las máquinas${endColour} ${redColour}$os${endColour} ${grayColour}de dificultad ${redColour}$difficulty${endColour}:${endColour}\n"
    echo -e "$machines\n"
  else
    echo -e "\n${redColour}[!] No se han encontrado máquinas${endColour}"
  fi
}

declare -i parameter_counter=0

# Chivatos
declare -i chivato_difficulty=0
declare -i chivato_os=0

while getopts "m:ui:r:d:o:s:h" arg; do
  case $arg in
    m) machineName="$OPTARG"; let parameter_counter+=1;;
    u) let parameter_counter+=2;;
    i) ipAddress="$OPTARG"; let parameter_counter+=3;;
    r) machineName="$OPTARG"; let parameter_counter+=4;;
    d) difficulty="$OPTARG"; chivato_difficulty=1; let parameter_counter+=5;;
    o) os="$OPTARG"; chivato_os=1; let parameter_counter+=6;;
    s) skill="$OPTARG"; let parameter_counter+=7;;
    h) ;;
  esac
done

if [ $parameter_counter -eq 1 ]; then
  searchMachine $machineName
elif [ $parameter_counter -eq 2 ]; then
  updateFiles
elif [ $parameter_counter -eq 3 ]; then
  searchIP $ipAddress
elif [ $parameter_counter -eq 4 ]; then
  getResolution $machineName
elif [ $parameter_counter -eq 5 ]; then
  getMachinesByDifficulty $difficulty
elif [ $parameter_counter -eq 6 ]; then
  getMachinesByOS $os
elif [ $parameter_counter -eq 7 ]; then
  getMachinesBySkill "$skill"
elif [ $chivato_difficulty -eq 1 ] && [ $chivato_os -eq 1 ]; then
  getMachinesByOSAndDifficulty $os $difficulty
else
  helpPanel
fi
