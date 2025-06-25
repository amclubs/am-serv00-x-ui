#!/bin/sh

set -e

echo "🛠️ 开始构建 x-ui FreeBSD amd64 版本..."

# 检查 Go 是否已安装
if ! command -v go >/dev/null 2>&1; then
  echo "❌ Go 未安装，请先执行：pkg install go"
  exit 1
fi

# 清理旧目录
rm -rf build
mkdir -p build/x-ui

# 构建主程序
echo "⚙️ 编译 Go 程序..."
GOOS=freebsd GOARCH=amd64 go build -o build/x-ui/xui-release -v main.go

# 复制脚本和服务文件
echo "📦 拷贝脚本和服务文件..."
cp x-ui.service build/x-ui/x-ui.service
cp x-ui.sh build/x-ui/x-ui.sh

# 下载 Xray 核心及规则文件
echo "🌐 下载 Xray 核心及规则..."
cd build/x-ui
mkdir bin
cd bin

fetch https://github.com/XTLS/Xray-core/releases/latest/download/Xray-freebsd-64.zip
unzip Xray-freebsd-64.zip
rm -f Xray-freebsd-64.zip geoip.dat geosite.dat

fetch https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
fetch https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat

mv xray xray-freebsd-amd64
cd ../..

# 打包为 tar.gz
echo "📦 创建归档文件..."
tar -zcvf x-ui-freebsd-amd64.tar.gz x-ui

echo "✅ 构建完成：build/x-ui-freebsd-amd64.tar.gz"
