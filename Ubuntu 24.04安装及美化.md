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
# 执行该命令，其他相关库会自动安装 
sudo apt install gnome-shell gnome-shell-extension-manager gnome-tweaks -y
# 安装ocs-url
wget -q -O /tmp/ocs-url_3.1.0-0ubuntu1_amd64.deb "https://ocs-dl.fra1.cdn.digitaloceanspaces.com/data/files/1467909105/ocs-url_3.1.0-0ubuntu1_amd64.deb?response-content-disposition=attachment%3B%2520ocs-url_3.1.0-0ubuntu1_amd64.deb&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=RWJAQUNCHT7V2NCLZ2AL%2F20251227%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20251227T174241Z&X-Amz-SignedHeaders=host&X-Amz-Expires=3600&X-Amz-Signature=976ab1f1db395dd0631acd296cededd528b66135c5ee0b28d105b594dc7c15ac" && \
sudo apt install -y /tmp/ocs-url_3.1.0-0ubuntu1_amd64.deb && \
rm -f /tmp/ocs-url_3.1.0-0ubuntu1_amd64.deb
```
```
#!/bin/bash

# GNOME 扩展 一键批量下载+安装+启用脚本（集成缓存刷新，解决list查询不到问题）

# 说明：在配置区域添加多个扩展的「下载链接」和「扩展 ID」即可批量处理

  

# ===================== 配置区域（需手动修改，支持添加多个扩展）=====================

EXTENSION_DOWNLOAD_URLS=(

    # 示例1：Apps Menu 扩展

    "https://extensions.gnome.org/extension-data/apps-menugnome-shell-extensions.gcampax.github.com.v61.shell-extension.zip"

    # 示例2：User Themes 扩展

    "https://extensions.gnome.org/extension-data/user-themegnome-shell-extensions.gcampax.github.com.v60.shell-extension.zip"

    #  Dish To Dock

    "https://extensions.gnome.org/extension-data/dash-to-dockmicxgx.gmail.com.v102.shell-extension.zip"

    "https://extensions.gnome.org/extension-data/clipboard-indicatortudmotu.com.v69.shell-extension.zip"

    "https://extensions.gnome.org/extension-data/CoverflowAltTabpalatis.blogspot.com.v77.shell-extension.zip"

)

  

TARGET_EXTENSION_IDS=(

    "apps-menu@gnome-shell-extensions.gcampax.github.com"

    "user-theme@gnome-shell-extensions.gcampax.github.com"

    "dash-to-dock@micxgx.gmail.com"

    "clipboard-indicator@tudmotu.com"

    "CoverflowAltTab@palatis.blogspot.com"

)

# =================================================================

  

# ===================== 脚本核心逻辑（无需修改）=====================

# 定义颜色输出

RED='\033[0;31m'

GREEN='\033[0;32m'

YELLOW='\033[1;33m'

NC='\033[0m' # 恢复默认颜色

  

# 函数：打印信息

info_log() {

    echo -e "${GREEN}[INFO]${NC} $1"

}

  

# 函数：打印警告

warn_log() {

    echo -e "${YELLOW}[WARN]${NC} $1"

}

  

# 函数：打印错误并退出（全局致命错误）

error_log() {

    echo -e "${RED}[ERROR]${NC} $1"

    exit 1

}

  

# 函数：打印单个扩展操作错误（不终止批量流程）

ext_error_log() {

    echo -e "${RED}[EXT-ERROR]${NC} $1"

}

  

# 新增函数：刷新 GNOME 扩展配置缓存（核心解决list查询不到问题）

refresh_extension_cache() {

    info_log "正在刷新 GNOME 扩展配置缓存..."

    # 步骤1：刷新用户级桌面/扩展索引（无侵入，优先推荐）

    if command -v update-desktop-database &> /dev/null; then

        update-desktop-database ~/.local/share/applications/ &> /dev/null

        info_log "步骤1：桌面扩展索引刷新完成"

    else

        warn_log "步骤1：未找到 update-desktop-database，跳过该刷新方式"

    fi

  

    # 步骤2：确保扩展目录权限正确（避免权限问题导致无法识别）

    chmod -R 755 ~/.local/share/gnome-shell/extensions/ &> /dev/null

    info_log "步骤2：扩展目录权限已修复（755）"

  

    # 步骤3：重启 GNOME 扩展后台服务（强有效，备用）

    if command -v busctl &> /dev/null; then

        busctl --user restart org.gnome.Shell.Extensions &> /dev/null

        info_log "步骤3：GNOME 扩展后台服务已重启"

    else

        warn_log "步骤3：未找到 busctl，跳过服务重启（部分发行版无需此步骤）"

    fi

  

    info_log "扩展配置缓存刷新完成，可立即查询新安装扩展"

}

  

# 步骤1：检查必备工具是否安装

info_log "===== 步骤1：检查必备全局工具 ====="

if ! command -v gnome-extensions &> /dev/null; then

    error_log "未找到 gnome-extensions 命令，请先安装 GNOME 扩展核心依赖（gnome-shell-extensions）"

fi

  

# 选择下载工具（优先 wget，无则用 curl）

DOWNLOAD_TOOL=""

if command -v wget &> /dev/null; then

    DOWNLOAD_TOOL="wget"

    info_log "检测到 wget，将使用 wget 进行下载"

elif command -v curl &> /dev/null; then

    DOWNLOAD_TOOL="curl"

    info_log "检测到 curl，将使用 curl 进行下载"

else

    error_log "未找到 wget 或 curl，请先安装其中一个下载工具（sudo apt install wget/curl）"

fi

  

# 步骤2：检查 GNOME Shell 版本

info_log "\n===== 步骤2：检查 GNOME Shell 版本 ====="

if ! GNOME_VERSION=$(gnome-shell --version | awk '{print $3}'); then

    error_log "无法获取 GNOME Shell 版本，请确认已安装 GNOME 桌面环境"

fi

info_log "当前 GNOME Shell 版本：$GNOME_VERSION"

warn_log "请确保所有下载的扩展与该版本兼容，否则可能无法正常工作"

  

# 步骤3：验证两个数组长度是否一致

info_log "\n===== 步骤3：验证扩展配置信息 ====="

DOWNLOAD_URLS_LEN=${#EXTENSION_DOWNLOAD_URLS[@]}

EXTENSION_IDS_LEN=${#TARGET_EXTENSION_IDS[@]}

  

if [ "$DOWNLOAD_URLS_LEN" -ne "$EXTENSION_IDS_LEN" ]; then

    error_log "配置错误！下载链接数组长度（$DOWNLOAD_URLS_LEN）与扩展 ID 数组长度（$EXTENSION_IDS_LEN）不一致，请检查配置区域"

fi

info_log "验证通过，共配置 $DOWNLOAD_URLS_LEN 个扩展，将开始批量处理"

  

# 步骤4：批量处理每个扩展（下载→安装→【缓存刷新】→启用→验证）

info_log "\n===== 步骤4：开始批量处理扩展 ====="

EXTENSION_SAVE_DIR="$HOME/Downloads/gnome-extensions-batch"

mkdir -p "$EXTENSION_SAVE_DIR"

  

# 定义成功/失败统计变量

SUCCESS_COUNT=0

FAIL_COUNT=0

  

# 循环遍历数组，处理每个扩展

for (( i=0; i<DOWNLOAD_URLS_LEN; i++ )); do

    # 提取当前扩展的下载链接和 ID

    CURRENT_DOWNLOAD_URL=${EXTENSION_DOWNLOAD_URLS[$i]}

    CURRENT_EXTENSION_ID=${TARGET_EXTENSION_IDS[$i]}

    CURRENT_EXTENSION_ZIP_NAME=$(basename "$CURRENT_DOWNLOAD_URL")

    CURRENT_EXTENSION_ZIP_PATH="$EXTENSION_SAVE_DIR/$CURRENT_EXTENSION_ZIP_NAME"

  

    # 打印当前处理的扩展信息

    info_log "\n====================================="

    info_log "正在处理第 $((i+1))/$DOWNLOAD_URLS_LEN 个扩展：$CURRENT_EXTENSION_ID"

    info_log "====================================="

  

    # 子步骤1：下载当前扩展包

    info_log "子步骤1：下载扩展包"

    if [ "$DOWNLOAD_TOOL" = "wget" ]; then

        wget -q -O "$CURRENT_EXTENSION_ZIP_PATH" "$CURRENT_DOWNLOAD_URL" || {

            ext_error_log "第 $((i+1)) 个扩展下载失败，请检查链接是否有效：$CURRENT_DOWNLOAD_URL"

            FAIL_COUNT=$((FAIL_COUNT+1))

            continue

        }

    else

        curl -s -o "$CURRENT_EXTENSION_ZIP_PATH" "$CURRENT_DOWNLOAD_URL" || {

            ext_error_log "第 $((i+1)) 个扩展下载失败，请检查链接是否有效：$CURRENT_DOWNLOAD_URL"

            FAIL_COUNT=$((FAIL_COUNT+1))

            continue

        }

    fi

  

    # 验证下载文件是否存在

    if [ ! -f "$CURRENT_EXTENSION_ZIP_PATH" ]; then

        ext_error_log "第 $((i+1)) 个扩展下载失败，未找到文件：$CURRENT_EXTENSION_ZIP_PATH"

        FAIL_COUNT=$((FAIL_COUNT+1))

        continue

    fi

    info_log "扩展包已成功下载到：$CURRENT_EXTENSION_ZIP_PATH"

  

    # 子步骤2：安装当前扩展（强制覆盖已安装版本）

    info_log "子步骤2：安装扩展"

    gnome-extensions install -f "$CURRENT_EXTENSION_ZIP_PATH" &> /dev/null || {

        ext_error_log "第 $((i+1)) 个扩展安装失败：$CURRENT_EXTENSION_ID"

        FAIL_COUNT=$((FAIL_COUNT+1))

        continue

    }

    info_log "扩展已成功安装（强制覆盖已存在版本）"

  

    # 子步骤3：刷新缓存（关键！解决安装后list查询不到的问题）

    info_log "子步骤3：刷新扩展配置缓存"

    refresh_extension_cache

  

    # 子步骤4：启用当前扩展

    info_log "子步骤4：启用扩展"

    # 先检查扩展是否已安装（此时缓存已刷新，可正常查询）

    if ! gnome-extensions list | grep -q "$CURRENT_EXTENSION_ID"; then

        ext_error_log "第 $((i+1)) 个扩展未找到 ID：$CURRENT_EXTENSION_ID，启用失败（可能是缓存刷新失败或扩展包损坏）"

        FAIL_COUNT=$((FAIL_COUNT+1))

        continue

    fi

  

    # 启用扩展

    gnome-extensions enable "$CURRENT_EXTENSION_ID" &> /dev/null || {

        ext_error_log "第 $((i+1)) 个扩展启用失败，可能是版本不兼容：$CURRENT_EXTENSION_ID"

        FAIL_COUNT=$((FAIL_COUNT+1))

        continue

    }

    info_log "扩展已成功启用：$CURRENT_EXTENSION_ID"

  

    # 子步骤5：验证当前扩展结果

    info_log "子步骤5：验证安装结果"

    if gnome-extensions list --enabled | grep -q "$CURRENT_EXTENSION_ID"; then

        info_log "第 $((i+1)) 个扩展：安装并启用成功"

        SUCCESS_COUNT=$((SUCCESS_COUNT+1))

    else

        warn_log "第 $((i+1)) 个扩展：已安装，但未成功启用，请手动检查"

        FAIL_COUNT=$((FAIL_COUNT+1))

    fi

done

  

# 步骤5：批量处理总结

info_log "\n===== 步骤5：批量处理完成总结 ====="

info_log "${GREEN}成功处理：$SUCCESS_COUNT 个扩展${NC}"

if [ "$FAIL_COUNT" -gt 0 ]; then

    warn_log "${RED}失败处理：$FAIL_COUNT 个扩展${NC}，请查看上方错误日志排查问题"

else

    info_log "${GREEN}所有扩展均处理成功！${NC}"

fi

  

# 步骤6：给出生效提示

info_log "\n===== 生效说明 ====="

info_log "1. 若使用 X11 环境：按下 Alt + F2，输入 r，回车即可立即生效所有扩展"

info_log "2. 若使用 Wayland 环境：请注销当前用户，重新登录即可生效所有扩展"

info_log "3. 查看单个扩展详细信息：gnome-extensions info 扩展ID"

info_log "4. 查看所有已启用扩展：gnome-extensions list --enabled"
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


