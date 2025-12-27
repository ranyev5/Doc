## 基础工具安装
``` shell
sudo apt update && sudo apt install vim git curl -y
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
git clone https://github.com/wting/autojump.git ~/.oh-my-zsh/plugins/autojump
# 安装autojump
cd ~/.oh-my-zsh/plugins/autojump
/install.py
# 修改配置文件
sed -i.bak \
  -e 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' \
  -e 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting autojump extract sudo)/' \
  ~/.zshrc
```
