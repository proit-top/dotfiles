starship init fish | source

# Проверка: если мы в интерактивном режиме и НЕ внутри tmux
if status is-interactive
    and not set -q TMUX
    # Пытаемся подключиться к сессии 'main', если её нет — создаем
    exec tmux new-session -A -s main
end

# Инициализация zoxide (команда z)
zoxide init fish | source

# Create aliases
alias cls="clear"
alias g="git"
alias n="nvim"
alias lsa="ls -la"
#alias m="micro"
#alias cat="bat"
#alias feh=="feh --scale-down"
#alias rm="rmt"

set -gx LS_COLORS "ow=01;34:tw=01;34:st=01;34"


# Настройка SSH Agent моста для KeePassXC
set -gx SSH_AUTH_SOCK "$HOME/.ssh/agent.sock"
if not ss -a | grep -q $SSH_AUTH_SOCK
    rm -f $SSH_AUTH_SOCK
    # Указываем полный путь к npiperelay.exe в папке пользователя Windows
    setsid nohup socat UNIX-LISTEN:$SSH_AUTH_SOCK,fork EXEC:"/mnt/c/Users/Nick/bin/npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork >/dev/null 2>&1 &
end


function s
    # ищем во всех файлах ssh_config в папке dotfiles
    set -l target (grep -i '^Host ' ~/dotfiles/ssh_config ~/dotfiles/ssh_config_local 2>/dev/null | awk '{print $NF}' | grep -v '*' | sort -u | fzf --height 40% --reverse --border --header="Выберите сервер:")

    if test -n "$target"
        # Подключаемся, используя основной конфиг (он сам подтянет local через Include)
        ssh -F ~/dotfiles/ssh_config $target
    end
end


function scopy
    # 1. Выбор ключа
    set -l key_line (ssh-add -L | fzf --height 40% --reverse --border --header="1. Выберите КЛЮЧ:")
    if test -z "$key_line"; echo "Отмена: Ключ не выбран"; return; end

    # 2. Выбор сервера или ручной ввод
    set -l servers (grep -i '^Host ' ~/dotfiles/ssh_config ~/dotfiles/ssh_config_local 2>/dev/null | awk '{print $NF}' | grep -v '*' | sort -u)
    set -l target (begin; echo "--- ВВЕСТИ ВРУЧНУЮ ---"; printf '%s\n' $servers; end | fzf --height 40% --reverse --border --header="2. Выберите СЕРВЕР:")

    if test -z "$target" -o "$target" = ""; echo "Отмена: Цель не выбрана"; return; end

    if test "$target" = "--- ВВЕСТИ ВРУЧНУЮ ---"
        read -p "echo 'Введите user@host: '" target
        if test -z "$target"; return; end
    end

    # 3. Подготовка ключа во временном файле
    set -l tmp_key (mktemp).pub
    echo "$key_line" > $tmp_key

    echo "Попытка копирования ключа на $target..."


    # 4. Копирование ключа
    # Используем -F для подхвата всех конфигов, включая кастомные порты
    if ssh-copy-id -F ~/dotfiles/ssh_config -i $tmp_key $target
        echo "Успех: Ключ скопирован на $target"
    else
        echo "Ошибка: Не удалось скопировать ключ. Проверьте доступность SSH вручную."
    end

    # Удаляем временный файл

    rm -f $tmp_key
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

        # Проверка: доступен ли сервер вообще (таймаут 3 сек)
        echo "🔍 Проверка связи с $target..."
        if not timeout 3s ssh -F ~/dotfiles/ssh_config -o ConnectTimeout=2 $target "true" 2>/dev/null
            echo "❌ Сервер $target недоступен или SSH не отвечает."
            return
        end

        echo "🚀 Монтирую $target..."

        # Добавляем -o BatchMode=no, чтобы он мог спросить пароль, если нужно
        # И убираем лишние опции для теста
        sshfs "$target:/" "$mount_path" \
            -o ssh_command="ssh -F $HOME/dotfiles/ssh_config" \
            -o reconnect,follow_symlinks

        if test $status -eq 0
            echo "✨ Готово! cd $mount_path"
            cd $mount_path
        else
            # Если не вышло, пробуем размонтировать "мусор"
            fusermount -u $mount_path 2>/dev/null
            echo "❌ Ошибка. Попробуй: sftp -F ~/dotfiles/ssh_config $target"
        end
    end
end
