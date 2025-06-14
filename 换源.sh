#!/bin/bash

# Termux 清华大学镜像源设置脚本 (HTTPS)

# 颜色定义
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
RESET='\033[0m'

# 检查是否为Termux环境
if [ ! -d "$PREFIX" ]; then
    echo -e "${RED}错误：此脚本只能在Termux环境中运行！${RESET}"
    exit 1
fi

# 检测网络连接
echo -e "${YELLOW}[1/3] 正在检测网络连接...${RESET}"
if ! ping -c 1 mirrors.tuna.tsinghua.edu.cn &> /dev/null; then
    echo -e "${RED}错误：无法连接到清华大学镜像站，请检查网络连接！${RESET}"
    exit 1
fi

echo "正在备份原始sources.list文件..."
cp -f $PREFIX/etc/apt/sources.list $PREFIX/etc/apt/sources.list.bak

echo "正在写入清华大学HTTPS源..."
sed -i 's@^\(deb.*stable main\)$@#\1\ndeb https://mirrors.tuna.tsinghua.edu.cn/termux/apt/termux-main stable main@' $PREFIX/etc/apt/sources.list
echo "更新软件包列表..."
sleep 1
apt update -y && apt upgrade -y

echo "清华大学HTTPS源已成功配置！"
echo "原始源文件已备份为: $PREFIX/etc/apt/sources.list.bak"
