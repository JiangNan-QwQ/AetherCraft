#!/bin/bash
# Minecraft服务器管理脚本 - 插件模块
# 作者: B站@爱做视频のJack_Eason
# 版本: 3.3
# 日期: 2025-06-25

# 加载公共库
source <(curl -s https://raw.githubusercontent.com/JiangNan-QwQ/AetherCraft/main/common.sh)

# 插件主菜单
plugins_menu() {
    while true; do
        choice=$(dialog --menu "插件管理" 15 50 5 \
            "1" "安装插件" \
            "2" "管理已安装插件" \
            "3" "插件市场" \
            "4" "更新插件" \
            "5" "返回主菜单" 2>&1 >/dev/tty)
            
        case "$choice" in
            1) install_plugins ;;
            2) manage_plugins ;;
            3) plugin_market ;;
            4) update_plugins ;;
            5) return 0 ;;
            *) log "无效选项" "WARN";;
        esac
    done
}

# 安装插件
install_plugins() {
    # 扫描所有安装的实例
    local instances=()
    while IFS= read -r -d $'\0' dir; do
        instances+=("$(basename "$dir")" "${dir#${VERSIONS_DIR}/}")
    done < <(find "${VERSIONS_DIR}" -maxdepth 1 -type d -name "*" -print0)

    if [ ${#instances[@]} -eq 0 ]; then
        dialog --msgbox "未找到任何服务器实例，请先安装！" 10 50
        return 1
    fi

    # 实例选择菜单
    local selected_instance=$(dialog --menu "选择目标实例" 18 70 12 \
        "${instances[@]}" 2>&1 >/dev/tty)
    [ -z "$selected_instance" ] && return

    # 解析实例元数据
    local dir_name="$selected_instance"
    local core_type=$(echo "$dir_name" | awk -F- '{print $1}')
    local mc_version=$(echo "$dir_name" | awk -F- '{print $2}')
    local instance_path="${VERSIONS_DIR}/${selected_instance}"

    # 确定插件目录
    local install_dir="${instance_path}/plugins"
    [ "$core_type" = "Fabric" ] && install_dir="${instance_path}/mods"
    mkdir -p "$install_dir" || {
        dialog --msgbox "无法创建插件目录：$install_dir" 10 50
        return 1
    }

    # 插件数据库（支持多源回退）
    declare -A plugin_sources=(
        # 基岩版互通
        ["Geyser"]="mirror|https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot
                    github|https://github.com/GeyserMC/Geyser/releases/latest/download/Geyser-Spigot.jar
                    jenkins|https://ci.opencollab.dev/job/GeyserMC/job/Geyser/job/master/lastSuccessfulBuild/artifact/bootstrap/spigot/target/Geyser-Spigot.jar"
        
        ["Floodgate"]="mirror|https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot
                       github|https://github.com/GeyserMC/Floodgate/releases/latest/download/floodgate-spigot.jar
                       jenkins|https://ci.opencollab.dev/job/GeyserMC/job/Floodgate/job/master/lastSuccessfulBuild/artifact/spigot/target/floodgate-spigot.jar"
        
        # 跨版本支持
        ["ViaVersion"]="spigotmc|https://www.spigotmc.org/resources/viaversion.19254/download?version=476915
                        github|https://github.com/ViaVersion/ViaVersion/releases/latest/download/ViaVersion-4.8.1.jar"
        
        ["ViaBackwards"]="spigotmc|https://www.spigotmc.org/resources/viabackwards.27448/download?version=476916
                          github|https://github.com/ViaVersion/ViaBackwards/releases/latest/download/ViaBackwards-4.8.1.jar"
        
        # 经济与管理
        ["EssentialsX"]="jenkins|https://ci.ender.zone/job/EssentialsX/job/EssentialsX/lastSuccessfulBuild/artifact/jars/EssentialsX-2.20.0.jar
                         github|https://github.com/EssentialsX/Essentials/releases/latest/download/EssentialsX-2.20.0.jar"
        
        ["Vault"]="github|https://github.com/MilkBowl/Vault/releases/latest/download/Vault.jar
                   spigotmc|https://www.spigotmc.org/resources/vault.34315/download?version=476917"
        
        # 性能优化
        ["ClearLag"]="spigotmc|https://www.spigotmc.org/resources/clearlag.103482/download?version=476918
                      github|https://github.com/badbones69/ClearLag/releases/latest/download/ClearLag.jar"
        
        ["Spark"]="modrinth|https://cdn.modrinth.com/data/A4dZQDY9/versions/1.10.39/spark-1.10.39-bukkit.jar
                   github|https://github.com/lucko/spark/releases/latest/download/spark-1.10.39-bukkit.jar"
        
        # 安全与权限
        ["LuckPerms"]="modrinth|https://cdn.modrinth.com/data/1w4d5N5O/versions/5.4.87/LuckPerms-Bukkit-5.4.87.jar
                       github|https://github.com/LuckPerms/LuckPerms/releases/latest/download/LuckPerms-Bukkit-5.4.87.jar"
        
        ["AuthMe"]="github|https://github.com/AuthMe/AuthMeReloaded/releases/latest/download/AuthMeReloaded-5.6.0-SNAPSHOT.jar
                    spigotmc|https://www.spigotmc.org/resources/authmereloaded.6269/download?version=476919"
        
        # 世界管理
        ["WorldEdit"]="enginehub|https://dev.bukkit.org/projects/worldedit/files/latest
                       github|https://github.com/EngineHub/WorldEdit/releases/latest/download/worldedit-bukkit-7.2.15.jar"
        
        ["WorldGuard"]="enginehub|https://dev.bukkit.org/projects/worldguard/files/latest
                        github|https://github.com/EngineHub/WorldGuard/releases/latest/download/worldguard-bukkit-7.0.9.jar"
    )

    # 生成插件选择列表
    local plugin_choices=()
    for plugin in "${!plugin_sources[@]}"; do
        case "$plugin" in
            "Geyser"|"Floodgate") desc="基岩版互通组件" ;;
            "Via"*)               desc="跨版本支持" ;;
            "Essentials"*|"Vault") desc="经济与管理" ;;
            "ClearLag"|"Spark")    desc="性能优化" ;;
            "LuckPerms"|"AuthMe")  desc="安全与权限" ;;
            "World"*)              desc="世界管理" ;;
            *)                     desc="功能插件" ;;
        esac
        plugin_choices+=("$plugin" "$desc" off)
    done

    # 插件选择对话框
    local selected_plugins=$(dialog --checklist "选择插件 (当前版本：${mc_version})" 20 70 15 \
        "${plugin_choices[@]}" 3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && return

    # 前台安装过程
    clear
    echo -e "${GREEN}=== 开始安装插件 ===${NC}"
    echo -e "目标实例: ${YELLOW}${selected_instance}${NC}"
    echo -e "核心类型: ${YELLOW}${core_type}${NC}"
    echo -e "游戏版本: ${YELLOW}${mc_version}${NC}"
    echo -e "安装目录: ${YELLOW}${install_dir}${NC}"
    echo -e "选择插件: ${YELLOW}${selected_plugins}${NC}"
    echo "----------------------------------------"

    # 下载工具检测
    if ! command -v wget &> /dev/null; then
        echo -e "${RED}错误: 需要安装 wget 工具${NC}"
        apt-get install -y wget || {
            echo -e "${RED}无法安装 wget，请手动执行: apt-get install wget${NC}"
            return 1
        }
    fi

    declare -a installed_plugins
    for plugin in $selected_plugins; do
        echo -e "\n${GREEN}>>> 正在处理 ${plugin}...${NC}"
        
        # 获取所有备用源
        IFS=' ' read -r -a sources <<< "${plugin_sources[$plugin]}"
        local filename="${plugin}.jar"
        local temp_file="${install_dir}/${filename}.tmp"
        local success=0

        # 多源重试机制
        for source in "${sources[@]}"; do
            IFS='|' read -r source_type source_url <<< "$source"
            
            echo -e "${YELLOW}[来源: ${source_type}]${NC}"
            case "$source_type" in
                "mirror")
                    if curl -fsSL "$source_url" -o "$temp_file"; then
                        success=1
                        break
                    fi
                    ;;
                    
                "github"|"jenkins"|"spigotmc"|"modrinth"|"enginehub")
                    if wget --show-progress -q -O "$temp_file" "$source_url"; then
                        success=1
                        break
                    fi
                    ;;
            esac
            echo -e "${YELLOW}⚠️ 尝试失败，切换备用源...${NC}"
            rm -f "$temp_file" 2>/dev/null
            sleep 1
        done

        # 安装验证
        if [ "$success" -eq 1 ] && [ -f "$temp_file" ]; then
            # 文件完整性检查（至少100KB）
            if [ $(stat -c%s "$temp_file") -lt 102400 ]; then
                echo -e "${RED}错误: 下载文件过小，可能损坏！${NC}"
                rm -f "$temp_file"
                continue
            fi
            
            # 覆盖旧版本
            [ -f "${install_dir}/${filename}" ] && rm -f "${install_dir}/${filename}"
            mv "$temp_file" "${install_dir}/${filename}"
            
            installed_plugins+=("$plugin")
            echo -e "${GREEN}✔ 安装成功 (来自: ${source_type})${NC}"
            echo -e "文件大小: $(du -h "${install_dir}/${filename}" | cut -f1)"
            
            # 记录安装信息
            log_plugin_install "$plugin" "$source_url" "$install_dir"
        else
            echo -e "${RED}✖✖ 所有下载源均失败！${NC}"
            echo -e "请手动下载: ${plugin_sources[$plugin]// / 或 }"
        fi
    done

    # 显示安装结果
    echo -e "\n${GREEN}=== 安装结果 ===${NC}"
    if [ ${#installed_plugins[@]} -gt 0 ]; then
        echo -e "已安装插件:"
        for p in "${installed_plugins[@]}"; do
            echo -e "  • ${p}"
        done
        
        # 提示重启服务器
        if check_server_status "$selected_instance"; then
            echo -e "\n${YELLOW}⚠️ 部分插件需要重启服务器才能生效${NC}"
            if dialog --yesno "检测到服务器正在运行，是否要重启服务器使插件生效？" 10 50; then
                restart_instance "$selected_instance"
            fi
        fi
    else
        echo -e "${YELLOW}⚠️ 没有插件被安装${NC}"
    fi
    
    # 显示失败插件（如果有）
    local failed_plugins=($(comm -23 <(echo "$selected_plugins" | tr ' ' '\n' | sort) <(printf "%s\n" "${installed_plugins[@]}" | sort)))
    if [ ${#failed_plugins[@]} -gt 0 ]; then
        echo -e "\n${RED}失败的插件:${NC}"
        for p in "${failed_plugins[@]}"; do
            echo -e "  • ${p} (可尝试手动下载)"
            echo -e "    下载链接: ${plugin_sources[$p]// / 或 }"
        done
    fi
    
    echo -e "\n安装目录: ${install_dir}"
    echo -e "\n按任意键返回主菜单..."
    read -n 1 -s
}

# 记录插件安装信息
log_plugin_install() {
    local plugin=$1
    local source=$2
    local install_dir=$3
    
    cat >> "${install_dir}/plugin_install.log" <<EOF
[$(date +%FT%T)]
plugin=${plugin}
source=${source}
file=${plugin}.jar
size=$(du -h "${install_dir}/${plugin}.jar" | cut -f1)
sha256=$(sha256sum "${install_dir}/${plugin}.jar" | cut -d' ' -f1)
EOF
}

# 管理已安装插件
manage_plugins() {
    # 扫描所有安装的实例
    local instances=()
    while IFS= read -r -d $'\0' dir; do
        instances+=("$(basename "$dir")" "${dir#${VERSIONS_DIR}/}")
    done < <(find "${VERSIONS_DIR}" -maxdepth 1 -type d -name "*" -print0)

    if [ ${#instances[@]} -eq 0 ]; then
        dialog --msgbox "未找到任何服务器实例，请先安装！" 10 50
        return 1
    fi

    # 实例选择菜单
    local selected_instance=$(dialog --menu "选择目标实例" 18 70 12 \
        "${instances[@]}" 2>&1 >/dev/tty)
    [ -z "$selected_instance" ] && return

    # 解析实例元数据
    local dir_name="$selected_instance"
    local core_type=$(echo "$dir_name" | awk -F- '{print $1}')
    local instance_path="${VERSIONS_DIR}/${selected_instance}"

    # 确定插件目录
    local plugins_dir="${instance_path}/plugins"
    [ "$core_type" = "Fabric" ] && plugins_dir="${instance_path}/mods"
    
    if [ ! -d "$plugins_dir" ]; then
        dialog --msgbox "该实例没有插件目录！" 8 40
        return 1
    fi

    # 获取插件列表
    local plugins=()
    while IFS= read -r -d $'\0' file; do
        local plugin_name=$(basename "$file" .jar)
        local plugin_size=$(du -h "$file" | cut -f1)
        plugins+=("$plugin_name" "$plugin_size" off)
    done < <(find "$plugins_dir" -maxdepth 1 -type f -name "*.jar" -print0)

    if [ ${#plugins[@]} -eq 0 ]; then
        dialog --msgbox "没有找到已安装的插件！" 8 40
        return
    fi

    # 插件管理菜单
    while true; do
        local action=$(dialog --menu "插件管理 - ${selected_instance}" 20 70 15 \
            "list" "查看插件列表" \
            "remove" "删除插件" \
            "disable" "禁用插件" \
            "enable" "启用插件" \
            "info" "查看插件信息" \
            "back" "返回" 2>&1 >/dev/tty)
        
        [ -z "$action" ] && return

        case "$action" in
            "list")
                list_plugins "$plugins_dir"
                ;;
                
            "remove")
                remove_plugins "$plugins_dir"
                plugins=()  # 清空缓存，需要重新扫描
                ;;
                
            "disable")
                disable_plugins "$plugins_dir"
                ;;
                
            "enable")
                enable_plugins "$plugins_dir"
                ;;
                
            "info")
                plugin_info "$plugins_dir"
                ;;
                
            "back")
                return
                ;;
        esac
    done
}

# 列出所有插件
list_plugins() {
    local plugins_dir=$1
    local plugins_list=""
    
    while IFS= read -r -d $'\0' file; do
        local plugin_name=$(basename "$file" .jar)
        local plugin_size=$(du -h "$file" | cut -f1)
        local plugin_date=$(stat -c %y "$file" | cut -d' ' -f1)
        
        # 检查是否被禁用
        local status="${GREEN}启用${NC}"
        if [[ "$file" == *.disabled ]]; then
            status="${RED}禁用${NC}"
        fi
        
        plugins_list+="名称: ${plugin_name}\n"
        plugins_list+="大小: ${plugin_size} | 日期: ${plugin_date} | 状态: ${status}\n"
        plugins_list+="----------------------------------------\n"
    done < <(find "$plugins_dir" -maxdepth 1 -type f \( -name "*.jar" -o -name "*.jar.disabled" \) -print0)
    
    dialog --title "插件列表 - $(basename "$plugins_dir")" \
           --msgbox "$plugins_list" 25 80
}

# 删除插件
remove_plugins() {
    local plugins_dir=$1
    local plugins=()
    
    while IFS= read -r -d $'\0' file; do
        local plugin_name=$(basename "$file" .jar)
        plugin_name=${plugin_name%.disabled}  # 移除.disabled后缀
        local plugin_size=$(du -h "$file" | cut -f1)
        plugins+=("$plugin_name" "$plugin_size" off)
    done < <(find "$plugins_dir" -maxdepth 1 -type f \( -name "*.jar" -o -name "*.jar.disabled" \) -print0)

    local selected=($(dialog --checklist "选择要删除的插件 (空格选择,Enter确认):" \
        20 80 15 "${plugins[@]}" 3>&1 1>&2 2>&3))
    [ $? -ne 0 ] && return

    for plugin in "${selected[@]}"; do
        # 删除插件文件（包括可能存在的.disabled文件）
        rm -f "${plugins_dir}/${plugin}.jar" "${plugins_dir}/${plugin}.jar.disabled"
        dialog --msgbox "插件 ${plugin} 已删除" 8 40
    done
}

# 禁用插件
disable_plugins() {
    local plugins_dir=$1
    local plugins=()
    
    while IFS= read -r -d $'\0' file; do
        # 只列出当前启用的插件
        if [[ "$file" == *.jar ]]; then
            local plugin_name=$(basename "$file" .jar)
            local plugin_size=$(du -h "$file" | cut -f1)
            plugins+=("$plugin_name" "$plugin_size" off)
        fi
    done < <(find "$plugins_dir" -maxdepth 1 -type f -name "*.jar" -print0)

    local selected=($(dialog --checklist "选择要禁用的插件:" \
        20 80 15 "${plugins[@]}" 3>&1 1>&2 2>&3))
    [ $? -ne 0 ] && return

    for plugin in "${selected[@]}"; do
        mv "${plugins_dir}/${plugin}.jar" "${plugins_dir}/${plugin}.jar.disabled"
        dialog --msgbox "插件 ${plugin} 已禁用" 8 40
    done
}

# 启用插件
enable_plugins() {
    local plugins_dir=$1
    local plugins=()
    
    while IFS= read -r -d $'\0' file; do
        # 只列出当前禁用的插件
        if [[ "$file" == *.jar.disabled ]]; then
            local plugin_name=$(basename "$file" .jar.disabled)
            local plugin_size=$(du -h "$file" | cut -f1)
            plugins+=("$plugin_name" "$plugin_size" off)
        fi
    done < <(find "$plugins_dir" -maxdepth 1 -type f -name "*.jar.disabled" -print0)

    local selected=($(dialog --checklist "选择要启用的插件:" \
        20 80 15 "${plugins[@]}" 3>&1 1>&2 2>&3))
    [ $? -ne 0 ] && return

    for plugin in "${selected[@]}"; do
        mv "${plugins_dir}/${plugin}.jar.disabled" "${plugins_dir}/${plugin}.jar"
        dialog --msgbox "插件 ${plugin} 已启用" 8 40
    done
}

# 查看插件信息
plugin_info() {
    local plugins_dir=$1
    local plugins=()
    
    while IFS= read -r -d $'\0' file; do
        local plugin_name=$(basename "$file" .jar)
        plugin_name=${plugin_name%.disabled}  # 移除.disabled后缀
        local plugin_size=$(du -h "$file" | cut -f1)
        plugins+=("$plugin_name" "$plugin_size")
    done < <(find "$plugins_dir" -maxdepth 1 -type f \( -name "*.jar" -o -name "*.jar.disabled" \) -print0)

    local selected=$(dialog --menu "选择要查看的插件:" \
        20 80 15 "${plugins[@]}" 3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && return

    # 获取插件信息
    local info="插件名称: ${selected}\n"
    info+="文件大小: $(du -h "${plugins_dir}/${selected}.jar" 2>/dev/null || du -h "${plugins_dir}/${selected}.jar.disabled" | cut -f1)\n"
    info+="修改时间: $(stat -c %y "${plugins_dir}/${selected}.jar" 2>/dev/null || stat -c %y "${plugins_dir}/${selected}.jar.disabled" | cut -d' ' -f1)\n"
    
    # 尝试从jar文件中提取插件信息
    if [ -f "${plugins_dir}/${selected}.jar" ] || [ -f "${plugins_dir}/${selected}.jar.disabled" ]; then
        local jar_file="${plugins_dir}/${selected}.jar"
        [ -f "${jar_file}.disabled" ] && jar_file="${jar_file}.disabled"
        
        # 使用unzip和java读取插件信息
        if unzip -p "$jar_file" plugin.yml 2>/dev/null > /tmp/plugin_meta; then
            info+="\n插件元数据:\n"
            info+="$(grep -E "^(name|version|main|description):" /tmp/plugin_meta | sed 's/^/  /')\n"
        elif unzip -p "$jar_file" fabric.mod.json 2>/dev/null > /tmp/plugin_meta; then
            info+="\nFabric模组信息:\n"
            info+="$(jq -r '[.name, .version, .description] | join(" | ")' /tmp/plugin_meta 2>/dev/null | sed 's/^/  /')\n"
        fi
        
        rm -f /tmp/plugin_meta
    fi
    
    dialog --title "插件信息" --msgbox "$info" 20 80
}

# 插件市场
plugin_market() {
    # 这里可以添加从在线插件市场获取插件列表的功能
    # 目前仅作为示例，实际实现需要对接插件市场的API
    
    dialog --msgbox "插件市场功能正在开发中..." 8 40
}

# 更新插件
update_plugins() {
    # 扫描所有安装的实例
    local instances=()
    while IFS= read -r -d $'\0' dir; do
        instances+=("$(basename "$dir")" "${dir#${VERSIONS_DIR}/}")
    done < <(find "${VERSIONS_DIR}" -maxdepth 1 -type d -name "*" -print0)

    if [ ${#instances[@]} -eq 0 ]; then
        dialog --msgbox "未找到任何服务器实例，请先安装！" 10 50
        return 1
    fi

    # 实例选择菜单
    local selected_instance=$(dialog --menu "选择目标实例" 18 70 12 \
        "${instances[@]}" 2>&1 >/dev/tty)
    [ -z "$selected_instance" ] && return

    # 解析实例元数据
    local dir_name="$selected_instance"
    local core_type=$(echo "$dir_name" | awk -F- '{print $1}')
    local instance_path="${VERSIONS_DIR}/${selected_instance}"

    # 确定插件目录
    local plugins_dir="${instance_path}/plugins"
    [ "$core_type" = "Fabric" ] && plugins_dir="${instance_path}/mods"
    
    if [ ! -d "$plugins_dir" ]; then
        dialog --msgbox "该实例没有插件目录！" 8 40
        return 1
    fi

    # 检查是否有可更新的插件
    local update_list=""
    local has_updates=0
    
    while IFS= read -r -d $'\0' file; do
        local plugin_name=$(basename "$file" .jar)
        plugin_name=${plugin_name%.disabled}  # 移除.disabled后缀
        
        # 这里应该添加检查更新的逻辑
        # 示例: 检查插件是否有新版本可用
        update_list+="  • ${plugin_name} (当前: 1.0.0) | 最新: 1.0.1\n"
        has_updates=1
    done < <(find "$plugins_dir" -maxdepth 1 -type f \( -name "*.jar" -o -name "*.jar.disabled" \) -print0)

    if [ "$has_updates" -eq 0 ]; then
        dialog --msgbox "没有找到可更新的插件" 8 40
        return
    fi

    dialog --title "可用的插件更新" --yesno "以下插件有新版本可用:\n\n${update_list}\n是否要更新所有插件？" 20 80
    [ $? -ne 0 ] && return

    # 这里应该添加实际的更新逻辑
    dialog --msgbox "插件更新功能正在开发中..." 8 40
}

# 检查服务器运行状态
check_server_status() {
    local instance=$1
    if pgrep -f "java -jar ${VERSIONS_DIR}/${instance}/server.jar" >/dev/null; then
        return 0  # 运行中
    else
        return 1  # 已停止
    fi
}


#重启服务器实例

restart_instance() {
local instance= 1
local instance_dir=" {VERSIONS_DIR}/${instance}"

if check_server_status "$instance"; then
    # 停止服务器
    echo "stop" > "${instance_dir}/command_input"
    sleep 5
    
    # 确保服务器已停止
    if check_server_status "$instance"; then
        pkill -f "java -jar ${instance_dir}/server.jar"
        sleep 2
    fi
fi

# 启动服务器
(
    cd "${instance_dir}" || exit 1
    bash start.sh
)

}

#主入口

if [[ " {BASH_SOURCE[0]}" == " {0}" ]]; then
plugins_menu
fi


