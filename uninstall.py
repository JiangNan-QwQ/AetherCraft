import os
import common
print(f"真的要***{RED_BOLD}卸载{NC}***管理系统吗？卸载后您的服务器数据将{RED_BOLD}永久丢失{NC}！！！\n[y/N]")
reply=input()
if reply in ["Y","y"]:
    print("确认卸载")
    os.chdir(os.path.expanduser('~'))
    os.system("rm -rfv xnlr && rm .xnlr")
elif reply in ["N","n",""]:
    print("取消卸载")
    print("退出程序")
else:
    print("无效选项！！！")