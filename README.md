注意: 此存储库未完成，目前可能有很多bug

# OpenJDK-Builder

OpenJDK-Builder用于构建OpenJDK

## 特性

- 当前支持构建目标为 Android 和 iOS 平台的OpenJDK

## 目标系统

| 系统   | 支持情况   |
|--------|------------|
| Android| ✅ 支持     |
| iOS    | 🚧 开发中   |
| 其它   | 🚧 计划中   |

## 支持架构

| 系统    | 架构                          |
|---------|-------------------------------|
| Android | arm64, arm32, x86_64, x86, riscv64 |
| iOS     | arm64, x86_64                 |

## 目标JDK

| 版本   | 支持情况   |
|--------|------------|
| 28     | ✅ 支持     |
| 27     | ⚠️ 损坏     |
| 26     | 🚧 计划中   |
| 其它   | 🚧 计划中   |

| 供应商   | 支持情况   |
|--------|------------|
| OpenJDK | ✅ 支持   |
| 其它   | 🚧 计划中   |

## 快速开始

1. 设置环境变量（以 Android arm64 构建 JDK 28 为例）：

```bash
export TARGET_OS=android
export TARGET_ARCH=arm64
export TARGET_JAVA_VERSION=28
```

2. 安装依赖并构建：

```bash
bash ./scripts/install_deps.bash
bash ./scripts/build_jdk.bash
```

构建产物位于 `openjdk/build/**/images/` 目录。

## 目录结构

| 目录            | 说明                     |
|-----------------|--------------------------|
| scripts/        | 构建、补丁、打包等脚本   |
| patches/        | 各版本 JDK 的补丁        |
| libs/           | 各平台预编译的第三方库   |
| wrapper/        | 编译器等工具包装脚本     |
| devkit_info/    | 各架构的 devkit 信息     |
| fonts_config/   | 字体与 fontconfig 配置   |
| include/        | 构建依赖头文件           |

## 鸣谢

本项目参考或借鉴了以下优秀开源项目：

- [openjdk/mobile](https://github.com/openjdk/mobile)
- [termux/termux-packages](https://github.com/termux/termux-packages)
- [AngelAuraMC/angelauramc-openjdk-build](https://github.com/AngelAuraMC/angelauramc-openjdk-build)
- [aaaapai/android-openjdk-build](https://github.com/aaaapai/android-openjdk-build) (old repositories)

## FAQ

TODO

## 联系与交流

如有问题或建议，欢迎提交 Issue 或发起 Pull Request！
