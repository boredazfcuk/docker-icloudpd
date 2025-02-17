#!/bin/ash

EUID=$(id -u)
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/icloudpd/bin"
export PAGER=less
export LS_COLORS='no=32:fi=32:di=01;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.heic=01;35:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=035:*.mp3=01;35:*.wav=01;35:*.xml=00;31:'
umask 027

for script in /etc/profile.d/*.sh ; do
   if [ -r "$script" ] ; then
      . "$script"
   fi
done

dl_path="$(grep "^download_path=" /config/icloudpd.conf | awk '{print $2}')"
alias bins='cd /usr/local/bin'
alias opt='cd /opt'
alias config='cd /config'
alias cls='clear'
alias dls="cd ${dl_path:=\/home\/$(id -un)\/iCloud\/}"
alias ls='ls -l --color --escape --human-readable'
alias sl='ls -l --color --escape --human-readable'
alias rm='rm -v'
alias mv='mv -v'
alias cp='cp -vp'
alias rcp='scp'
alias dfh='df -h | grep -v "/var/lib/docker\|udev\|tmpfs"'
alias duh='du -h'
alias grep='grep --color'
alias home='cd ~'
alias sourcereload='source /etc/profile'
alias logs='cd /var/log/'
alias listening='netstat -lntu'
alias install='apk add'
alias remove='apk del'
alias update='apk update'
alias listupdates='apk list --upgradable'
alias upgrade='apk update && apk upgrade'
alias editconfig='nano /config/icloudpd.conf'
alias whatsmyip='wget -qO- icanhazip.com'
alias innit='/usr/local/bin/sync-icloud.sh --init'

function __setprompt
{

   # Define colors
   local LIGHTGREY='\[\033[0;37m\]'
   local WHITE='\[\033[1;37m\]'
   local BLACK='\[\033[0;30m\]'
   local DARKGRAY='\[\033[1;30m\]'
   local RED='\[\033[0;31m\]'
   local LIGHTRED='\[\033[1;31m\]'
   local GREEN='\[\033[0;32m\]'
   local LIGHTGREEN='\[\033[1;32m\]'
   local BROWN='\[\033[0;33m\]'
   local YELLOW='\[\033[1;33m\]'
   local BLUE='\[\033[0;34m\]'
   local LIGHTBLUE='\[\033[1;34m\]'
   local MAGENTA='\[\033[0;35m\]'
   local LIGHTMAGENTA='\[\033[1;35m\]'
   local CYAN='\[\033[0;36m\]'
   local LIGHTCYAN='\[\033[1;36m\]'
   local NOCOLOR='\[\033[0m\]'

   # Green prompt is user, red prompt if red
   if [ $EUID -eq 0 ]; then
      PS1="${LIGHTRED}\u${LIGHTGREY}@${LIGHTRED}\h"
   else
      PS1="${LIGHTGREEN}\u${LIGHTGREY}@${LIGHTGREEN}\h"
   fi

   # Current directory
   PS1="${PS1}${LIGHTGREY}:${LIGHTBLUE}\w"

   # Prompt end
   if [ $EUID -eq 0 ]; then
      PS1="${PS1}${RED}>${GREEN} " # Root user
   else
      PS1="${PS1}${GREEN}>${GREEN} " # Normal user
   fi

}
__setprompt
PROMPT_COMMAND='echo -ne "\e]0;$USER@${HOSTNAME}: $(pwd -P)\a"'

unset script dl_path