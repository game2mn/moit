#!/bin/bash

# 函数：确认删除目录
confirm_delete() {
    echo "目标目录已存在，是否删除并拉取最新代码？(y/n)"
    read confirm
    if [ "$confirm" == "y" ]; then
        # 删除目录的操作
        cd / && rm -rf "$target_dir"
    else
        echo "取消操作，退出脚本。"
        exit 1
    fi
}

# 检查是否已经安装 Docker
if ! command -v docker &> /dev/null; then
    # 安装 Docker
    sudo apt update
    sudo apt-get install docker-ce
    if [ $? -eq 0 ]; then
        echo "安装 Docker 成功！"
    else
        echo "安装 Docker 失败，请检查错误并重新运行脚本。"
        exit 1
    fi
else
    echo "Docker 已经安装，跳过安装步骤。"
fi

# 检查是否已经安装 Docker Compose
if ! command -v docker-compose &> /dev/null; then
    # 安装 Docker Compose
    sudo apt install docker-compose
    if [ $? -eq 0 ]; then
        echo "安装 Docker Compose 成功！"
    else
        echo "安装 Docker Compose 失败，请检查错误并重新运行脚本。"
        exit 1
    fi
else
    echo "Docker Compose 已经安装，跳过安装步骤。"
fi

# 切换到根目录
cd /

# 设置目标目录
target_dir="/pandora"

# 检查目标目录是否已经存在
if [ -d "$target_dir" ]; then
    confirm_delete
fi

echo "克隆 GitHub 仓库到目标目录并切换到主分支"
git clone https://github.com/Yanyutin753/two-PandoraNext /pandora
if [ $? -eq 0 ]; then
    echo "克隆成功"
else
    echo "克隆失败，请检查错误并重新运行脚本。"
    exit 1
fi

echo "进入 /pandora 目录"
cd /pandora

# 提示用户输入 PandoraNext 的 license_id
echo "请输入 PandoraNext 的 license_id："
read license_id

# 使用 jq 直接在原始文件中修改 JSON 内容

jq --arg license_id "$license_id" -i ' . license_id = ($license_id)' ./pandora/data/config.json

jq --arg license_id "$license_id" -i '.license_id = ($license_id)' /pandora/pandoraproxy/data/config.json

# 运行 Docker Compose 启动命令
cd /pandora && docker-compose up -d

echo "开放 8081（tokensTool）、8082(proxy)、8181(web) 端口即可访问"
echo "启动成功后，打开 8081 网页，填写你的刷新 token 地址：http://你的ip:8082"
