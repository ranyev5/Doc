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
# 功能：Ubuntu24.04桌面版一键部署：卸载Firefox+安装Chrome(默认)+VS Code+JetBrains Toolbox+PyCharm/Goland/CLion
# 要求：以普通用户执行（含sudo权限，脚本内会请求密码）
# 注意：执行前确保网络通畅，全程约10-20分钟（取决于网络速度）
# 定义颜色输出（可选，方便查看执行状态）
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # 恢复默认颜色

# 函数：输出信息提示
info() {
    echo -e "${GREEN}[INFO] $1${NC}"
}
warn() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}
error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}
# 第一步：校验系统版本（确保是Ubuntu24.04）
info "正在校验系统版本..."
if [ ! -f /etc/os-release ] || ! grep -q "24.04" /etc/os-release; then
    error "此脚本仅支持Ubuntu24.04系统，当前系统不匹配！"
fi

# 第二步：卸载原生Firefox浏览器
info "开始卸载原生Firefox浏览器..."
# Ubuntu24.04原生Firefox为snap包，同时兼容deb包卸载
sudo snap remove --purge firefox 2>/dev/null
sudo apt remove --purge firefox -y 2>/dev/null
sudo apt autoremove -y >/dev/null 2>&1
info "Firefox卸载完成（若未安装，忽略相关报错）"

# 第三步：安装Google Chrome并设为默认浏览器
info "开始安装Google Chrome浏览器..."
# 1. 安装依赖包
sudo apt update >/dev/null 2>&1
sudo apt install -y wget apt-transport-https ca-certificates gnupg -y >/dev/null 2>&1
# 2. 添加Chrome官方软件源密钥
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo gnupg --dearmor -o /usr/share/keyrings/google-chrome-keyring.gpg >/dev/null 2>&1
# 3. 添加Chrome软件源
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] https://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list >/dev/null
# 4. 安装Chrome稳定版
sudo apt update >/dev/null 2>&1
sudo apt install -y google-chrome-stable >/dev/null 2>&1 
# 5. 设置Chrome为默认浏览器
info "将Chrome设置为系统默认浏览器..."
xdg-settings set default-web-browser google-chrome.desktop >/dev/null 2>&1
info "Google Chrome安装并设为默认浏览器完成"

# 第四步：安装Visual Studio Code (VS Code)
info "开始安装Visual Studio Code..."
# 1. 添加VS Code官方密钥
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/vscode-keyring.gpg >/dev/null 2>&1
# 2. 添加VS Code软件源
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/vscode-keyring.gpg] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null

# 3. 安装VS Code
sudo apt update >/dev/null 2>&1
sudo apt install -y code >/dev/null 2>&1
info "Visual Studio Code安装完成"

# 第五步：安装JetBrains Toolbox
info "开始安装JetBrains Toolbox..."
# 1. 定义安装目录和下载地址（适配最新版，自动获取64位包）
JB_TOOLBOX_DIR="$HOME/.local/share/JetBrains/Toolbox"
JB_TOOLBOX_TAR="jetbrains-toolbox.tar.gz"
JB_DOWNLOAD_URL=$(wget -qO- https://data.services.jetbrains.com/products/releases?code=TB&latest=true&type=release | grep -o '"linux":".*?.tar.gz"' | cut -d'"' -f4)

# 2. 下载JetBrains Toolbox
wget -q -O $JB_TOOLBOX_TAR $JB_DOWNLOAD_URL >/dev/null 2>&1
if [ ! -f $JB_TOOLBOX_TAR ]; then
    error "JetBrains Toolbox下载失败，请检查网络连接！"
fi
# 3. 创建安装目录并解压
mkdir -p $JB_TOOLBOX_DIR
tar -xzf $JB_TOOLBOX_TAR -C $JB_TOOLBOX_DIR --strip-components=1 >/dev/null 2>&1
# 4. 启动Toolbox（首次启动生成配置，后台运行）
info "首次启动JetBrains Toolbox，生成配置文件..."
$JB_TOOLBOX_DIR/jetbrains-toolbox >/dev/null 2>&1 &
sleep 10 # 等待Toolbox初始化完成
# 5. 清理下载包
rm -f $JB_TOOLBOX_TAR
info "JetBrains Toolbox安装完成"
# 第六步：通过JetBrains Toolbox安装PyCharm/Goland/CLion
info "开始通过JetBrains Toolbox安装PyCharm、Goland、CLion..."
# 1. 定义Toolbox命令行工具路径（初始化后生成）
JB_TOOLBOX_CLI="$HOME/.local/share/JetBrains/Toolbox/bin/jetbrains-toolbox"
# 2. 等待CLI工具生成（防止未初始化完成）
for i in {1..10}; do
    if [ -f $JB_TOOLBOX_CLI ]; then
        break
    fi
    sleep 3
done
if [ ! -f $JB_TOOLBOX_CLI ]; then
    warn "JetBrains Toolbox CLI工具未找到，将跳过自动安装IDE（可手动打开Toolbox安装）"
else
    # 3. 安装各IDE（--silent 静默安装，无图形界面交互）
    $JB_TOOLBOX_CLI install pycharm-professional --silent >/dev/null 2>&1 &
    $JB_TOOLBOX_CLI install goland --silent >/dev/null 2>&1 &
    $JB_TOOLBOX_CLI install clion --silent >/dev/null 2>&1 &
    # 4. 等待安装启动（后台安装，进度可在Toolbox图形界面查看）
    sleep 15
    info "PyCharm、Goland、CLion已启动后台安装，可打开JetBrains Toolbox查看安装进度"
fi
# 第七步：清理系统缓存，完成部署
info "清理系统安装缓存..."
sudo apt autoremove -y >/dev/null 2>&1
sudo apt clean >/dev/null 2>&1
# 最终提示
info "=============================================="
info "所有任务执行完成！"
info "1. Firefox已卸载"
info "2. Chrome已安装并设为默认浏览器（可直接启动）"
info "3. VS Code已安装（终端输入code启动）"
info "4. JetBrains Toolbox已安装（应用菜单中可找到）"
info "5. PyCharm/Goland/CLion已启动后台安装（查看Toolbox进度）"
info "=============================================="
exit 0
```