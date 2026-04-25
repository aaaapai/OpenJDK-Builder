#!/bin/bash

if [[ -z "${JDK_DEBUG_LEVEL}" ]]
then
  export JDK_DEBUG_LEVEL=release
fi

export JVM_PLATFORM=${TARGET_OS}

export FREETYPE_DIR=${CURRENT_DIR}/freetype/build
export CUPS_DIR=${CURRENT_DIR}/cups


if [[ "${TARGET_ARCH}" == "arm32" ]]; then
  Set_C_CPPFLAGS -marm -Wno-unknown-attributes -Wno-inline-asm
else
  if [[ "${TARGET_ARCH}" == "x86" ]]; then
     Set_C_CPPFLAGS -mstackrealign
  fi
fi
if [[ "${TARGET_ARCH}" == "riscv64" ]]; then
  Set_C_CPPFLAGS -I${DEPS_INCLUDE_DIR}/riscv
fi

# if [[ "${TARGET_ARCH}" == "arm64" ]]; then
  # Set_C_CPPFLAGS -march=armv8-a+simd
# fi

if [[ "${ANDROID_API}" -ge 32 ]]; then
  Set_C_CPPFLAGS -fno-emulated-tls
  Set_LDFLAGS -Wl,-plugin-opt=-emulated-tls=0
fi # Real LTS support is started at Android 12L, I disabled emulated lts here for better performence.

if [[ "${ANDROID_API}" -lt 24 ]]; then
  Set_C_CPPFLAGS -include ${DEPS_INCLUDE_DIR}/compat_file.h -Dfseeko=compat_fseeko -Dftello=compat_ftello
fi


Set_C_CPPFLAGS -O3
# Set_CPPFLAGS -D__STDC_CONSTANT_MACROS -D__STDC_FORMAT_MACROS -stdlib=libc++
# Set_C_CPPFLAGS -flto
# Set_LDFLAGS -flto -Wl,--lto-O3
#polly
if [[ "${TARGET_ARCH}" != "arm32" ]]; then
Set_C_CPPFLAGS -mllvm -polly -mllvm -polly-vectorizer=stripmine -mllvm -polly-invariant-load-hoisting -mllvm -polly-run-inliner -mllvm -polly-run-dce -mllvm -polly-detect-keep-going -mllvm -polly-ast-use-context -mllvm -polly-parallel
fi

# Set_C_CPPFLAGS -fexperimental-relative-c++-abi-vtables

case "${TARGET_OS}" in
    "ios")
        export CC=./wrapper/ios/ios-arm64-clang
        export CXX=./wrapper/ios/ios-arm64-clang++
        export CXXCPP="$CXX -E"
        export LD=$(xcrun -find -sdk iphoneos ld)
        
        Set_LDFLAGS -L${DEPS_LIB_DIR}
        ;;
    
    "android")
        export AR=${NDK_TOOLCHAIN}/bin/llvm-ar
        export AS=${NDK_TOOLCHAIN}/bin/llvm-as
        
        if [[ -n "${FAKE_GCC}" ]] && [[ "${FAKE_GCC}" == "1" ]]; then
            export CC=./wrapper/gcc/android-wrapped-clang
            export CXX=./wrapper/gcc/android-wrapped-clang++
        else
            export CC=${thecc}
            export CXX=${thecxx}
        fi
        
        if [[ -n "${FAKE_GCC}" && "${FAKE_GCC}" == "1" ]] || [[ -n "${USE_GCC}" && "${USE_GCC}" == "1" ]]; then
            # USE_GCC is unfinished.
            export LD=${NDK_TOOLCHAIN}/bin/ld
        else
            export LD=${NDK_TOOLCHAIN}/bin/ld.lld
        fi
        
        export OBJCOPY=${NDK_TOOLCHAIN}/bin/llvm-objcopy
        export RANLIB=${NDK_TOOLCHAIN}/bin/llvm-ranlib
        export STRIP=${NDK_TOOLCHAIN}/bin/llvm-strip
        export PATH=${NDK_TOOLCHAIN}/bin:${PATH}
        export LD_LIBRARY_PATH=./openjdk/build/${TARGET}/buildjdk/jdk/lib:$LD_LIBRARY_PATH
        export NM=${NDK_TOOLCHAIN}/bin/llvm-nm
        export DLLTOOL=${NDK_TOOLCHAIN}/bin/llvm-dlltool

        Set_CFLAGS -I${FREETYPE_DIR}/include/freetype2 -I${CUPS_DIR} -I${DEPS_INCLUDE_DIR} -Wno-unknown-warning-option
        Set_CPPFLAGS -I${FREETYPE_DIR}/include/freetype2 -I${CUPS_DIR} -I${DEPS_INCLUDE_DIR} -Wno-unknown-warning-option
        Set_LDFLAGS -L${FREETYPE_DIR}/lib -L${DEPS_LIB_DIR} -L${NDK_TOOLCHAIN}/sysroot/usr/lib/${TARGET}/${ANDROID_API}
        ;;
    
    *)
        echo "Unknown TARGET_OS: ${TARGET_OS}" >&2
        exit 1
        ;;
esac

