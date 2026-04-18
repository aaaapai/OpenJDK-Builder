#!/bin/bash

echo "Removing debuginfo..."

cd ${CURRENT_DIR}/openjdk/build/${TARGET}


if [[ "${TARGET_ARCH}" == "arm64" ]] || [[ "${TARGET_ARCH}" == "x86_64" ]] || [[ "${TARGET_ARCH}" == "riscv64" ]]; then
   echo "Building for ${TARGET_ARCH}, introducing JVMCI module"
   export EXTRA_JLINK_JMODS=jdk.internal.vm.ci
fi

cp -v buildjdk/jdk/lib/jspawnhelper buildjdk/jdk/lib/libjspawnhelper.so || true

# Produce the jre equivalent from the jdk (https://blog.adoptium.net/2021/10/jlink-to-produce-own-runtime/)
export JLINK_STRIP_ARG="--strip-native-debug-symbols=exclude-debuginfo-files:objcopy=${OBJCOPY}"

./buildjdk/jdk/bin/jlink \
--module-path=images/jdk/jmods \
--add-modules java.base,java.compiler,java.datatransfer,java.desktop,java.instrument,java.logging,java.management,java.management.rmi,java.naming,java.net.http,java.prefs,java.rmi,java.scripting,java.se,java.security.jgss,java.security.sasl,java.sql,java.sql.rowset,java.transaction.xa,java.xml,java.xml.crypto,jdk.accessibility,jdk.charsets,jdk.crypto.cryptoki,jdk.crypto.ec,jdk.dynalink,jdk.editpad,jdk.httpserver,jdk.jdwp.agent,jdk.jfr,jdk.localedata,jdk.management,jdk.management.agent,jdk.management.jfr,jdk.naming.dns,jdk.naming.rmi,jdk.net,jdk.nio.mapmode,jdk.sctp,jdk.security.auth,jdk.security.jgss,jdk.unsupported,jdk.xml.dom,jdk.zipfs,jdk.hotspot.agent,jdk.incubator.vector,jdk.attach,jdk.jartool,jdk.jcmd,jdk.jconsole,jdk.jdeps,jdk.jdi,jdk.jpackage,jdk.jlink,jdk.jshell,jdk.jstatd,jdk.javadoc,jdk.unsupported.desktop,java.smartcardio,jdk.internal.jvmstat,jdk.internal.ed,jdk.internal.le,jdk.internal.md,jdk.internal.opt,${EXTRA_JLINK_JMODS} \
--output images/jre \
${JLINK_STRIP_ARG} \
--no-man-pages \
--no-header-files \
--endian=little \
--release-info=jdk/release


for dir in jdk jre; do
    cp -v ${FREETYPE_DIR}/lib/libfreetype.so images/${dir}/lib/ || true # Perhaps it's needed for caciocavallo.
    cp -v ${DEPS_LIB_DIR}/libawt_xawt.so images/${dir}/lib/ || true # It's needed for caciocavallo.
    cp -v ${DEPS_LIB_DIR}/libnuma.so images/${dir}/lib/ || true # Android doesn't have NUMA, it's a shim, perhaps there is no need to add it?
    cp -rv ${CURRENT_DIR}/fonts_config/* images/${dir}/lib/ || true # It's needed for caciocavallo.
    cp -v images/jdk/lib/jspawnhelper images/${dir}/lib/libjspawnhelper.so || true
done


find images/jdk/bin images/jre/bin -type f -exec ${NDK_TOOLCHAIN}/bin/llvm-strip {} \;
find images/jdk/lib images/jre/lib -type f -name "*.so" -exec ${NDK_TOOLCHAIN}/bin/llvm-strip {} \;


unset CC CXX LD CFLAGS CPPFLAGS
git clone --depth 1 https://github.com/termux/termux-elf-cleaner || true
cd termux-elf-cleaner
mkdir build
cd build
cmake ..
make -j6
cd ../..

findexec() { find $1 -type f -name "*" -not -name "*.o" -exec bash -c '
    case "$(head -n 1 "$1")" in
      ?ELF*) exit 0;;
      MZ*) exit 0;;
      #!*/ocamlrun*)exit0;;
    esac
exit 1
' bash {} \; -print
}

findexec images/jre | xargs ./termux-elf-cleaner/build/termux-elf-cleaner --api-level ${ANDROID_API}
findexec images/jdk | xargs ./termux-elf-cleaner/build/termux-elf-cleaner --api-level ${ANDROID_API}
