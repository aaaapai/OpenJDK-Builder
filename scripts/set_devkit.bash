#!/bin/bash

export JVM_PLATFORM=${TARGET_OS}
if [[ -z "${JDK_DEBUG_LEVEL}" ]]
then
  export JDK_DEBUG_LEVEL=release
fi

if [[ "${USE_LTO}" == "1" ]]; then
  Set_CFLAGS -flto
  Set_CPPFLAGS -flto
  Set_LDFLAGS -flto
fi


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
            if [[ "${USE_CCACHE}" == "1" ]]; then
                export CC="/tmp/ccache-wrapped-clang"
                export CXX="/tmp/ccache-wrapped-clang++"
            else
                export CC="./wrapper/gcc/android-wrapped-clang"
                export CXX="./wrapper/gcc/android-wrapped-clang++"
            fi
        else
            if [[ "${USE_CCACHE}" == "1" ]]; then
                export CC="/tmp/ccache-wrapped-cc"
                export CXX="/tmp/ccache-wrapped-cxx"
            else
                export CC="${thecc}"
                export CXX="${thecxx}"
            fi
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
        export PATH=${NDK_TOOLCHAIN}/bin:$PATH
        export NM=${NDK_TOOLCHAIN}/bin/llvm-nm
        export DLLTOOL=${NDK_TOOLCHAIN}/bin/llvm-dlltool

        Set_CFLAGS -I${NDK_INCLUDE} -I${NDK_INCLUDE}/${TARGET} -I${DEPS_INCLUDE_DIR} -Wno-unknown-warning-option
        Set_CPPFLAGS -I${NDK_INCLUDE} -I${NDK_INCLUDE}/${TARGET} -I${DEPS_INCLUDE_DIR} -Wno-unknown-warning-option
        Set_LDFLAGS -L${DEPS_LIB_DIR} -L${NDK_TOOLCHAIN}/sysroot/usr/lib/${TARGET}/${ANDROID_API}
        ;;
    
    *)
        echo "Unknown TARGET_OS: ${TARGET_OS}" >&2
        exit 1
        ;;
esac

export FREETYPE_DIR=${CURRENT_DIR}/freetype/build
export CUPS_DIR=${CURRENT_DIR}/cups
