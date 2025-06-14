
# 备份原 sources.list
cp /etc/apt/sources.list /etc/apt/sources.list.bak

# 选择镜像源（默认清华源）
MIRROR="https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/"

# 检测 Ubuntu 版本代号（如 jammy, noble 等）
CODENAME=$(lsb_release -cs 2>/dev/null || echo "noble")  # 默认 noble (24.04)

# 生成新的 sources.list
cat > /etc/apt/sources.list << EOL
deb ${MIRROR} ${CODENAME} main restricted universe multiverse
deb ${MIRROR} ${CODENAME}-updates main restricted universe multiverse
deb ${MIRROR} ${CODENAME}-backports main restricted universe multiverse
deb ${MIRROR} ${CODENAME}-security main restricted universe multiverse
EOL

echo "已替换为 ${MIRROR} (Ubuntu ${CODENAME})"
echo "正在更新软件列表..."
apt update -y && apt upgrade -y

apt install -y curl ; bash -c "$(https://raw.githubusercontent.com/JiangNan-QwQ/AetherCraft/main/3.3.sh)"
