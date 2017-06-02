# Path to your oh-my-zsh installation.
export ZSH=/Users/lhabel/.oh-my-zsh
ZSH_THEME="af-magic"
# CASE_SENSITIVE="true"
# HYPHEN_INSENSITIVE="true"
# DISABLE_AUTO_UPDATE="true"
# export UPDATE_ZSH_DAYS=13
# DISABLE_LS_COLORS="true"
# DISABLE_AUTO_TITLE="true"
# ENABLE_CORRECTION="true"
# COMPLETION_WAITING_DOTS="true"
# DISABLE_UNTRACKED_FILES_DIRTY="true"
HIST_STAMPS="dd.mm.yyyy"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration
export DYLD_LIBRARY_PATH=/opt/sqlplus/instantclient_11_2
export ELIS_HOME=~/Apps/elis-apps
export APPT_HOME=~/Apps/elis2_appointment_service
export GRADLE_HOME=/opt/gradle/gradle-2.7
export GRADLE_USER_HOME=/opt/.g
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_102.jdk/Contents/Home
export TEST_LIB=~/Apps/elis-apps/Tests/SharedFunctionalTestAssets/lib # ELIS libs for CLI testing
export LIQUIBASE_HOME=/opt/liquibase/liquibase-3.0.5
export NODEJS_HOME=/usr/local/bin/node
export ORACLE_HOME=${DYLD_LIBRARY_PATH}
export PSQL_BIN=/Applications/Postgres.app/Contents/Versions/9.6/bin/psql
export USER_SCRIPTS=~/cbin

#:${MONGODB_HOME}/bin
export PATH=${USER_SCRIPTS}:${LIQUIBASE_HOME}:${JAVA_HOME}/bin:${GRADLE_HOME}/bin:${NODEJS_HOME}:${DYLD_LIBRARY_PATH}:${DYLD_LIBRARY_PATH}/11.2.0.3.0/bin:${PATH}
export PATH=$USER_DIR/.vagrant.d/data/service-manager/bin/openshift/:$PATH
export CLASSPATH=${CLASSPATH}:${TEST_LIB}/junit-4.11.jar:${TEST_LIB}/hamcrest-core-1.3.jar:~/Apps

export PROXY=preproxy.uscis.dhs.gov:80
export PROXY_USER=
export PROXY_PASSWORD=

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='vim'
fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

alias openshift='cd ~/elis/OpenShift/cdk/components/rhel/rhel-ose; vagrant up'
