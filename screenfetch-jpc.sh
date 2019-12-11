#!/usr/bin/env bash

# screenFetch - a CLI Bash script to show system/theme info in screenshots

# Copyright (c) 2010-2019 Brett Bohnenkamper <kittykatt@kittykatt.us>

#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Yes, I do realize some of this is horribly ugly coding. Any ideas/suggestions would be
# appreciated by emailing me or by stopping by http://github.com/KittyKatt/screenFetch. You
# could also drop in on the IRC channel at irc://irc.rizon.net/screenFetch.
# to put forth suggestions/ideas. Thank you.

##############################################

# Edited by Jure Cerar -- 11.12.2019
# - Removed OS logos & added UL logo.
# - Added `skip_lines` options.
# - More primitive distro detection.
# - Changed CPU & MEM detection.
# - Multi GPU detection.
# - Changed output order.
# - Removed "bloat" functionality.

scriptVersion="3.9.1"

######################
# Settings for fetcher
######################

# This sets the information to be displayed. Available: distro, Kernel, DE, WM, Win_theme, Theme, Icons, Font, Background, ASCII.
# To get just the information, and not a text-art logo, you would take "ASCII" out of the below variable.
valid_display=(
	'distro'
	'host'
	'kernel'
	'uptime'
	'shell'
	'disk'
	'cpu'
	'gpu'
	'mem'
)
display=(
	'distro'
	'host'
	'kernel'
	'uptime'
	'shell'
	'disk'
	'cpu'
	'gpu'
	'mem'
)

# Display Type: ASCII or Text
display_type="ASCII"
# Plain logo
display_logo="no"
# Skip lines
skip_lines=5

# Verbose Setting - Set to 1 for verbose output.
verbosity=

#########################################
# Static Variables and Common Functions #
#########################################
c0=$'\033[0m' # Reset Text
bold=$'\033[1m' # Bold Text
underline=$'\033[4m' # Underline Text
display_index=0

# Static Color Definitions
colorize () {
	printf $'\033[0m\033[38;5;%sm' "$1"
}

getColor () {
	local tmp_color=""
	if [[ -n "$1" ]]; then
		if [[ ${BASH_VERSINFO[0]} -ge 4 ]]; then
			if [[ ${BASH_VERSINFO[0]} -eq 4 && ${BASH_VERSINFO[1]} -gt 1 ]] || [[ ${BASH_VERSINFO[0]} -gt 4 ]]; then
				tmp_color=${1,,}
			else
				tmp_color="$(tr '[:upper:]' '[:lower:]' <<< "${1}")"
			fi
		else
			tmp_color="$(tr '[:upper:]' '[:lower:]' <<< "${1}")"
		fi
		case "${tmp_color}" in
			# Standards
			'black')					color_ret='\033[0m\033[30m';;
			'red')						color_ret='\033[0m\033[31m';;
			'green')					color_ret='\033[0m\033[32m';;
			'brown')					color_ret='\033[0m\033[33m';;
			'blue')						color_ret='\033[0m\033[34m';;
			'purple')					color_ret='\033[0m\033[35m';;
			'cyan')						color_ret='\033[0m\033[36m';;
			'yellow')					color_ret='\033[0m\033[1;33m';;
			'white')					color_ret='\033[0m\033[1;37m';;
			# Bolds
			'dark grey'|'dark gray')	color_ret='\033[0m\033[1;30m';;
			'light red')				color_ret='\033[0m\033[1;31m';;
			'light green')				color_ret='\033[0m\033[1;32m';;
			'light blue')				color_ret='\033[0m\033[1;34m';;
			'light purple')				color_ret='\033[0m\033[1;35m';;
			'light cyan')				color_ret='\033[0m\033[1;36m';;
			'light grey'|'light gray')	color_ret='\033[0m\033[37m';;
			# Some 256 colors
			'orange')					color_ret="$(colorize '202')";; #DarkOrange
			'light orange') 			color_ret="$(colorize '214')";; #Orange1
			# HaikuOS
			'black_haiku') 				color_ret="$(colorize '7')";;
			#ROSA color
			'rosa_blue') 				color_ret='\033[01;38;05;25m';;
			# ArcoLinux
			'arco_blue') color_ret='\033[1;38;05;111m';;
		esac
		[[ -n "${color_ret}" ]] && echo "${color_ret}"
	fi
}

verboseOut () {
	if [[ "$verbosity" -eq "1" ]]; then
		printf '\033[1;31m:: \033[0m%s\n' "$1"
	fi
}

errorOut () {
	printf '\033[1;37m[[ \033[1;31m! \033[1;37m]] \033[0m%s\n' "$1"
}

stderrOut () {
	while IFS='' read -r line; do
		printf '\033[1;37m[[ \033[1;31m! \033[1;37m]] \033[0m%s\n' "$line"
	done
}

# Code timing
mytime () {
	time=$(($(date +%s%N)/1000000))
	$@
	time=$((  $(($(date +%s%N)/1000000)) - $time ))
  echo "Elapsed time $time us."
}

####################
#  Color Defines
####################

colorNumberToCode () {
	local number="$1"
	if [[ "${number}" == "na" ]]; then
		unset code
	elif [[ $(tput colors) -eq "256" ]]; then
		code=$(colorize "${number}")
	else
		case "$number" in
			0|00) code=$(getColor 'black');;
			1|01) code=$(getColor 'red');;
			2|02) code=$(getColor 'green');;
			3|03) code=$(getColor 'brown');;
			4|04) code=$(getColor 'blue');;
			5|05) code=$(getColor 'purple');;
			6|06) code=$(getColor 'cyan');;
			7|07) code=$(getColor 'light grey');;
			8|08) code=$(getColor 'dark grey');;
			9|09) code=$(getColor 'light red');;
			  10) code=$(getColor 'light green');;
			  11) code=$(getColor 'yellow');;
			  12) code=$(getColor 'light blue');;
			  13) code=$(getColor 'light purple');;
			  14) code=$(getColor 'light cyan');;
			  15) code=$(getColor 'white');;
			*) unset code;;
		esac
	fi
	echo -n "${code}"
}

detectColors () {
	my_colors=$(sed 's/^,/na,/;s/,$/,na/;s/,/ /' <<< "${OPTARG}")
	my_lcolor=$(awk -F' ' '{print $1}' <<< "${my_colors}")
	my_lcolor=$(colorNumberToCode "${my_lcolor}")
	my_hcolor=$(awk -F' ' '{print $2}' <<< "${my_colors}")
	my_hcolor=$(colorNumberToCode "${my_hcolor}")
}

####################
#  Help message
####################

displayHelp () {
	echo "${underline}Usage${c0}:"
	echo "  ${0} [OPTIONAL FLAGS]"
	echo ""
	echo "screenFetch - a CLI Bash script to show system/theme info in screenshots."
	echo ""
	echo ""
	echo "${underline}Options${c0}:"
	echo "   ${bold}-v${c0}                 Verbose output."
	echo "   ${bold}-o 'OPTIONS'${c0}       Allows for setting script variables on the"
	echo "                      command line. Must be in the following format..."
	echo "                      'OPTION1=\"OPTIONARG1\";OPTION2=\"OPTIONARG2\"'"
	echo "   ${bold}-d '+var;-var;var'${c0} Allows for setting what information is displayed"
	echo "                      on the command line. You can add displays with +var,var. You"
	echo "                      can delete displays with -var,var. Setting without + or - will"
	echo "                      set display to that explicit combination. Add and delete statements"
	echo "                      may be used in conjunction by placing a ; between them as so:"
	echo "                      +var,var,var;-var,var. See above to find supported display names."
	echo "   ${bold}-n${c0}                 Do not display ASCII distribution logo."
	echo "   ${bold}-L${c0}                 Display ASCII distribution logo only."
	echo "   ${bold}-N${c0}                 Strip all color from output."
	echo "   ${bold}-w${c0}                 Wrap long lines."
	echo "   ${bold}-t${c0}                 Truncate output based on terminal width (Experimental!)."
	echo "   ${bold}-p${c0}                 Portrait output."
	echo "   ${bold}-s [-u IMGHOST]${c0}    Using this flag tells the script that you want it"
	echo "                      to take a screenshot. Use the -u flag if you would like"
	echo "                      to upload the screenshots to one of the pre-configured"
	echo "                      locations. These include: teknik, imgur, mediacrush and hmp."
	echo "   ${bold}-c string${c0}          You may change the outputted colors with -c. The format is"
	echo "                      as follows: [0-9][0-9],[0-9][0-9]. The first argument controls the"
	echo "                      ASCII logo colors and the label colors. The second argument"
	echo "                      controls the colors of the information found. One argument may be"
	echo "                      used without the other. For terminals supporting 256 colors argument"
	echo "                      may also contain other terminal control codes for bold, underline etc."
	echo "                      separated by semicolon. For example -c \"4;1,1;2\" will produce bold"
	echo "                      blue and dim red."
	echo "   ${bold}-a 'PATH'${c0}          You can specify a custom ASCII art by passing the path"
	echo "                      to a Bash script, defining \`startline\` and \`fulloutput\`"
	echo "                      variables, and optionally \`labelcolor\` and \`textcolor\`."
	echo "                      See the \`asciiText\` function in the source code for more"
	echo "                      information on the variables format."
	echo "   ${bold}-S 'COMMAND'${c0}       Here you can specify a custom screenshot command for"
	echo "                      the script to execute. Surrounding quotes are required."
	echo "   ${bold}-D 'DISTRO'${c0}        Here you can specify your distribution for the script"
	echo "                      to use. Surrounding quotes are required."
	echo "   ${bold}-A 'DISTRO'${c0}        Here you can specify the distribution art that you want"
	echo "                      displayed. This is for when you want your distro"
	echo "                      detected but want to display a different logo."
	echo "   ${bold}-E${c0}                 Suppress output of errors."
	echo "   ${bold}-V, --version${c0}      Display current script version."
	echo "   ${bold}-h, --help${c0}         Display this help."
}

displayVersion () {
	echo "${underline}screenFetch${c0} - Version ${scriptVersion}"
	echo " Created by Brett Bohnenkamper <kittykatt@kittykatt.us>"
	echo " Modified by Jure Cerar <jure.cerar@fkkt.uni-lj.si>"
	echo " Original git repo by Brett Bohnenkamper can be found at: https://github.com/KittyKatt/screenFetch"
	echo ""
	echo "Copyright (C) 2019 Brett Bohnenkamper, Jure Cerar"
	echo " This is free software; See the source for copying conditions. There is NO warranty;"
	echo " Not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE."
}

#####################
# Begin Flags Phase
#####################

case $1 in
	--help) displayHelp; exit 0;;
	--version) displayVersion; exit 0;;
esac


while getopts ":hsu:evVEnLNtlS:A:D:o:c:d:pa:w" flags; do
	case $flags in
		h) displayHelp; exit 0 ;;
		s) screenshot='1' ;;
		S) screenCommand="${OPTARG}" ;;
		u) upload='1'; uploadLoc="${OPTARG}" ;;
		v) verbosity=1 ;;
		V) displayVersion; exit 0 ;;
		E) errorSuppress='1' ;;
		D) distro="${OPTARG}" ;;
		A) asc_distro="${OPTARG}" ;;
		t) truncateSet='Yes' ;;
		n) display_type='Text' ;;
		L) display_type='ASCII'; display_logo='Yes' ;;
		o) overrideOpts="${OPTARG}" ;;
		c) detectColors "${OPTARGS}" ;;
		d) overrideDisplay="${OPTARG}" ;;
		N) no_color='1' ;;
		p) portraitSet='Yes' ;;
		a) art="${OPTARG}" ;;
		w) lineWrap='Yes' ;;
		:) errorOut "Error: You're missing an argument somewhere. Exiting."; exit 1 ;;
		?) errorOut "Error: Invalid flag somewhere. Exiting."; exit 1 ;;
		*) errorOut "Error"; exit 1 ;;
	esac
done

#########################
# Begin Detection Phase
#########################

detectdistro () {
	# Redhat like
	if [[ -e /etc/redhat-release ]]; then
		distro=$(cat /etc/redhat-release)
	elif [[ -e /etc/system-release ]]; then
		distro=$(cat /etc/system-release)
	# Ubuntu like
	elif type -p lsb_release >/dev/null 2>&1; then
		distro=$(awk -F'"' '/^DISTRIB_DESCRIPTION/ {print $2}' /etc/lsb-release)
	# Tough luck
	else
		distro="Unknown"
  fi
}

detecthost () {
	myUser=${USER}
	myHost=${HOSTNAME}
	if [[ -z "$USER" ]]; then
		myUser=$(whoami)
	fi

	verboseOut "Finding hostname and user...found as '${myUser}@${myHost}'"
}

detectkernel () {
	if [[ "$distro" == "OpenBSD" ]]; then
		kernel=$(uname -a | cut -f 3- -d ' ')
	else
		# compatibility for older versions of OS X:
		kernel=$(uname -m && uname -sr)
		kernel=${kernel//$'\n'/ }
		#kernel=( $(uname -srm) )
		#kernel="${kernel[${#kernel[@]}-1]} ${kernel[@]:0:${#kernel[@]}-1}"
		verboseOut "Finding kernel version...found as '${kernel}'"
	fi
}

detectuptime () {
	unset uptime
	if [[ -f /proc/uptime ]]; then
		uptime=$(</proc/uptime)
		uptime=${uptime//.*}
	fi

	if [[ -n ${uptime} ]]; then
		mins=$((uptime/60%60))
		hours=$((uptime/3600%24))
		days=$((uptime/86400))
		uptime="${mins}m"
		if [ "${hours}" -ne "0" ]; then
			uptime="${hours}h ${uptime}"
		fi
		if [ "${days}" -ne "0" ]; then
			uptime="${days}d ${uptime}"
		fi
	fi

	verboseOut "Finding current uptime...found as '${uptime}'"
}

detectcpu () {
	local REGEXP="-r"

  # Model
	cpu_model=$(awk -F':' '/^model name/ {split($2, A, " @"); print A[1]; exit}' /proc/cpuinfo)

  # Number of cores
  cpu_cores=$(awk -F':' '/^cpu cores/ {printf "%d\n", $2; exit}' /proc/cpuinfo)

  # Number of threads
	cpu_threads=$(awk -F':' '/^siblings/ {printf "%d\n", $2; exit}' /proc/cpuinfo)

	# Number of sockets
	cpu_sockets=$( lscpu | awk -F':' '/^Socket\(s\)\:/ {printf "%dx\n", $2; exit}' )
	[[ "$cpu_sockets" == "1x" ]] && cpu_sockets=""

  # Frequency
	# cpu_ghz=$(awk -F':' '/cpu MHz/{ printf "%.2f\n", $2/1000. }' /proc/cpuinfo | head -n 1)
  cpu_ghz=$( lscpu | awk -F':' '/CPU max MHz/{ printf "%.2f\n", $2/1000. }' )
	[[ -z $cpu_ghz ]] && cpu_ghz=$( cat "/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq" | awk '{printf "%.2f\n", $1/1000./1000. }' )

  # Formulate and remove branding
  cpu="${cpu_sockets}${cpu_model} ${cpu_cores}(${cpu_threads})@${cpu_ghz}GHz"
  cpu=$(sed $REGEXP 's/\([tT][mM]\)|\([Rr]\)|[pP]rocessor|CPU//g' <<< "${cpu}" | xargs)

	verboseOut "Finding current CPU...found as '$cpu'"
}

detectgpu () {
  if [[ -n "$(PATH="/opt/bin:$PATH" type -p nvidia-smi)" ]]; then
    # gpu=$($(PATH="/opt/bin:$PATH" type -p nvidia-smi | cut -f1) -q | awk -F':' '/Product Name/ {gsub(/: /,":"); print $2}' | sed ':a;N;$!ba;s/\n/, /g')
		gpu_num=$( nvidia-smi -L | grep -c "GPU" )
		for i in $( seq 0 $(($gpu_num-1)) );do
			gpu[$i]="Nvidia $(nvidia-smi --id=$i --query-gpu=gpu_name --format=csv,noheader )"
		done
  elif [[ -n "$(PATH="/usr/sbin:$PATH" type -p glxinfo)" && -z "${gpu}" ]]; then
    gpu_info=$($(PATH="/usr/sbin:$PATH" type -p glxinfo | cut -f1) 2>/dev/null)
    gpu=$(grep "OpenGL renderer string" <<< "${gpu_info}" | cut -d ':' -f2 | sed -n -e '1h;2,$H;${g;s/\n/, /g' -e 'p' -e '}')
    gpu="${gpu:1}"
    gpu_info=$(grep "OpenGL vendor string" <<< "${gpu_info}")
  elif [[ -n "$(PATH="/usr/sbin:$PATH" type -p lspci)" && -z "$gpu" ]]; then
    gpu_info=$($(PATH="/usr/bin:$PATH" type -p lspci | cut -f1) 2> /dev/null | grep VGA)
    gpu=$(grep -oE '\[.*\]' <<< "${gpu_info}" | sed 's/\[//;s/\]//' | sed -n -e '1h;2,$H;${g;s/\n/, /g' -e 'p' -e '}')
  fi

  if [ -n "$gpu" ];then
		if grep -q -i 'nvidia' <<< "${gpu_info}"; then
			gpu_info="NVidia "
		elif grep -q -i 'intel' <<< "${gpu_info}"; then
			gpu_info="Intel "
		elif grep -q -i 'amd' <<< "${gpu_info}"; then
			gpu_info="AMD "
		elif grep -q -i 'ati' <<< "${gpu_info}" || grep -q -i 'radeon' <<< "${gpu_info}"; then
			gpu_info="ATI "
		else
			gpu_info=$(cut -d ':' -f2 <<< "${gpu_info}")
			gpu_info="${gpu_info:1} "
		fi
		gpu="${gpu}"
	else
		gpu="Not Found"
	fi

	verboseOut "Finding current GPU...found as '$gpu'"
}

detectdisk () {
	diskusage="Unknown"
	if type -p df >/dev/null 2>&1; then
		if [[ "${distro}" =~ (Free|Net|DragonFly)BSD ]]; then
			totaldisk=$(df -h -c 2>/dev/null | tail -1)
		elif [[ "${distro}" == "OpenBSD" ]]; then
			totaldisk=$(df -Pk 2> /dev/null | awk '
				/^\// {total+=$2; used+=$3; avail+=$4}
				END{printf("total %.1fG %.1fG %.1fG %d%%\n", total/1048576, used/1048576, avail/1048576, used*100/total)}')
		else
			totaldisk=$(df -h -x aufs -x tmpfs -x overlay --total 2>/dev/null | tail -1)
		fi
		disktotal=$(awk '{print $2}' <<< "${totaldisk}")
		diskused=$(awk '{print $3}' <<< "${totaldisk}")
		diskusedper=$(awk '{print $5}' <<< "${totaldisk}")
		diskusage="${diskused}B / ${disktotal}B (${diskusedper})"
		diskusage_verbose=$(sed 's/%/%%/' <<< "$diskusage")
	fi
	verboseOut "Finding current disk usage...found as '$diskusage_verbose'"
}

detectmem () {
	# mem=$(free -b | awk 'NR==2{print $2"-"$7}')
  # mem=$(awk -v x="${mem//-*}" 'BEGIN { printf "%.0fGB\n", x/1024./1024./1024. }')

	mem=$( grep "MemTotal" /proc/meminfo | awk '{printf "%.0fGB\n", $2/1024./1024.}' )

  verboseOut "Finding current RAM usage...found as '$mem'"
}

detectshell_ver () {
	local version_data='' version='' get_version='--version'

	case $1 in
		# ksh sends version to stderr. Weeeeeeird.
		ksh)
			version_data="$( $1 $get_version 2>&1 )"
			;;
		*)
			version_data="$( $1 $get_version 2>/dev/null )"
			;;
	esac

	if [[ -n $version_data ]];then
		version=$(awk '
		BEGIN {
			IGNORECASE=1
		}
		/'$2'/ {
			gsub(/(,|v|V)/, "",$'$3')
			if ($2 ~ /[Bb][Aa][Ss][Hh]/) {
				gsub(/\(.*|-release|-version\)/,"",$4)
			}
			print $'$3'
			exit # quit after first match prints
		}' <<< "$version_data")
	fi
	echo "$version"
}
detectshell () {
	if [[ ! "${shell_type}" ]]; then
		if [[ "${distro}" == "Cygwin" || "${distro}" == "Msys" || "${distro}" == "Haiku" || "${distro}" == "Alpine Linux" ||
			"${distro}" == "Mac OS X" || "${distro}" == "TinyCore" || "${distro}" == "Raspbian" || "${OSTYPE}" == "gnu" ]]; then
			shell_type=$(echo "$SHELL" | awk -F'/' '{print $NF}')
		elif readlink -f "$SHELL" 2>&1 | grep -q -i 'busybox'; then
			shell_type="BusyBox"
		else
			if [[ "${OSTYPE}" =~ "linux" ]]; then
				shell_type=$(tr '\0' '\n' </proc/$PPID/cmdline | head -1)
			elif [[ "${distro}" =~ "BSD" ]]; then
				shell_type=$(ps -p $PPID -o command | tail -1)
			else
				shell_type=$(ps -p "$(ps -p $PPID | awk '$1 !~ /PID/ {print $1}')" | awk 'FNR>1 {print $1}')
			fi
			shell_type=${shell_type/-}
			shell_type=${shell_type//*\/}
		fi
	fi

	case $shell_type in
		bash)
			shell_version_data=$( detectshell_ver "$shell_type" "^GNU.bash,.version" "4" )
			;;
		BusyBox)
			shell_version_data=$( busybox | head -n1 | cut -d ' ' -f2 )
			;;
		csh)
			shell_version_data=$( detectshell_ver "$shell_type" "$shell_type" "3" )
			;;
		dash)
			shell_version_data=$( detectshell_ver "$shell_type" "$shell_type" "3" )
			;;
		ksh)
			shell_version_data=$( detectshell_ver "$shell_type" "version" "5" )
			;;
		tcsh)
			shell_version_data=$( detectshell_ver "$shell_type" "^tcsh" "2" )
			;;
		zsh)
			shell_version_data=$( detectshell_ver "$shell_type" "^zsh" "2" )
			;;
		fish)
			shell_version_data=$( fish --version | awk '{print $3}' )
			;;
	esac

	if [[ -n $shell_version_data ]];then
		shell_type="$shell_type $shell_version_data"
	fi

	myShell=${shell_type}
	verboseOut "Finding current shell...found as '$myShell'"
}

asciiText () {

# Distro logos and ASCII outputs
	# if [[ "$asc_distro" ]]; then
	# 	myascii="${asc_distro}"
	# elif [[ "$art" ]]; then
	# 	myascii="custom"
	# elif [[ "$fake_distro" ]]; then
	# 	myascii="${fake_distro}"
	# else
	# 	myascii="${distro}"
	# fi
	[[ "$art" ]] && myascii="custom"


	case ${myascii} in
		"custom")
			source "$art"
		;;
		*)
			if [[ "$no_color" != "1" ]]; then
			  c1='\033[1m' # $(getColor 'white')
			  c2='\033[1;91m' # $(getColor 'light red')
			fi
			startline="0"
			logowidth="28"
			fulloutput=(
"${c1}                           %s"
"  Univerza ${c1}v Ljubljani     %s"
"  Fakulteta za ${c2}kemijo      %s"
"  ${c2}in kemijsko tehnologijo  %s"
"${c1}            .            %s"
"${c1}            │            %s"
"${c1}     A      M      A     %s"
"${c1}     ║___ ────\ ___║     %s"
"${c1}   A/┐┐┐ A ^ ^ A ┐┐┐\A   %s"
"${c1}   │____┐  /¯\_ ┐____│   %s"
"${c1}   │┐┐┐┐│ ┐ ╗ ┐ │┐┐┐┐│   %s"
"${c1}   ¦────┤ ┐ ╗ ┐ ├────¦   %s"
"${c1}   │¦¦¦¦│ │ ║ │ │¦¦¦¦│   %s"
"${c1}   └──── ─ ─── ─ ────┘   %s"
"${c2}   ███████████████████   %s"
"${c2}   ███████████████████   %s"
"${c2}   ███████████████████   %s"
"${c2}   ███████████████████   %s"
"${c2}   ███████████████████   %s"
"${c2}   ███████████████████   %s"
"${c2}   ███████████████████   %s"
"${c2}   ███████████████████   %s"
"${c2}   ███████████████████   %s")
	;;
  esac

  if [ "$truncateSet" == "Yes" ]; then
    missinglines=$((${#out_array[*]} + startline - ${#fulloutput[*]}))
    for ((i=0; i<missinglines; i++)); do
      fulloutput+=("${c1}$(printf '%*s' "$logowidth")%s")
    done
    for ((i=0; i<${#fulloutput[@]}; i++)); do
      my_out=$(printf "${fulloutput[i]}$c0\n" "${out_array}")
      my_out_full=$(echo "$my_out" | cat -v)
      termWidth=$(tput cols)
      SHOPT_EXTGLOB_STATE=$(shopt -p extglob)
      read SHOPT_CMD SHOPT_STATE SHOPT_OPT <<< "${SHOPT_EXTGLOB_STATE}"
      if [[ ${SHOPT_STATE} == "-u" ]]; then
        shopt -s extglob
      fi

      stringReal="${my_out_full//\^\[\[@([0-9]|[0-9];[0-9][0-9])m}"

      if [[ ${SHOPT_STATE} == "-u" ]]; then
        shopt -u extglob
      fi

      if [[ "${#stringReal}" -le "${termWidth}" ]]; then
        echo -e "${my_out}"$c0
      elif [[ "${#stringReal}" -gt "${termWidth}" ]]; then
        ((NORMAL_CHAR_COUNT=0))
        for ((j=0; j<=${#my_out_full}; j++)); do
          if [[ "${my_out_full:${j}:3}" == '^[[' ]]; then
            if [[ "${my_out_full:${j}:5}" =~ ^\^\[\[[[:digit:]]m$ ]]; then
              if [[ ${j} -eq 0 ]]; then
                j=$((j + 5))
              else
                j=$((j + 4))
              fi
            elif [[ "${my_out_full:${j}:8}" =~ ^\^\[\[[[:digit:]]\;[[:digit:]][[:digit:]]m ]]; then
              if [[ ${j} -eq 0 ]]; then
                j=$((j + 8))
              else
                j=$((j + 7))
              fi
            fi
          else
            ((NORMAL_CHAR_COUNT++))
            if [[ ${NORMAL_CHAR_COUNT} -ge ${termWidth} ]]; then
              echo -e "${my_out:0:$((j - 5))}"$c0
              break 1
            fi
          fi
        done
      fi

      if [[ "$i" -ge "$startline" ]]; then
        unset 'out_array[0]'
        out_array=( "${out_array[@]}" )
      fi
    done
  elif [[ "$portraitSet" = "Yes" ]]; then
    for i in "${!fulloutput[@]}"; do
      printf "${fulloutput[$i]}$c0\n"
    done

    printf "\n"

    for ((i=0; i<${#fulloutput[*]}; i++)); do
      [[ -z "$out_array[0]" ]] && continue
      printf "%s\n" "${out_array[0]}"
      unset 'out_array[0]'
      out_array=( "${out_array[@]}" )
    done

  elif [[ "$display_logo" == "Yes" ]]; then
    for i in "${!fulloutput[@]}"; do
      printf "${fulloutput[i]}$c0\n"
    done
  else
    if [[ "$lineWrap" = "Yes" ]]; then
      availablespace=$(($(tput cols) - logowidth + 16)) #I dont know why 16 but it works
      new_out_array=("${out_array[0]}")
      for ((i=1; i<${#out_array[@]}; i++)); do
        lines=$(echo "${out_array[i]}" | fmt -w $availablespace)
        IFS=$'\n' read -rd '' -a splitlines <<<"$lines"
        new_out_array+=("${splitlines[0]}")
        for ((j=1; j<${#splitlines[*]}; j++)); do
          line=$(echo -e "$labelcolor $textcolor  ${splitlines[j]}")
          new_out_array=( "${new_out_array[@]}" "$line" );
        done
      done
      out_array=("${new_out_array[@]}")
    fi
    missinglines=$((${#out_array[*]} + startline - ${#fulloutput[*]}))
    for ((i=0; i<missinglines; i++)); do
      fulloutput+=("${c1}$(printf '%*s' "$logowidth")%s")
    done
    #n=${#fulloutput[*]}
    for ((i=0; i<${#fulloutput[*]}; i++)); do
      # echo "${out_array[@]}"
      case $(awk 'BEGIN{srand();print int(rand()*(1000-1))+1 }') in
        411|188|15|166|609)
          f_size=${#fulloutput[*]}
          o_size=${#out_array[*]}
          f_max=$(( 32768 / f_size * f_size ))
          #o_max=$(( 32768 / o_size * o_size ))
          for ((a=f_size-1; a>0; a--)); do
            while (( (rand=RANDOM) >= f_max )); do :; done
            rand=$(( rand % (a+1) ))
            tmp=${fulloutput[a]} fulloutput[a]=${fulloutput[rand]} fulloutput[rand]=$tmp
          done
          for ((b=o_size-1; b>0; b--)); do
            rand=$(( rand % (b+1) ))
            tmp=${out_array[b]} out_array[b]=${out_array[rand]} out_array[rand]=$tmp
          done
        ;;
      esac
      printf "${fulloutput[i]}$c0\n" "${out_array[0]}"
      if [[ "$i" -ge "$startline" ]]; then
        unset 'out_array[0]'
        out_array=( "${out_array[@]}" )
      fi
    done
  fi
}


infoDisplay () {

	# Default colors
	textcolor="\033[0m"
	labelcolor=$(getColor 'light red')
	[[ "$my_lcolor" ]] && labelcolor="${my_lcolor}"

	if [[ "$art" ]]; then
		source "$art"
	fi

	if [[ "$no_color" == "1" ]]; then
		labelcolor=""
		bold=""
		c0=""
		textcolor=""
	fi


	#########################
	# Info Variable Setting #
	#########################

	# Skip 3 lines
	# let display_index=$display_index+3
	for i in $(seq 1 $skip_lines); do
		out_array=( "${out_array[@]}" "" )
		((display_index++))
	done

	# Host
	if [[ "${display[@]}" =~ "host" ]]; then
		myinfo=$(echo -e "${labelcolor} ${myUser}$textcolor${bold}@${c0}${labelcolor}${myHost}")
		out_array=( "${out_array[@]}" "$myinfo" )
		((display_index++))
	fi

	# OS
	if [[ "${display[@]}" =~ "distro" ]]; then
		if [ -n "$distro_more" ]; then
			mydistro=$(echo -e "$labelcolor OS:$textcolor $distro_more")
		else
			mydistro=$(echo -e "$labelcolor OS:$textcolor $distro $sysArch")
		fi
		out_array=( "${out_array[@]}" "$mydistro $wsl" )
		((display_index++))
	fi

	# Kernel
	if [[ "${display[@]}" =~ "kernel" ]]; then
		mykernel=$(echo -e "$labelcolor Kernel:$textcolor $kernel")
		out_array=( "${out_array[@]}" "$mykernel" )
		((display_index++))
	fi

	# Shell
	if [[ "${display[@]}" =~ "shell" ]]; then
		myshell=$(echo -e "$labelcolor Shell:$textcolor $myShell")
		out_array=( "${out_array[@]}" "$myshell" )
		((display_index++))
	fi

	# CPU
	if [[ "${display[@]}" =~ "cpu" ]]; then
		mycpu=$(echo -e "$labelcolor CPU:$textcolor $cpu")
		out_array=( "${out_array[@]}" "$mycpu" )
		((display_index++))
	fi

	# GPU
	if [[ "${display[@]}" =~ "gpu" ]] && [[ "$gpu" != "Not Found" ]]; then
		if [[ "$gpu_num" -gt 1  ]]; then
			for i in $(seq 0 $(($gpu_num-1)) ); do
				mygpu=$(echo -e "$labelcolor GPU $i:$textcolor ${gpu[$i]}")
				out_array=( "${out_array[@]}" "$mygpu" )
				((display_index++))
			done
		else
			mygpu=$(echo -e "$labelcolor GPU:$textcolor ${gpu[0]}")
			out_array=( "${out_array[@]}" "$mygpu" )
			((display_index++))
		fi
	fi

	# MEM
	if [[ "${display[@]}" =~ "mem" ]]; then
		mymem=$(echo -e "$labelcolor RAM:$textcolor $mem")
		out_array=( "${out_array[@]}" "$mymem" )
		((display_index++))
	fi

	# Disk usage
	if [[  "${display[@]}" =~ "disk" ]]; then
		mydisk=$(echo -e "$labelcolor Disk:$textcolor $diskusage")
		out_array=( "${out_array[@]}" "$mydisk" )
		((display_index++))
	fi

	# Uptime
	if [[ "${display[@]}" =~ "uptime" ]]; then
		myuptime=$(echo -e "$labelcolor Uptime:$textcolor $uptime")
		out_array=( "${out_array[@]}" "$myuptime" )
		((display_index++))
	fi

	# Custom
	# if [[ "$use_customlines" = 1 ]]; then
	# 	customlines
	# fi

	# ASCII artwork
	if [[ "$display_type" == "ASCII" ]]; then
		asciiText
	fi

}


# CODE TEST
# mytime test
# mytime detectdistro
# mytime detecthost
# mytime detectkernel
# mytime detectuptime
# mytime detectcpu
# mytime detectgpu
# mytime detectdisk
# mytime detectmem
# mytime detectshell
# mytime asciiText
# exit 0

##################
# Let's Do This!
##################

if [[ -f "$HOME/.screenfetchOR" ]]; then
	source "$HOME/.screenfetchOR"
fi

if [[ "$overrideDisplay" ]]; then
	verboseOut "Found 'd' flag in syntax. Overriding display..."
	OLDIFS=$IFS
	IFS=';'
	for i in ${overrideDisplay}; do
		modchar="${i:0:1}"
		if [[ "${modchar}" == "-" ]]; then
			i=${i/${modchar}}
			_OLDIFS=IFS
			IFS=,
			for n in $i; do
				if [[ ! "${display[@]}" =~ "$n" ]]; then
					echo "The var $n is not currently being displayed."
				else
					for e in "${!display[@]}"; do
						if [[ ${display[e]} = "$n" ]]; then
							unset 'display[e]'
						fi
					done
				fi
			done
			IFS=$_OLDIFS
		elif [[ "${modchar}" == "+" ]]; then
			i=${i/${modchar}}
			_OLDIFS=IFS
			IFS=,
			for n in $i; do
				if [[ "${valid_display[@]}" =~ "$n" ]]; then
					if [[ "${display[@]}" =~ "$n" ]]; then
						echo "The $n var is already being displayed."
					else
						display+=("$n")
					fi
				else
					echo "The var $n is not a valid display var."
				fi
			done
			IFS=$_OLDIFS
		else
			IFS=$OLDIFS
			i="${i//,/ }"
			display=( "$i" )
		fi
	done
	IFS=$OLDIFS
fi

for i in "${display[@]}"; do
	if [[ -n "$i" ]]; then
		if [[ $i =~ wm ]]; then
			test -z "$WM" && detectwm
			test -z "$Win_theme" && detectwmtheme
		else
			if [[ "${display[*]}" =~ "$i" ]]; then
				if [[ "$errorSuppress" == "1" ]]; then
					detect"${i}" 2>/dev/null
				else
					detect"${i}"
				fi
			fi
		fi
	fi
done


infoDisplay
