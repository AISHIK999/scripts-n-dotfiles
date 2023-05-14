## Install Visual Studio Code
```bash
sudo pacman -S visual-studio-code-bin
```

**Some extensions that I use**

Name: GitHub Copilot
Id: GitHub.copilot
Description: Your AI pair programmer
Version: 1.84.51
Publisher: GitHub
VS Marketplace Link: https://marketplace.visualstudio.com/items?itemName=GitHub.copilot

Name: Gruvbox Material Icon Theme
Id: JonathanHarty.gruvbox-material-icon-theme
Description: Gruvbox Material Icons
Version: 1.1.5
Publisher: JonathanHarty
VS Marketplace Link: https://marketplace.visualstudio.com/items?itemName=JonathanHarty.gruvbox-material-icon-theme

Name: Gruvbox Theme
Id: jdinhlife.gruvbox
Description: Gruvbox Theme
Version: 1.8.0
Publisher: jdinhlife
VS Marketplace Link: https://marketplace.visualstudio.com/items?itemName=jdinhlife.gruvbox

Name: Python
Id: ms-python.python
Description: IntelliSense (Pylance), Linting, Debugging (multi-threaded, remote), Jupyter Notebooks, code formatting, refactoring, unit tests, and more.
Version: 2023.6.1
Publisher: Microsoft
VS Marketplace Link: https://marketplace.visualstudio.com/items?itemName=ms-python.python

Name: Live Server
Id: ritwickdey.LiveServer
Description: Launch a development local Server with live reload feature for static & dynamic pages
Version: 5.7.9
Publisher: Ritwick Dey
VS Marketplace Link: https://marketplace.visualstudio.com/items?itemName=ritwickdey.LiveServer

Name: Markdown All in One
Id: yzhang.markdown-all-in-one
Description: All you need to write Markdown (keyboard shortcuts, table of contents, auto preview and more)
Version: 3.5.1
Publisher: Yu Zhang
VS Marketplace Link: https://marketplace.visualstudio.com/items?itemName=yzhang.markdown-all-in-one

Name: Prettier - Code formatter
Id: esbenp.prettier-vscode
Description: Code formatter using prettier
Version: 9.12.0
Publisher: Prettier
VS Marketplace Link: https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode

Name: WakaTime
Id: WakaTime.vscode-wakatime
Description: Metrics, insights, and time tracking automatically generated from your programming activity.
Version: 24.0.10
Publisher: WakaTime
VS Marketplace Link: https://marketplace.visualstudio.com/items?itemName=WakaTime.vscode-wakatime

## Install Neovim
```bash
sudo pacman -S neovim
```

I use [NvChad](https://github.com/NvChad/NvChad) dotfiles\
Install NvChad
```bash
git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1 && nvim
```

Some extra plugins I use are [github copilot](https://github.com/github/copilot.vim) and [wakatime](https://github.com/wakatime/vim-wakatime)

Move the plugins.lua file to `~/.config/nvim/lua/custom

Copilot also needs nodejs and npm toi function
```bash
sudo pacman -S nodejs npm
```



