#!/bin/bash

# GridTimer Flutter 版本设置脚本
# 此脚本自动下载并配置包含 Dart 3.8.0+ 的 Flutter SDK

set -e

# 定义 Flutter 版本（使用包含 Dart 3.8+ 的版本）
FLUTTER_VERSION="3.38.5"
FLUTTER_CHANNEL="stable"

echo "=== Flutter 版本设置 ==="
echo "目标版本: Flutter ${FLUTTER_VERSION}"
echo ""

# 检测操作系统
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    FLUTTER_TAR="flutter_${OS}_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    FLUTTER_TAR="flutter_${OS}_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.zip"
else
    echo "错误: 不支持的操作系统 $OSTYPE"
    exit 1
fi

echo "检测到操作系统: ${OS}"

# 设置下载路径
FLUTTER_HOME="${HOME}/flutter-${FLUTTER_VERSION}"
DOWNLOAD_URL="https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_CHANNEL}/${OS}/${FLUTTER_TAR}"

# 检查是否已经下载
if [ -d "${FLUTTER_HOME}" ]; then
    echo "Flutter ${FLUTTER_VERSION} 已存在于 ${FLUTTER_HOME}"
else
    echo "下载 Flutter ${FLUTTER_VERSION}..."
    echo "下载 URL: ${DOWNLOAD_URL}"
    
    # 下载 Flutter SDK
    if [[ "$OS" == "linux" ]]; then
        wget -q --show-progress "${DOWNLOAD_URL}" -O "/tmp/${FLUTTER_TAR}"
        echo "解压 Flutter SDK..."
        tar -xf "/tmp/${FLUTTER_TAR}" -C "${HOME}"
        mv "${HOME}/flutter" "${FLUTTER_HOME}"
        rm "/tmp/${FLUTTER_TAR}"
    else
        curl -L "${DOWNLOAD_URL}" -o "/tmp/${FLUTTER_TAR}"
        echo "解压 Flutter SDK..."
        unzip -q "/tmp/${FLUTTER_TAR}" -d "${HOME}"
        mv "${HOME}/flutter" "${FLUTTER_HOME}"
        rm "/tmp/${FLUTTER_TAR}"
    fi
    
    echo "Flutter SDK 已下载并解压到 ${FLUTTER_HOME}"
fi

# 导出 Flutter 到 PATH
export PATH="${FLUTTER_HOME}/bin:${PATH}"

# 验证 Flutter 版本
echo ""
echo "验证 Flutter 安装..."
flutter --version

echo ""
echo "验证 Dart 版本..."
dart --version

echo ""
echo "=== Flutter 版本设置完成 ==="
echo ""
echo "提示: 在当前会话中使用此 Flutter 版本，请运行:"
echo "  export PATH=${FLUTTER_HOME}/bin:\$PATH"
echo ""
