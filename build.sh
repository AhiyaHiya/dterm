#!/bin/bash
set -e -o pipefail

help() {
  cat <<HELP
Usage: $(basename $0) [--help] [--clean] [--no-code-sign] [--code-sign-identity NAME] [--with-dmg]
HELP
}


main() {
  CLEAN=""
  BUILD=""
  WITH_DMG="no"
  WITH_CODESIGN="yes"
  CODESIGN_IDENTITY=""

  until [ -z "$1" ]; do
    case "$1" in
      -h|--help)
        help;
        exit 0;
        ;;
      --clean)
        CLEAN="yes";
        shift;
        ;;
      --build)
        BUILD="yes";
        shift;
        ;;
      --no-code-sign)
        BUILD="yes";
        WITH_CODESIGN="no";
        shift;
        ;;
      --code-sign-identity)
        BUILD="yes";
        shift;
        if [ -z "$1" ]; then
          error "missing code-sign-identity NAME"
          exit 1
        fi
        CODESIGN_IDENTITY="$1"
        ;;
      --with-dmg)
        BUILD="yes";
        WITH_DMG="yes";
        shift;
        ;;
      *)
        error "unknown option $1";
        exit 1;
        ;;
    esac
  done

  if [[ -z "$CLEAN" ]]; then
    CLEAN="$WITH_DMG"
  fi

  if [[ "$WITH_DMG" == "yes" ]]; then
    ensure_create_dmg
  fi

  if [[ "$CLEAN" == "yes" ]]; then
    xcodebuild \
      -project "./DTerm.xcodeproj" \
      -target "DTerm" \
      -configuration "Release" \
      clean
    EX=$?
    if [[ -z "$BUILD" ]]; then
      exit $EX
    fi
  fi

  xcodebuild \
    -project "./DTerm.xcodeproj" \
    -target "DTerm" \
    -configuration "Release"

  TARGET_APP="./build/Release/DTerm.app"
  TARGET_VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$TARGET_APP/Contents/Info.plist")"

  if [[ ! -d "$TARGET_APP" ]]; then
    error "missing $TARGET_APP"
    exit 1;
  fi

  if [[ "$WITH_CODESIGN" == "yes" ]]; then
    if [ -z "$CODESIGN_IDENTITY" ]; then
      CODESIGN_IDENTITY="$(git config --get user.name)"
    fi
    set -x
    codesign --deep -s "$CODESIGN_IDENTITY" -f "$TARGET_APP" -v
    set +x
  fi

  if [[ "$WITH_DMG" == "yes" ]]; then
    TARGET_DMG="./build/Release/DTerm.dmg"
    TARGET_DMG_RW="./build/Release/rw.DTerm.dmg"
    SOURCE_DIR="./build/Release.dmg-tmp"
    [ -e "$TARGET_DMG" ] && rm -f "$TARGET_DMG"
    [ -e "$TARGET_DMG_RW" ] && rm -f "$TARGET_DMG_RW"
    [ -e "$SOURCE_DIR" ] && rm -rf "$SOURCE_DIR"
    mkdir -p "$SOURCE_DIR"
    cp -r "$TARGET_APP" "$SOURCE_DIR"
    create_dmg \
      --window-size 500 300 \
      --background "./Images/dmg-background@2x.png" \
      --icon-size 96 \
      --volname "DTerm" \
      --app-drop-link 380 116 \
      --icon "DTerm" 110 116 \
      "$TARGET_DMG" \
      "$SOURCE_DIR"
  fi

  echo "---------------------------------------------------"
  echo ">> Build Complete: $(dirname $TARGET_APP)"
  echo ">>   Version:      $TARGET_VERSION"
  echo ">>   APP:          $TARGET_APP"
  if [[ "$WITH_DMG" == "yes" ]]; then
    echo ">>   DMG:          $TARGET_DMG"
  fi
  if [[ "$WITH_CODESIGN" == "yes" ]]; then
    echo ">> Codesigning Details:"
      codesign -dvvv "$TARGET_APP" 2>&1 | awk '{ printf ">>    %s\n", $0}'
  fi
  echo ">> done."
}

create_dmg() {
  ./yoursway-create-dmg/create-dmg "$@"
}

ensure_create_dmg() {
  if [[ ! -e ./yoursway-create-dmg/create-dmg ]]; then
    echo >&2 "Ouch: missing 'yoursway-create-dmg' toolkit."
    CLONE_CMD="git clone https://github.com/muhqu/yoursway-create-dmg.git"
    while true; do
        read -p "Wanna get it via: $CLONE_CMD ? [yes|no] " yn
        case $yn in
            [Yy]* ) $CLONE_CMD; break;;
            [Nn]* ) exit 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
    if [[ ! -e ./yoursway-create-dmg/create-dmg ]]; then
      echo >&2 "Ouch: git clone failed?! 'yoursway-create-dmg' toolkit still missing."
      exit 1;
    fi
  fi
}

error() {
  echo >&2 "Error: " "$@"
}

main "$@"