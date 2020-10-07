# ==============================================================================
# Copyright 2020 The Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ==============================================================================

FROM tensorflow/tensorflow:nightly-custom-op-ubuntu16
#FROM tensorflow/tensorflow:latest-devel-py3

RUN apt update

# Development Tools
RUN apt install -y curl wget tree less git vim tmux htop

# Compilers
RUN apt install clang-8 lld-8 -y

# ONNX-mlir dependencies
RUN apt install -y libncurses-dev
# Due to old version on apt, these are compiled from source
# RUN apt install -y protobuf-compiler libprotobuf-dev

# Requirements for VSCODE plugins
WORkDIR /usr/local/bin
RUN wget -q https://github.com/bazelbuild/buildtools/releases/download/3.2.1/buildifier -O buildifier

# Tools to profile x86 code 
# RUN apt install -y perf

WORKDIR /tmp
RUN wget https://github.com/Kitware/CMake/releases/download/v3.18.2/cmake-3.18.2-Linux-x86_64.sh && \
    chmod +x cmake-3.18.2-Linux-x86_64.sh && \
    ./cmake-3.18.2-Linux-x86_64.sh --skip-license --prefix=/usr/local

RUN wget https://github.com/ninja-build/ninja/releases/download/v1.10.1/ninja-linux.zip && \
    unzip ninja-linux.zip && \
    mv ninja /usr/local/bin/ninja && \
    ln -s /usr/local/bin/ninja /usr/sbin/ninja

 
# # Clone flame graphs for profiling
# WORKDIR /root/src
# RUN git clone https://github.com/brendangregg/FlameGraph

# Setup some convenient tools/functionalities
WORKDIR /root
RUN git clone https://github.com/agostini01/dotfiles.git && \
    \
    ln -sf dotfiles/.gitignore_global .gitignore_global && \
    \
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim && \
    \
    ln -sf dotfiles/.vimrc            .vimrc && \
    ln -sf dotfiles/.ctags            .ctags && \
    ln -sf dotfiles/.inputrc          .inputrc && \
    \
    git clone https://github.com/tmux-plugins/tpm /root/.tmux/plugins/tpm && \
    ln -sf dotfiles/.tmux.conf        .tmux.conf

RUN echo "PS1='\[\033[01;31m\][\[\033[01;30m\]\u@\h\[\033[01;36m\] \W\[\033[01;31m\]]\$\[\033[00m\] '" >> .bashrc


# ============================================================================
# Add dev user with matching UID of the user who build the image
ARG USER_ID
ARG GROUP_ID
RUN useradd -m --uid $USER_ID developer && \
    echo "developer:devpasswd" | chpasswd && \
    usermod -aG dialout developer && \
    usermod -aG sudo developer

USER developer
WORKDIR /home/developer
RUN git clone https://github.com/agostini01/dotfiles.git && \
    \
    ln -sf dotfiles/.gitignore_global .gitignore_global && \
    \
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim && \
    \
    ln -sf dotfiles/.vimrc            .vimrc && \
    ln -sf dotfiles/.ctags            .ctags && \
    ln -sf dotfiles/.inputrc          .inputrc && \
    \
    git clone https://github.com/tmux-plugins/tpm .tmux/plugins/tpm && \
    ln -sf dotfiles/.tmux.conf        .tmux.conf

RUN echo "PS1='\[\033[01;31m\][\[\033[01;30m\]\u@\h\[\033[01;36m\] \W\[\033[01;31m\]]\$\[\033[00m\] '" >> .bashrc

# Select clang compiler
RUN echo "export CXX=/usr/bin/clang++-8" >> ~/.bashrc && \
    echo "export CC=/usr/bin/clang-8" >> ~/.bashrc
    
# Print welcome message
RUN echo "echo 'Welcome to Nico development container'" >> ~/.bashrc && \
    echo "echo ' '" >> ~/.bashrc && \
    echo "echo 'Make sure that the correct USER_ID and GROUP_ID'" >> ~/.bashrc && \
    echo "echo '    have been used to start this container'" >> ~/.bashrc && \
    echo "echo ' '" >> ~/.bashrc && \
    echo "echo 'NOTE:'" >> ~/.bashrc && \
    echo "echo '    /working_dir folder was volume mounted'" >> ~/.bashrc && \
    echo "echo '    $HOME/.cache/bazel folder was volume mounted'" >> ~/.bashrc && \
    echo "echo ' '" >> ~/.bashrc 
