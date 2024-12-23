#!/bin/bash

set -e

bold=$(tput bold)
normal=$(tput sgr0)
underline=$(tput smul)
nounderline=$(tput rmul)

fail() {
  echo -e "\n\nTry ${bold}'./deploy.sh --help'${normal} or ${bold}'./deploy.sh -h'${normal} for more information" >&2
  exit 255
}

if [[ "$*" =~ (^|\ )(-h|-H|--help)($|\ ) ]]; then
  echo "

${bold}NAME${normal}
    ${bold}deploy.sh${normal} - script to deploy sisoputnfrba's TP.

${bold}SYNOPSIS${normal}
    ${bold}deploy.sh${normal} [ ${bold}-t${normal}=${underline}target${nounderline} ] [ ${bold}-s${normal}=${underline}structure${nounderline} ] [ ${bold}-r${normal}=${underline}rule${nounderline} ] [ option=${underline}value${nounderline}... ] ${underline}repository${nounderline}

${bold}DESCRIPTION${normal}
    The ${bold}deploy.sh${normal} utility is to ease the deploy process.

${bold}POSITIONAL ARGUMENTS${normal}
    ${bold}-t | --target${normal}       Changes the directory where the script is executed. By default it will be the current directory.

    ${bold}-s | --structure${normal}    Changes the path where the script should look for makefiles. By default it will be the current directory of each project.

    ${bold}-r | --rule${normal}         Changes the makefile rule for building projects. By default it will be 'all'.

${bold}OPTIONS${normal}
    ${bold}-l | --lib${normal}          Adds an external dependency to build and install.

    ${bold}-d | --dependency${normal}   Adds an internal dependency to build and install from the repository.

    ${bold}-p | --project${normal}      Adds a project to build from the repository.

    ${bold}-c | --config${normal}       Replaces a variable in all configuration files containing it. The format is 'key=value'.

${bold}COMPATIBILITY${normal}
    The repository must be in ${bold}sisoputnfrba${normal} organization and have makefiles to compile each project or dependency.

${bold}EXAMPLE${normal}
      ${bold}./deploy.sh${normal} ${bold}-l${normal}=mumuki/cspec ${bold}-d${normal}=sockets ${bold}-p${normal}=server ${bold}-p${normal}=client -c=IP_SERVER=192.168.0.32 ${underline}tp-2022-1c-example${nounderline}

  "
  exit 1
fi

TARGET=""
case $1 in
  -t=*|--target=*)
    case ${1#*=} in
      /*) TARGET="${1#*=}" ;;
      *) TARGET="$PWD/${1#*=}" ;;
    esac
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

if [[ $# -lt 1 ]]; then
  echo -e "\n\n${bold}No repository specified!${normal}" >&2
  fail
fi

LIBRARIES=()
DEPENDENCIES=()
PROJECTS=()
CONFIGURATIONS=()

OPTIONS=("${@:1:$#-1}")
for i in "${OPTIONS[@]}"
do
    case $i in
        -l=*|--lib=*)
          LIBRARIES+=("${i#*=}")
          shift
        ;;
        -d=*|--dependency=*)
          DEPENDENCIES+=("${i#*=}")
          shift
        ;;
        -p=*|--project=*)
          PROJECTS+=("${i#*=}")
          shift
        ;;
        -c=*|--config=*)
          CONFIGURATIONS+=("${i#*=}")
          shift
        ;;
        *)
          echo -e "\n\n${bold}Invalid option:${normal} ${i}" >&2
          fail
        ;;
    esac
done

REPONAME="$1"
if [[ $REPONAME != "tp"* ]]; then
  echo -e "\n\n${bold}Invalid repository${normal}: $REPONAME" >&2
  fail
fi

if [[ $TARGET ]]; then
  echo -e "\n\n${bold}Changing directory:${normal} ${PWD} -> ${bold}$TARGET${normal}"
  cd "$TARGET" || fail
fi

echo -e "\n\n${bold}Installing commons library...${normal}\n\n"

# clone only if repo not exist locally
if [ ! -d "so-commons-library" ]; then
  git clone --recurse-submodules --shallow-submodules --depth 1 --branch master "https://github.com/sisoputnfrba/so-commons-library.git"
fi
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

if [ ! -d "${REPONAME}" ]; then
    git clone "https://github.com/sisoputnfrba/${REPONAME}.git"
fi

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

echo -e "\n\n${bold}Replacing variables...${normal}"

for i in "${CONFIGURATIONS[@]}"
do
  KEY="${i%=*}"
  VALUE="${i#*=}"
  echo -e "\n\nReplacing all ${bold}${KEY:?}${normal} values with ${bold}${VALUE:?}${normal}...\n\n"
  grep -Rl "^\s*$KEY\s*=" "$REPONAME" | grep -E '\.config|\.cfg' | tee >(xargs -n1 sed -i "s|^\($KEY\s*=\).*|\1$VALUE|")
done

echo -e "\n\n${bold}Deploy done!${normal}\n\n"
