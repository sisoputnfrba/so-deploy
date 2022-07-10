#!/bin/bash

set -e

bold=$(tput bold)
normal=$(tput sgr0)
underline=$(tput smul)
nounderline=$(tput rmul)

if [[ "$*" =~ (-h|-H|--help) ]]; then
  echo "

${bold}NAME${normal}
    ${bold}deploy.sh${normal} - script to deploy sisoputnfrba's TP.

${bold}SYNOPSIS${normal}
    ${bold}deploy.sh${normal} [${bold}--lib${normal}=${underline}library${nounderline}] [${bold}--dependency${normal}=${underline}dependency${nounderline}] [${bold}--project${normal}=${underline}project${nounderline}] ${underline}repository${nounderline}

${bold}DESCRIPTION${normal}
    The ${bold}deploy.sh${normal} utility is to ease the deploy process.

    The options are as follows:

    ${bold}-t | --target${normal}       Changes the directory where the script is executed. By default it will be the current directory.

    ${bold}-s | --structure${normal}    Changes the path where the script should look for makefiles. By default it will be the current directory of each project.

    ${bold}-r | --rule${normal}         Changes the makefile rule for building projects. By default it will be 'all'.

    ${bold}-l | --lib${normal}          Adds an external dependency to build and install.

    ${bold}-d | --dependency${normal}   Adds an internal dependency to build and install from the repository.

    ${bold}-p | --project${normal}      Adds a project to build from the repository.

${bold}COMPATIBILITY${normal}
    The repository must have makefiles to compile each project or dependency.

${bold}EXAMPLE${normal}
      ${bold}deploy.sh${normal} ${bold}-s${normal}=Release ${bold}-l${normal}=sisoputnfrba/so-nivel-gui-library ${bold}-d${normal}=sockets ${bold}-p${normal}=consola ${bold}-p${normal}=kernel ${bold}-p${normal}=memoria ${underline}tp-20XX-XC-example${nounderline}

  " | less
  exit
fi

case $1 in
  -t=*|--target=*)
    echo -e "\n\n${bold}Changing directory:${normal} ${PWD} -> ${bold}${1#*=}${normal}\n\n"
    cd "${1#*=}" || exit
    shift
  ;;
  *)
  ;;
esac

STRUCTURE=""
case $1 in
  -s=*|--structure=*)
    STRUCTURE="${1#*=}"
    shift
  ;;
  *)
  ;;
esac

RULE="all"
case $1 in
  -r=*|--rule=*)
    RULE="${1#*=}"
    shift
  ;;
  *)
  ;;
esac

echo -e "\n\n${bold}Installing commons library...${normal}\n\n"

COMMONS="sisoputnfrba/so-commons-library"

rm -rf "$COMMONS"
git clone "https://github.com/${COMMONS}.git" "$COMMONS"
make -C "$COMMONS" uninstall install

length=$(($#-1))
OPTIONS=("${@:1:length}")
REPONAME="sisoputnfrba/${!#}"

LIBRARIES=()
DEPENDENCIES=()
PROJECTS=()

for i in "${OPTIONS[@]}"
do
    case $i in
        -l=*|--lib=*)
          LIBRARIES+=("${i#*=}")
        ;;
        -d=*|--dependency=*)
          DEPENDENCIES+=("${i#*=}")
        ;;
        -p=*|--project=*)
          PROJECTS+=("${i#*=}")
        ;;
        *)
        ;;
    esac
done

echo -e "\n\n${bold}Cloning external libraries...${normal}"

for i in "${LIBRARIES[@]}"
do
  echo -e "\n\n${bold}Building ${i}${normal}\n\n"
  rm -rf "$i"
  git clone "https://github.com/${i}.git" "$i"
  make -C "$i" install
done

echo -e "\n\n${bold}Cloning project repo...${normal}\n\n"

rm -rf "$REPONAME"
git clone "https://github.com/${REPONAME}.git" "$REPONAME"

echo -e "\n\n${bold}Building dependencies${normal}..."

for i in "${DEPENDENCIES[@]}"
do
  echo -e "\n\n${bold}Building ${i}${normal}\n\n"
  make -C "$REPONAME/$i/$STRUCTURE" install
done

echo -e "\n\n${bold}Building projects...${normal}"

for i in "${PROJECTS[@]}"
do
  echo -e "\n\n${bold}Building ${i}${normal}\n\n"
  make -C "$REPONAME/$i/$STRUCTURE" "$RULE"
done

echo -e "\n\n${bold}Deploy done!${normal}\n\n"
