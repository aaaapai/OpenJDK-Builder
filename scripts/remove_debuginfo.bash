#!/bin/bash

echo "Removing debuginfo..."

cd ${CURRENT_DIR}/openjdk/build/${TARGET}


if [[ "${TARGET_ARCH}" == "arm64" ]] || [[ "${TARGET_ARCH}" == "x86_64" ]] || [[ "${TARGET_ARCH}" == "riscv64" ]]; then
   echo "Building for ${TARGET_ARCH}, introducing JVMCI module"
   export EXTRA_JLINK_JMODS=jdk.internal.vm.ci
fi

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


find images/jdk/bin images/jre/bin -type f -exec ${NDK_TOOLCHAIN}/bin/llvm-strip {} \;
find images/jdk/lib images/jre/lib -type f -name "*.so" -exec ${NDK_TOOLCHAIN}/bin/llvm-strip {} \;
