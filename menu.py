import dialog####pip install pythondialog
import os

x=dialog.Dialog(dialog="dialog")

def menu():
    while True:
        re,selection=x.menu(
            "AetherCraft",
            choices=[
                ("I","下载服务器"),
                ("S","启动服务器"),
                ("C","配置服务器"),###TODO 插件管理
                ("B","备份/恢复服务器"),
                ("U","卸载整个管理系统"),
                ("E","退出管理系统")
                     ]
                                 )
        if re==x.OK:
            match selection:
                case "I":
                    os.system("python functions/install.py")
                case "S":
                    os.system("python functions/start.py")
                case "C":
                    os.system("python functions/config.py")
                case "B":
                    os.system("python functions/backup.py")
                case "U":
                    os.system("python functions/uninstall.py")
                case "E":
                    break
                case _:
                    print(f"{RED}无效选项{NC}")
                    continue
        elif re==x.CANCEL:
            continue
        else:
            continue

menu()