###############################################################################################
# Enhanced Audio Recording Script - do-rec.sh
# Version: 1.0
# Author: Evaldo Oliveira <evaldojr@evaldo.com>
# License: MIT
# GitHub: https://github.com/evaldojr/do-rec
#
# Description:
#   This script automates audio recording using the `arecord` utility, providing options for 
#   scheduling, file splitting, and custom output paths. Logs session details and supports 
#   email notifications for session progress and errors.
#
# Features:
#   - Schedule recordings at a specific time or start immediately.
#   - Split recordings into files of configurable durations.
#   - Save recordings locally or to a network location.
#   - Email notifications for start, end, and errors during sessions.
#   - Debug mode for detailed output.
#
# Requirements:
#   - Bash (version 4+ recommended)
#   - `arecord` (from ALSA tools)
#   - `mutt` (for email notifications)
#
# Usage:
#   ./do-rec.sh [options]
#
# Options:
#   -d <hours>     Total recording duration in hours (default: 48)
#   -f <minutes>   Duration of each recorded file in minutes (default: 30)
#   -i <hh:mm>     Schedule start time (24-hour format, e.g., 22:00)
#   -l             Save recordings locally (default: ~/Rec/WAV/)
#   -n             Save recordings to the network path (default: /mnt/nas/RAW_SOUND/)
#   -o <path>      Custom output path
#   -s <rate>      Sampling rate in Hz (default: 48000; options: 8000, 16000, 32000, 48000)
#   -b             Enable debug mode
#   -h             Show help and usage instructions
#
# Examples:
#   1. Record for 24 hours, split into 15-minute files, save locally:
#      ./do-rec.sh -d 24 -f 15 -l
#
#   2. Schedule recording to start at 10:00 PM and save to an external path:
#      ./do-rec.sh -i 22:00 -o /mnt/harddisk/Rec/WAV
#
#   3. Record with a sampling rate of 16000 Hz and enable debug mode:
#      ./do-rec.sh -d 6 -s 16000 -b
#
###############################################################################################
# Configuration Defaults
THIS=$(basename $0)						# Script name
CONFIG_FILE="$HOME/Rec/do-rec.ini" 		# Configuration file

# Default values if no configuration file is present
START_TIME_HHMM=""
let TOTAL_DURATION_SECONDS=48*3600		# to set Default full recording windows to 48 hours
let FILE_DURATION_SECONDS=30*60			# to set Default file size to 30 minutes
let DEBUG=0 							# Debug mode off by default

WAVPATH="$HOME/Rec/WAV/"				# Default local path
NAS="/mnt/nas/RAW_SOUND/"				# Default network path
LOCAL=$WAVPATH							# Default save path

DEVICE_NAME="_Rode"						# Device name suffix
DEVICE="hw:CARD=II,DEV=0"				# ALSA device identifier
let RATE=48000							# Default sample rate (48kHz)
LOG_EMAIL="your-email@domain.com"			# Email for notifications

LOGPATH="$HOME/Rec/log/"				# Log directory

# Load configuration file if it exists
if [ -f "$CONFIG_FILE" ]; then
	source "$CONFIG_FILE"
	#Validate loaded parameters
	if ! [[ "$FILE_DURATION_SECONDS" =~ ^[0-9]+$ && "$TOTAL_DURATION_SECONDS" =~ ^[0-9]+$ ]]; then
		echo "Error: Configuration file contains invalid duration values."
		exit 1
	fi
fi

if [ ! -d "$WAVPATH" ]; then
	mkdir -p "$WAVPATH"
fi

if [ ! -d "$LOGPATH" ]; then
	mkdir -p "$LOGPATH"
fi

# Show script usage instructions
function usage() {
	echo -e "$THIS 1.0 - Enhanced Recorder Script - Author: Evaldo Oliveira <evaldojr@evaldo.com>\n"
	echo "Usage: $THIS [options]"
	echo ""
	echo "Options:"
	echo "  -d <hours>     Total recording duration (in hours) [Default: 48]"
	echo "  -f <minutes>   File split duration (in minutes) [Default: 30]"
	echo "  -i <hh:mm>     Start recording at specific time"
	echo "  -l             Save recordings on ~/Rec/WAV"
	echo "  -n             Save recordings on the Network"
	echo "  -o <path>      Set custom save path"
	echo "  -s <rate>      Set sample rate [Supported rates: 8000, 16000, 32000, 48000]"
	echo "  -b             Enable debug mode"
	echo "  -h             Show this help message and exit"
	echo ""
	echo "Examples:"
	echo "  $THIS -d 24 -f 15 -l                       = 24 hour split in 15 minutes files, store file locally"
	echo "  $THIS -d 24 -f 15 -o /mnt/harddisk/Rec/WAV = 24 hour split in 15 minutes files, store file in external HD"
	echo "  $THIS -i 22:00    -o /mnt/harddisk/Rec/WAV = Start recording at 22:00 using default durations, store file in external HD"
	exit 1
}

function log() {
	LOGFILE=$LOGPATH$START_NAME$DEVICE_NAME.recording
	{
		echo "############## START OF FILE ##############"
		echo "Recording until:     " $(date -d "@$END_TIME_SECONDS" +%Y.%m.%d_%Hh%Mm%Ss) in blocks of "$FILE_DURATION_SECONDS" seconds
		echo "Start of recording:" $(date -d "@$START_TIME_SECONDS" +%Y.%m.%d_%Hh%Mm%Ss)
		echo "----"
		echo "LOCAL         " $LOCAL
		echo "DEVICE_NAME   " $DEVICE_NAME
		echo "DEVICE        " $DEVICE
		echo "RATE          " $RATE
		echo "DEBUG         " $DEBUG
		echo "Format         S16_LE"
		echo "Channels       1"
		echo "Vumeter        mono"
		echo "----"
		echo "TOTAL_DURATION in Hours:"   $(($TOTAL_DURATION_SECONDS /3600))
		echo "TOTAL_DURATION in Minutes:" $(($TOTAL_DURATION_SECONDS /60))
		echo "TOTAL_DURATION in Seconds:" $(($TOTAL_DURATION_SECONDS))
		echo "----"	
		echo "FILE_DURATION in Seconds:" $(($FILE_DURATION_SECONDS))
		echo "FILE_DURATION in Minutes:" $(($FILE_DURATION_SECONDS /60))
		echo "FILE_DURATION in Hours:"   $(($FILE_DURATION_SECONDS /3600))
		echo "----"
		echo "START_TIME_SECONDS :" $START_TIME_SECONDS
		echo "END_TIME_SECONDS :" $END_TIME_SECONDS
		echo " "
	} | tee -a $LOGFILE
	
	if [ ! -f "$LOGFILE" ]; then
		echo "Error: Log file $LOGFILE was not created."
		exit 1
	fi
}

# Function to send an email with the log file content
function send_email_log() {
	# Arguments:
	#   $1 - Email subject
	if [ -z "$EMAIL_CMD" ]; then
		echo "Warning: Email utility not available. Skipping email: $1"
		return
	fi

	if [ -f "$LOGFILE" ]; then
		case $EMAIL_CMD in
			"mutt")
				cat "$LOGFILE" | mutt -s "$1" "$LOG_EMAIL"
				;;
			"mail -s")
				cat "$LOGFILE" | mail -s "$1" "$LOG_EMAIL"
				;;
			"sendmail")
				(echo "Subject: $1"; cat "$LOGFILE") | sendmail "$LOG_EMAIL"
				;;
			"msmtp")
				(echo "Subject: $1"; cat "$LOGFILE") | msmtp "$LOG_EMAIL"
				;;
			*)
				echo "Warning: Unsupported email utility. Skipping email: $1"
				;;
		esac
	else
		echo "Warning: Log file not found, unable to send email: $1"
	fi
}

while getopts "f:d:i:nlomrs:g:ptbh" OPT; do
	case $OPT in
		"f") let FILE_DURATION_SECONDS=$OPTARG*60;;
		"d") let TOTAL_DURATION_SECONDS=$OPTARG*3600;;
		"i") START_TIME_HHMM=$OPTARG; TIMER=1;;

		"n") LOCAL=$NAS;;
		"l") LOCAL=$WAVPATH;;
		"o") LOCAL=$OPTARG;;

		"s") let RATE=$OPTARG;;

		"b") let DEBUG=1;;
		"h") usage;;
		*) usage;;
	esac
done

# Detect available email utility
if command -v mutt > /dev/null; then
	EMAIL_CMD="mutt"
elif command -v mail > /dev/null; then
	EMAIL_CMD="mail -s"
elif command -v sendmail > /dev/null; then
	EMAIL_CMD="sendmail"
elif command -v msmtp > /dev/null; then
	EMAIL_CMD="msmtp"
else
	echo "Error: No supported email utility (mutt, mail, sendmail, msmtp) is installed. Email notifications will not work."
	EMAIL_CMD=""
fi

clear
let TDS=TOTAL_DURATION_SECONDS/3600
let FDS=FILE_DURATION_SECONDS/60

if [ $FILE_DURATION_SECONDS -le 0 ] || [ $TOTAL_DURATION_SECONDS -le 0 ]; then
		echo "Error: Durations must be greater than 0." | tee -a $LOGFILE
		send_email_log "Error: Durations must be greater than 0"
	exit 1
fi

# Wait until scheduled start
if [ -n "$START_TIME_HHMM" ]; then
	START_TIME_SECONDS=$(date -d "$START_TIME_HHMM" +%s)
	if [ "$START_TIME_SECONDS" -lt "$(date +%s)" ]; then
		START_TIME_SECONDS=$((START_TIME_SECONDS + 60*60*24))
	fi
	echo "#### Waiting until " $(date -d "@$START_TIME_SECONDS" +%Y.%m.%d_%Hh%Mm%Ss) " Ctrl-C to abort"
	while [ $(date +%s) -lt $START_TIME_SECONDS ]; do
		sleep 1
	done
	send_email_log "Start Rec Scheduled Session $(date +%Y.%m.%d_%Hh%Mm%Ss)"
else
	# If not scheduled, start now
	let START_TIME_SECONDS=$(date +%s)
fi

# calculate end time
let END_TIME_SECONDS=$(($START_TIME_SECONDS + $TOTAL_DURATION_SECONDS))
trap "echo Interrupted!; exit" SIGINT SIGTERM

while [ $(date +%s) -lt $END_TIME_SECONDS ]; do
	START_NAME=$(date +%Y.%m.%d_%Hh%Mm%Ss)
	WAVFILE=$LOCAL$START_NAME$DEVICE_NAME.wav
	log;
	send_email_log "Rec Session Started $(date +%Y.%m.%d_%Hh%Mm%Ss)"
	arecord $WAVFILE --duration=$FILE_DURATION_SECONDS --device=$DEVICE --format=S16_LE --channels=1 --rate=$RATE --vumeter=mono $( (( DEBUG == 1 )) && echo "-vv" )
done
send_email_log "Rec Session FINISHED $(date +%Y.%m.%d_%Hh%Mm%Ss)"

exit 0
