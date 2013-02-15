#!/bin/bash
# configure-system.sh by Patrick Wyatt 1/26/2013
# Configures a Mac/Linux box with development software


#######################################################
# You can easily add your own recipes in marked spots:
#   EDIT ME
#     ... change things here ...
#   EDIT END
#######################################################


# Implementation notes: I got a bit out-of-control
# learning bash and this script is the by-product.


# http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Make sure script runs from the script's directory
cd "$DIR"

# Defining HEREDOCS "almost just like" Ruby
# http://ss64.com/bash/read.html
# http://stackoverflow.com/questions/1167746/how-to-assign-a-heredoc-value-to-a-variable-in-bash
heredoc(){ IFS='\n' read -r -d '' ${1} || true; }


# Parse command line
heredoc USAGE << EOF
Usage: `basename $0` [-h] [-s]
  -h  help
  -s  skip git archive updates
EOF
while getopts hs OPT; do
  case "$OPT" in
    s)
      skip_git_update=1
    ;;
    h)
      echo -e "$USAGE"
      exit 0
    ;;
    \?)
      # getopts issues an error message
      echo -e "$USAGE" >&2
      exit 1
    ;;
  esac
done


# Ensure soloist installed
if ! which soloist >/dev/null 2>/dev/null; then
  # TODO: we could actually try and install it...
  echo "install soloist"
  exit 1
fi


# $1 = repostiory owner on github
# $2 = archive name/directory
function update_github_archive () {
  mkdir -p cookbooks; cd cookbooks
  if [[ -d $2 ]]; then
    cd $2 && git pull && cd ..
  else
    git clone git://github.com/$1/$2.git
  fi
  cd ..
}


# Install/update git archives
if [ -z "$skip_git_update" ]; then
  # EDIT ME: select repos containing your recipes
  update_github_archive webcoyote pivotal_workstation
  update_github_archive opscode-cookbooks dmg
  update_github_archive opscode-cookbooks yum
  # EDIT END
fi


# EDIT ME: define OS-specific recipes to run
heredoc MAC_RECIPES << EOF
- pivotal_workstation::iterm2
- pivotal_workstation::diff_merge
- pivotal_workstation::finder_display_full_path
EOF
heredoc LINUX_RECIPES << EOF
- yum::epel # Enterprise Linux
- yum::remi # for Firefox
- pivotal_workstation::xmonad
- pivotal_workstation::meld
EOF
# EDIT END


# Choose OS-specific recipes
case "$OSTYPE" in
  darwin*) OS_RECIPES="$MAC_RECIPES" ;;
  linux*) OS_RECIPES="$LINUX_RECIPES" ;;
  *) echo Unknown OS: $OSTYPE; exit 1 ;;
esac


# Strip trailing newline from OS_RECIPES
OS_RECIPES=$(echo "$OS_RECIPES" | sed 's/ *$//g')


# EDIT ME: define recipes and attributes
cat > soloistrc << EOF
# This file generated by $0; do not edit directly
cookbook_paths:
- $PWD/cookbooks

recipes:
$OS_RECIPES
- pivotal_workstation::wget
- pivotal_workstation::git
- pivotal_workstation::rvm
- pivotal_workstation::oh_my_zsh
- pivotal_workstation::zsh
- pivotal_workstation::workspace_directory
- pivotal_workstation::git_projects
- pivotal_workstation::firefox
- pivotal_workstation::sublime_text

node_attributes:
  workspace_directory: dev

  git:
    - - user.name
      - Patrick Wyatt
    - - user.email
      - pat@codeofhonor.com
    - - color.ui
      - true
    - - difftool.prompt
      - false
    - - alias.lol
      - log --graph --decorate --oneline
    - - alias.lola
      - log --graph --decorate --oneline --all

  git_projects:
    # put the dotfiles in the home directory
    - - .dotfiles
      - git://github.com/webcoyote/dotfiles.git
      - .

    # Store my other projects in "~/dev"
    - - network-traffic-visualize
      - git://github.com/webcoyote/network.git


EOF
# EDIT END


# Build it
soloist
