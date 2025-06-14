#启动脚本


# 获取脚本的绝对路径（包括脚本名）
SCRIPT_PATH="$(realpath "$0")"


YUANWEI_ZHI="$(dirname "$SCRIPT_PATH")"

UBUNTU_ROOT=/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/ubuntu/root

MARKER_FILE="$HOME/.jack_eason"

#!/bin/bash

# 检测Termux环境
check_termux() {
    if [ -d "/data/data/com.termux/files/usr" ] && [ -n "$TERMUX_VERSION" ]; then
        return 0  # 是Termux环境
    else
        return 1  # 不是Termux环境
    fi
}

# 主逻辑
if check_termux; then
    echo "检测到运行环境: Termux"

if [ ! -f "$MARKER_FILE" ]; then
    echo "首次运行脚本！"
    echo "换源。。。"
    sleep 1
    bash $YUANWEI_ZHI/换源.sh
    touch "$MARKER_FILE"  # 创建标记文件
else
    echo "欢迎，即将进入"
    sleep 1
fi

bash $YUANWEI_ZHI/容器.sh
else
    echo "检测到运行环境: 标准Linux系统"
   bash $YUANWEI_ZHI/3.3.sh
fi
