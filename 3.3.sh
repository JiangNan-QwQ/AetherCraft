#!/bin/bash
# Minecraft Server Management Script by B站搜 爱做视频のJack_Eason
# Version: 3.3
# Date: 2025-06-07
#更新:修复了spigot
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8
export NCURSES_NO_UTF8_ACS=1

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # 无颜色

# 全局变量定义
REQUIRED_DEPS=("curl" "jq" "lolcat")
INSTALL_CMD="apt install -y"
REQUIRED_DEPS=("figlet" "lolcat")
INSTALL_CMD="apt install -y"
BACKTITLE="B站JE"
MENU_HEIGHT=15
MENU_WIDTH=40
MENU_CHOICE_HEIGHT=4
ROOT_DIR="/root"
JAVA_REQUIRED=21
BACKUP_DIR="${ROOT_DIR}/backups"

     TITLE="由JE制作"
        MENU_PROMPT="请选择要执行的操作"
        INSTALL_PROMPT="选择核心类型"
        VERSION_PROMPT="选择版本"
        START_PROMPT="选择要启动的核心"
        UNINSTALL_PROMPT="选择要卸载的核心"
        CONFIG_PROMPT="配置服务器"
        BACKUP_PROMPT="备份服务器"
        RESTORE_PROMPT="恢复服务器"
        STATUS_PROMPT="检查状态"
        CLEAN_LOGS_PROMPT="清理旧日志"
        MONITOR_PROMPT="性能监控"
        EXIT_PROMPT="退出"
        
        HITOKOTO_TITLE="日萃一言"
        HITOKOTO_ERROR="获取一言失败，请检查网络或安装 curl 和 jq"
        HITOKOTO_INSTALLING="回车安装 curl 和 jq..."
        HITOKOTO_NET_ERROR="网络连接失败，请检查网络设置"
        DIALOG_ERROR="未找到 dialog 命令，正在尝试安装..."
        DIALOG_FAIL="安装 dialog 失败，请手动安装："
        LOCALE_WARNING="警告：当前语言环境不支持 UTF-8，中文可能显示乱码！请设置语言环境为 zh_CN.UTF-8。"
        NO_INSTANCE="未找到实例，请先安装！"
        CLEAN_LOGS_SUCCESS="旧日志清理完成！"
        UPDATE_AVAILABLE="有新版本可用："
        MONITOR_RUNNING="服务器运行中，资源使用情况："
        MONITOR_NOT_RUNNING="服务器未运行。"
        STOP_SUCCESS="服务器已停止！"
        

check_language() {
# 目标语言环境
TARGET_LOCALE="zh_CN.UTF-8"

# 检查是否已安装目标语言环境
check_locale() {
    if locale -a | grep -q "$TARGET_LOCALE"; then
        echo "✅ 语言环境 $TARGET_LOCALE 已安装。"
        return 0
    else
        echo "❌ 语言环境 $TARGET_LOCALE 未安装。"
        return 1
    fi
}

# 安装语言包（根据系统类型）
install_locale() {
    echo "尝试安装语言包..."
    if command -v apt &> /dev/null; then
        # Debian/Ubuntu
        apt update && apt install -y language-pack-zh-hans
    elif command -v yum &> /dev/null; then
        # CentOS/RHEL
        yum install -y glibc-common zh-CN
    elif command -v pacman &> /dev/null; then
        # Arch Linux
        pacman -S --noconfirm glibc
    else
        echo "⚠️ 不支持的系统，请手动安装语言包。"
        exit 1
    fi

    # 生成语言环境
    locale-gen "$TARGET_LOCALE"
    update-locale LANG="$TARGET_LOCALE"
    echo "🔄 已生成并启用 $TARGET_LOCALE。"
}

# 临时修复（仅当前会话）
temp_fix() {
    export LC_ALL=C.UTF-8
    echo "⚠️ 临时设置 LC_ALL=C.UTF-8（仅当前会话有效）。"
}

# 主逻辑
if check_locale; then
    echo "无需操作。"
else
    read -p "是否安装 $TARGET_LOCALE？(y/n) " choice
    case "$choice" in
        y|Y ) install_locale ;;
        n|N ) temp_fix ;;
        * ) echo "无效输入，退出。" ;;
    esac
fi

# 验证结果
echo -e "\n当前语言环境设置："
locale
}
download_spigot() {
    local version=$1
    local install_dir=$2

    echo -e "${GREEN}正在获取Spigot ${version}下载链接...${NC}"
    
    # 创建临时目录
    local temp_dir="${ROOT_DIR}/temp"
    mkdir -p "$temp_dir"
    
    # 尝试从cdn.getbukkit.org直接下载
    local direct_url="https://cdn.getbukkit.org/spigot/spigot-${version}.jar"
    echo -e "尝试直接下载: ${direct_url}"
    
    if wget --show-progress -q -O "${temp_dir}/spigot-${version}.jar" "$direct_url"; then
        # 验证文件大小
        local file_size=$(stat -c%s "${temp_dir}/spigot-${version}.jar")
        if [ "$file_size" -gt 1000000 ]; then
            echo -e "${GREEN}直接下载成功！${NC}"
            mv "${temp_dir}/spigot-${version}.jar" "${install_dir}/server.jar"
            rm -rf "$temp_dir"
            
            # 记录版本信息
            cat > "${install_dir}/spigot_info.json" <<EOF
{
    "version": "${version}",
    "source": "cdn.getbukkit.org",
    "download_url": "${direct_url}",
    "install_time": "$(date +%FT%T%z)"
}
EOF
            return 0
        fi
    fi
    
    # 直接下载失败，尝试通过getbukkit.org获取动态链接
    echo -e "${YELLOW}直接下载失败，尝试获取动态链接...${NC}"
    
    local download_page
    if ! download_page=$(curl -s "https://getbukkit.org/download/spigot"); then
        echo -e "${RED}错误：无法访问getbukkit.org${NC}"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # 提取动态下载链接
    local dynamic_url=$(echo "$download_page" | grep -oP "href=\"https://getbukkit.org/get/[^\"]+\"" | grep -oP "https://[^\"]+" | head -1)
    
    if [ -z "$dynamic_url" ]; then
        echo -e "${RED}错误：无法找到动态下载链接${NC}"
        rm -rf "$temp_dir"
        return 1
    fi
    
    echo -e "获取到动态链接: ${dynamic_url}"
    
    # 从动态链接获取实际下载URL
    local redirect_page
    if ! redirect_page=$(curl -s "$dynamic_url"); then
        echo -e "${RED}错误：无法访问动态下载页面${NC}"
        rm -rf "$temp_dir"
        return 1
    fi
    
    local actual_url=$(echo "$redirect_page" | grep -oP "href=\"https://cdn.getbukkit.org/spigot/spigot-${version}.jar\"" | grep -oP "https://[^\"]+")
    
    if [ -z "$actual_url" ]; then
        echo -e "${RED}错误：无法从动态页面解析实际下载链接${NC}"
        rm -rf "$temp_dir"
        return 1
    fi
    
    echo -e "实际下载URL: ${actual_url}"
    
    # 下载文件
    if ! wget --show-progress -q -O "${temp_dir}/spigot-${version}.jar" "$actual_url"; then
        echo -e "${RED}Spigot下载失败！${NC}"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # 验证文件大小
    local file_size=$(stat -c%s "${temp_dir}/spigot-${version}.jar")
    if [ "$file_size" -lt 1000000 ]; then
        echo -e "${RED}错误：下载的文件过小，可能下载失败${NC}"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # 移动文件到目标位置
    mv "${temp_dir}/spigot-${version}.jar" "${install_dir}/server.jar"
    rm -rf "$temp_dir"
    
    # 记录版本信息
    cat > "${install_dir}/spigot_info.json" <<EOF
{
    "version": "${version}",
    "source": "getbukkit.org",
    "download_url": "${actual_url}",
    "install_time": "$(date +%FT%T%z)"
}
EOF

    echo -e "${GREEN}Spigot ${version} 下载完成！${NC}"
    return 0
}


# 检查依赖是否安装

check_dependencies() {
    local missing=()
    for dep in "${REQUIRED_DEPS[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "\033[1;33m正在安装缺失依赖：${missing[*]} ...\033[0m"
        if ! $INSTALL_CMD "${missing[@]}"; then
            echo -e "\033[1;31m依赖安装失败，请手动执行：$INSTALL_CMD ${missing[*]}\033[0m"
            exit 1
        fi
    fi
}


check_wget() {
# 检查wget是否已安装
if ! command -v wget &> /dev/null; then
    echo "wget未安装，正在尝试自动安装..."
    
    # 检测包管理器并安装
    if command -v apt-get &> /dev/null; then
        # Debian/Ubuntu
        apt-get update && apt-get install -y wget
    elif command -v yum &> /dev/null; then
        # CentOS/RHEL
        yum install -y wget
    elif command -v dnf &> /dev/null; then
        # Fedora
        dnf install -y wget
    elif command -v zypper &> /dev/null; then
        # openSUSE
        zypper install -y wget
    elif command -v pacman &> /dev/null; then
        # Arch Linux
        pacman -Sy --noconfirm wget
    elif command -v apk &> /dev/null; then
        # Alpine Linux
        apk add wget
    else
        echo "错误：无法识别的包管理器，请手动安装wget"
        exit 1
    fi
    
    # 再次验证安装是否成功
    if command -v wget &> /dev/null; then
        echo "wget安装成功！"
    else
        echo "wget安装失败，请手动安装"
        exit 1
    fi
else
    echo "wget已安装"
fi
}
check_deps() {
    for dep in "${REQUIRED_DEPS[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            echo -e "\033[1;33m正在安装 $dep ...\033[0m"
            if ! $INSTALL_CMD "$dep"; then
                echo -e "\033[1;31m安装失败，请手动执行：$INSTALL_CMD $dep\033[0m"
                exit 1
            fi
        fi
    done
}


check_ubuntu() {
if [ -f /etc/os-release ]; then
    source /etc/os-release
    if [ "$ID" = "ubuntu" ]; then
        echo "系统检测通过，正在运行于Ubuntu环境。"
    else
        echo "错误：此脚本仅支持Ubuntu系统，当前系统为 $ID。" >&2
        exit 1
    fi
else
    echo "错误：无法识别操作系统，脚本终止。" >&2
    exit 1
fi
}

# 统一提示信息
show_info() {
    echo -e "${RED}bug反馈加QQ1706491377${NC}"
    echo -e "${RED}B站搜爱做视频のJack_Eason${NC}"
    echo -e "${RED}最终解释权归B站爱做视频のJack_Eason所有${NC}"
}

# 检查root权限
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}非root用户，请以root身份运行！${NC}"
        show_info
        sleep 1
        exit 1
    fi
    echo -e "${GREEN}root用户，即将开始执行！${NC}"
    show_info
    sleep 1
}
install_plugins() {
    # 扫描所有安装的实例
    local instances=()
    while IFS= read -r -d $'\0' dir; do
        instances+=("$(basename "$dir")" "${dir#${ROOT_DIR}/versions/}")
    done < <(find "${ROOT_DIR}/versions" -maxdepth 1 -type d -name "*" -print0)

    # 检查是否有安装实例
    if [ ${#instances[@]} -eq 0 ]; then
        dialog --msgbox "未找到任何服务器实例，请先安装！" 10 50
        return 1
    fi

    # 实例选择菜单
    local selected_instance=$(dialog --menu "选择目标实例" 18 70 12 \
        "${instances[@]}" 2>&1 >/dev/tty)
    [ -z "$selected_instance" ] && return

    # 从目录名解析元数据
    local dir_name="$selected_instance"
    local core_type=$(echo "$dir_name" | awk -F- '{print $1}')
    local mc_version=$(echo "$dir_name" | awk -F- '{print $2}')
    local instance_name=$(echo "$dir_name" | awk -F- '{for(i=3;i<=NF;i++) printf "%s%s", $i, (i<NF?"-":"")}')

    # 验证核心类型
    case "$core_type" in
        "Fabric"|"Spigot") ;;
        *)
            dialog --msgbox "无效的目录结构：无法识别核心类型" 10 50
            return 1
            ;;
    esac

    # 验证版本格式
    if ! [[ "$mc_version" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
        dialog --msgbox "无效的版本格式：$mc_version" 10 50
        return 1
    fi

    # 确定插件目录
    local instance_path="${ROOT_DIR}/versions/${selected_instance}"
    local install_dir="${instance_path}/plugins"
    [ "$core_type" = "Fabric" ] && install_dir="${instance_path}/mods"
    mkdir -p "$install_dir" || {
        dialog --msgbox "无法创建插件目录：$install_dir" 10 50
        return 1
    }

    # 动态生成插件数据库（支持扩展）
    declare -A plugin_map=(
        ["Geyser"]="GeyserMC/Geyser"
        ["Floodgate"]="GeyserMC/Floodgate"
        ["ViaVersion"]="ViaVersion/ViaVersion"
        ["ViaBackwards"]="ViaVersion/ViaBackwards"
        ["ViaRewind"]="ViaVersion/ViaRewind"
        ["Spark"]="lucko/spark"
        ["LuckPerms"]="LuckPerms/LuckPerms"
    )

    # 生成插件选择列表（带版本兼容性提示）
    local plugin_choices=()
    for plugin in "${!plugin_map[@]}"; do
        if check_plugin_compatibility "$plugin" "$mc_version" "$core_type"; then
            plugin_choices+=("$plugin" "√ 兼容" on)
        else
            plugin_choices+=("$plugin" "× 不兼容" off)
        fi
    done

    # 插件选择对话框
    local selected_plugins=$(dialog --checklist "选择插件 (当前版本：${mc_version})" 18 60 15 \
        "${plugin_choices[@]}" 3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && return

    # 安装进度对话框
    (
        echo "0"
        echo "# 初始化插件安装环境..."
        local total_steps=$(($(wc -w <<< "$selected_plugins") * 6))
        local current_step=0
        declare -a installed_plugins

        for plugin in $selected_plugins; do
            current_step=$((current_step + 1))
            echo "$((current_step * 100 / total_steps))"
            echo "# 处理插件: ${plugin}..."

            # 获取插件元数据
            local plugin_id=${plugin_map[$plugin]}
            local api_url="https://api.modrinth.com/v2/project/${plugin_id}/version"
            local version_info
            if ! version_info=$(curl -fsSL --retry 3 "$api_url"); then
                echo "100"
                dialog --msgbox "${plugin} 元数据获取失败！错误码: $?" 7 50
                return 1
            fi

            # 解析最新兼容版本
            local version_data
            version_data=$(jq -r --arg mc_version "$mc_version" \
                --arg loader "${core_type,,}" \
                '[.[] | select(
                    .game_versions[] == $mc_version and 
                    .loaders[] == $loader and 
                    .version_type == "release"
                )] | sort_by(.date_published) | reverse | .[0]' <<< "$version_info")

            if [ "$version_data" = "null" ] || [ -z "$version_data" ]; then
                echo "100"
                dialog --msgbox "${plugin} 无兼容版本！" 7 40
                continue
            fi

            # 下载插件
            local download_url=$(jq -r '.files[0].url' <<< "$version_data")
            local filename="${plugin}.jar"
            local temp_file="${install_dir}/${filename}.tmp"

            current_step=$((current_step + 1))
            echo "$((current_step * 100 / total_steps))"
            echo "# 下载 ${plugin}..."

            if ! wget -q --show-progress --progress=bar:force \
                -O "$temp_file" "$download_url"; then
                echo "100"
                dialog --msgbox "${plugin} 下载失败！" 7 40
                continue
            fi

            # 校验文件完整性
            current_step=$((current_step + 1))
            echo "$((current_step * 100 / total_steps))"
            echo "# 验证 ${plugin} 完整性..."

            local expected_hash=$(jq -r '.files[0].hashes.sha1' <<< "$version_data")
            local actual_hash=$(sha1sum "$temp_file" | cut -d' ' -f1)
            if [ "$expected_hash" != "$actual_hash" ]; then
                rm -f "$temp_file"
                echo "100"
                dialog --msgbox "${plugin} 文件校验失败！" 7 40
                continue
            fi

            # 安装插件
            current_step=$((current_step + 1))
            echo "$((current_step * 100 / total_steps))"
            echo "# 安装 ${plugin}..."

            local final_file="${install_dir}/${filename}"
            if [ -f "$final_file" ]; then
                local backup_file="${final_file}.bak_$(date +%s)"
                mv "$final_file" "$backup_file"
                echo "检测到旧版本，已备份至: $(basename "$backup_file")" >> "${install_dir}/install.log"
            fi

            mv "$temp_file" "$final_file"

            # 记录安装日志
            current_step=$((current_step + 1))
            echo "$((current_step * 100 / total_steps))"
            echo "# 完成 ${plugin} 安装..."

            installed_plugins+=("${plugin} v$(jq -r '.version_number' <<< "$version_data")")
            echo "[$(date +%F_%T)] 安装插件: ${plugin} ${mc_version}" >> "${install_dir}/install.log"
        done

        # 生成安装报告
        echo "100"
        echo "# 生成安装报告..."
        local result_msg="安装目录: $install_dir\n"
        result_msg+="已安装插件:\n"
        for p in "${installed_plugins[@]}"; do
            result_msg+="• $p\n"
        done
        result_msg+="\n详细日志请查看: ${install_dir}/install.log"

        sleep 1
    ) | dialog --gauge "插件安装进度" 12 70 0

    # 显示安装结果
    dialog --msgbox "插件安装完成！\n\n${result_msg}" 16 60
}


# 检查并安装 dialog
check_dialog() {
    if ! command -v dialog &> /dev/null; then
        echo -e "${YELLOW}${DIALOG_ERROR}${NC}"
        if command -v apt &> /dev/null; then
            apt update && apt install -y dialog || {
                echo -e "${RED}${DIALOG_FAIL}${NC}"
                echo "apt update &&apt install -y dialog"
                exit 1
            }
        else
            echo -e "${RED}${DIALOG_FAIL}${NC}"
            echo "apt update &&apt install -y dialog"
            exit 1
        fi
        if [ "$LANG" = "zh" ]; then
            echo -e "${GREEN}dialog 安装成功，继续执行...${NC}"
        else
            echo -e "${GREEN}dialog installed successfully, proceeding...${NC}"
        fi
    fi
}

# 检查并安装 curl 和 jq
check_curl_jq() {
    if ! command -v curl &> /dev/null || ! command -v jq &> /dev/null; then
        dialog --msgbox "$HITOKOTO_INSTALLING" 10 50
        if command -v apt &> /dev/null; then
            apt update && apt install -y curl jq || {
                dialog --msgbox "$HITOKOTO_ERROR" 10 50
                return 1
            }
        else
            dialog --msgbox "$HITOKOTO_ERROR" 10 50
            return 1
        fi
    fi
    return 0
}

# 检查网络连接
check_network() {
    if ! ping -c 1 -W 2 www.badu.com &> /dev/null; then
        dialog --msgbox "$HITOKOTO_NET_ERROR" 10 50
        return 1
    fi
    return 0
}

# 显示一言
show_hitokoto() {
    if ! check_curl_jq || ! check_network; then
        return 1
    fi

    local api_url="https://v1.hitokoto.cn"
    [ "$LANG" = "en" ] && api_url="${api_url}?c=i" # 英文句子

    local hitokoto
    hitokoto=$(curl -s --connect-timeout 5 --retry 2 "$api_url" | jq -r '.hitokoto' 2>/dev/null)
    
    if [ -z "$hitokoto" ] || [ "$hitokoto" = "null" ]; then
        dialog --msgbox "$HITOKOTO_ERROR" 10 50
    else
        dialog --title "$HITOKOTO_TITLE" --msgbox "$hitokoto" 10 50
    fi
}

# Java版本检查并自动安装 Java 21
check_java() {
    if ! command -v java &> /dev/null; then
        if [ "$LANG" = "zh" ]; then
            echo -e "${YELLOW}Java 未安装，正在自动安装 Java 21...${NC}"
        else
            echo -e "${YELLOW}Java is not installed, installing Java 21 automatically...${NC}"
        fi
        install_java_21
        return
    fi

    local java_version
    java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d. -f1)
    if [ -z "$java_version" ]; then
        install_java_21
        return
    fi
    if [ "$java_version" -lt "$JAVA_REQUIRED" ]; then
        if [ "$LANG" = "zh" ]; then
            echo -e "${YELLOW}当前 Java 版本 $java_version 低于 21，正在自动安装 Java 21...${NC}"
        else
            echo -e "${YELLOW}Current Java version $java_version is below 21, installing Java 21 automatically...${NC}"
        fi
        install_java_21
    elif [ "$java_version" -eq "$JAVA_REQUIRED" ]; then
        if [ "$LANG" = "zh" ]; then
            echo -e "${GREEN}Java 21 已正确安装，继续执行...${NC}"
        else
            echo -e "${GREEN}Java 21 is correctly installed, proceeding...${NC}"
        fi
    else
        if [ "$LANG" = "zh" ]; then
            echo -e "${YELLOW}当前 Java 版本 $java_version 高于 21，为确保兼容性，正在安装 Java 21...${NC}"
        else
            echo -e "${YELLOW}Current Java version $java_version is above 21, installing Java 21 for compatibility...${NC}"
        fi
        install_java_21
    fi
}

# 自动安装 Java 21
install_java_21() {
    if command -v apt &> /dev/null; then
        apt update && apt install -y openjdk-21-jdk || {
            if [ "$LANG" = "zh" ]; then
                echo -e "${RED}Java 21 安装失败，请手动安装！${NC}"
            else
                echo -e "${RED}Failed to install Java 21, please install it manually!${NC}"
            fi
            echo "apt update &&apt install -y openjdk-21-jdk"
            exit 1
        }
    else
        if [ "$LANG" = "zh" ]; then
            echo -e "${RED}不支持的包管理器！请手动安装 Java 21：${NC}"
        else
            echo -e "${RED}Unsupported package manager! Please install Java 21 manually:${NC}"
        fi
        echo "apt update &&apt install -y openjdk-21-jdk"
        exit 1
    fi
    if [ "$LANG" = "zh" ]; then
        echo -e "${GREEN}Java 21 安装成功，继续执行...${NC}"
    else
        echo -e "${GREEN}Java 21 installed successfully, proceeding...${NC}"
    fi
}



# 核心安装函数
install_core() {
    # 创建版本隔离目录
    mkdir -p "${ROOT_DIR}/versions" || return 1

    # 核心类型选择
    local core_type=$(dialog --menu "选择服务器核心" 15 50 5 \
        "1" "Fabric" \
        "2" "Spigot" \
        2>&1 >/dev/tty) || return 0

    case $core_type in
        1) core_name="Fabric" ;;
        2) core_name="Spigot" ;;
        *) return ;;
    esac

    # 获取所有可用版本
    local versions=()
    case $core_name in
        "Fabric")
            versions=($(curl -fsSL "https://meta.fabricmc.net/v2/versions/game" |
                        jq -r '.[] | select(.stable == true) | .version' | sort -Vr | head -n 10)) || {
                dialog --msgbox "无法获取Fabric版本信息" 10 50
                return 1
            }
            ;;
        "Spigot")
            versions=($(curl -fsSL "https://hub.spigotmc.org/versions/" |
                        grep -Eo '[0-9]+\.[0-9]+(\.[0-9]+)?' | 
                        sort -Vr | uniq | head -n 10)) || {
                dialog --msgbox "无法获取Spigot版本信息" 10 50
                return 1
            }
            ;;
    esac

    [ ${#versions[@]} -eq 0 ] && {
        dialog --msgbox "没有找到可用版本" 10 50
        return 1
    }

    # 生成dialog菜单选项
    local menu_options=()
    for ((i=0; i<${#versions[@]}; i++)); do
        menu_options+=("$((i+1))" "${versions[$i]}")
    done

    # 显示版本选择菜单
    local version_choice=$(dialog --menu "选择版本 (最新在最上)" 20 60 15 \
        "${menu_options[@]}" 2>&1 >/dev/tty) || return 0
    
    local selected_version="${versions[$((version_choice-1))]}"

    # 获取实例名称
    local instance_name=$(dialog --inputbox "输入实例名称" 8 40 2>&1 >/dev/tty) || return 0
    local install_dir="${ROOT_DIR}/versions/${core_name}-${selected_version}-${instance_name}"
    mkdir -p "$install_dir" || return 1

    # 下载核心
    case $core_name in
        "Paper")
            local build_info=$(curl -fsSL "https://api.papermc.io/v2/projects/paper/versions/${selected_version}")
            local build_number=$(jq -r '.builds[-1]' <<< "$build_info")
            wget -q --show-progress --progress=bar:force "https://api.papermc.io/v2/projects/paper/versions/${selected_version}/builds/${build_number}/downloads/paper-${selected_version}-${build_number}.jar" \
                -O "${install_dir}/server.jar" || {
                rm -rf "$install_dir"
                dialog --msgbox "Paper核心下载失败" 10 50
                return 1
            }
            ;;

        "Fabric")
            local loader_version=$(curl -fsSL "https://meta.fabricmc.net/v2/versions/loader" |
                                jq -r '.[0].version')
            local installer_version=$(curl -fsSL "https://meta.fabricmc.net/v2/versions/installer" |
                                    jq -r '.[0].version')
            wget -q --show-progress --progress=bar:force "https://meta.fabricmc.net/v2/versions/loader/${selected_version}/${loader_version}/${installer_version}/server/jar" \
                -O "${install_dir}/server.jar" || {
                rm -rf "$install_dir"
                dialog --msgbox "Fabric核心下载失败" 10 50
                return 1
            }
            ;;
 
    "Spigot")
        if ! download_spigot "$selected_version" "$install_dir"; then
            rm -rf "$install_dir"
            return 1
        fi
       
          ;;
 esac
    # 生成启动脚本
    cat > "${install_dir}/start.sh" <<EOF
#!/bin/bash
java -Xms2G -Xmx4G -jar server.jar nogui
EOF

    # 自动同意EULA
    echo "eula=true" > "${install_dir}/eula.txt"

    # 生成配置文件并关闭正版验证
    if [ ! -f "${install_dir}/server.properties" ]; then
        (cd "${install_dir}" && timeout 10s java -jar server.jar --nogui >/dev/null 2>&1)
    fi

    if [ -f "${install_dir}/server.properties" ]; then
        sed -i 's/online-mode=true/online-mode=false/' "${install_dir}/server.properties"
    else
        echo "online-mode=false" > "${install_dir}/server.properties"
    fi

    dialog --msgbox "安装完成！\n路径: ${install_dir}" 12 50
}


# 通用菜单函数
create_menu() {
    local title="$1"
    local prompt="$2"
    shift 2
    dialog --clear \
        --backtitle "$BACKTITLE" \
        --title "$title" \
        --menu "$prompt" \
        "$MENU_HEIGHT" "$MENU_WIDTH" "$MENU_CHOICE_HEIGHT" \
        "$@" \
    2>&1 >/dev/tty
}
tool_box() {
while true; do
         local dynamic_title="${TITLE}" 
        choice=$(create_menu "$dynamic_title" "$MENU_PROMPT" \
        "1" "时钟" \
        "2" "退出")
         case "$choice" in
         "1") time_clock ;;
         "2") break ;;
         "") echo -e "${RED}取消操作${NC}"; sleep 1 ;;
        *) echo -e "${RED}无效选项，请重试！${NC}"; sleep 1 ;;
        esac
        done
}
# 主菜单
main_menu() {
    
    while true; do
local dynamic_title="${TITLE}"
        choice=$(create_menu "$dynamic_title" "$MENU_PROMPT" \
            "1" "$INSTALL_PROMPT" \
            "2" "$START_PROMPT" \
            "3" "$UNINSTALL_PROMPT" \
            "4" "$CONFIG_PROMPT" \
            "5" "$BACKUP_PROMPT" \
            "6" "$RESTORE_PROMPT" \
            "7" "$CLEAN_LOGS_PROMPT" \
            "8" "工具箱" \
            "9" "安装互通插件" \
            "10" "$EXIT_PROMPT")

        case "$choice" in
        "1") install_core ;;
        "2") start_menu ;;
        "3") uninstall_menu ;;
        "4") config_menu ;;
        "5") backup_menu ;;
        "6") restore_menu ;;
        "7") clean_logs_menu ;;
        "8") tool_box ;;
        "9") install_plugins ;;
        "10") echo "感谢使用，再见😊"
        sleep 2
         exit 0 ;;
        "") echo -e "${RED}取消操作${NC}"; sleep 1 ;;
        *) echo -e "${RED}无效选项，请重试！${NC}"; sleep 1 ;;
        esac
    done
}

# 启动子菜单
# 启动函数 - 支持版本隔离启动
start_menu() {
    # 扫描所有安装的实例
    local instances=()
    while IFS= read -r -d $'\0' dir; do
        instances+=("$(basename "$dir")" "${dir#${ROOT_DIR}/versions/}")
    done < <(find "${ROOT_DIR}/versions" -maxdepth 1 -type d -name "*" -print0)

    # 检查是否有安装实例
    if [ ${#instances[@]} -eq 0 ]; then
        dialog --msgbox "未找到任何服务器实例，请先安装！" 10 50
        return 1
    fi

    # 生成dialog菜单选项
    local menu_items=()
    for ((i=0; i<${#instances[@]}; i+=2)); do
        menu_items+=("${instances[$i]}" "${instances[$((i+1))]}")
    done

    # 显示实例选择菜单
    local selected_instance=$(dialog --menu "选择要启动的实例" 20 60 15 \
        "${menu_items[@]}" 2>&1 >/dev/tty)
    
    [ -z "$selected_instance" ] && return

    # 获取完整路径
    local instance_path="${ROOT_DIR}/versions/${selected_instance}"
    
    # 验证必要文件
    if [ ! -f "${instance_path}/server.jar" ]; then
        dialog --msgbox "错误：server.jar 文件缺失！" 10 50
        return 1
    fi

    # 前台启动服务器
    (
        cd "${instance_path}" || exit 1
        dialog --msgbox "回车启动服务器...\n输入stop停止服务器" 8 50
        clear
        echo -e "${GREEN}=== 服务器控制台 (直接输入命令) ===${NC}"
        bash start.sh
    )

    # 显示启动结果
    if [ $? -eq 0 ]; then
        dialog --msgbox "服务器已正常退出" 8 40
    else
        dialog --msgbox "服务器异常退出！请检查日志" 8 50
    fi
}


# 卸载子菜单
uninstall_menu() {
    
    # 获取所有安装的版本实例
    local installed_dirs=($(find "${ROOT_DIR}/versions" -maxdepth 1 -type d -name "*Paper-*" -o -name "*Fabric-*" -o -name "*Spigot-*" | sort -r))

    # 检查空目录
    if [ ${#installed_dirs[@]} -eq 0 ]; then
        dialog --msgbox "没有找到可卸载的服务器实例" 7 40
        return
    fi

    # 生成菜单选项
    local menu_items=()
    for ((i=0; i<${#installed_dirs[@]}; i++)); do
        dir_name=$(basename "${installed_dirs[$i]}")
        core_type=$(echo "$dir_name" | cut -d- -f1)
        mc_version=$(echo "$dir_name" | cut -d- -f2)
        instance_name=$(echo "$dir_name" | cut -d- -f3-)
        menu_items+=("$((i+1))" "${core_type} | ${mc_version} | ${instance_name}")
    done

    # 显示选择菜单
    local choice=$(dialog --menu "选择要卸载的实例 (最新在最上)" 20 80 15 \
        "${menu_items[@]}" 2>&1 >/dev/tty)

    [ -z "$choice" ] && return

    # 获取完整路径
    local selected_dir="${installed_dirs[$((choice-1))]}"

    # 安全检查
    if [[ "$selected_dir" != "${ROOT_DIR}/versions/"* ]]; then
        dialog --msgbox "错误：非法路径访问" 7 40
        return
    fi

    # 二次确认
    dialog --yesno "确定要永久删除以下实例吗？\n\n路径：${selected_dir}" 12 60
    if [ $? -eq 0 ]; then
        # 停止运行中的实例
        if pgrep -f "java -jar ${selected_dir}/server.jar" >/dev/null; then
            pkill -f "java -jar ${selected_dir}/server.jar"
            sleep 3 # 等待进程结束
        fi

        # 执行删除
        rm -rf "${selected_dir}"
        
        # 清理空目录
        find "${ROOT_DIR}/versions" -type d -empty -delete
        
        dialog --msgbox "实例已成功卸载" 7 40
    fi

}

# 配置子菜单
config_menu() {
    # 获取可配置实例列表
    local instances=($(find "${ROOT_DIR}/versions" -maxdepth 1 -type d -name "*Paper-*" -o -name "*Fabric-*" -o -name "*Spigot-*" | grep -v '/\.'))

    # 空实例检查
    if [ ${#instances[@]} -eq 0 ]; then
        dialog --msgbox "当前没有可配置的服务器实例" 8 45
        return
    fi

    # 生成配置菜单
    local menu_items=()
    for ((i=0; i<${#instances[@]}; i++)); do
        dir_name=$(basename "${instances[$i]}")
        core_info=$(echo "$dir_name" | cut -d- -f1,2)
        instance_name=$(echo "$dir_name" | cut -d- -f3-)
        menu_items+=("$((i+1))" "${core_info} | ${instance_name}")
    done

    # 实例选择
    local choice=$(dialog --menu "选择要配置的实例" 18 70 12 \
        "${menu_items[@]}" 2>&1 >/dev/tty)
    [ -z "$choice" ] && return

    local instance_path="${instances[$((choice-1))]}"
    local instance_name=$(basename "$instance_path")

    # 安全路径验证
    if [[ "$instance_path" != "${ROOT_DIR}/versions/"* ]] || [ ! -d "$instance_path" ]; then
        dialog --msgbox "无效的实例路径" 7 40
        return 1
    fi

    # 获取实例元数据
    local core_type=$(echo "$instance_name" | cut -d- -f1)
    local java_version=$(grep 'java_version=' "$instance_path/instance.cfg" | cut -d= -f2)

    # 配置主菜单
    while true; do
        # 检测服务状态
        local service_status="已停止"
        if pgrep -f "java -jar ${instance_path}/server.jar" >/dev/null; then
            service_status="运行中"
        fi

        choice=$(dialog --menu "实例配置：${instance_name}\n状态：${service_status}" 17 60 10 \
            "1" "编辑服务器配置" \
            "2" "调整JVM参数" \
            "3" "管理插件/模组" \
            "4" "开关服务器" \
            "5" "查看日志" \
            "6" "返回主菜单" 3>&1 1>&2 2>&3)

        case $choice in
            1)
                local config_files=("server.properties" "spigot.yml" "bukkit.yml")
[ "$core_type" = "Fabric" ] && config_files+=("fabric-server-launcher.properties")

local file_items=()
for ((i=0; i<${#config_files[@]}; i++)); do
    file_path="${instance_path}/${config_files[$i]}"
    [ -f "$file_path" ] && file_items+=("$((i+1))" "${config_files[$i]}")
done

local file_choice=$(dialog --menu "选择配置文件" 15 50 8 \
    "${file_items[@]}" 3>&1 1>&2 2>&3)
[ -z "$file_choice" ] && continue

local selected_file="${config_files[$((file_choice-1))]}"

# 捕获编辑后的内容并保存回文件
edited_content=$(dialog --title "编辑 ${selected_file}" --editbox "${instance_path}/${selected_file}" 25 80 3>&1 1>&2 2>&3)
if [ $? -eq 0 ]; then
    echo "$edited_content" > "${instance_path}/${selected_file}"
fi
                ;;

            2)
                # JVM参数优化
                local current_args=$(grep 'JAVA_ARGS=' "${instance_path}/start.sh" | cut -d= -f2-)
                local new_args=$(dialog --inputbox "输入JVM参数" 10 60 "$current_args" 3>&1 1>&2 2>&3)
                
                # 参数验证
                if ! java -version ${new_args} 2>/dev/null; then
                    dialog --msgbox "无效的JVM参数" 7 40
                    continue
                fi

                # 应用修改
                sed -i "s|JAVA_ARGS=.*|JAVA_ARGS=\"${new_args}\"|" "${instance_path}/start.sh"
                dialog --msgbox "JVM参数已更新" 7 40
                ;;

            3)
                # 插件/模组管理
                local mod_dir="${instance_path}/mods"
                [ "$core_type" = "Spigot" ] && mod_dir="${instance_path}/plugins"
                
                # 文件操作
                while true; do
                    local mod_files=($(find "$mod_dir" -maxdepth 1 -type f -name "*.jar"))
                    local mod_items=()
                    for ((i=0; i<${#mod_files[@]}; i++)); do
                        mod_items+=("$((i+1))" "$(basename "${mod_files[$i]}")")
                    done

                    local mod_choice=$(dialog --menu "插件/模组管理" 20 60 15 \
                        "${mod_items[@]}" \
                        "U" "上传新文件" \
                        "B" "返回" 3>&1 1>&2 2>&3)

                    case $mod_choice in
                        U)
                            local upload_file=$(dialog --fselect "$HOME/" 15 60 3>&1 1>&2 2>&3)
                            [ -f "$upload_file" ] && cp "$upload_file" "$mod_dir"
                            ;;
                        B) break ;;
                        *) 
                            local selected_mod="${mod_files[$((mod_choice-1))]}"
                            dialog --yesno "确定要删除 ${selected_mod} 吗？" 7 50 && rm -f "$selected_mod"
                            ;;
                    esac
                done
                ;;

            4)
                # 服务控制
                local service_action
                if [ "$service_status" = "运行中" ]; then
                    service_action=$(dialog --menu "选择操作" 10 40 3 \
                        "1" "重启服务" \
                        "2" "停止服务" 3>&1 1>&2 2>&3)
                    
                    case $service_action in
                        1) 
                            pkill -f "java -jar ${instance_path}/server.jar"
                            (cd "$instance_path" && bash start.sh) &
                            ;;
                        2) 
                            pkill -f "java -jar ${instance_path}/server.jar" 
                            ;;
                    esac
                else
                    (cd "$instance_path" && bash start.sh) &
                fi
                ;;

            5)
                # 日志查看（支持实时跟踪）
                dialog --tailbox "${instance_path}/logs/latest.log" 25 80
                ;;

            *) break ;;
        esac
    done
}

# 备份子菜单
backup_menu() {
    # 创建备份目录结构
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_root="${ROOT_DIR}/backups"
    mkdir -p "${backup_root}/full" "${backup_root}/incremental"

    # 获取可备份实例（排除隐藏文件）
    local instances=($(find "${ROOT_DIR}/versions" -maxdepth 1 -type d -name "*Paper-*" -o -name "*Fabric-*" -o -name "*Spigot-*" | grep -v '/\.'))

    # 空目录检查
    if [ ${#instances[@]} -eq 0 ]; then
        dialog --msgbox "当前没有可备份的服务器实例" 8 45
        return
    fi

    # 生成交互菜单
    local menu_items=()
    for ((i=0; i<${#instances[@]}; i++)); do
        dir_name=$(basename "${instances[$i]}")
        core_ver=$(echo "$dir_name" | cut -d- -f1,2)
        instance_name=$(echo "$dir_name" | cut -d- -f3-)
        menu_items+=("$((i+1))" "${core_ver} | ${instance_name}")
    done

    # 实例选择
    local choice=$(dialog --menu "选择要备份的实例" 18 70 12 \
        "${menu_items[@]}" 2>&1 >/dev/tty)
    [ -z "$choice" ] && return

    local selected_instance="${instances[$((choice-1))]}"

    # 安全边界检查
    if [[ "$selected_instance" != "${ROOT_DIR}/versions/"* ]] || [ ! -d "$selected_instance" ]; then
        dialog --msgbox "无效的实例路径" 7 40
        return 1
    fi

    # 备份类型选择
    dialog --radiolist "选择备份类型" 10 40 3 \
        1 "完整备份" on \
        2 "增量备份" off 2>/tmp/backup_type
    local backup_type=$(</tmp/backup_type)

    # 压缩选项
    dialog --checklist "备份选项" 10 40 2 \
        "compress" "启用ZSTD压缩（并行加速）" on \
        "checksum" "生成SHA256校验文件" on 2>/tmp/backup_opts
    local opts=($(</tmp/backup_opts))

    # 构建备份路径
    local instance_name=$(basename "$selected_instance")
    local backup_path
    case $backup_type in
        1) backup_path="${backup_root}/full/${instance_name}_${timestamp}" ;;
        2) backup_path="${backup_root}/incremental/${instance_name}_${timestamp}" ;;
    esac

    # 二次确认
    dialog --yesno "确认备份设置：\n\n实例：${instance_name}\n类型：${backup_type}\n路径：${backup_path}" 12 60
    [ $? -ne 0 ] && return

    # 前台备份流程
    (
        echo "10" ; echo "# 检查服务器状态..."
        if pgrep -f "java -jar ${selected_instance}/server.jar" >/dev/null; then
            echo "20" ; echo "# 暂停自动保存..."
            echo "save-off\nsave-all\n" > ${selected_instance}/command_input
            sleep 3
        fi

        echo "30" ; echo "# 创建备份目录..."
        mkdir -p "$backup_path"

        echo "50" ; echo "# 打包世界数据..."
        rsync -a --exclude 'logs' --exclude 'cache' "${selected_instance}/" "${backup_path}/"

        # 压缩处理
        if [[ "${opts[@]}" =~ "compress" ]]; then
            echo "70" ; echo "# 压缩备份文件 (使用zstd)..."
            tar -I 'zstd --threads=4' -cf "${backup_path}.tar.zst" -C "${backup_path}" .
            rm -rf "$backup_path"
            backup_path="${backup_path}.tar.zst"
        fi

        # 生成校验文件
        if [[ "${opts[@]}" =~ "checksum" ]]; then
            echo "90" ; echo "# 生成校验文件..."
            sha256sum "$backup_path" > "${backup_path}.sha256"
        fi

        # 恢复自动保存
        if pgrep -f "java -jar ${selected_instance}/server.jar" >/dev/null; then
            echo "save-on\n" > ${selected_instance}/command_input
        fi

        echo "100" ; echo "# 备份完成!"
    ) | dialog --gauge "备份进行中..." 12 70 0

    # 显示备份信息
    local result_msg="备份路径：${backup_path}"
    [ -f "${backup_path}.sha256" ] && result_msg+="\n校验文件：$(cat "${backup_path}.sha256")"
    
    dialog --msgbox "备份成功完成！\n\n${result_msg}" 14 60
}


# 恢复子菜单
restore_menu() {
    # 创建恢复日志
    local restore_log="${ROOT_DIR}/restore.log"
    date "+%Y-%m-%d %T" >> "$restore_log"

    # 获取可恢复备份列表
    local backup_root="${ROOT_DIR}/backups"
    declare -a backup_files
    while IFS= read -r -d $'\0' file; do
        backup_files+=("$file")
    done < <(find "$backup_root" -type f \( -name "*.tar.zst" -o -name "*.sha256" \) -print0 | sort -rz)

    # 空备份检查
    if [ ${#backup_files[@]} -eq 0 ]; then
        dialog --msgbox "未找到任何可恢复的备份文件" 8 45
        return
    fi

    # 生成菜单项（排除校验文件）
    local menu_items=()
    for ((i=0; i<${#backup_files[@]}; i++)); do
        file_path="${backup_files[$i]}"
        [[ "$file_path" == *.sha256 ]] && continue
        
        file_name=$(basename "$file_path")
        instance_info=$(echo "$file_name" | cut -d_ -f1)
        backup_type=$(echo "$file_path" | awk -F/ '{print $(NF-1)}')
        timestamp=$(echo "$file_name" | grep -oE '[0-9]{8}-[0-9]{6}')
        menu_items+=("$((i+1))" "${instance_info} | ${backup_type} | ${timestamp}")
    done

    # 备份选择
    local choice=$(dialog --menu "选择要恢复的备份" 20 80 15 \
        "${menu_items[@]}" 2>&1 >/dev/tty)
    [ -z "$choice" ] && return

    local selected_file="${backup_files[$((choice-1))]}"

    # 安全路径验证
    if [[ "$selected_file" != "${ROOT_DIR}/backups/"* ]] || [ ! -f "$selected_file" ]; then
        dialog --msgbox "无效的备份文件路径" 7 40
        return 1
    fi

    # 自动关联校验文件
    local checksum_file="${selected_file}.sha256"
    if [ -f "$checksum_file" ]; then
        {
            echo "20" ; echo "# 验证备份完整性..."
            pushd "$(dirname "$selected_file")" >/dev/null
            if ! sha256sum -c "$checksum_file"; then
                dialog --msgbox "校验和不匹配，备份文件可能损坏！" 7 50
                return 1
            fi
            popd >/dev/null
        } | dialog --gauge "准备恢复环境..." 8 60 0
    fi

    # 确定恢复路径
    local instance_name=$(basename "$selected_file" | cut -d_ -f1)
    local restore_path="${ROOT_DIR}/versions/${instance_name}"

    # 冲突处理选项
    if [ -d "$restore_path" ]; then
        dialog --yesno "目标实例已存在，如何处理？\n\n1. 覆盖现有实例\n2. 创建新版本" 12 50
        local conflict_choice=$?
        case $conflict_choice in
            0) 
                rm -rf "$restore_path"
                echo "[覆盖恢复] ${instance_name}" >> "$restore_log"
                ;;
            1)
                local new_name="${instance_name}-$(date +%s)"
                restore_path="${ROOT_DIR}/versions/${new_name}"
                echo "[新建恢复] ${new_name}" >> "$restore_log"
                ;;
        esac
    fi

    # 服务状态管理
    local service_name=$(basename "$restore_path")
    {
        echo "30" ; echo "# 停止相关服务..."
        if systemctl is-active --quiet "mc-${service_name}"; then
            systemctl stop "mc-${service_name}"
            sleep 3
        fi

        # 解压恢复流程
        echo "50" ; echo "# 解压备份文件..."
        mkdir -p "$restore_path"
        case "$selected_file" in
            *.tar.zst)
                tar --use-compress-program='zstd -d' -xf "$selected_file" -C "$restore_path"
                ;;
            *)
                cp -a "$(dirname "$selected_file")"/* "$restore_path"
                ;;
        esac

        # 权限修复
        echo "80" ; echo "# 修复文件权限..."
        chown -R minecraft:minecraft "$restore_path"
        find "$restore_path" -type f -name "*.sh" -exec chmod +x {} \;

        # 服务重启
        echo "90" ; echo "# 重启服务..."
        if systemctl is-enabled --quiet "mc-${service_name}" 2>/dev/null; then
            systemctl start "mc-${service_name}"
        fi
    } | dialog --gauge "恢复进行中..." 12 70 0

    # 记录元数据
    echo "恢复路径：$restore_path" >> "$restore_log"
    echo "备份来源：$selected_file" >> "$restore_log"
    [ -f "$checksum_file" ] && echo "校验验证：通过" >> "$restore_log"

    # 显示恢复报告
    dialog --msgbox "恢复成功完成！\n\n恢复实例：${instance_name}\n存储路径：${restore_path}" 12 60

   if [ -d "$target_path" ]; then
       dialog --yesno "检测到已有版本：\n$(basename $target_path)\n如何处理？" 10 50 \
           --yes-label "覆盖更新" --no-label "创建副本"
       if [ $? -eq 0 ]; then
           rm -rf "$target_path"
       else
           target_path="${target_path}-$(date +%s)"
       fi
   fi

}

# 清理日志子菜单
clean_logs_menu() {
    cleanup_logs() {
    # 创建清理审计日志
    local audit_log="${ROOT_DIR}/cleanup_audit.log"
    echo "[$(date +%F_%T)] 清理操作开始" >> "$audit_log"

    # 获取所有实例的日志目录
    declare -A log_dirs
    while IFS= read -r -d '' instance; do
        local instance_name=$(basename "$instance")
        log_dirs["$instance_name"]="${instance}/logs"
    done < <(find "${ROOT_DIR}/versions" -maxdepth 1 -type d \( -name "*Paper-*" -o -name "*Fabric-*" -o -name "*Spigot-*" \) -print0)

    # 添加全局日志目录
    log_dirs["global_backups"]="${ROOT_DIR}/backups"
    log_dirs["system_logs"]="/var/log/minecraft"

    # 清理策略选择
    dialog --menu "选择清理模式" 12 50 4 \
        1 "按时间清理（保留最近N天）" \
        2 "按磁盘空间清理（自动计算）" \
        3 "交互式选择清理" 2>/tmp/clean_mode
    local clean_mode=$(</tmp/clean_mode)

    case $clean_mode in
        1)
            dialog --inputbox "输入保留天数（默认7天）" 8 40 7 2>/tmp/keep_days
            local keep_days=${$(</tmp/keep_days):-7}
            ;;
        2)
            local disk_usage=$(df -h ${ROOT_DIR} | awk 'NR==2{print $5}')
            dialog --msgbox "当前存储使用率：$disk_usage\n超过80%将触发自动清理" 8 50
            ;;
        3)
            interactive_cleanup
            return
            ;;
    esac

    # 执行批量清理
    {
        echo "10" ; echo "# 初始化清理环境..."
        local total_freed=0
        for instance in "${!log_dirs[@]}"; do
            local log_dir="${log_dirs[$instance]}"
            
            # 安全路径验证
            if [[ "$log_dir" != *"minecraft"* ]] || [ ! -d "$log_dir" ]; then
                echo "30" ; echo "⚠️ 跳过非法路径：$log_dir"
                continue
            fi

            # 根据模式处理
            case $clean_mode in
                1)
                    echo "40" ; echo "# 清理$instance超过${keep_days}天的日志..."
                    find "$log_dir" -name "*.log" -mtime +${keep_days} -print0 | safe_delete
                    ;;
                2)
                    if [ ${disk_usage%\%} -gt 80 ]; then
                        echo "50" ; echo "# 自动清理$instance日志..."
                        find "$log_dir" -name "*.log" -size +100M -print0 | safe_delete
                    fi
                    ;;
            esac

            # 计算释放空间
            local freed=$(($(du -sb "$log_dir" | cut -f1) - $(du -sb "$log_dir" | cut -f1)))
            total_freed=$((total_freed + freed))
        done

        echo "90" ; echo "# 优化存储空间..."
        sync && echo 3 > /proc/sys/vm/drop_caches

        echo "100" ; echo "# 清理完成！释放空间：$(numfmt --to=iec $total_freed)"
    } | dialog --gauge "日志清理进行中" 12 70 0

    # 记录审计日志
    echo "释放空间总计：$(numfmt --to=iec $total_freed)" >> "$audit_log"
    echo "[$(date +%F_%T)] 清理操作完成" >> "$audit_log"
    dialog --msgbox "日志清理操作已完成！\n详细信息请查看审计日志：$audit_log" 10 60
}

# 安全删除函数
safe_delete() {
    while IFS= read -r -d '' file; do
        # 检查文件占用状态
        if ! lsof -t "$file" >/dev/null; then
            # 保留最新日志的硬链接
            ln "$file" "${file}.deletelink" 2>/dev/null
            if rm --preserve-root "$file"; then
                echo "[清理] $file" >> "$audit_log"
            fi
        else
            echo "[保留] 使用中的文件：$file" >> "$audit_log"
        fi
    done
}

# 交互式清理模式
interactive_cleanup() {
    while true; do
        # 生成文件列表
        local file_list=()
        while IFS= read -r -d '' file; do
            file_list+=("$file" "$(stat -c '%y 大小：%s' "$file" | numfmt --to=iec --field=4)" off)
        done < <(find "${ROOT_DIR}" \( -name "*.log" -o -name "*.gz" \) -mtime +3 -print0)

        # 显示选择对话框
        dialog --checklist "选择要清理的文件（空格选择，Enter确认）" 20 80 15 \
            "${file_list[@]}" 2>/tmp/selected_files

        [ $? -ne 0 ] && break

        # 执行删除
        local count=0
        while IFS= read -r file; do
            rm --preserve-root "$file"
            ((count++))
        done < <(xargs -0 -a /tmp/selected_files)
        
        dialog --msgbox "已安全删除 $count 个文件" 7 40
    done
}

}

# 主程序
clear
check_ubuntu
check_root
check_language
check_deps
check_dependencies
check_wget
check_dialog
check_java
show_hitokoto
main_menu