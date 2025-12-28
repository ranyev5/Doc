#!/bin/bash

# Ubuntu 24.04 完整安装与美化脚本
# 功能：一键完成系统基础配置、软件安装和界面美化

# 定义颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # 恢复默认颜色

# 函数：打印信息
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# 函数：打印警告
warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# 函数：打印错误
error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 函数：执行命令并检查结果
exec_cmd() {
    local cmd="$1"
    local desc="$2"
    local quiet="$3"
    
    if [ -z "$quiet" ]; then
        info "$desc..."
    fi
    
    if eval "$cmd" >/dev/null 2>&1; then
        return 0
    else
        error "$desc 失败"
        return 1
    fi
}

# 刷新 GNOME 扩展配置缓存
refresh_extension_cache() {
    info "刷新 GNOME 扩展配置缓存..."
    # 步骤1：刷新用户级桌面/扩展索引
    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database ~/.local/share/applications/ &> /dev/null
        info "桌面扩展索引刷新完成"
    fi

    # 步骤2：确保扩展目录权限正确
    chmod -R 755 ~/.local/share/gnome-shell/extensions/ &> /dev/null
    info "扩展目录权限已修复（755）"

    # 步骤3：重启 GNOME 扩展后台服务
    if command -v busctl &> /dev/null; then
        busctl --user restart org.gnome.Shell.Extensions &> /dev/null
        info "GNOME 扩展后台服务已重启"
    fi

    info "扩展配置缓存刷新完成"
}

# 安装 GNOME 扩展
install_gnome_extensions() {
    info "安装 GNOME 扩展..."
    
    # 配置区域
    EXTENSION_DOWNLOAD_URLS=(
        "https://extensions.gnome.org/extension-data/apps-menugnome-shell-extensions.gcampax.github.com.v61.shell-extension.zip"
        "https://extensions.gnome.org/extension-data/user-themegnome-shell-extensions.gcampax.github.com.v60.shell-extension.zip"
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
    
    # 检查必备工具
    if ! command -v gnome-extensions &> /dev/null; then
        error "未找到 gnome-extensions 命令，请先安装 GNOME 扩展核心依赖"
        return 1
    fi
    
    # 选择下载工具
    DOWNLOAD_TOOL=""
    if command -v wget &> /dev/null; then
        DOWNLOAD_TOOL="wget"
    elif command -v curl &> /dev/null; then
        DOWNLOAD_TOOL="curl"
    else
        error "未找到 wget 或 curl"
        return 1
    fi
    
    # 检查 GNOME Shell 版本
    if ! GNOME_VERSION=$(gnome-shell --version | awk '{print $3}'); then
        error "无法获取 GNOME Shell 版本"
        return 1
    fi
    info "当前 GNOME Shell 版本：$GNOME_VERSION"
    
    # 验证数组长度
    if [ "${#EXTENSION_DOWNLOAD_URLS[@]}" -ne "${#TARGET_EXTENSION_IDS[@]}" ]; then
        error "扩展配置错误：下载链接与扩展 ID 数量不一致"
        return 1
    fi
    
    # 批量处理扩展
    EXTENSION_SAVE_DIR="$HOME/Downloads/gnome-extensions-batch"
    mkdir -p "$EXTENSION_SAVE_DIR"
    
    SUCCESS_COUNT=0
    FAIL_COUNT=0
    
    for (( i=0; i<${#EXTENSION_DOWNLOAD_URLS[@]}; i++ )); do
        CURRENT_DOWNLOAD_URL=${EXTENSION_DOWNLOAD_URLS[$i]}
        CURRENT_EXTENSION_ID=${TARGET_EXTENSION_IDS[$i]}
        CURRENT_EXTENSION_ZIP_NAME=$(basename "$CURRENT_DOWNLOAD_URL")
        CURRENT_EXTENSION_ZIP_PATH="$EXTENSION_SAVE_DIR/$CURRENT_EXTENSION_ZIP_NAME"
        
        info "处理扩展：$CURRENT_EXTENSION_ID"
        
        # 下载扩展包
        if [ "$DOWNLOAD_TOOL" = "wget" ]; then
            wget -q -O "$CURRENT_EXTENSION_ZIP_PATH" "$CURRENT_DOWNLOAD_URL" || {
                error "下载失败: $CURRENT_DOWNLOAD_URL"
                FAIL_COUNT=$((FAIL_COUNT+1))
                continue
            }
        else
            curl -s -o "$CURRENT_EXTENSION_ZIP_PATH" "$CURRENT_DOWNLOAD_URL" || {
                error "下载失败: $CURRENT_DOWNLOAD_URL"
                FAIL_COUNT=$((FAIL_COUNT+1))
                continue
            }
        fi
        
        # 安装扩展
        gnome-extensions install -f "$CURRENT_EXTENSION_ZIP_PATH" &> /dev/null || {
            error "安装失败: $CURRENT_EXTENSION_ID"
            FAIL_COUNT=$((FAIL_COUNT+1))
            continue
        }
        
        # 刷新缓存
        refresh_extension_cache
        
        # 启用扩展
        if gnome-extensions list | grep -q "$CURRENT_EXTENSION_ID"; then
            gnome-extensions enable "$CURRENT_EXTENSION_ID" &> /dev/null || {
                error "启用失败: $CURRENT_EXTENSION_ID"
                FAIL_COUNT=$((FAIL_COUNT+1))
                continue
            }
        else
            error "未找到扩展 ID: $CURRENT_EXTENSION_ID"
            FAIL_COUNT=$((FAIL_COUNT+1))
            continue
        fi
        
        # 验证结果
        if gnome-extensions list --enabled | grep -q "$CURRENT_EXTENSION_ID"; then
            info "扩展 $CURRENT_EXTENSION_ID 安装并启用成功"
            SUCCESS_COUNT=$((SUCCESS_COUNT+1))
        else
            warn "扩展 $CURRENT_EXTENSION_ID 已安装，但未成功启用"
            FAIL_COUNT=$((FAIL_COUNT+1))
        fi
    done
    
    info "GNOME 扩展安装完成：成功 $SUCCESS_COUNT 个，失败 $FAIL_COUNT 个"
}

# 安装 Orchis 主题和 Tela 图标主题
install_themes() {
    info "安装 Orchis 主题和 Tela 图标主题..."
    
    # 检查依赖
    local dependencies=("git" "sassc" "gtk2-engines-murrine" "gnome-themes-extra")
    for dep in "${dependencies[@]}"; do
        if ! dpkg -s "$dep" &> /dev/null; then
            exec_cmd "sudo apt install -y $dep" "安装依赖 $dep"
        fi
    done
    
    # 安装 Orchis 主题
    local temp_dir=$(mktemp -d)
    git clone https://github.com/vinceliuice/Orchis-theme.git "$temp_dir/orchis" &> /dev/null
    cd "$temp_dir/orchis" || { error "无法进入 Orchis 目录"; return 1; }
    chmod +x install.sh
    ./install.sh -t all -c all -s all --tweaks macos &> /dev/null
    cd - || return
    rm -rf "$temp_dir/orchis"
    info "Orchis 主题安装完成"
    
    # 安装 Tela 图标主题
    git clone https://github.com/vinceliuice/Tela-icon-theme.git "$temp_dir/tela" &> /dev/null
    cd "$temp_dir/tela" || { error "无法进入 Tela 目录"; return 1; }
    chmod +x install.sh
    ./install.sh -a &> /dev/null
    cd - || return
    rm -rf "$temp_dir/tela"
    info "Tela 图标主题安装完成"
}

# 主函数
main() {
    info "========================================"
    info "Ubuntu 24.04 完整安装与美化脚本"
    info "========================================"
    
    # 检查系统版本
    if ! grep -q "24.04" /etc/os-release; then
        error "此脚本仅支持 Ubuntu 24.04 系统"
        exit 1
    fi
    
    # 步骤1：基础工具安装
    info ""
    info "步骤1：安装基础工具"
    exec_cmd "sudo apt update" "更新软件源"
    exec_cmd "sudo apt install -y vim git curl" "安装vim、git、curl"
    
    # 步骤2：配置sudo密码缓存时间
    info ""
    info "步骤2：配置sudo密码缓存时间"
    exec_cmd "sudo bash -c 'TARGET_TIMEOUT=30; if grep -q "^Defaults\\s\\+timestamp_timeout=" /etc/sudoers /etc/sudoers.d/* 2>/dev/null; then sed -i "s/^Defaults\\s\\+timestamp_timeout=.*/Defaults timestamp_timeout=\$TARGET_TIMEOUT/" /etc/sudoers; grep -rl "^Defaults\\s\\+timestamp_timeout=" /etc/sudoers.d/* 2>/dev/null | while read FILE; do sed -i "s/^Defaults\\s\\+timestamp_timeout=.*/Defaults timestamp_timeout=\$TARGET_TIMEOUT/" \$FILE; done; else echo "Defaults timestamp_timeout=\$TARGET_TIMEOUT" > /etc/sudoers.d/sudo-timeout; chmod 0440 /etc/sudoers.d/sudo-timeout; fi; visudo -c >/dev/null 2>&1'" "配置sudo密码缓存为30分钟"
    
    # 步骤3：更新software updater配置
    info ""
    info "步骤3：配置软件更新器"
    exec_cmd "sudo bash -c 'sed -i \"s/APT::Periodic::Update-Package-Lists \".*\";.*$/APT::Periodic::Update-Package-Lists \"0\";\"/ /etc/apt/apt.conf.d/10periodic; sed -i \"s/APT::Periodic::Download-Upgradeable-Packages \".*\";.*$/APT::Periodic::Download-Upgradeable-Packages \"0\";\"/ /etc/apt/apt.conf.d/10periodic; sed -i \"s/APT::Periodic::AutocleanInterval \".*\";.*$/APT::Periodic::AutocleanInterval \"7\";\"/ /etc/apt/apt.conf.d/10periodic; sed -i \"s/APT::Periodic::Unattended-Upgrade \".*\";.*$/APT::Periodic::Unattended-Upgrade \"0\";\"/ /etc/apt/apt.conf.d/10periodic; echo -e \"APT::Periodic::Update-Package-Lists \\\"0\\\";\nAPT::Periodic::Download-Upgradeable-Packages \\\"0\\\";\nAPT::Periodic::AutocleanInterval \\\"0\\\";\nAPT::Periodic::Unattended-Upgrade \\\"0\\\";\" > /etc/apt/apt.conf.d/20auto-upgrades'" "配置软件更新器"
    
    # 步骤4：安装代理工具
    info ""
    info "步骤4：安装代理工具"
    exec_cmd "mkdir -p ~/Downloads" "创建Downloads目录"
    exec_cmd "cd ~/Downloads && wget https://storage.abyss.moe/d/Proxy/Linux/clash-party-linux-1.8.9-amd64.deb" "下载Clash代理工具"
    exec_cmd "sudo dpkg -i ~/Downloads/clash-party-linux-1.8.9-amd64.deb" "安装Clash代理工具"
    
    # 步骤5：安装终端工具
    info ""
    info "步骤5：安装终端工具"
    exec_cmd "sudo apt install -y terminator autojump zsh" "安装terminator、autojump、zsh"
    exec_cmd "chsh -s $(which zsh)" "设置zsh为默认shell"
    exec_cmd "sh -c \"$(curl -fsSL https://install.ohmyz.sh/)\"" "安装Oh My Zsh"
    
    # 安装zsh插件
    exec_cmd "git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/plugins/zsh-autosuggestions" "安装zsh-autosuggestions插件"
    exec_cmd "git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/plugins/zsh-syntax-highlighting" "安装zsh-syntax-highlighting插件"
    
    # 修改zsh配置
    exec_cmd "sed -i.bak -e 's/^ZSH_THEME=.*/ZSH_THEME=\"agnoster\"/' -e 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting autojump extract sudo)/' ~/.zshrc" "配置zsh主题和插件"
    
    # 步骤6：安装常用软件
    info ""
    info "步骤6：安装常用软件"
    
    # 卸载Firefox
    exec_cmd "sudo snap remove --purge firefox" "卸载Firefox（snap版）"
    exec_cmd "sudo apt remove --purge -y firefox" "卸载Firefox（apt版）"
    exec_cmd "sudo apt autoremove -y" "清理系统"
    
    # 安装Google Chrome
    exec_cmd "sudo apt install -y wget apt-transport-https ca-certificates gnupg" "安装Chrome依赖"
    exec_cmd "wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor | sudo tee /usr/share/keyrings/google-chrome-keyring.gpg > /dev/null" "导入Chrome密钥"
    exec_cmd "echo \"deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] https://dl.google.com/linux/chrome/deb/ stable main\" | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null" "添加Chrome源"
    exec_cmd "sudo apt update" "更新软件源"
    exec_cmd "sudo apt install -y google-chrome-stable" "安装Chrome"
    exec_cmd "sudo ln -s /opt/google/chrome/google-chrome /usr/bin/google-chrome" "创建Chrome软链接"
    exec_cmd "xdg-settings set default-web-browser google-chrome.desktop" "设置Chrome为默认浏览器"
    
    # 安装VS Code
    exec_cmd "wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/vscode-keyring.gpg >/dev/null" "导入VS Code密钥"
    exec_cmd "echo \"deb [arch=amd64 signed-by=/usr/share/keyrings/vscode-keyring.gpg] https://packages.microsoft.com/repos/vscode stable main\" | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null" "添加VS Code源"
    exec_cmd "sudo apt update" "更新软件源"
    exec_cmd "sudo apt install -y code" "安装VS Code"
    
    # 安装JetBrains Toolbox
    local JB_TOOLBOX_DIR="$HOME/.local/share/JetBrains/Toolbox"
    local JB_TOOLBOX_TAR="jetbrains-toolbox-3.2.0.65851.tar.gz"
    local JB_DOWNLOAD_URL="https://download-cdn.jetbrains.com/toolbox/jetbrains-toolbox-3.2.0.65851.tar.gz"
    
    exec_cmd "wget -q -O $JB_TOOLBOX_TAR $JB_DOWNLOAD_URL" "下载JetBrains Toolbox"
    exec_cmd "mkdir -p $JB_TOOLBOX_DIR" "创建Toolbox目录"
    exec_cmd "tar -xzf $JB_TOOLBOX_TAR -C $JB_TOOLBOX_DIR --strip-components=1" "解压Toolbox"
    exec_cmd "$JB_TOOLBOX_DIR/jetbrains-toolbox >/dev/null 2>&1 & sleep 10" "首次启动Toolbox"
    exec_cmd "rm -f $JB_TOOLBOX_TAR" "清理安装文件"
    
    # 清理系统缓存
    exec_cmd "sudo apt autoremove -y && sudo apt clean" "清理系统缓存"
    
    # 步骤7：Jetbrain IDE激活参考
    info ""
    info "步骤7：Jetbrain IDE激活参考"
    info "使用以下命令获取激活码："
    info "wget -q ckey.run -O ckey.run && bash ckey.run"
    
    # 步骤8：美化
    info ""
    info "步骤8：系统美化"
    
    # 安装GNOME扩展相关工具
    exec_cmd "sudo apt install -y gnome-shell gnome-shell-extension-manager gnome-tweaks" "安装GNOME扩展工具"
    
    # 安装GNOME扩展
    install_gnome_extensions
    
    # 安装字体
    info "安装字体..."
    exec_cmd "sudo apt install -y fontconfig" "安装fontconfig"
    exec_cmd "sudo mkdir -p /usr/share/fonts/ttf-custom" "创建字体目录"
    exec_cmd "sudo cp ~/Documents/Obsidian/Consolas.ttf /usr/share/fonts/ttf-custom/" "复制Consolas字体（从当前目录）"
    exec_cmd "sudo chmod 644 /usr/share/fonts/ttf-custom/*.ttf" "设置字体权限"
    exec_cmd "sudo chown root:root /usr/share/fonts/ttf-custom/*.ttf" "设置字体所有者"
    exec_cmd "fc-cache -fv" "刷新字体缓存"
    exec_cmd "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/JetBrains/JetBrainsMono/master/install_manual.sh)\"" "安装JetBrains Mono字体"
    
    # 安装终端主题
    info "安装终端主题..."
    exec_cmd "sudo apt-get install -y dconf-cli uuid-runtime python3-pip" "安装主题依赖"
    exec_cmd "mkdir -p \"$HOME/.terminal\" && cd \"$HOME/.terminal\" && git clone https://github.com/Gogh-Co/Gogh.git gogh" "下载Gogh主题"
    exec_cmd "cd \"$HOME/.terminal/gogh\" && export TERMINAL=terminator && cd installs && ./atom.sh" "安装Atom终端主题"
    
    # 配置terminator
    info "配置Terminator..."
    exec_cmd "mkdir -p ~/.config/terminator" "创建Terminator配置目录"
    cat > ~/.config/terminator/config << EOF
[global_config]
  title_transmit_bg_color = "#d30102"
[keybindings]
[profiles]
  [[default]]
    font = Noto Mono Bold 14
    color_scheme = Solarized dark
    background_transparent = True
    background_darkness = 0.8
    foreground_color = "#839496"
    background_color = "#002b36"
    cursor_color = "#839496"
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
    
    # 安装主题
    install_themes
    
    # 完成提示
    info ""
    info "========================================"
    info "所有任务执行完成！"
    info "========================================"
    info "1. 终端已安装并配置完成（zsh + Oh My Zsh + 插件）"
    info "2. 常用软件已安装：Chrome、VS Code、JetBrains Toolbox"
    info "3. GNOME扩展已安装并启用"
    info "4. 系统主题和字体已美化"
    info ""
    info "注意事项："
    info "- 若使用 X11 环境：按下 Alt + F2，输入 r，回车即可立即生效所有扩展"
    info "- 若使用 Wayland 环境：请注销当前用户，重新登录即可生效所有扩展"
    info "- JetBrains IDE需要手动安装并激活"
    info "========================================"
}

# 调用主函数
main