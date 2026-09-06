# Directory listings
if type -q eza
    alias ls='eza -al --color=always --group-directories-first --icons=always'
    alias la='eza -a --color=always --group-directories-first --icons=always'
    alias ll='eza -l --color=always --group-directories-first --icons=always'
    alias lt='eza -aT --color=always --group-directories-first --icons=always'
    alias l.="eza -a | grep -e '^\.'"
else
    alias ls='ls -la --color=auto'
    alias la='ls -A --color=auto'
    alias ll='ls -l --color=auto'
    alias l.="ls -A | grep -e '^\.'"
end

if type -q bat
    alias cat='bat'
end

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# DietPi & APT Package Management
alias update='sudo dietpi-update && sudo apt update && sudo apt upgrade'
# alias apt-update='sudo apt update && sudo apt upgrade'
alias install='sudo apt install'
alias remove='sudo apt remove'
alias search='apt search'
alias cleanup='sudo apt autoremove --purge && sudo apt clean'
alias fixapt='sudo dpkg --configure -a && sudo apt --fix-broken install'

# Utilities
alias please='sudo'
alias tb='nc termbin.com 9999'
