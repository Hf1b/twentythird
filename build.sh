#!/bin/bash

if [[ -f config.sh ]]; then
  . config.sh
fi

# Zipping
USEZIP=1

VARS=(NAME ARCH ANDROID_VERSION CONFIG)
OPT=(TASK USER HOST IMAGE CONFILE)
ALL=( "${VARS[@]}" "${OPT[@]}" )

for i in ${VARS[@]}; do
  if [[ "$i" == NAME ]] && [[ -z "${!i}" ]]; then
    echo "Warning: $i isn't specified, no ability to make installer"
  elif [[ -z "${!i}" ]]; then
    echo "You should specify $i in your environment or config.sh"
    echo "NOTE: You man check config.sh.example for some details"
    exit 1
  fi
done

# Aliasing
export ANDROID_MAJOR_VERSION=$ANDROID_VERSION
export KBUILD_BUILD_USER=$USER
export KBUILD_BUILD_HOST=$HOST

: ${TASK:=Image}
: ${IMAGE:=arch/$ARCH/boot/$TASK}
: ${CONFILE:=arch/$ARCH/configs/"$CONFIG"_defconfig}

# Main stuff
if [[ -z `which zip` ]]; then
  echo "Warning: zip utility isn't found, no ability to make installer"
  USEZIP=
fi

if [[ ! -f "$CONFILE" ]]; then
  echo "Error: $CONFILE is blank, specify currect defconfig in CONFILE or create it yourself"
  exit 1
fi

USAGE() {
  echo "Usage: $0 instruction"
  echo "Instructions"
  echo "Trivial:"
  echo "  all    - Build with prompts"
  echo "  config - Configure only"
  echo "  build  - Build only"
  echo "  zip    - Zip only"
  echo "Manual:"
  echo "  diff   - Compare .config and default config"
  echo "  edit   - Edit current config"
  echo "  save   - Save .config as default config"
  echo "Miscellaneous:"
  echo "  auto   - Build without prompts"
  echo "  clean  - Clean repository"
  echo "  help   - Show usage"
  echo "  mhelp  - Run 'make help'"
  echo "Environment:"
  echo "  CC - $CROSS_COMPILE"
  for i in ${ALL[@]}; do
    echo "  $i - ${!i}"
  done
  echo "Status:"
  if isconfig; then
    echo "  Config file exists"
  else
    echo "  Config file is missing"
  fi
  if isbuilt; then
    echo "  Kernel is built"
  else
    echo "  Kernel isn't built"
  fi
}

HELP() {
  make help
}

CONFIG() {
  make "$CONFIG"_defconfig
  if [[ $? == 0 ]]; then
    echo "Config is done"
  else
    echo "Config is failed"
    exit 1
  fi
}

BUILD() {
  CHECKCON

  echo "Kernel $TYPE is being built"
  make -j$((`nproc --all`+2)) $TASK
  if [[ $? == 0 ]]; then
    ECHO "Is built"
  else
    ECHO "Building is failed"
    exit 1
  fi
}

ZIP() {
  if [[ -z "$USEZIP" ]]; then
    echo "You can't make installer without \`zip\` utility"
    return 1
  fi

  CHECKBUILT

  ECHO "Is being zipped"

  cp $IMAGE releases/AnyKernel3/$TASK
  cd releases/AnyKernel3
  if [[ ! -d ../zip ]]; then mkdir ../zip; fi
  zip -r9 ../zip/$NAME.$TYPE-$VERSION.zip *
  rm $TASK
  cd ../..

  ECHO "Installer is done"
}

DIFF() {
  CHECKCON

  diff $CONFILE .config --color=always | less -R
}

EDIT() {
  CHECKCON

  make nconfig
}

SAVE() {
  CHECKCON

  cp .config $CONFILE
}

CLEAN() {
  make clean
  make mrproper
  # git clean -Xdf
}

ECHO() {
  if [[ ! -z "$TYPE" ]]; then
    echo "Kernel $TYPE: $@"
  else
    echo "Kernel: $@"
  fi
}

check() {
  if [[ "${!1}" == y ]] || [[ "${!1}" == n ]]; then
    return 0
  else
    return 1
  fi
}

isconfig() {
  if test -f .config; then
    return 0
  else
    return 1
  fi
}

isbuilt() {
  if test -f $IMAGE; then
    return 0
  else
    return 1
  fi
}

CHECKCON() {
  if ! isconfig; then
    echo "Do config first"
    exit 1
  fi
}

CHECKBUILT() {
  if ! isbuilt; then
    echo "Do image first"
    exit 1
  fi
}

AUTO() {
  : ${BUILD_GSI:=y}
  : ${BUILD_ONEUI:=y}
  : ${FORCE_RECONFIG:=y}
  : ${FORCE_REBUILD:=y}
  : ${FORCE_INSTALLER:=y}
}

ENABLE() {
  sed -i "s/# $1 is not set/$1=y/" .config
}

DISABLE() {
  sed -i "s/$1=y/# $1 is not set/" .config
}


MAIN() {
  BUILD
  ZIP
  CLEAN
}

if [[ -z "$CROSS_COMPILE" ]] && find -L toolchain -name 'gcc-linaro-*-linux-manifest.txt' 2>/dev/null | grep . &>/dev/null; then
  export CROSS_COMPILE=`pwd`/toolchain/bin/aarch64-linux-gnu-
fi

case "$1" in
      "all" )      ;;
   "config" ) CONFIG; exit 0;;
    "build" ) BUILD ; exit 0;;
      "zip" ) ZIP   ; exit 0;;
     "diff" ) DIFF  ; exit 0;;
     "edit" ) EDIT  ; exit 0;;
     "save" ) SAVE  ; exit 0;;
     "auto" ) AUTO ;;
    "clean" ) CLEAN ; exit 0;;
    "mhelp" ) HELP  ; exit 0;;
  "help"|"" ) USAGE ; exit 0;;
  * )
    echo "$0: Unknown instruction: $1"
    USAGE
    exit 0
    ;;
esac

if [[ -z "$BUILD_GSI" ]] && [[ -z "$CI" ]]; then
  printf "Do you want to build kernel for GSI (y/n)? "
  read BUILD_GSI
fi

if [[ "$BUILD_GSI" == y ]]; then
  TYPE=GSI

  CONFIG
  ENABLE CONFIG_USB_ANDROID_GOOGLE_MTP

  MAIN
fi

if [[ -z "$BUILD_ONEUI" ]] && [[ -z "$CI" ]]; then
  printf "Do you want to build kernel for OneUI (y/n)? "
  read BUILD_ONEUI
fi

if [[ "$BUILD_ONEUI" == y ]]; then
  TYPE=OneUI

  CONFIG
  DISABLE CONFIG_USB_ANDROID_GOOGLE_MTP

  MAIN
fi