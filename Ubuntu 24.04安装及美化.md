## 基础工具安装
``` shell
sudo apt update && sudo apt install vim -y
```
## 安装代理工具
``` shell
cd ~/Downloads
wget https://storage.abyss.moe/d/Proxy/Linux/clash-party-linux-1.8.9-amd64.deb
sudo dpkg -i ./clash-party-linux-1.8.9-amd64.deb
```
## 安装终端工具
``` shell
sudo apt update && sudo apt install terminator autojump zsh -y 
chsh -s $(which zsh)
cd ~/Downloads
wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O - | sh 
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/plugins/zsh-syntax-highlighting


```
