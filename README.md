# proit-dotfiles



Мой персональный конфиг для работы в WSL2 (Ubuntu) + Alacritty.



## 🛠 Что внутри:

* **Shell:** Fish + Starship prompt.

* **Navigation:** `fzf` для быстрого SSH (команда `s`).

* **Automation:** Ansible playbook для развертывания.



## ⚠️ Важно перед установкой (Windows)

1. Скачать и установить шрифт **[JetBrainsMono Nerd Font](https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip)**.

2. Без этого шрифта иконки в Starship и Alacritty будут отображаться как квадраты.



## 🚀 Как развернуть:

1. `git clone https://github.com/proit-top/proit-dotfiles.git ~/dotfiles`

2. `cd ~/dotfiles`

3. `ansible-playbook dotfile-ansible-setup.yml --ask-become-pass`


ПОЕЛСЕ ANSIBLE команды написать: 
source ~/.config/fish/config.fish
