#!/bin/bash


cd_to_script_dir() {
    cd "$(dirname "$(readlink -f "$0")")" || {
        echo "Error: failed to cd_to_script_dir"
        exit 1
    }
}
cd_to_script_dir
export CURRENT_DIR="$(dirname "$(dirname "$(readlink -f "$0")")")" && cd "$(dirname "$(readlink -f "$0")")"
export DEPS_LIB_DIR="${CURRENT_DIR}/libs/${TARGET_OS}/${TARGET_ARCH}"
export DEPS_INCLUDE_DIR="${CURRENT_DIR}/include"


declare -A ARCH_MAP=(
    ["arm64"]="aarch64-linux-android"
    ["arm32"]="arm-linux-androideabi"
    ["x86_64"]="x86_64-linux-android"
    ["x86"]="i686-linux-android"
    ["riscv64"]="riscv64-linux-android"
)

declare -A JDK_ARCH_MAP=(
    ["arm64"]="aarch64"
    ["arm32"]="arm"
    ["x86_64"]="x86_64"
    ["x86"]="i386"
    ["riscv64"]="riscv"
)

if [[ -n "${TARGET_ARCH}" ]]; then
    case "${TARGET_OS}" in
        "android")
            if [[ -n "${ARCH_MAP[${TARGET_ARCH}]}" ]]; then
                export TARGET="${ARCH_MAP[${TARGET_ARCH}]}"
                export TARGET_JDK="${JDK_ARCH_MAP[${TARGET_ARCH}]}"
                echo "Configuring for Android: ${TARGET}"
            else
                echo "Error: Unsupported Android architecture: ${TARGET_ARCH}" >&2
                exit 1
            fi
            ;;
            
        "ios")
            case "${TARGET_ARCH}" in
                "arm64")
                    export TARGET="arm64-apple-ios"
                    export TARGET_JDK="aarch64"
                    export thesysroot=$(xcrun --sdk iphoneos --show-sdk-path 2>/dev/null)
                    echo "Configuring for iOS: ${TARGET}"
                    ;;
                "x86_64")
                    export TARGET="x86_64-apple-ios"
                    export TARGET_JDK="x86_64"
                    export thesysroot=$(xcrun --sdk iphonesimulator --show-sdk-path 2>/dev/null)
                    echo "Configuring for iOS: ${TARGET}"
                    ;;
                *)
                    echo "Error: Unsupported iOS architecture: ${TARGET_ARCH}" >&2
                    exit 1
                    ;;
            esac
            ;;
            
        *)
            if [[ -n "${TARGET_OS}" ]]; then
                echo "Error: Unsupported OS: ${TARGET_OS}" >&2
                exit 1
            else
                echo "Warning: TARGET_OS not set, skipping platform configuration" >&2
                export TARGET="aarch64-linux-android"
                export TARGET_JDK="aarch64"
            fi
            ;;
    esac
else
    echo "Warning: TARGET_ARCH not set, skipping architecture configuration" >&2
    export TARGET="aarch64-linux-android"
    export TARGET_JDK="aarch64"
fi

if [[ "${TARGET_OS}" == "android" ]]; then
    if [[ -n "${USE_GCC}" ]] && [[ "${USE_GCC}" == "1" ]]; then
        export NDK_PATH="${CURRENT_DIR}/android-ndk"
    else
        if [[ -z "${ANDROID_NDK_LATEST_HOME}" ]]; then
            if [[ -z "${ANDROID_NDK_HOME}" ]]; then
                export NDK_PATH="${CURRENT_DIR}/android-ndk"
            else
                export NDK_PATH="${ANDROID_NDK_HOME}"
            fi
        else
            export NDK_PATH="${ANDROID_NDK_LATEST_HOME}"
        fi
    fi
    
    if [[ -n "${USE_GCC}" ]] && [[ "${USE_GCC}" == "1" ]]; then
      if [[ "$TARGET_JDK" == "aarch64" ]]; then
        export NDK_TOOLCHAIN=${NDK_PATH}/generated-toolchains/android-arm64-toolchain
      else
        export NDK_TOOLCHAIN=${NDK_PATH}/generated-toolchains/android-${TARGET_JDK}-toolchain
      fi
      export NDK_INCLUDE=${NDK_TOOLCHAIN}/sysroot/usr/include
    else
      export NDK_TOOLCHAIN="${NDK_PATH}/toolchains/llvm/prebuilt/linux-x86_64"
      export NDK_INCLUDE="${NDK_TOOLCHAIN}/sysroot/usr/include"
    fi
fi

# 根据操作系统设置编译器
if [[ "${TARGET_OS}" == "android" ]]; then
    if [[ -z "${USE_GCC}" ]]; then
        if [[ -n "${TARGET}" && -n "${ANDROID_API}" ]]; then
            if [[ "${TARGET}" == *"riscv64"* ]]; then
                if [[ "${ANDROID_API}" -lt 35 ]]; then
                    echo "Warning: RISC-V architecture requires ANDROID_API >= 35 (current: ${ANDROID_API})" >&2
                    export ANDROID_API=35
                fi
            fi
            if [[ "${TARGET_ARCH}" == "arm32" ]]; then
              export thecc="${NDK_TOOLCHAIN}/bin/armv7a-linux-androideabi${ANDROID_API}-clang"
              export thecxx="${NDK_TOOLCHAIN}/bin/armv7a-linux-androideabi${ANDROID_API}-clang++"
            else
              export thecc="${NDK_TOOLCHAIN}/bin/${TARGET}${ANDROID_API}-clang"
              export thecxx="${NDK_TOOLCHAIN}/bin/${TARGET}${ANDROID_API}-clang++"
            fi

            # 验证编译器是否存在
            if [[ ! -f "${thecc}" ]] || [[ ! -f "${thecxx}" ]]; then
                echo "Error: Compiler not found for ${TARGET}${ANDROID_API}" >&2
                echo "  CC: ${thecc}" >&2
                echo "  CXX: ${thecxx}" >&2
                exit 1
            fi
        else
            echo "Error: TARGET and ANDROID_API must be set for Android compilation" >&2
            exit 1
        fi
    else
        export thecc="${TOOLCHAIN}/bin/${TARGET}-gcc"
        export thecxx="${TOOLCHAIN}/bin/${TARGET}-g++"
        
        if [[ ! -f "${thecc}" ]] || [[ ! -f "${thecxx}" ]]; then
            echo "Error: Compiler not found" >&2
            echo "  CC: ${thecc}" >&2
            echo "  CXX: ${thecxx}" >&2
            exit 1
        fi
    fi
elif [[ "${TARGET_OS}" == "ios" ]]; then
    export thecc="./wrapper/ios/ios-${TARGET_ARCH}-clang"
    export thecxx="./wrapper/ios/ios-${TARGET_ARCH}-clang++"
    
    if [[ ! -f "${thecc}" ]] || [[ ! -f "${thecxx}" ]]; then
        echo "Error: iOS wrapped clang scripts not found" >&2
        echo "  CC: ${thecc}" >&2
        echo "  CXX: ${thecxx}" >&2
        exit 1
    fi
    
    export themacsysroot=$(xcrun --sdk macosx --show-sdk-path 2>/dev/null)
    export thehostcxx="./wrapper/macos/macos-host-cc"
    export HOTSPOT_DISABLE_DTRACE_PROBES=1
fi


Set_CFLAGS() {
    if [[ -z "${CFLAGS}" ]]; then
      export CFLAGS="$*"
    else
      export CFLAGS="${CFLAGS} $*"
    fi
}

Set_CPPFLAGS() {
    if [[ -z "${CPPFLAGS}" ]]; then
      export CPPFLAGS="$*"
    else
      export CPPFLAGS="${CPPFLAGS} $*"
    fi
}

Set_C_CPPFLAGS() {
    Set_CFLAGS "$@"
    Set_CPPFLAGS "$@"
}

Set_LDFLAGS() {
    if [[ -z "${LDFLAGS}" ]]; then
      export LDFLAGS="$*"
    else
      export LDFLAGS="${LDFLAGS} $*"
    fi
}


PrintConfigurationInfo() {
  echo "Current configuration:"
  echo "  TARGET_ARCH: ${TARGET_ARCH}"
  echo "  TARGET_OS: ${TARGET_OS}"
  if [[ "${TARGET_OS}" == "android" ]]; then
    echo "  NDK_PATH: ${NDK_PATH}"
    echo "  ANDROID_API: ${ANDROID_API}"
  elif [[ "${TARGET_OS}" == "ios" ]]; then
    echo "  iOS SDK: ${thesysroot}"
    echo "  macOS SDK: ${themacsysroot}"
  fi
  echo "  C Compiler: ${thecc}"
  echo "  C++ Compiler: ${thecxx}"
  echo "  Linker: ${LD}"
  echo "  OBJCOPY: ${OBJCOPY}"
  echo "  RANLIB: ${RANLIB}"
  echo "  Archiver: ${AR}"
  echo "  Assembler: ${AS}"
}

bash ./set_devkit.bash
