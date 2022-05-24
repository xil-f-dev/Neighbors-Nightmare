default_interface="wlan0"
terminal_cmd="gnome-terminal --" # Change to your desktop environment supported terminal
capdir="${HOME}/airocap"         # Directory to save .cap files
tmpDir="/tmp/airocap"            # Output of the airodump command
#conf_wordlist="/root/wordlist"

# State
discretModeEnabled=false

###############  --  COLORS         --  ##################
NORMAL=$(tput sgr0)
BLUE=$(tput setaf 4)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
BOLD=$(tput bold)
ITALIC=$(tput sitm)
###############  --  COLORS END     --  ##################
