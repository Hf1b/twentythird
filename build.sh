#!/bin/bash

# User stuff
#export CROSS_COMPILE=

VERSION=1.0
NAME=twentythird-v$VERSION.zip
TASK=Image

# Kbuild
export KBUILD_BUILD_USER=Hfib
export KBUILD_BUILD_HOST=4pda

# Make
export ARCH=arm64
export ANDROID_MAJOR_VERSION=q
CONFIG=exynos7885-a30s

# Zipping
USEZIP=1
IMAGE=arch/arm/boot/$TASK

# Main stuff
if [[ -z `which zip` ]]; then
  echo "Warning: zip utility isn't found, no ability to make installer"
  USEZIP=
fi

USAGE() {
  echo "Usage: $0 instruction"
  echo "Instructions:"
  echo "  auto   - Build without prompts"
  echo "  all    - Build with prompts"
  echo "  config - Configure only"
  echo "  build  - Build only"
  echo "  zip    - Zip only"
  echo "  clean  - Clean repository"
  echo "  help   - Show usage"
  echo "  mhelp  - Run 'make help'"
  echo "Environment:"
  echo "  ARCH: $ARCH"
  echo "  TASK: $TASK"
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
  exit 0
}

HELP() {
  make help
  exit 0
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
  if ! isconfig; then
    echo "Do config first"
    exit 1
  fi
  make $TASK
  if [[ $? == 0 ]]; then
    echo "Kernel is built"
  else
    echo "Building is failed"
    exit 1
  fi
}

ZIP() {
  if [[ -z "$USEZIP" ]]; then
    echo "You can't make installer without \`zip\` utility"
    exit 1
  fi

  if ! isbuilt; then
    echo "Do image first"
    exit 1
  fi
  rm -f $NAME

  cp $IMAGE AnyKernel3
  cd AnyKernel3
  zip -r ../releases/$NAME *
  cd ..

  echo "Installer is done"
}

CLEAN() {
  make clean
  make mrproper
  # git clean -Xdf
}

check() {
  if [[ "${!1}" == y ]] || [[ "${!1}" == n ]]; then
    return 0
  else
    return 1
  fi
}

isconfig()
{
  if test -f .config; then
    return 0
  else
    return 1
  fi
}

isbuilt()
{
  if test -f $IMAGE; then
    return 0
  else
    return 1
  fi
}

AUTO() {
  : ${FORCE_RECONFIG:=y}
  : ${FORCE_REBUILD:=y}
}

mkdir releases -p

case "$1" in
      "all" )      ;;
     "auto" )  AUTO;;
   "config" ) CONFIG; exit 0;;
    "build" ) BUILD ; exit 0;;
      "zip" ) ZIP   ; exit 0;;
    "clean" ) CLEAN ; exit 0;;
    "mhelp" ) HELP ;;
  "help"|"" ) USAGE;;
  * )
    echo "$0: Unknown instruction: $1"
    USAGE
    ;;
esac

if isconfig; then
  printf "Do you want to update \'.config\' (y/n)? "
  if check FORCE_RECONFIG; then
    case "$FORCE_RECONFIG" in
      y) echo y; CONFIG;;
      n) echo n;;
    esac
  else
    read RECONFIG
    if [[ "$RECONFIG" == y ]]; then
      CONFIG
    else
      echo "Reconfig is aborted."
    fi
  fi
else
  CONFIG
fi

if isbuilt; then
  printf "Do you want to rebuild kernel (y/n)? "
  if check FORCE_REBUILD; then
      case "$FORCE_REBUILD" in
        y) echo y; BUILD;;
        n) echo n;;
      esac
  else
    read REBUILD
    if [[ "$REBUILD" == y ]]; then
      BUILD
    else
      echo "Rebuild is aborted."
    fi
  fi
else
  BUILD
fi

if [[ "$USEZIP" == 1 ]]; then
  printf "Do you want to make installer (y/n)? "
  if check FORCE_INSTALLER; then
    case "$FORCE_INSTALLER" in
      y) echo y; ZIP;;
      n) echo n;;
    esac
  else
    read MAKEINS
    if [[ "$MAKEINS" == y ]]; then
      ZIP
    else
      echo "Zipping is aborted."
    fi
  fi
fi