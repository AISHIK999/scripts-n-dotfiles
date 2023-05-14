## Install lutris
```bash
sudo pacman -S lutris
``` 
(Make sure to enable multilib support from `/etc/pacman.conf`)

Install respective drivers for your system from [Lutris docs](https://github.com/lutris/docs/blob/master/InstallingDrivers.md)

Install wine and it's dependencies:
```bash
sudo pacman -S wine winetricks
```
```bash
sudo pacman -S giflib lib32-giflib libpng lib32-libpng libldap lib32-libldap gnutls lib32-gnutls mpg123 lib32-mpg123 openal lib32-openal v4l-utils lib32-v4l-utils libpulse lib32-libpulse alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib libjpeg-turbo lib32-libjpeg-turbo libxcomposite lib32-libxcomposite libxinerama lib32-libxinerama ncurses lib32-ncurses opencl-icd-loader lib32-opencl-icd-loader libxslt lib32-libxslt libva lib32-libva gtk3 lib32-gtk3 gst-plugins-base-libs lib32-gst-plugins-base-libs vulkan-icd-loader lib32-vulkan-icd-loader cups samba dosbox
```

Install wine GE from their [release page](https://github.com/GloriousEggroll/wine-ge-custom/releases)\
Extract the downloaded archive and save it to the path: `/~/.local/share/lutris/runners/wine/`