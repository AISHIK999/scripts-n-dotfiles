## System update
```bash
sudo pacman -Syu
```

## Add chaotic-aur repo
```bash
wget https://aur.chaotic.cx/chaotic.gpg
```
```bash
sudo pacman-key --add chaotic.gpg
```
```bash
pacman-key --lsign-key FBA220DFC880C036
```
```bash
pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
```

Now edit `/etc/pacman.conf` and add the following lines at the end of the file:
```
[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
```

## Install pamac
```bash
sudo pacman -S pamac
```

## Install wayland session
```bash
sudo pacman -S plasma-wayland-session
```
Fix screen sharing issues for wayland
```
sudo pacman -S xdg-desktop-portal
```
