FROM archlinux/base:latest
RUN pacman -Syu --needed --noconfirm base-devel git sshpass
RUN pacman -Scc --noconfirm
RUN useradd -m -G wheel -s /bin/bash aurbuild
RUN echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel
USER aurbuild
WORKDIR /home/aurbuild
RUN mkdir src pkg .ssh
