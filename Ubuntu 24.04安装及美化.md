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
sudo sed -i 's/APT::Periodic::AutocleanInterval ".*";/APT::Periodic::AutocleanInterval "7 ";/' /etc/apt/apt.conf.d/10periodic

# 步骤四: 禁用自动安装更新
sudo sed -i 's/APT::Periodic::Unattended-Upgrade ".*";/APT::Periodic::Unattended-Upgrade "0";/' /etc/apt/apt.conf.d/10periodic

sudo tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null <<EOF
APT::Periodic::Update-Package-Lists "0";
APT::Periodic::Download-Upgradeable-Packages "0";
APT::Periodic::AutocleanInterval "0";
APT::Periodic::Unattended-Upgrade "0";
EOF
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

## 安装常用软件
```
#!/bin/bash

# 功能：Ubuntu24.04桌面版一键部署：卸载Firefox+安装Chrome(默认)+VS Code+JetBrains Toolbox（无额外自动配置/IDE安装）
# 核心：1. 保留指定Chrome安装方法 2. 固定Toolbox下载链接 3. 删除IDE自动安装+Toolbox自动配置逻辑
# 要求：以普通用户执行（含sudo权限，脚本内会请求密码）

# 定义颜色输出（简洁实用，无特殊字符）
GREEN='\033[0;32m'
NC='\033[0m'

# 简化信息输出函数
info() {
    echo -e "${GREEN}[INFO] $1${NC}"
}

# 第一步：校验系统版本（确保是Ubuntu24.04）
info "正在校验系统版本..."
if [ ! -f /etc/os-release ] || ! grep -q "24.04" /etc/os-release; then
    echo "错误：此脚本仅支持Ubuntu24.04系统！"
    exit 1
fi

# 第二步：卸载原生Firefox浏览器
info "开始卸载原生Firefox浏览器..."
sudo snap remove --purge firefox 2>/dev/null
sudo apt remove --purge firefox -y 2>/dev/null
sudo apt autoremove -y >/dev/null 2>&1
info "Firefox卸载完成（若未安装，忽略相关报错）"

# 第三步：安装Google Chrome（保留你的核心方法，无修改）
info "开始安装Google Chrome浏览器..."
# 1. 安装必备依赖（确保wget、gpg等工具可用）
sudo apt update >/dev/null 2>&1
sudo apt install -y wget apt-transport-https ca-certificates gnupg -y >/dev/null 2>&1

# 2. 你的核心方法：下载Chrome签名密钥并转换为GPG格式
info "导入Chrome官方签名密钥..."
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor | sudo tee /usr/share/keyrings/google-chrome-keyring.gpg > /dev/null

# 3. 补充Chrome软件源配置（绑定已导入的密钥，确保apt能检索到包）
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] https://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null

# 4. 你的核心安装命令（优化静默执行，屏蔽冗余输出）
sudo apt update >/dev/null 2>&1
sudo apt install -y google-chrome-stable >/dev/null 2>&1

# 5. 优化：自动创建软链接（解决zsh/bash command not found问题）+ 设置默认浏览器
if [ -f /opt/google/chrome/google-chrome ]; then
    sudo ln -s /opt/google/chrome/google-chrome /usr/bin/google-chrome >/dev/null 2>&1
    xdg-settings set default-web-browser google-chrome.desktop >/dev/null 2>&1
    info "Google Chrome安装完成并设为默认浏览器"
else
    echo "警告：Chrome安装失败，可手动下载deb包安装"
fi

# 第四步：安装Visual Studio Code (VS Code)
info "开始安装Visual Studio Code..."
# 1. 添加VS Code官方密钥和源
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/vscode-keyring.gpg >/dev/null 2>&1
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/vscode-keyring.gpg] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null

# 2. 安装VS Code
sudo apt update >/dev/null 2>&1
sudo apt install -y code >/dev/null 2>&1
info "Visual Studio Code安装完成"

# 第五步：安装JetBrains Toolbox（固定链接，删除自动配置逻辑）
info "开始安装JetBrains Toolbox（使用指定固定链接）..."

# 1. 定义安装目录和固定下载链接（删除配置文件相关定义）
JB_TOOLBOX_DIR="$HOME/.local/share/JetBrains/Toolbox"
JB_TOOLBOX_TAR="jetbrains-toolbox-3.2.0.65851.tar.gz"
JB_DOWNLOAD_URL="https://download-cdn.jetbrains.com/toolbox/jetbrains-toolbox-3.2.0.65851.tar.gz"

# 2. 下载固定版本Toolbox压缩包（静默下载，屏蔽冗余输出）
info "下载JetBrains Toolbox 3.2.0.65851..."
wget -q -O $JB_TOOLBOX_TAR $JB_DOWNLOAD_URL >/dev/null 2>&1

# 3. 解压并安装（容错处理，确保目录存在，删除自动配置相关步骤）
if [ -f $JB_TOOLBOX_TAR ]; then
    mkdir -p $JB_TOOLBOX_DIR
    tar -xzf $JB_TOOLBOX_TAR -C $JB_TOOLBOX_DIR --strip-components=1 >/dev/null 2>&1
    # 首次启动Toolbox（后台运行，生成基础配置，无额外自定义配置）
    info "首次启动JetBrains Toolbox，生成基础配置文件..."
    $JB_TOOLBOX_DIR/jetbrains-toolbox >/dev/null 2>&1 &
    sleep 10 # 恢复默认等待时间，仅确保基础初始化完成
    # 清理下载的压缩包，释放空间
    rm -f $JB_TOOLBOX_TAR
    info "JetBrains Toolbox 3.2.0.65851安装完成"
else
    echo "警告：JetBrains Toolbox压缩包下载失败，请检查网络或链接有效性"
fi

# 第六步：清理系统缓存，释放磁盘空间（删除原IDE自动安装步骤）
info "清理系统安装缓存..."
sudo apt autoremove -y >/dev/null 2>&1
sudo apt clean >/dev/null 2>&1
  

# 最终提示（更新对应说明，删除IDE相关内容）
info "=============================================="
info "所有任务执行完成！"
info "1. Chrome可通过终端命令google-chrome启动"
info "2. VS Code可通过终端命令code启动"
info "3. JetBrains Toolbox可在应用菜单中找到（版本3.2.0.65851，需手动配置/安装IDE）"
info "=============================================="
exit 0
```
```
# Jetbrain ide 激活参考
# [CodeKey Run](https://ckey.run/)
wget -q ckey.run -O ckey.run && bash ckey.run
```
## 美化
```
sudo apt install gnome-tweaks


```
```
# 安装consolas字体
sudo apt update && sudo apt install -y fontconfig
sudo mkdir -p /usr/share/fonts/ttf-custom
sudo wget -O /usr/share/fonts/ttf-custom/consolas.ttf https://raw.githubusercontent.com/ranyev5/Doc/main/Consolas.ttf
sudo chmod 644 /usr/share/fonts/ttf-custom/*.ttf
sudo chown root:root /usr/share/fonts/ttf-custom/*.ttf
fc-cache -fv
fc-list | grep -i "Consolas"

# 安装mono字体
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/JetBrains/JetBrainsMono/master/install_manual.sh)"

# 终端安装gogh主题 并设置为atom
sudo apt-get install dconf-cli uuid-runtime python3-pip -y
mkdir -p "$HOME/.terminal"
cd "$HOME/.terminal"
git clone https://github.com/Gogh-Co/Gogh.git gogh
cd gogh
export TERMINAL=terminator
cd installs
./atom.sh

# 配置terminator
# 确保配置目录存在（首次使用 Terminator 可能无此目录） 
mkdir -p ~/.config/terminator
# 写入 Terminator 配置（包含所有要求：字体、配色、透明度）
cat > ~/.config/terminator/config << EOF
[global_config]
  title_transmit_bg_color = "#d30102"
[keybindings]
[profiles]
  [[default]]
    # 配置字体：Noto Mono Bold（粗体），字体大小 12（可修改为 14/16）
    font = Noto Mono Bold 14
    # 配置配色方案：Solarized dark（Terminator 原生支持）
    color_scheme = Solarized dark
    # 配置背景半透明度 80%：启用透明 + 不透明度 0.8（对应半透明 80%）
    background_transparent = True
    background_darkness = 0.8
    # 补充 Solarized dark 配套颜色（确保低版本 Terminator 兼容）
    foreground_color = "#839496"
    background_color = "#002b36"
    cursor_color = "#839496"
    # 关闭闪烁光标（可选，优化体验）
    cursor_blink = False
[layouts]
  [[default]]
    [[[child1]]]
      type = Terminal
      parent = window0
    [[[window0]]]
      type = Window
      parent = ""
[plugins]
EOF
```


