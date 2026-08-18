starship init fish | source


function load_env
    if test -f .env
        for line in (cat .env | grep -v '^#' | grep -v '^\s*$')
            set -l item (string split -m 1 = $line)
            if test (count $item) -eq 2
                set -gx $item[1] $item[2]
            end
        end
        echo "Переменные из .env загружены."
    end
end

#set -g fish_greeting ""

if test -d /home/linuxbrew/.linuxbrew
    eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
end

if not set -q CUDA_HOME
    set -gx CUDA_HOME /usr
end

set -gx EDITOR nvim


zoxide init fish | source

# Список команд, которые мы хотим раскрасить
set -l colored_cmds ping traceroute ip netstat df mount lsblk cat bat

for cmd in $colored_cmds
    # Проверяем, существует ли сама команда в системе
    if type -q $cmd
        # Создаем функцию-обертку, которая вызывает grc для этой команды
        eval "function $cmd; grc --colour=auto $cmd \$argv; end"
    end
end

alias cls="tput cup 0 0"
alias g="git"
alias lg='lazygit'
alias n="nvim"
alias ls='lsd'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'
#alias cat='batcat'
alias ai="npx @google/gemini-cli"


set -gx LS_COLORS "ow=01;34:tw=01;34:st=01;34"


# Настройка SSH Agent моста для KeePassXC
set -gx SSH_AUTH_SOCK "$HOME/.ssh/agent.sock"
if not ss -a | grep -q $SSH_AUTH_SOCK
    rm -f $SSH_AUTH_SOCK
    setsid nohup socat UNIX-LISTEN:$SSH_AUTH_SOCK,fork EXEC:"/mnt/c/Users/Nick/bin/npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork >/dev/null 2>&1 &
end


function s
    set -l target (grep -i '^Host ' ~/dotfiles/ssh_config ~/dotfiles/ssh_config_local 2>/dev/null | awk '{print $NF}' | grep -v '*' | sort -u | fzf --height 40% --reverse --border --header="Выберите сервер:")
    if test -n "$target"
        ssh -F ~/dotfiles/ssh_config $target
    end
end


function scopy
    set -l key_line (ssh-add -L | fzf --height 40% --reverse --border --header="1. Выберите КЛЮЧ:")
    if test -z "$key_line"
        echo "Отмена: Ключ не выбран"
        return
    end
    set -l servers (grep -i '^Host ' ~/dotfiles/ssh_config ~/dotfiles/ssh_config_local 2>/dev/null | awk '{print $NF}' | grep -v '*' | sort -u)
    set -l target (begin; echo "--- ВВЕСТИ ВРУЧНУЮ ---"; printf '%s\n' $servers; end | fzf --height 40% --reverse --border --header="2. Выберите СЕРВЕР:")

    if test -z "$target" -o "$target" = ""
        echo "Отмена: Цель не выбрана"
        return
    end
    if test "$target" = "--- ВВЕСТИ ВРУЧНУЮ ---"
        read -p "echo 'Введите user@host: '" target
        if test -z "$target"
            return
        end
    end
    set -l tmp_key (mktemp).pub
    echo "$key_line" >$tmp_key
    echo "Попытка копирования ключа на $target..."
    if ssh-copy-id -F ~/dotfiles/ssh_config -i $tmp_key $target
        echo "Успех: Ключ скопирован на $target"
    else
        echo "Ошибка: Не удалось скопировать ключ. Проверьте доступность SSH вручную."
    end

    rm -f $tmp_key
end

function scopyw
    set -l key_line (ssh-add -L | fzf --height 40% --reverse --header="Выберите КЛЮЧ:")

    if test -z "$key_line"
        return
    end
    set -l target (grep -i '^Host ' ~/dotfiles/ssh_config ~/dotfiles/ssh_config_local 2>/dev/null | awk '{print $NF}' | grep -v '*' | sort -u | fzf --height 40% --reverse --header="Выберите Windows СЕРВЕР:")
    if test -z "$target"
        return
    end
    echo "🚀 Добавляю ключ на $target..."
    ssh -F ~/dotfiles/ssh_config $target "powershell -Command \"if (!(Test-Path 'C:\ProgramData\ssh')) { New-Item -ItemType Directory -Path 'C:\ProgramData\ssh' }; Add-Content -Path 'C:\ProgramData\ssh\administrators_authorized_keys' -Value '$key_line'\""
    echo "✅ Ключ отправлен. ВАЖНО: Если вход не работает, выполните на сервере:"
    echo "icacls.exe \"C:\ProgramData\ssh\administrators_authorized_keys\" /inheritance:r /grant \"Administrators:F\" /grant \"SYSTEM:F\""
end

function smount
    set -l target (grep -i '^Host ' ~/dotfiles/ssh_config ~/dotfiles/ssh_config_local 2>/dev/null | awk '{print $NF}' | grep -v '*' | sort -u | fzf --height 40% --reverse --border --header="Выберите сервер для МОНТИРОВАНИЯ:")

    if test -n "$target"
        set -l mount_path "$HOME/remote_server/$target"
        mkdir -p $mount_path

        if mountpoint -q $mount_path
            echo "✅ Сервер $target уже смонтирован"
            cd $mount_path
            return
        end
        echo "🔍 Проверка связи с $target..."
        if not timeout 3s ssh -F ~/dotfiles/ssh_config -o ConnectTimeout=2 $target true 2>/dev/null
            echo "❌ Сервер $target недоступен или SSH не отвечает."
            return
        end
        echo "🚀 Монтирую $target..."
        sshfs "$target:/" "$mount_path" \
            -o ssh_command="ssh -F $HOME/dotfiles/ssh_config" \
            -o reconnect,follow_symlinks
        if test $status -eq 0
            echo "✨ Готово! cd $mount_path"
            cd $mount_path
        else
            fusermount -u $mount_path 2>/dev/null
            echo "❌ Ошибка. Попробуй: sftp -F ~/dotfiles/ssh_config $target"
        end
    end
end

function sumount
    # Выводит список уже смонтированных папок в ~/remote_server
    set -l target (mount | grep "sshfs" | awk '{print $3}' | fzf --height 40% --reverse --header="Выберите что отмонтировать:")

    if test -n "$target"
        fusermount -u $target
        echo "✅ Папка $target размонтирована."
    end
end




# Автозапуск tmux (в конце, чтобы функции и ssh-агент определились раньше)
# Отключить автозапуск (нужно для herdr в чистом терминале): HERDR_NO_TMUX=1
if status is-interactive
    and not set -q TMUX
    and not set -q HERDR_NO_TMUX
    tmux new-session -A -s main
end


#if test -f .env
#    load_env
#end
