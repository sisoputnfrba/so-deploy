#!/bin/bash

set -e

bold=$(tput bold)
normal=$(tput sgr0)
underline=$(tput smul)
nounderline=$(tput rmul)

fail() {
  echo -e "\n\nTry ${bold}'./deploy.sh --help'${normal} or ${bold}'./deploy.sh -h'${normal} for more information" >&2
  exit 1
}

if [[ "$*" =~ (^|\ )(-h|-H|--help)($|\ ) ]]; then
  echo "

${bold}NAME${normal}
    ${bold}deploy.sh${normal} - script to deploy sisoputnfrba's TP.

${bold}SYNOPSIS${normal}
    ${bold}deploy.sh${normal} [ ${bold}-t${normal}=${underline}target${nounderline} ] [ ${bold}-s${normal}=${underline}structure${nounderline} ] [ ${bold}-r${normal}=${underline}rule${nounderline} ] [ option=${underline}value${nounderline}... ] ${underline}repository${nounderline}

${bold}DESCRIPTION${normal}
    The ${bold}deploy.sh${normal} utility is to ease the deploy process.

${bold}OPTIONS${normal}
    ${bold}-t | --target${normal}       Changes the directory where the script is executed. By default it will be the current directory.
    ${bold}-s | --structure${normal}    Changes the path where the script should look for makefiles. By default it will be the current directory of each project.
    ${bold}-r | --rule${normal}         Changes the makefile rule for building projects. By default it will be 'all'.
    ${bold}-l | --lib${normal}          Adds an external dependency to build and install.
    ${bold}-d | --dependency${normal}   Adds an internal dependency to build and install from the repository.
    ${bold}-p | --project${normal}      Adds a project to build from the repository.
    ${bold}-ip-memoria${normal}         Sets the IP address for the Memoria module.
    ${bold}-ip-kernel${normal}          Sets the IP address for the Kernel module.
    ${bold}-ip-cpu${normal}             Sets the IP address for the CPU module.

${bold}COMPATIBILITY${normal}
    The repository must be in ${bold}sisoputnfrba${normal} organization and have makefiles to compile each project or dependency.

${bold}EXAMPLE${normal}
    ${bold}./deploy.sh${normal} ${bold}-l${normal}=mumuki/cspec ${bold}-d${normal}=sockets ${bold}-p${normal}=kernel ${bold}-p${normal}=memoria ${underline}tp-2022-1c-example${nounderline}

  " | less -r
  exit 0
fi

TARGET=""
STRUCTURE=""
RULE="all"
IP_MEMORIA=""
IP_KERNEL=""
IP_CPU=""

LIBRARIES=()
DEPENDENCIES=()
PROJECTS=()

# Process options
while [[ "$1" =~ ^- ]]; do
  case "$1" in
    -t=*|--target=*)
      case ${1#*=} in
        /*) TARGET="${1#*=}" ;;
        *) TARGET="$PWD/${1#*=}" ;;
      esac
      shift
    ;;
    -s=*|--structure=*)
      STRUCTURE="${1#*=}"
      shift
    ;;
    -r=*|--rule=*)
      RULE="${1#*=}"
      shift
    ;;
    -l=*|--lib=*)
      LIBRARIES+=("${1#*=}")
      shift
    ;;
    -d=*|--dependency=*)
      DEPENDENCIES+=("${1#*=}")
      shift
    ;;
    -p=*|--project=*)
      PROJECTS+=("${1#*=}")
      shift
    ;;
    -ip-memoria=*)
      IP_MEMORIA="${1#*=}"
      shift
    ;;
    -ip-kernel=*)
      IP_KERNEL="${1#*=}"
      shift
    ;;
    -ip-cpu=*)
      IP_CPU="${1#*=}"
      shift
    ;;
    *)
      echo -e "\n\n${bold}Invalid option:${normal} ${1}" >&2
      fail
    ;;
  esac
done

if [[ $# -lt 1 ]]; then
  echo -e "\n\n${bold}No repository specified!${normal}" >&2
  fail
fi

REPONAME="$1"
if [[ $REPONAME != "tp"* ]]; then
  echo -e "\n\n${bold}Invalid repository${normal}: $REPONAME" >&2
  fail
fi

if [[ $TARGET ]]; then
  echo -e "\n\n${bold}Changing directory:${normal} ${PWD} -> ${bold}$TARGET${normal}"
  cd "$TARGET" || exit 1
fi

echo -e "\n\n${bold}Installing commons library...${normal}\n\n"

rm -rf "so-commons-library"
git clone "https://github.com/sisoputnfrba/so-commons-library.git"
make -C "so-commons-library" uninstall install

echo -e "\n\n${bold}Cloning external libraries...${normal}"

for i in "${LIBRARIES[@]}"
do
  echo -e "\n\n${bold}Building ${i}${normal}\n\n"
  rm -rf "${i#*\/}"
  git clone "https://github.com/${i}.git"
  make -C "${i#*\/}"
  sudo make -C "${i#*\/}" install
done

echo -e "\n\n${bold}Cloning project repo...${normal}\n\n"

rm -rf "$REPONAME"
git clone "https://github.com/sisoputnfrba/${REPONAME}.git"

echo -e "\n\n${bold}Building dependencies${normal}..."

for i in "${DEPENDENCIES[@]}"
do
  echo -e "\n\n${bold}Building ${i}${normal}\n\n"
  make -C "$REPONAME/$i/$STRUCTURE" "$RULE"
  sudo make -C "$REPONAME/$i/$STRUCTURE" install
done

echo -e "\n\n${bold}Building projects...${normal}"

for i in "${PROJECTS[@]}"
do
  echo -e "\n\n${bold}Building ${i}${normal}\n\n"
  make -C "$REPONAME/$i/$STRUCTURE" "$RULE"
done

# Reemplazo de IPs en archivos .config
if [[ $IP_MEMORIA || $IP_KERNEL || $IP_CPU ]]; then
  echo -e "\n\n${bold}Updating IP configurations in .config files...${normal}\n\n"
  for CONFIG_FILE in $(find "$REPONAME" -name "*.config"); do
    [[ $IP_MEMORIA ]] && sed -i "s/^IP_MEMORIA=.*/IP_MEMORIA=$IP_MEMORIA/" "$CONFIG_FILE"
    [[ $IP_KERNEL ]] && sed -i "s/^IP_KERNEL=.*/IP_KERNEL=$IP_KERNEL/" "$CONFIG_FILE"
    [[ $IP_CPU ]] && sed -i "s/^IP_CPU=.*/IP_CPU=$IP_CPU/" "$CONFIG_FILE"
  done
fi

echo -e "\n\n${bold}Deploy done!${normal}\n\n"
