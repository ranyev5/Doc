## 基础工具安装
``` shell
sudo apt update && sudo apt install vim git curl -y
```
## 配置sudo 密码缓存时间
``` shell
#!/bin/bash 
# 检测/修改/添加sudo timestamp_timeout配置

# 第一步：校验root权限（必须） 
if [ "$(id -u)" -ne 0 ];
	then echo "错误：请用sudo/root权限执行此脚本" 
	exit 1 
fi 

# 定义目标缓存时长（仅此处需修改，单位：分钟） 
TARGET_TIMEOUT=30 

# 第二步：检查是否存在有效配置（忽略注释，仅匹配核心配置行） 
if grep -q "^Defaults\s\+timestamp_timeout=" /etc/sudoers /etc/sudoers.d/* 2>/dev/null; then 
	# 场景1：存在配置，直接替换（兼容空格，全局修改匹配项） 
	echo "检测到timestamp_timeout配置，正在修改为${TARGET_TIMEOUT}分钟..." 
	sed -i 's/^Defaults\s\+timestamp_timeout=.*/Defaults timestamp_timeout='"${TARGET_TIMEOUT}"'/' /etc/sudoers 
	# 同时修改sudoers.d目录下的匹配文件（若有） 
	grep -rl "^Defaults\s\+timestamp_timeout=" /etc/sudoers.d/* 2>/dev/null | while read FILE; do 
		sed -i 's/^Defaults\s\+timestamp_timeout=.*/Defaults timestamp_timeout='"${TARGET_TIMEOUT}"'/' $FILE 
	done 
else 
	# 场景2：不存在配置，安全添加到sudoers.d（不修改核心sudoers） 
	echo "未检测到timestamp_timeout配置，正在添加为${TARGET_TIMEOUT}分钟..." 
	# 写入自定义配置并设置正确权限（必须0440） 
	echo "Defaults timestamp_timeout=${TARGET_TIMEOUT}" > /etc/sudoers.d/sudo-timeout 
	chmod 0440 /etc/sudoers.d/sudo-timeout 
fi 

# 第三步：语法校验（兜底安全，避免sudo失效） 
if visudo -c >/dev/null 2>&1; then 
	echo "操作成功！当前timestamp_timeout配置：" 
	grep -r "timestamp_timeout" /etc/sudoers /etc/sudoers.d/* 2>/dev/null else echo "错误：配置语法异常，已放弃修改（避免sudo失效）" 
	# 清理无效的自定义配置文件（若为添加场景） 
	[ -f /etc/sudoers.d/sudo-timeout ] && rm -f /etc/sudoers.d/sudo-timeout exit 1 
fi
```

## 更新software updater配置
```
# 步骤1：设置禁用更新检查
sudo sed -i 's/APT::Periodic::Update-Package-Lists ".*";/APT::Periodic::Update-Package-Lists "0";/' /etc/apt/apt.conf.d/10periodic

# 步骤2：禁用自动下载更新包（1=启用，0=禁用）
sudo sed -i 's/APT::Periodic::Download-Upgradeable-Packages ".*";/APT::Periodic::Download-Upgradeable-Packages "0";/' /etc/apt/apt.conf.d/10periodic

# 步骤3：启用自动清理更新缓存，每7天一次
sudo sed -i 's/APT::Periodic::AutocleanInterval ".*";/APT::Periodic::AutocleanInterval "7";/' /etc/apt/apt.conf.d/10periodic

# 步骤四: 禁用自动安装更新
sudo sed -i 's/APT::Periodic::Unattended-Upgrade ".*";/APT::Periodic::Unattended-Upgrade "0";/' /etc/apt/apt.conf.d/10periodic


```
## 安装代理工具
``` shell
cd ~/Downloads
wget https://storage.abyss.moe/d/Proxy/Linux/clash-party-linux-1.8.9-amd64.deb
sudo dpkg -i ./clash-party-linux-1.8.9-amd64.deb
```
## 安装终端工具
``` shell
cd ~/Downloads
sudo apt update && sudo apt install terminator autojump zsh -y 
chsh -s $(which zsh)
sh -c "$(curl -fsSL https://install.ohmyz.sh/)"
# 安装插件
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/plugins/zsh-syntax-highlighting
# 修改配置文件
sed -i.bak \
  -e 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' \
  -e 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting autojump extract sudo)/' \
  ~/.zshrc
```
