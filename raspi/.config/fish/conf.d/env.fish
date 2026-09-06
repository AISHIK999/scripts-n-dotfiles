set -x MANROFFOPT "-c"
if type -q bat
    set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"
end

fish_add_path ~/.local/bin ~/.cargo/bin
fish_add_path /boot/dietpi /boot/dietpi/misc
