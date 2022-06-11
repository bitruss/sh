#!/bin/bash
exists()
{
  command -v "$1" >/dev/null 2>&1
}
if exists curl; then
	echo ''
else
  sudo apt install curl -y < "/dev/null"
fi
bash_profile=$HOME/.bash_profile
if [ -f "$bash_profile" ]; then
    . $HOME/.bash_profile
fi
sleep 1 && curl -s https://raw.githubusercontent.com/bitruss/sh/main/logo.sh | bash && sleep 3

avail_space=`df $PWD -h | awk '/[0-9]%/{print $(NF-2)}' | sed 's/.$//'`
if [ $avail_space -lt 20 ]; then
	echo -e '\e[31mYou have less than 20GB available space, please free some space and retry install.\e[39m'
	exit 1
fi

function setupVars {
	if [ ! $MESON_TOKEN ]; then
		read -p "Enter your meson token: " MESON_TOKEN
		echo 'export MESON_TOKEN='${MESON_TOKEN} >> $HOME/.bash_profile
	fi
	echo -e '\n\e[42mYour meson token:' $MESON_TOKEN '\e[0m\n'
	if [ ! $MESON_PORT ]; then
		read -p "Enter your meson port (443 by default): " MESON_PORT
		MESON_PORT=${MESON_PORT:-443}
		echo 'export MESON_PORT='${MESON_PORT} >> $HOME/.bash_profile
	fi
	echo -e '\n\e[42mYour meson port:' $MESON_PORT '\e[0m\n'
	if [ ! $MESON_SPACELIMIT ]; then
		echo -e '\e[42mAt this moment you have' $avail_space 'GB available space\e[0m'
		read -p "Enter your spacelimit for Meson (at least 20GB), ONLY NUMBER (without GB): " MESON_SPACELIMIT
		MESON_SPACELIMIT=${MESON_SPACELIMIT:-20}
		echo 'export MESON_SPACELIMIT='${MESON_SPACELIMIT} >> $HOME/.bash_profile
	fi
	echo -e '\n\e[42mYour Meson spacelimit:' $MESON_SPACELIMIT '\e[0m\n'
	. $HOME/.bash_profile
	sleep 1
}

function setupSwap {
	echo -e '\n\e[42mSet up swapfile\e[0m\n'
	curl -s https://raw.githubusercontent.com/bitruss/sh/main/swap4.sh | bash
}

function installDeps {
	echo -e '\n\e[42mPreparing to install\e[0m\n' && sleep 1
	cd $HOME
	sudo apt update
	sudo apt install make clang pkg-config libssl-dev build-essential git jq ufw -y < "/dev/null"
}

function installSoftware {
	echo -e '\n\e[42mInstall software\e[0m\n' && sleep 1
	ufw allow 80
	ufw allow 443
	ufw allow 19091
	wget 'https://dashboard.meson.network/static_assets/node/v3.0.0/meson-linux-amd64.tar.gz'
	tar -zxf meson-linux-amd64.tar.gz
	cd ./meson-linux-amd64
echo "#token register and login in https://meson.network
token = $MESON_TOKEN

# server port DO NOT run in 80 or 443
# open this port on your firewall
# default 443
port = $MESON_PORT

# space limit (Maximum allowable space for Terminal in GB. Less than the total disk. At least 20 GB)
spacelimit = $MESON_SPACELIMIT
" > $HOME/meson-linux-amd64/config.txt
	sudo $HOME/meson-linux-amd64/meson service-install
	sudo $HOME/meson-linux-amd64/meson service-start
	echo -e '\n\e[42mCheck node status\e[0m\n' && sleep 3
	if [[ `$HOME/meson-linux-amd64/meson service-status | grep "is running"` =~ "is running" ]]; then
	  echo -e "Your Meson minrt \e[32minstalled and works\e[39m!"
	  echo -e "You can check miner status by the command \e[7m$HOME/meson-linux-amd64/meson service-status\e[0m"
	  echo -e "Press \e[7mQ\e[0m for exit from status menu"
	else
	  echo -e "Your Meson miner \e[31mwas not installed correctly\e[39m, please reinstall."
	fi
}

function deleteMESON {
	sudo systemctl disable meson
	sudo systemctl stop meson
	$HOME/meson-linux-amd64/meson service-remove
}

PS3='Please enter your choice (input your option number and press enter): '
options=("Install" "Delete" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Install")
            echo -e '\n\e[42mYou choose install...\e[0m\n' && sleep 1
			setupVars
			setupSwap
			installDeps
			installSoftware
			break
            ;;
		"Delete")
            echo -e '\n\e[31mYou choose delete...\e[0m\n' && sleep 1
			deleteMESON
			echo -e '\n\e[42mMeson miner was deleted!\e[0m\n' && sleep 1
			break
            ;;
        "Quit")
            break
            ;;
        *) echo -e "\e[91minvalid option $REPLY\e[0m";;
    esac
done
