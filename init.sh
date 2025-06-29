function addenv() {
  sed -i -e "/^export $1=.*/d" ~/.bashrc
  echo "export $1=$2" >> ~/.bashrc
}

addenv CPU_HOME `pwd`
addenv AM_HOME $CPU_HOME/abstract-machine
addenv NPC_HOME $CPU_HOME/core
