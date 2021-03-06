#!/usr/bin/env bash

set -e

ANSIBLE_CONFIGURATION_DIRECTORY="$HOME/.ansible-mac-setup"

# Download and install Command Line Tools with a checking heuristic
if [[ $(/usr/bin/gcc 2>&1) =~ "no developer tools were found" ]] || [[ ! -x /usr/bin/gcc ]]; then
    echo "Info   | Install   | xcode"
    xcode-select --install
fi

# Download and install Homebrew
if [[ ! -x /usr/local/bin/brew ]]; then
    echo "Info   | Install   | homebrew"
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    echo "Info   | Update    | homebrew"
    brew update
fi

# Modify the PATH
export PATH=/usr/local/bin:$PATH

# Download and install git
if [[ ! -x /usr/local/bin/git ]]; then
    echo "Info   | Install   | git"
    brew install git
fi

# Download and install ruby
if [[ ! -x /usr/local/bin/ruby ]]; then
    echo "Info   | Install   | ruby"
    brew install ruby
fi

if [[ `which ruby` != "/usr/local/bin/ruby" ]]; then
    echo "Info   | Symlink   | ruby"
    brew link --overwrite ruby
fi

if [[ `which pip3` != "/usr/local/bin/pip3" ]]; then
    echo "Info   | Install   | python"
    brew install python3
fi

# Download and install Ansible 2.7.x
if [[ ! -x /usr/local/bin/ansible ]]; then
    /usr/local/bin/pip3 install 'ansible>=2.7.0,<2.8.0'
fi

if [[ ! `ansible --version | grep 2.7` ]]; then
    echo "This playbook works with Ansible 2.7. Please install this version."
    exit 1
fi

# Clone down the Ansible repo
if [[ ! -d $ANSIBLE_CONFIGURATION_DIRECTORY ]]; then
    git clone https://github.com/genjusz/mac-setup $ANSIBLE_CONFIGURATION_DIRECTORY
fi

cd $ANSIBLE_CONFIGURATION_DIRECTORY
git pull

# Install ansible requirements
ansible-galaxy install -r requirements.yml

# run provisioning
ansible-playbook playbooks/php.yml -u $(whoami)
ansible-playbook main.yml -u $(whoami) --ask-sudo
ansible-playbook playbooks/fisher.yml -u $(whoami)

read -p "Do You wish to configure macOS now ? [yN] " configureMacOS
if [[ $configureMacOS == 'y' ]]; then
    ./macos-setup.sh
fi
