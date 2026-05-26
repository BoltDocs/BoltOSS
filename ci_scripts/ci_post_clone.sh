#!/bin/zsh

set -e

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/refs/heads/master/install.sh | bash

sh ../Frontend/build-frontend.sh
