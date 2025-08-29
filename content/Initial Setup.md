When i set up a new machine/VM/etc for development, there are some things that are neccessary, so i compile a list of them here in order to speed up the setup process.

```bash
# brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
exec $SHELL

# JetBrains Mono Nerd Font
brew install --cask font-jetbrains-mono-nerd-font

# zsh
brew install zsh
exec zsh

# oh-my-posh + catpuccin theme
brew install jandedobbeleer/oh-my-posh/oh-my-posh
curl -L -o ~/catppuccin.omp.json https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/refs/heads/main/themes/catppuccin.omp.json
echo 'eval "$(oh-my-posh init zsh --config ~/catppuccin.omp.json)"' >> ~/.zshrc

# zsh-autocomplete
brew install zsh-autocomplete

# zsh-autosuggestions
brew install zsh-autosuggestions

# zsh-syntax-highlighting
brew install zsh-syntax-highlighting

# bashtop
brew install bashtop

# ncdu
brew install ncdu

# tree
brew install tree

# tmux
brew install tmux

# neovim
brew install neovim

# bat
brew install bat

# direnv
brew install direnv

# jenv
brew install jenv
echo 'export PATH="$HOME/.jenv/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(jenv init -)"' >> ~/.zshrc

# openjdk17
brew install openjdk@17

# pyenv
brew install openssl readline sqlite3 xz zlib tcl-tk@8 libb2 zstd
curl -fsSL https://pyenv.run | bash
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(pyenv init - zsh)"' >> ~/.zshrc
exec zsh

# python 3.12
pyenv install 3.12
pyenv global 3.12

# uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# ruff
curl -LsSf https://astral.sh/ruff/install.sh | sh

# nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
exec zsh

# node 22-lts
nvm install lts/jod
nvm use lts/jod

# fzf
brew install fzf

# ripgrep
brew install ripgrep

# k9s
brew install k9s

# aws-cli
brew install awscli

# duckdb
curl https://install.duckdb.org | sh

# oxker
brew install oxker

# dclint
npm install --g dclint

# hadolint
brew install hadolint

# checkov
brew install checkov

# sqlfluff
brew install sqlfluff

# dotenv-linter
brew install dotenv-linter
```

## Others:

- htop
- nvtop, if gpu is available
- openssh, if needed
- kickstart
- docker-cli or docker-desktop
- minikube, if needed
  - (kustomize)
- task, if primary work/private workload
- Ghostty, if access to UI
- vs code, if access to UI

## vs code plugins:

```
docker.docker
github.copilot
github.copilot-chat
mermaidchart.vscode-mermaid-chart
mongodb.mongodb-vscode
ms-azuretools.vscode-containers
ms-dotnettools.csdevkit
ms-dotnettools.csharp
ms-dotnettools.vscode-dotnet-runtime
ms-kubernetes-tools.vscode-kubernetes-tools
ms-ossdata.vscode-pgsql
ms-python.debugpy
ms-python.python
ms-python.vscode-pylance
ms-python.vscode-python-envs
ms-toolsai.jupyter
ms-toolsai.jupyter-keymap
ms-toolsai.jupyter-renderers
ms-toolsai.vscode-jupyter-cell-tags
ms-toolsai.vscode-jupyter-slideshow
ms-vscode-remote.remote-containers
ms-vscode.cmake-tools
ms-vscode.cpptools
ms-vscode.cpptools-extension-pack
ms-vscode.cpptools-themes
perkovec.emoji
redhat.vscode-yaml
tomoki1207.pdf
vstirbu.vscode-mermaid-preview
```
