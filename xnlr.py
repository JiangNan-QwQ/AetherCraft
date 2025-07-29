import os
import shutil
import pathlib
import time
import requests  ###pip install requests
import datetime
import common###common.py为公共库
####TODO 检查更新

###颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # 无颜色

# 加粗颜色
BOLD='\033[1m'
RED_BOLD='\033[1;31m'
GREEN_BOLD='\033[1;32m'
YELLOW_BOLD='\033[1;33m'



###定义
os.chdir(os.path.expanduser('~'))
path1=os.getcwd()


def write_file(repo):
    os.system("touch version/update")
    with open("version/update","w",encoding="utf-8") as updatefile:
        updatefile.write(repo)

def update(url):
    os.chdir("xnlr")
    with open("version/version") as file:
        version_now=float(file.read())
    version_new1 = requests.get(f"https://{url}.com/jiangnan-qwq/aethercraft/raw/main/version/version")
    version_new=float(version_new1.text)
    print(f"{BLUE}======检查更新======{NC}\n当前版本：{YELLOW_BOLD}v{version_now}{NC}\n远程仓库版本：{YELLOW_BOLD}v{version_new}{NC}")
    time.sleep(1.5)
    if version_now<version_new:
        print(f"{BLUE}检查到版本更新！{NC}\n是否安装？[Y/n]")
        usr_reply=input()
        if usr_reply in ['Y','y',""]:
            os.system("git pull")
            print("更新成功")
        else:
            print("取消")
    elif version_now==version_new:
        pass
    else:
        print(f"{RED_BOLD}错误！无法检查更新！请检查网络连接！{NC}")
        time.sleep(1)

def timezone():
    time1=-time.timezone // 3600
    return time1 == 8


def install():
    print(f'{BLUE}开始安装脚本{NC}')
    if path1=="/data/data/com.termux/files/home":
        pkg='pkg'
    else:
        pkgm=('apt','yum','dnf','pacman','zypper')
        pm=None
        for a in pkgm:
            pm=shutil.which(a)
            if pm is not None:
                pkg=a
                break
    deps=("curl","jq","figlet","dialog","wget","tar","unzip","rsync","java")
    for b in deps:
        dep=shutil.which(b)
        if dep is None:
            print(f'{RED}软件包:{b} 未安装，尝试安装。{NC}')
            try:
                if b=="java":
                    if pkg=="pkg":
                        os.system('pkg install openjdk-21 -y')
                    else:
                        os.system(f'{pkg} install openjdk-21-jdk -y')
                else:
                    os.system(f'{pkg} install {b} -y')
            except:
                if b=="java":
                    if pkg=="pkg":
                        print(f'{RED_BOLD}软件包:{b}安装失败！\n请尝试使用pkg up -y && pkg install openjdk-21 安装\n如果还是无法安装，请复制错误信息自行搜索！（推荐复制给AI查询）{NC}')
                    else:
                        print(f'{RED_BOLD}软件包:{b}安装失败！\n请尝试使用{pkg} update -y && {pkg} upgrade -y && {pkg} install openjdk-21-jdk 安装\n如果还是无法安装，请复制错误信息自行搜索！（推荐复制给AI查询）{NC}')
                else:
                    print(f'{RED_BOLD}软件包:{b}安装失败！\n请尝试使用{pkg} update -y && {pkg} upgrade -y && {pkg} install {b}安装\n如果还是无法安装，请复制错误信息自行搜索！（推荐复制给AI查询）{NC}')

        
def main():
    if shutil.which("figlet") is None:
        print("============AetherCraft============")
    else:
        os.system('figlet "Aether" && figlet "Craft"')
    
    if os.path.exists('.xnlr'):
        with open("xnlr/version/update") as updateurl:
            update_url=updateurl
        update(update_url)
        os.system("python menu.py")
    else:
        print('首次进入！检查地区（通过时区检查，可能不准确）！')
        if timezone():
            
            if path1=="/data/data/com.termux/files/home":
                print(f'位于中国大陆，如需换源请执行{BLUE}termux-change-repo{NC}')
                time.sleep(1.5)
                install()
                os.system('touch .xnlr')
                os.system("git clone https://gitee.com/jiangnan-qwq/aethercraft xnlr")
                update("gitee")
                os.system("touch version/update")
                write_file("gitee")
                os.system("python menu.py")
            else:
                print('位于中国大陆\n换源请自行搜索相关教程')
                time.sleep(1.5)
                install()
                os.system('touch .xnlr')
                os.system("git clone https://gitee.com/jiangnan-qwq/aethercraft xnlr")
                update("gitee")
                write_file("gitee")
                os.system("python menu.py")
        else:
            print('位于海外，无需换源')
            time.sleep(1.5)
            install()
            os.system('touch .xnlr')
            os.system("git clone https://github.com/jiangnan-qwq/aethercraft xnlr")
            update("github")
            write_file("github")
            os.system("python menu.py")
            
main()
######now=datetime.datetime.now().strftime("%Y-%m-%d_%H:%M:%S+8:00")
######os.system(f"script ~xnlr/logs/{now}.log")
######print(f"{BLUE}开始记录日志信息。日志将在脚本结束后保存。{NC}\n使用下面的命令查看日志\n{YELLOW_BOLD}cat ~xnlr/logs/{now}.log{NC}")


#TODO
#####os.system("exit")
