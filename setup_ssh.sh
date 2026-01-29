#!/bin/bash

# 1. 检查是否为 Root 用户
if [ "$EUID" -ne 0 ]; then
  echo "请使用 root 权限运行此脚本 (sudo bash ...)"
  exit
fi

echo ">>> 开始配置 Root 免密登录..."

# 定义密钥路径
KEY_PATH="/root/.ssh/id_ed25519"
SSH_CONFIG="/etc/ssh/sshd_config"

# 2. 创建 .ssh 目录（如果不存在）
mkdir -p /root/.ssh
chmod 700 /root/.ssh

# 3. 生成 Ed25519 密钥对 (如果已存在则覆盖，由 -f -N "" 决定无密码)
# 注意：这会覆盖旧的 root 密钥，请谨慎
rm -f "$KEY_PATH" "$KEY_PATH.pub"
ssh-keygen -t ed25519 -f "$KEY_PATH" -C "root_auto_gen" -N "" -q

echo ">>> 密钥生成完毕"

# 4. 将公钥写入 authorized_keys
cat "$KEY_PATH.pub" >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

# 5. 修改 SSH 配置文件
# 备份原配置
cp $SSH_CONFIG "$SSH_CONFIG.bak"

# 确保配置项存在，使用追加方式确保覆盖默认值
# 允许 Root 登录
echo "PermitRootLogin yes" >> $SSH_CONFIG
# 启用公钥认证
echo "PubkeyAuthentication yes" >> $SSH_CONFIG
# (可选) 如果你想强制只用 Key 登录，取消下面这行的注释
# echo "PasswordAuthentication no" >> $SSH_CONFIG

echo ">>> SSH 配置已修改"

# 6. 重启 SSH 服务
if command -v systemctl &> /dev/null; then
    systemctl restart ssh
    systemctl restart sshd
else
    service ssh restart
fi

echo ">>> 服务已重启"
echo "-------------------------------------------------------"
echo "✅ 配置成功！请立即复制下面的【私钥】内容保存到本地文件 (例如: myserver.key)"
echo "-------------------------------------------------------"
# 7. 在屏幕上输出私钥内容，方便用户直接复制
cat "$KEY_PATH"
echo "-------------------------------------------------------"
echo "本地登录命令示例: ssh -i myserver.key root@<Server_IP>"
echo "-------------------------------------------------------"

# 为了安全，脚本执行完后可以考虑删除私钥文件 (根据需求选择)
# rm -f "$KEY_PATH"
