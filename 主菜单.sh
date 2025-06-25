#!/bin/bash
# 主入口脚本

# 加载公共库
source <(curl -s https://raw.githubusercontent.com/JiangNan-QwQ/AetherCraft/main/common.sh)

# 检查依赖
check_deps
check_java

# 主菜单
main_menu() {
    while true; do
        choice=$(dialog --menu "Minecraft服务器管理" 15 50 5 \
            "1" "安装服务器" \
            "2" "启动服务器" \
            "3" "配置服务器" \
            "4" "备份/恢复" \
            "5" "插件管理" \
            "6" "退出" 2>&1 >/dev/tty)
            
        case "$choice" in
            1) source <(curl -s https://raw.githubusercontent.com/JiangNan-QwQ/AetherCraft/main/install.sh); install_menu ;;
            2) source <(curl -s https://raw.githubusercontent.com/JiangNan-QwQ/AetherCraft/main/start.sh); start_menu ;;
            3) source <(curl -s https://raw.githubusercontent.com/JiangNan-QwQ/AetherCraft/main/config.sh); config_menu ;;
            4) source <(curl -s https://raw.githubusercontent.com/JiangNan-QwQ/AetherCraft/main/backup.sh); backup_menu ;;
            5) source <(curl -s https://raw.githubusercontent.com/JiangNan-QwQ/AetherCraft/main/plugins.sh); plugins_menu ;;
            6) exit 0 ;;
            *) echo "无效选项";;
        esac
    done
}

# 初始化
clear
echo "$(curl -L https://raw.githubusercontent.com/JiangNan-QwQ/AetherCraft/main/公告.txt)"
sleep 1.5
clear
show_banner
init_directories
check_resources || error_exit "系统资源检查失败" 1
check_deps || error_exit "依赖检查失败" 1
check_java || error_exit "Java安装失败" 1
sleep 3
log "公共库初始化完成" "INFO"
main_menu
