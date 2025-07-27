import os
import shutil
import pathlib
import time
import requests  ###pip install requests
import datetime
import common###common.py为公共库


###定义path1
os.chdir(os.path.expanduser('~'))
path1=os.getcwd()

dirs=['xnlr/download','xnlr/mc','xnlr/logs']

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
        os.system('figlet "Aether" && figlet "Craft"')
    if os.path.exists('.xnlr'):
        pass
    else:
        print('首次进入！检查地区（通过时区检查，可能不准确）！')
        if timezone():
            if path1=="/data/data/com.termux/files/home":
                print(f'位于中国大陆，如需换源请执行{BLUE}termux-change-repo{NC}')
                time.sleep(1.5)
                install()
                os.system('touch .xnlr')
                os.chdir("xnlr")
                os.system("python menu.py")
            else:
                print('位于中国大陆\n换源请自行搜索相关教程')
                time.sleep(1.5)
                install()
                os.system('touch .xnlr')
                os.chdir("xnlr")
                os.system("python menu.py")
        else:
            print('位于海外，无需换源')
            time.sleep(1.5)
            install()
            os.system('touch .xnlr')
            os.chdir("xnlr")
            os.system("python menu.py")
            
main()
######now=datetime.datetime.now().strftime("%Y-%m-%d_%H:%M:%S+8:00")
######os.system(f"script ~/xnlr/logs/{now}.log")
######print(f"{BLUE}开始记录日志信息。日志将在脚本结束后保存。{NC}\n使用下面的命令查看日志\n{YELLOW_BOLD}cat ~/xnlr/logs/{now}.log{NC}")


#TODO
#####os.system("exit")

#####TODO git clone