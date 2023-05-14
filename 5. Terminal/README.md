## Install kitty terminal
```bash
sudo pacman -S kitty
```

## Kitty themes

(optional gruvbox theme) [Credits](https://github.com/wdomitrz/kitty-gruvbox-theme)
```bash
git clone https://github.com/wdomitrz/kitty-gruvbox-theme.git ~/.config/kitty/themes
```
My kitty config has been uploaded here

Change themes using
```bash
kitty +kitten themes
```

## Change shell
```bash
sudo pacman -S fish
```
Check where fish shell is located
```bash
cat /etc/shells
```

Change shell `chsh -s <path-to-shell> <username>`
```bash
chsh -s /usr/bin/fish aishik999
```

Restart terminal

Disable the default fish welcome message
```bash
set -U fish_greeting
```
Install fisher
```bash
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
```

Install tide
```bash
fisher install IlanCosman/tide@v5
```
Configure tide
```bash
tide configure
```





