#!/bin/bash

# 本地一键 SSL 证书管理脚本 (仿 3x-ui 功能)
# 包含：申请证书、强制续签、移除证书、显示证书
CERT_DIR="$HOME/cert"
ACME_SH="$HOME/.acme.sh/acme.sh"

function install_acme_sh() {
    if ! command -v $ACME_SH &>/dev/null; then
        echo "acme.sh 未安装，正在安装..."
        curl -s https://get.acme.sh | sh
        if [ $? -ne 0 ]; then
            echo "acme.sh 安装失败"
            exit 1
        fi
    fi
}

function issue_cert() {
    read -rp "请输入要申请证书的域名: " DOMAIN
    DOMAIN_PATH="$CERT_DIR/$DOMAIN"
    mkdir -p "$DOMAIN_PATH"
    echo "正在为 $DOMAIN 申请证书..."
    $ACME_SH --set-default-ca --server letsencrypt
    $ACME_SH --issue -d "$DOMAIN" --standalone --keylength ec-256
    $ACME_SH --install-cert -d "$DOMAIN" \
        --key-file "$DOMAIN_PATH/privkey.pem" \
        --fullchain-file "$DOMAIN_PATH/fullchain.pem" \
        --reloadcmd "echo '证书已更新'"
    echo "证书已保存至: $DOMAIN_PATH"
    $ACME_SH --upgrade --auto-upgrade
}

function renew_cert() {
    read -rp "请输入需要强制续签的域名: " DOMAIN
    $ACME_SH --renew -d "$DOMAIN" --force
    echo "$DOMAIN 证书已强制续签"
}

function revoke_cert() {
    read -rp "请输入需要移除的域名: " DOMAIN
    $ACME_SH --revoke -d "$DOMAIN"
    rm -rf "$CERT_DIR/$DOMAIN"
    echo "$DOMAIN 证书已撤销并移除文件"
}

function show_certs() {
    echo "已存在证书域名列表:"
    find "$CERT_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;
}

function menu() {
    echo "证书管理菜单:"
    echo "1. 申请证书"
    echo "2. 强制续签证书"
    echo "3. 撤销/移除证书"
    echo "4. 显示已存在证书"
    echo "0. 退出"
    read -rp "请选择操作: " CHOICE
    case "$CHOICE" in
        1) issue_cert ;;
        2) renew_cert ;;
        3) revoke_cert ;;
        4) show_certs ;;
        0) exit 0 ;;
        *) echo "无效选项" ;;
    esac
}

# 主流程
install_acme_sh
while true; do
    menu
done
