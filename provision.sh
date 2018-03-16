#!/bin/bash

set -euo pipefail

echo "## Ensure this script is run as root"
if [ "${EUID}" -ne 0 ]; then
    echo "Please run as root"
    exit
fi

cd /vagrant

echo "## Persist the configuration directories for several tools."
declare -A from_to_dirs
from_to_dirs=( \
    ["/vagrant/dotfiles/dot.ssh"]="/home/vagrant/.ssh" \
    ["/vagrant/dotfiles/dot.aws"]="/home/vagrant/.aws" \
    ["/vagrant/dotfiles/dot.docker"]="/home/vagrant/.docker" \
    ["/vagrant/dotfiles/dot.emacs.d"]="/home/vagrant/.emacs.d" \
    ["/vagrant/dotfiles/dot.gnupg"]="/home/vagrant/.gnupg" \
    ["/vagrant/dotfiles/dot.gcloud"]="/home/vagrant/.config/gcloud" \
    ["/vagrant/dotfiles/dot.govc"]="/home/vagrant/.govc" \
    ["/vagrant/dotfiles/dot.helm"]="/home/vagrant/.helm" \
    ["/vagrant/dotfiles/dot.mc"]="/home/vagrant/.mc" \
    ["/vagrant/dotfiles/dot.minikube"]="/home/vagrant/.minikube" \
    ["/vagrant/dotfiles/dot.kube"]="/home/vagrant/.kube" )
for from_dir in "${!from_to_dirs[@]}"; do
    to_dir=${from_to_dirs[$from_dir]}
    ### Ensure dotfiles config directory exists.
    if [ ! -d "${from_dir}" ]; then
        sudo -u vagrant mkdir -p ${from_dir}
    fi
    ### Set link to the dotfiles config directory.
    if [ ! -e $to_dir ]; then
        sudo -u vagrant mkdir -p `dirname $to_dir`
        sudo -u vagrant ln -s $from_dir $to_dir
    fi
done

echo "## Persist the configuration files for several tools."
declare -A from_to_files
from_to_files=( \
  ["/vagrant/dotfiles/dot.ssh/config"]="/home/vagrant/.ssh/config" \
  ["/vagrant/dotfiles/dot.gitconfig"]="/home/vagrant/.gitconfig" \
  ["/vagrant/dotfiles/dot.hub"]="/home/vagrant/.config/hub" \
  ["/vagrant/dotfiles/dot.emacs"]="/home/vagrant/.emacs" \
  ["/vagrant/dotfiles/dot.gitignore"]="/home/vagrant/.gitignore" \
  ["/vagrant/dotfiles/dot.screenrc"]="/home/vagrant/.screenrc" \
  ["/vagrant/dotfiles/dot.nova"]="/home/vagrant/.nova" \
  ["/vagrant/dotfiles/dot.supernova"]="/home/vagrant/.supernova" \
  ["/vagrant/dotfiles/dot.superglance"]="/home/vagrant/.superglance" \
  ["/vagrant/dotfiles/dot.vimrc"]="/home/vagrant/.vimrc" )

for from_file in "${!from_to_files[@]}"; do
  to_file=${from_to_files[$from_file]}
  ### Ensure dotfiles config file exists and is empty.
  if [ ! -f ${from_file} ]; then
    sudo -u vagrant mkdir -p `dirname $from_file`
    sudo -u vagrant touch $from_file
  fi
  ### Set link to the dotfiles config file.
  if [ ! -L $to_file ] || [ ! -e $to_file ]; then
    rm -f $to_file
    sudo -u vagrant mkdir -p `dirname $to_file`
    sudo -u vagrant ln -s $from_file $to_file
  fi
done

echo "## Symlink config.yaml to vagrant homedir."
if [[ ! -e ~vagrant/config.yaml ]] ; then
  sudo -u vagrant ln -s /vagrant/config.yaml ~vagrant/config.yaml
fi

echo "## Install userspace 'provision.sh' to vagrant homedir."
cat <<'HERE_DOC' > /home/vagrant/provision.sh
#!/bin/bash

## WARNING: Do not edit this script.
##          Any changes you make will be lost with script execution.

set -euo pipefail

sudo \
  ANSIBLE_VERBOSITY="${ANSIBLE_VERBOSITY:-}" \
  /vagrant/provision.sh
HERE_DOC
chown 1000:1000 /home/vagrant/provision.sh
chmod 0755 /home/vagrant/provision.sh

/vagrant/.kdk/ansible.sh

echo "  "  # Highlight Ansible results.
echo "## Ensure vagrant owns everything in its home dir."
chown -R 1000:1000 /home/vagrant

echo "## Clean up yum metadata which may become stale during Vagrant box distribution."
yum clean all --quiet

echo "## Ensure all writes are sync'ed to disk."
sync

echo "## Provisioning complete!"

echo OK
