#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cd ~
cur_dir=$(pwd)

uname_output=$(uname -a)

# check os
if echo "$uname_output" | grep -Eqi "freebsd"; then
    release="freebsd"
else
    echo -e "${red}未检测到系统版本，请联系脚本作者！${plain}\n" && exit 1
fi

arch="none"

if echo "$uname_output" | grep -Eqi 'x86_64|amd64|x64'; then
    arch="amd64"
elif echo "$uname_output" | grep -Eqi 'aarch64|arm64'; then
    arch="arm64"
else
    arch="amd64"
    echo -e "${red}检测架构失败，使用默认架构: ${arch}${plain}"
fi

echo "架构: ${arch}"

#This function will be called when user installed x-ui out of sercurity
config_after_install() {
    echo -e "${yellow}出于安全考虑，安装/更新完成后需要强制修改端口与账户密码${plain}"
    read -p "确认是否继续?[y/n]": config_confirm
    if [[ x"${config_confirm}" == x"y" || x"${config_confirm}" == x"Y" ]]; then
        read -p "请设置您的账户名:" config_account
        echo -e "${yellow}您的账户名将设定为:${config_account}${plain}"
        read -p "请设置您的账户密码:" config_password
        echo -e "${yellow}您的账户密码将设定为:${config_password}${plain}"
        read -p "请设置面板访问端口:" config_port
        echo -e "${yellow}您的面板访问端口将设定为:${config_port}${plain}"
        read -p "请设置面板流量监测端口:" config_traffic_port
        echo -e "${yellow}您的面板流量监测端口将设定为:${config_traffic_port}${plain}"
        echo -e "${yellow}确认设定,设定中${plain}"
        ./x-ui setting -username ${config_account} -password ${config_password}
        echo -e "${yellow}账户密码设定完成${plain}"
        ./x-ui setting -port ${config_port}
        echo -e "${yellow}面板访问端口设定完成${plain}"
        ./x-ui setting -trafficport ${config_traffic_port}
        echo -e "${yellow}面板流量监测端口设定完成${plain}"
    else
        echo -e "${red}已取消,所有设置项均为默认设置,请及时修改${plain}"
        echo -e "如果是全新安装，默认网页端口为 ${green}54321${plain}，默认流量监测端口为 ${green}54322${plain}，用户名和密码默认都是 ${green}admin${plain}"
        echo -e "请自行确保此端口没有被其他程序占用，${yellow}并且确保 54321 和 54322 端口已放行${plain}"
        echo -e "若想将 54321 和 54322 修改为其它端口，输入 x-ui 命令进行修改，同样也要确保你修改的端口也是放行的"
    fi
}
stop_x-ui() {
    # 设置你想要杀死的nohup进程的命令名
    xui_com="./x-ui run"
    xray_com="bin/xray-$release-$arch -c bin/config.json"
 
    # 使用pgrep查找进程ID
    PID=$(pgrep -f "$xray_com")
 
    # 检查是否找到了进程
    if [ ! -z "$PID" ]; then
        # 找到了进程，杀死它
        kill $PID
    
        # 可选：检查进程是否已经被杀死
        if kill -0 $PID > /dev/null 2>&1; then
            kill -9 $PID
        fi
    fi
    # 使用pgrep查找进程ID
    PID=$(pgrep -f "$xui_com")
 
    # 检查是否找到了进程
    if [ ! -z "$PID" ]; then
        # 找到了进程，杀死它
        kill $PID
    
        # 可选：检查进程是否已经被杀死
        if kill -0 $PID > /dev/null 2>&1; then
            kill -9 $PID
        fi
    fi

}

install_x-ui() {
    stop_x-ui

    if [ $# == 0 ]; then
        last_version=$(curl -Ls "https://api.github.com/repos/amclubs/am-serv00-x-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        wget -N --no-check-certificate -O x-ui-${release}-${arch}.tar.gz https://github.com/amclubs/am-serv00-x-ui/releases/latest/download/x-ui-${release}-${arch}.tar.gz
        if [[ $? -ne 0 ]]; then
            echo -e "${red}下载 x-ui 失败，请确保你的服务器能够下载 Github 的文件${plain}"
            exit 1
        fi
    else
        last_version=$1
        url="https://github.com/vaxilu/x-ui/releases/latest/download/x-ui-${release}-${arch}.tar.gz"
        echo -e "开始安装 x-ui v$1"
        wget -N --no-check-certificate -O x-ui-${release}-${arch}.tar.gz ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "${red}下载 x-ui v$1 失败，请确保此版本存在${plain}"
            exit 1
        fi
    fi

    if [[ -e ./x-ui/ ]]; then
        rm ./x-ui/ -rf
    fi

    tar zxvf x-ui-${release}-${arch}.tar.gz
    rm -f x-ui-${release}-${arch}.tar.gz
    cd x-ui
    chmod +x x-ui bin/xray-${release}-${arch}
    #cp -f x-ui.service /etc/systemd/system/
    cp x-ui.sh ../x-ui.sh
    chmod +x ../x-ui.sh
    chmod +x x-ui.sh
    config_after_install
    #echo -e ""
    #echo -e "如果是更新面板，则按你之前的方式访问面板"
    #echo -e ""
    crontab -l > x-ui.cron
    sed -i "" "/x-ui.log/d" x-ui.cron
    echo "0 0 * * * cd $cur_dir/x-ui && cat /dev/null > x-ui.log" >> x-ui.cron
    echo "@reboot cd $cur_dir/x-ui && nohup ./x-ui run > ./x-ui.log 2>&1 &" >> x-ui.cron
    crontab x-ui.cron
    rm x-ui.cron
    nohup ./x-ui run > ./x-ui.log 2>&1 &
    echo -e "${green}x-ui v${last_version}${plain} 安装完成，面板已启动，"
    echo -e ""
    echo -e "x-ui 管理脚本使用方法: "
    echo -e "----------------------------------------------"
    echo -e "/home/${USER}/x-ui.sh               - 显示管理菜单 (功能更多)"
    echo -e "/home/${USER}/x-ui.sh  start        - 启动 x-ui 面板"
    echo -e "/home/${USER}/x-ui.sh  stop         - 停止 x-ui 面板"
    echo -e "/home/${USER}/x-ui.sh  restart      - 重启 x-ui 面板"
    echo -e "/home/${USER}/x-ui.sh  status       - 查看 x-ui 状态"
    echo -e "/home/${USER}/x-ui.sh  enable       - 设置 x-ui 开机自启"
    echo -e "/home/${USER}/x-ui.sh  disable      - 取消 x-ui 开机自启"
    echo -e "/home/${USER}/x-ui.sh  update       - 更新 x-ui 面板"
    echo -e "/home/${USER}/x-ui.sh  install      - 安装 x-ui 面板"
    echo -e "/home/${USER}/x-ui.sh  uninstall    - 卸载 x-ui 面板"
    echo -e "----------------------------------------------"
}

echo -e "${green}开始安装${plain}"
install_base
install_x-ui $1
