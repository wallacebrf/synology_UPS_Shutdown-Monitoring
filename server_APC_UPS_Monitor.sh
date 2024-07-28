#!/bin/bash
VERSION="7/26/2024"
#By Brian Wallace

#note if getting errors about syntax error near unexpected token `$'in\r''
#then run command sed -i 's/\r//' script_name.sh

#Change log between version "1/11/2023" and version "7/26/2024"
#->significant re-write of script to reduce code complexity and length. reduced code length by 312 lines while adding much more functionality. 
#->moved all email notifications to new function
#->moved other commonly used code to functions
#->added ability to decide if UPS shutdown is commanded when 1.) run time remaining only, 2.) time remaining only, 3.) run time remaining or battery voltage, 4.) time remaining or battery voltage, 5.) battery voltage only
#->added ability to individually turn on/off load shedding of PDU, surveillance station, or PLEX
#->added ability to control load shedding to be commanded when 1.) run time remaining only, 2.) time remaining only, 3.) run time remaining or battery voltage, 4.) time remaining or battery voltage, 5.) battery voltage only
#->load shedding thresholds are independent of shutdown parameters to allow finer grain control of when load shedding occurs. 
#->added battery over temperature protection. if battery is too hot while on battery system will shut down
#->added ability to enable or disable email notifications
#->changed code to allow un-doing load shedding even after system restarts
#->new email function can send emails using either "sendmail" command or the "ssmtp" command
#->added logic to verify the UPS NMC outlet group load shedding settings to make sure the UPS will not turn off its outlet groups before this script. otherwise the UPS will turn off the system in an uncontrolled manner
#->now use higher precision battery voltage, temperature, and capacity with tenth's digit accuracy
#->corrected error in DSM7 where docker is now called container manager
#->added logic to determine DSM version to control the script's use of "docker" or "container manager"


#***************************************************
#Dependencies:
#***************************************************
#2.) in order to send emails, this script requires either installation of Synology MailPlus server package in package center OR to ensure Synology control panel notification settings are configured and working. if MailPlus server package is installed, the script will default to that program
	#the mail plus server must be properly configured to relay received messages to another email account. 
#3.) this script is Dependent on a docker container for SNMP_SET commands using the "elcolio/net-snmp" container located here: https://hub.docker.com/r/elcolio/net-snmp
	#this is required as the Synology system does not contain the snmp_set commands. the set command is used to control the PDU outlets and to command the UPS to shutdown
	#the container does not always run, it is run once when a SET command needs to be executed 
#4.) A scheduled task to re-set the shutdown log file is required
	#to do so, create a scheduled task on boot up in Synology Task Scheduler to add the following line

		#echo "0,0" > $notification_file_location/$UPS_shutdown_status_file
		#where "$notification_file_location/$UPS_shutdown_status_file" is the location you want the files stored and are variables configured below
#5.) this script only supports SNMP V3. This is because lower versions are less secure especially when using the set commands that have the ability to remove power to the systems
	#SNMP must be enabled on the host NAS for the script to gather the NAS NAME
	#SNNMP must be enabled on the target APC UPS network management card
	#SNNMP must be enabled on the PDU
	#the snmp settings for the NAS, UPS, and PDU can all be entered into the web administration page
#6.) This script can be run through Synology Task Scheduler. However it has been observed that running large scripts like this as frequently as every 60 seconds causes the synoschedtask system application to use large amounts of resources and causes the script to execute slowly
	#details of this issue can be seen here:
	#https://www.reddit.com/r/synology/comments/kv7ufq/high_disk_usage_on_disk_1_caused_by_syno_task/
	#to fix this it is recommend to directly edit the crontab at /etc/crontab
	
	#this can be accomplished using vi /etc/crontab
	
	#add the following line: 
	#	*	*	*	*	*	root	$path_to_file/$filename
	#details on crontab can be found here: https://man7.org/linux/man-pages/man5/crontab.5.html
		
		
#***************************************************
#Power Distribution Unit (PDU) Outlet Control load shedding:
#***************************************************
#this script is written around the use of a cyberpower pdu81003 power distribution unit and the associated SNMP commands/IODs that it support.  
#if no PDU is available, ensure to un-check the "Enable Load Shed Control of PDU Outlets" the web administration page. 
#if a different PDU model or manufacture is utilized the script may not work as the SNMP commands will likely not match. 
#if PDU load shedding is desired, the PDU must have SNMP enabled for communications and control. 
#when load shedding occurs is configurable through the web administration page. 
# --> load shedding can be controlled by one of five things:
# --> 1.) run time remaining only
# --> 2.) time on battery only
# --> 3.) run time remaining or battery voltage
# --> 4.) time on battery or battery voltage
# --> 5.) battery voltage only
#outlets will be turned back on when UPS power is restored


#***************************************************
#Synology Surveillance Station Application Shutdown Load Shedding:
#***************************************************
#the script can terminate the Synology surveillance station application which can draw significant power from the CPU and GPU
#when load shedding occurs is configurable through the web administration page. 
# --> load shedding can be controlled by one of five things:
# --> 1.) run time remaining only
# --> 2.) time on battery only
# --> 3.) run time remaining or battery voltage
# --> 4.) time on battery or battery voltage
# --> 5.) battery voltage only
#surveillance Station will be restarted when UPS power is restored 


#***************************************************
#PLEX Media Server Application Shutdown Load Shedding:
#***************************************************
#the script can terminate any active PLEX streams which if performing transcoding can use high levels of CPU power and wattage
#when load shedding occurs is configurable through the web administration page. 
# --> load shedding can be controlled by one of five things:
# --> 1.) run time remaining only
# --> 2.) time on battery only
# --> 3.) run time remaining or battery voltage
# --> 4.) time on battery or battery voltage
# --> 5.) battery voltage only
#PLEX will be restarted when UPS power is restored
	

#***************************************************
#UPS Communications Loss Handling:
#***************************************************
#this script supports shutting down the server in the event of extended duration UPS network communications failures. 
	#This can be enabled and disabled in the web administration page. 
	#the purpose is to protect the system during extended network failures as the script will not be able to determine if the UPS run time is low which could cause the system to lose power and shutdown un-gracefully. 
#the script also allows for immediate shutdown of the system if the network communications are lost while the UPS is actively running on battery power. 
	#this is in case network switches between the system and the UPS lose power before the system does. 
	#this protects the system as it would not be able to determine the remaining run time of the battery as it is not guaranteed that communications will resume before the run time goes too low.  
#the amount of time [hours (1 through 20)] required to pass while UPS communications are down is user configurable in the web administration page
#starting half way through the configured delay time, a warning email will be sent to the configured email address warning that the system will be shutdown soon
#during the entire duration of failed network communications, a warning email will be sent to the configured email address every 2 minutes to ensure the administrator of the system knows of the error. 

	

 #***************************************************
#UPS Output Shutdown Post NAS System Shutdown:
#***************************************************
#this script supports commanding the UPS to turn off all outlet groups after the NAS system has been commanded to shutdown. 
#The delay time between when the NAS system is shutdown and when the outlet groups are turned off is user configurable. 
#if the outlet groups are commanded to turn off, they will NOT turn back on when AC power is restored to the UPS


#Debug Log dated 7/20/24
#1.) everything OK ------------------------------------------------------------------------------------------------------------- VERIFIED OK 7/20/24

#2.) UPS communications Offline while AC is OK
#	2 a.) Verify email sent every x minutes------------------------------------------------------------------------------------- VERIFIED OK 7/20/24
#	2 b.) verify email sent when UPS communications are down for too long, should get email when time delay is at 50%----------- VERIFIED OK 7/20/24
#	2 c.) verify when UPS communications are down for too long, the system shuts down------------------------------------------- VERIFIED OK 7/20/24
#	2 d.) verify while system is shutting down script does not run-------------------------------------------------------------- VERIFIED OK 7/20/24
#	2 e.) Verify if internet is down, email notifications are skipped----------------------------------------------------------- VERIFIED OK 7/20/24

#3.) UPS communications Online, no AC power
#	3 a.) verify email sent every x minutes when on battery power--------------------------------------------------------------- VERIFIED OK 7/20/24

#	3 b.) while communications remain ONLINE, verify system shuts down when
#	3 b.) 1.) run time remaining is below configured setting, and temperature is OK--------------------------------------------- VERIFIED OK 7/20/24
#	3 b.) 2.) run time remaining is below configured setting, and temperature is high------------------------------------------- VERIFIED OK 7/20/24
#	3 b.) 3.) run time remaining is above configured setting, and temperature is high------------------------------------------- VERIFIED OK 7/20/24
#	3 b.) 4.) run time remaining is above configured setting, and temperature is OK--------------------------------------------- VERIFIED OK 7/20/24
#	3 b.) 5.) time on battery is above configured setting, and temperature is OK------------------------------------------------ VERIFIED OK 7/20/24
#	3 b.) 6.) time on battery is above configured setting, and temperature is high---------------------------------------------- VERIFIED OK 7/20/24
#	3 b.) 7.) time on battery is below configured setting, and temperature is high---------------------------------------------- VERIFIED OK 7/20/24
#	3 b.) 8.) time on battery is below configured setting, and temperature is OK------------------------------------------------ VERIFIED OK 7/20/24
#	3 b.) 9.) run time remaining is below configured setting, and temperature is OK, battery voltage above threshold------------ VERIFIED OK 7/20/24
#	3 b.) 11.) run time remaining is below configured setting, and temperature is high, battery voltage above threshold--------- VERIFIED OK 7/20/24
#	3 b.) 12.) run time remaining is above configured setting, and temperature is high, battery voltage above threshold--------- VERIFIED OK 7/20/24
#	3 b.) 13.) run time remaining is above configured setting, and temperature is OK, battery voltage above threshold----------- VERIFIED OK 7/20/24
#	3 b.) 14.) run time remaining is below configured setting, and temperature is OK, battery voltage below threshold----------- VERIFIED OK 7/20/24
#	3 b.) 15.) run time remaining is below configured setting, and temperature is high, battery voltage below threshold--------- VERIFIED OK 7/20/24
#	3 b.) 16.) run time remaining is above configured setting, and temperature is high, battery voltage below threshold--------- VERIFIED OK 7/20/24
#	3 b.) 17.) run time remaining is above configured setting, and temperature is OK, battery voltage above threshold----------- VERIFIED OK 7/20/24
#	3 b.) 18.) time on battery is below configured setting, and temperature is OK, battery voltage is below threshold----------- VERIFIED OK 7/20/24
#	3 b.) 19.) time on battery is below configured setting, and temperature is OK, battery voltage is above threshold----------- VERIFIED OK 7/20/24
#	3 b.) 20.) time on battery is below configured setting, and temperature is high, battery voltage is below threshold--------- VERIFIED OK 7/20/24
#	3 b.) 21.) time on battery is above configured setting, and temperature is OK, battery voltage is below threshold----------- VERIFIED OK 7/20/24
#	3 b.) 21.) battery voltage trigger only and temperature is OK, battery voltage is below threshold--------------------------- VERIFIED OK 7/20/24
#	3 b.) 21.) battery voltage trigger only and temperature is high, battery voltage is below threshold------------------------- VERIFIED OK 7/20/24
#	3 b.) 21.) battery voltage trigger only and temperature is OK, battery voltage is above threshold--------------------------- VERIFIED OK 7/20/24
#	3 b.) 21.) battery voltage trigger only and temperature is high, battery voltage is above threshold------------------------- VERIFIED OK 7/20/24
#	3 b.) 21.) battery voltage trigger only and time on battery and run time remaining are ignored------------------------------ VERIFIED OK 7/20/24


#	3 c.) verify load shed occurs when
#	3 c.) 1.) run time remaining is below configured setting-------------------------------------------------------------------- VERIFIED OK 7/20/24
#	3 c.) 4.) run time remaining is above configured setting-------------------------------------------------------------------- VERIFIED OK 7/20/24
#	3 c.) 5.) time on battery is above configured setting----------------------------------------------------------------------- VERIFIED OK 7/20/24
#	3 c.) 7.) time on battery is below configured setting----------------------------------------------------------------------- VERIFIED OK 7/20/24
#	3 c.) 9.) run time remaining is below configured setting, and battery voltage above threshold------------------------------- VERIFIED OK 7/20/24
#	3 c.) 11.) run time remaining is below configured setting, and battery voltage above threshold------------------------------ VERIFIED OK 7/20/24
#	3 c.) 12.) run time remaining is above configured setting, battery voltage below threshold---------------------------------- VERIFIED OK 7/20/24
#	3 c.) 13.) run time remaining is above configured setting, battery voltage above threshold---------------------------------- VERIFIED OK 7/20/24
#	3 c.) 18.) time on battery is below configured setting, battery voltage is below threshold---------------------------------- VERIFIED OK 7/20/24
#	3 c.) 19.) time on battery is below configured setting, battery voltage is above threshold---------------------------------- VERIFIED OK 7/20/24
#	3 c.) 20.) time on battery is above configured setting, battery voltage is below threshold---------------------------------- VERIFIED OK 7/20/24
#	3 c.) 21.) time on battery is above configured setting, battery voltage is above threshold---------------------------------- VERIFIED OK 7/20/24

#	3 d.) verify PLEX is commanded to turn off---------------------------------------------------------------------------------- VERIFIED OK 
#	3 e.) verify SS is commanded to turn off------------------------------------------------------------------------------------ VERIFIED OK 
#	3 f.) while on battery, kill UPS communications, verify system shuts down immediately--------------------------------------- VERIFIED OK 7/20/24
#   3 g.) while on battery, when system shuts down, UPS outlet group delay time is properly commanded -------------------------- VERIFIED OK 7/20/24
#   3 h.) while on battery, when system shuts down, UPS turns outlets off after set delay period ------------------------------- VERIFIED OK 7/20/24
#   3 h.) verify PDU load shedding turns outlets off---------------------------------------------------------------------------- VERIFIED OK 7/20/24

#4.) after load shedding and before system shutdown, power comes back
#	4 a.) verify outlets turn back on------------------------------------------------------------------------------------------- VERIFIED OK 7/20/24
#	4 b.) verify PLEX turns back on--------------------------------------------------------------------------------------------- VERIFIED OK 
#	4 c.) verify SS turns back on----------------------------------------------------------------------------------------------- VERIFIED OK 
#	4 d.) verify that if the PDU outlets cannot be turned off or cannot be turned on, that the error email is sent-------------- VERIFIED OK 7/20/24

#5.) misc
#	5 a.) verify emails sent if config file is missing-------------------------------------------------------------------------- VERIFIED OK 7/20/24
#	5 b.) verify emails sent if config file has incorrect number of parameters-------------------------------------------------- VERIFIED OK 7/20/24
#	5 c.) verify after system is restarted after a commanded shutdown that items load shed are restarted------------------------ VERIFIED OK 7/20/24

##########################################################################
##########################################################################
#variable handling and initialization
##########################################################################
##########################################################################

#########################################################
#EMAIL SETTINGS USED IF CONFIGURATION FILE IS UNAVAILABLE
#These variables will be overwritten with new corrected data if the configuration file loads properly. 
email_address="email@email.com"
from_email_address="email@email.com"
#########################################################

UPS_shutdown_status_file="UPS_shutdown_status.txt"
UPS_load_shed_status_file="UPS_load_shed_status.txt"
ups_coms_fail_tracker="ups_coms_fail_tracker.txt"
ups_email_notification_last_sent_tracker="ups_email_notification_last_sent_tracker.txt"
ups_email_notification_file="ups_email_notification_file.txt"
shutdown_email_contents="shutdown_email_contents.txt"
pdu_outlet_failure_email_last_sent_tracker="pdu_outlet_failure_email_last_sent_tracker.txt"
SS_notification_last_sent_tracker="SS_notification_last_sent_tracker.txt"
sendmail_installed=0
ups_email_delay=60 #number of minutes to wait between UPS notification emails, this will be used if the config file does not load correctly
enable_notifications=1 #this will be used if the config file does not load correctly to ensure emergency notifications are still sent
UPS_monitor_Heartbeat="UPS_monitor_Heartbeat.txt"
debug_mode=0 #set to 1 to make script use debug variables below and to have much more verbose output to the screen and manually control variables.

##########################################################################
#delete lines 227 through 251 as these are for my personal use and are not needed
##########################################################################
server_type=1 #1=server2, 2=server_NVR, 3=server_plex

if [ $server_type -eq 1 ]; then
	nas_url="localhost" #needed to collect the name of the NAS running this script
	configuration_file="server2_UPS_monitor_config2.txt"
	config_file_location="/volume1/web/config/config_files/config_files_local"
	notification_file_location="/volume1/web/logging/notifications"
	lock_file_name="server_APC_UPS_Monitor2.lock"
fi

if [ $server_type -eq 2 ]; then
	nas_url="localhost" #needed to collect the name of the NAS running this script
	configuration_file="serverNVR_UPS_monitor_config2.txt"
	config_file_location="/volume1/web/logging"
	notification_file_location="/volume1/web/logging/notifications"
	lock_file_name="server_APC_UPS_Monitor2.lock"
fi

if [ $server_type -eq 3 ]; then
	nas_url="localhost" #needed to collect the name of the NAS running this script
	configuration_file="server_plex_UPS_monitor_config2.txt"
	config_file_location="/volume1/web/config/config_files/config_files_local"
	notification_file_location="/volume1/web/logging/notifications"
	lock_file_name="server_APC_UPS_Monitor2.lock"
fi 

##########################################################################
#check that the script is running as root or some of the commands required will not work
##########################################################################
if [[ $( whoami ) != "root" ]]; then
	echo -e "ERROR - Script requires ROOT permissions, exiting script"
	exit 1
fi

##########################################################################
#create a lock file in the ramdisk directory to prevent more than one instance of this script from executing  at once
##########################################################################

if ! mkdir "$notification_file_location/$lock_file_name"; then
	echo "Failed to acquire lock.\n" >&2
	exit 1
fi
trap 'rm -rf $notification_file_location/$lock_file_name' EXIT #remove the lockdir on exit


##########################################################################
#Main Script start
##########################################################################

##########################################################################
#Functions used within the script
##########################################################################


#########################################################
#this function pings google.com to confirm internet access is working prior to sending email notifications 
#########################################################
check_internet() {
ping -c1 "google.com" > /dev/null #ping google.com									
	local status=$?
	if ! (exit $status); then
		false
	else
		true
	fi
}
#########################################################
#this function is used to send notifications
#########################################################
function send_mail(){
#email_last_sent_log_file=${1}			this file contains the UNIX time stamp of when the email is sent so we can track how long ago an email was last sent
#message_text=${2}						this string of text contains the body of the email message
#email_subject=${3}						this string of text contains the email subject line
#email_contents_file=${4}				this file is where the contents of the email are saved prior to sending and it contains the log of the email transmission, either will indicated email sent successfully or will include the error details
#error_message=${5}						this string of text is only displayed when the script is executed from the CLI, it will be part of the error message if the email is not sent correctly
#email_interval=${6}					this numerical value will control how many minutes must pass before the next email is allowed to be sent
#use_mail_plus_server=${7}				this will control if mail plus server (IE sendmail) or ssmtp will be used to send emails. ssmtp is much slower to execute but does not require the installation of mail plus server
	if [[ $enable_notifications == 1 ]]; then
		local message_tracker=""
		local time_diff=0
		echo -e "${2}"
		echo ""
		if check_internet; then
			local current_time=$( date +%s )
			if [ -r "${1}" ]; then #file is available and readable 
				read message_tracker < "${1}"
				time_diff=$((( $current_time - $message_tracker ) / 60 ))
			else
				echo -n "$current_time" > "${1}"
				time_diff=$(( ${6} + 1 ))
			fi
					
			if [ $time_diff -ge ${6} ]; then
				local now=$(date +"%T")
				echo "the email has not been sent in over ${6} minutes, re-sending email"
				if [[ ${7} == 1 ]]; then #if this is a value of 1, use mail plus
					#verify MailPlus Server package is installed and running as the "sendmail" command is not installed in Synology by default. the MailPlus Server package is required
					local install_check=$(/usr/syno/bin/synopkg list | grep MailPlus-Server)
					if [ "$install_check" != "" ];then
						#"MailPlus Server is installed, verify it is running and not stopped"
						local status=$(/usr/syno/bin/synopkg is_onoff "MailPlus-Server")
						if [ "$status" = "package MailPlus-Server is turned on" ]; then
							echo "from: $from_email_address " > "${4}"
							echo "to: $email_address " >> "${4}"
							echo "subject: ${3}" >> "${4}"
							echo "" >> "${4}"
							echo -e "$now - ${2}" >> "${4}" #adding the mail-body text. 
							local email_response=$(sendmail -t < "${4}"  2>&1)
							if [[ "$email_response" == "" ]]; then
								echo "" |& tee -a "${4}"
								echo -e "Email to \"$email_address\" Sent Successfully\n" |& tee -a "${4}"
								message_tracker=$current_time
								time_diff=0
								echo -n "$message_tracker" > "${1}"
							else
								echo -e "Warning, an error occurred while sending the ${5} notification email. the error was: $email_response\n" |& tee -a "${4}"
							fi
						else
							echo -e "Warning Mail Plus Server is Installed but not running, unable to send email notification\n" |& tee -a "${4}"
						fi
					else
						echo -e "Mail Plus Server is not installed, unable to send email notification\n" |& tee -a "${4}"
					fi
				else #since the value is not equal to 1, use ssmtp command
					echo "From: $from_email_address " > "${4}"
					echo "Subject: ${3}" >> "${4}"
					echo "" >> "${4}"
					echo -e "\n$now - ${2}\n" >> "${4}" #adding the mail-body text. 
					
					#the "ssmtp" command can only take one email address destination at a time. so if there are more than one email addresses in the list, we need to send them one at a time
					address_explode=(`echo $email_address | sed 's/;/\n/g'`) #explode on the semicolon separating the different possible addresses
					local xx=0
					for xx in "${!address_explode[@]}"; do
						local email_response=$(ssmtp ${address_explode[$xx]} < "${4}"  2>&1)
						if [[ "$email_response" == "" ]]; then
							echo "" |& tee -a "${4}"
							echo -e "Email to \"${address_explode[$xx]}\" Sent Successfully\n" |& tee -a "${4}"
							message_tracker=$current_time
							time_diff=0
							echo -n "$message_tracker" > "${1}"
						else
							echo -e "Warning, an error occurred while sending the ${5} notification email. the error was: $email_response\n" |& tee -a "${4}"
						fi
					done
				fi
			else
				echo -e "Only $time_diff minuets have passed since the last notification, email will be sent every ${6} minutes. $(( ${6} - $time_diff )) Minutes Remaining Until Next Email\n"
			fi
		else
			echo -e "Internet is not available, skipping sending email\n" |& tee -a "${4}"
		fi
	else
		echo "Unable to send notifications, pleas enable notifications in the web-interface"
	fi
}

#####################################
#Function to send email when PDU outlet is turned off
#####################################
function PDU_outlet_off_email(){
#outlet number=${1}
	send_mail "$notification_file_location/$pdu_outlet_failure_email_last_sent_tracker" "ALERT $nas_name has turned off PDU outlet #${1}" "$nas_name has turned off PDU outlet #${1}" "$notification_file_location/$ups_email_notification_file" "outlet #${1} turn-off" 0 1
}

#####################################
#Function to send email when PDU outlet is turned on
#####################################
function PDU_outlet_on_email(){
#outlet number=${1}
	send_mail "$notification_file_location/$pdu_outlet_failure_email_last_sent_tracker" "ALERT $nas_name has turned ON PDU outlet #${1} now that UPS power has been restored" "$nas_name has turned ON PDU outlet #${1}" "$notification_file_location/$ups_email_notification_file" "outlet #${1} turn-on" 0 1
}

#####################################
#Function to send email when PDU outlet commands fail
#####################################
function PDU_outlet_error_email(){
#outlet number=${1}
	send_mail "$notification_file_location/$pdu_outlet_failure_email_last_sent_tracker" "ALERT $nas_name has attempted to change the state of PDU outlet #${1} but the outlet did not change state as commanded" "$nas_name has failed to command PDU outlet #${1}" "$notification_file_location/$ups_email_notification_file" "outlet #${1} command failure" 0 1
}

#####################################
#Function to send email when getting data from UPS fails
#####################################
function NAS_name_error_email(){
	send_mail "$notification_file_location/${0##*/}_UPS_SNMP_Error_last_sent.txt" "ALERT NAS at IP $nas_url appears to have an issue with SNMP as the NAS Name could not be determined" "ALERT NAS at IP $nas_url appears to have an issue with SNMP" "$notification_file_location/$ups_email_notification_file" "NAS Name Error" 60 1
}

#####################################
#Function to send email when UPS SNMP received data is bad
#####################################
function ups_snmp_data_bad_email(){
	send_mail "$notification_file_location/${0##*/}_UPS_SNMP_Error_last_sent.txt" "ALERT $nas_name could not receive SNMP data from UPS at $UPS_url. The UPS either 1.) does not have SNMP enabled 2.) does not have SNMP configured correctly 3.) the script web-administration page UPS SNMP values do not match what the UPS is configured. Please check the UPS and script configuration" "ALERT $nas_name could not receive SNMP data from UPS at $UPS_url" "$notification_file_location/$ups_email_notification_file" "UPS SNMP error" 60 1
}

#####################################
#Function to perform shutdown of active PLEX streams
#####################################
function plex_stream_terminate(){
#plex_IP_address=${1}
#DSM_version=${2}
#plex_installed_volume=${3} 	  "volume2" for example
#PDU_load_shed_active=${4}
#Surveillance_Station_Load_shed_active=${5}
#load_shed_file_location=${6}
	if [ "${3}" = "" ];then
		echo "PLEX Installed Volume is BLANK, If PLEX is installed, please configure the volume details"
	else
		if [ "${1}" = "" ];then
			echo "PLEX IP Address is BLANK, If PLEX is installed, please configure IP Address"
		else
			echo "UPS on battery power, need to shutdown active PLEX streams to reduce system power usage"
			
			local MinDSMVersion=7.0
			/usr/bin/dpkg --compare-versions "$MinDSMVersion" gt "${2}"
			if [ "$?" -eq "0" ]; then
				echo "DSM version is 6.x.x"
				echo "Current DSM Version Installed: ${2}"
				local plex_package_name="Plex Media Server"
				local plex_Preferences_loction="/${3}/Plex/Library/Application Support/Plex Media Server/Preferences.xml"
			else
				echo "DSM version is 7.x.x"
				echo "Current DSM Version Installed: ${2}"
				local plex_package_name="PlexMediaServer"
				local plex_Preferences_loction="/${3}/PlexMediaServer/AppData/Plex Media Server/Preferences.xml"
			fi

			#if PLEX is running we want to terminate any active users, this can also save some battery run time
			local PMS_IP=${1} #IP of PLEX server
			local TOKEN=$(cat "$plex_Preferences_loction" | grep -oP 'PlexOnlineToken="\K[^"]+')
			
			#ALERT (no spaces allowed)
			#message sent to PLEX client (no spaces allowed)
			local MSG='Power_Outtage_--_UPS_Runtime_Low_--_Shutting_Down_Plex'

			#Start by getting the active sessions
			local sessionURL="http://$PMS_IP:32400/status/sessions?X-Plex-Client-Identifier=123456&X-Plex-Token=$TOKEN"
			
			local response=$(curl -i -k -L -s $sessionURL)
			local sessions=$(printf %s "$response"| grep '^<Session*'| awk -F= '$1=="id"{print $2}' RS=' '| cut -d '"' -f 2)

			# Active sessions id's now stored in sessions variable, so convert to an array_sess
			set -f                      # avoid globbing (expansion of *).
			local array_sess=(${sessions//:/ })
			for z in "${!array_sess[@]}"
			do
				echo "PLEX Active - Need to kill session: ${array_sess[z]}"
				local killURL="http://$PMS_IP:32400/status/sessions/terminate?sessionId=${array_sess[z]}&reason=$MSG&X-Plex-Client-Identifier=$CLIENT_IDENT&X-Plex-Token=$TOKEN"
				# Kill it
				response=$(curl -i -k -L -s $killURL)
				# Get response
				local http_status=$(echo "$response" | grep HTTP |  awk '{print $2}')
				if [ $http_status -eq "200" ]; then
					echo "Success with killing of stream ${array_sess[z]}"
				else
					echo "Something went wrong here"
				fi
			done
			#file contents: "PDU_load_shed_active"  ||  "PLEX_load_shed_active"  ||  "Surveillance_Station_Load_shed_active" 
			echo "${4},1,${5} " > "${6}"
		fi
	fi
}


#####################################
#Function to Stop Synology Surveillance Station package to reduce system power draw
#####################################
function shutdown_Synology_SS(){
#unused=${1}
#email_tracking_file=${2}
#email_contents_file_name=${3}
#PDU_load_shed_active=${4}
#PLEX_load_shed_active=${5}
#load_shed_file_location=${6}
#sendmail_available=${7}
#surveillance_station_installed_on_system=${8}
#Surveillance_Station_Load_shed_active=${9}
#synology_ss_load_shed_enable=${10}
#nas_name=${11}
	if [ ${10} -eq 1 ]; then #SS load shedding enabled
		if [ ${8} -eq 1 ]; then #does the system have Surveillance Station installed? if it does, perform load shedding
			if [ ${9} -eq 0 ]; then #load shedding has not already been performed 
				echo "UPS on battery power, need to shutdown the package SurveillanceStation to reduce system power usage"
				local status=$(/usr/syno/bin/synopkg is_onoff "SurveillanceStation")
				if [ "$status" = "package SurveillanceStation is turned on" ]; then
					echo "Stopping Synology Surveillance Station...."
					/usr/syno/bin/synopkg stop "SurveillanceStation"
					sleep 1
					
					status=$(/usr/syno/bin/synopkg is_onoff "SurveillanceStation")
					if [ "$status" = "package SurveillanceStation is turned on" ]; then
						send_mail "${2}" "ALERT ${11} has FAIELD to stop the package \"SurveillanceStation\"" "${11} FAIELD to Stop package \"SurveillanceStation\"" "${3}" "SS Shutdown " 60 ${7}
					else
						echo -e "\n\nSurveillance Station Successfully Shutdown\n\n"
						
						#file contents: "PDU_load_shed_active"  ||  "PLEX_load_shed_active"  ||  "Surveillance_Station_Load_shed_active" 
						echo "${4},${5},1 " > "${6}"
						Surveillance_Station_Load_shed_active=1
						
						send_mail "${2}" "ALERT ${11} has stopped the package \"SurveillanceStation\"" "${11} Stopped package \"SurveillanceStation\"" "${3}" "SS Shutdown " 0 ${7}
					fi
				else
					echo "Surveillance Station Already Shutdown, no need to stop the package"
				fi
			else
				echo "Surveillance Station load shed has already been performed"
			fi
		else
			echo "Surveillance Station Not Installed on system"
		fi
	else
		echo "SS Load Shedding Disabled"
	fi
}

#####################################
#Function to restart Synology Surveillance Station package after battery power has been restored
#####################################
function restart_Synology_SS(){
#email_address=${1}
#email file location=${2}
#email file name=${3}
#PDU_load_shed_active=${4}
#PLEX_load_shed_active=${5}
#load_shed_file_location=${6}
#sendmail_available=${7}
#from=${8}
	echo "UPS no longer on battery power, re-starting the package SurveillanceStation"
	local status=$(/usr/syno/bin/synopkg is_onoff "SurveillanceStation")
	if [ "$status" = "package SurveillanceStation is turned on" ]; then
		echo -e "\n\nSynology Surveillance Station is already running\n\n"
	else
		echo -e "\n\nRestarting Synology Surveillance Station....\n\n"
		/usr/syno/bin/synopkg start "SurveillanceStation"
		sleep 1
		
		status=$(/usr/syno/bin/synopkg is_onoff "SurveillanceStation")
		if [ "$status" = "package SurveillanceStation is turned on" ]; then
			echo "Surveillance Station Successfully Restarted"
			
			#file contents: "PDU_load_shed_active"  ||  "PLEX_load_shed_active"  ||  "Surveillance_Station_Load_shed_active" 
			echo "${4},${5},0 " > "${6}"
			
			send_mail "$notification_file_location/$SS_notification_last_sent_tracker" "ALERT $nas_name has restarted the package \"SurveillanceStation\" after UPS power was restored. The UPS Voltage: $input_voltage VAC, Battery Capacity: $battery_capacity_decimal %, Runtime Remaining: ${battery_run_time_remaining_array[1]} Hours: ${battery_run_time_remaining_array[2]} Minutes: ${battery_run_time_remaining_array[3]} Seconds." "$nas_name has restarted package \"SurveillanceStation\" after UPS power was restored" "$notification_file_location/$ups_email_notification_file" "SS restart" 0 ${7}
		else
			send_mail "$notification_file_location/$SS_notification_last_sent_tracker" "ALERT $nas_name has FAILED to restart the package \"SurveillanceStation\" after UPS power was restored. The UPS Voltage: $input_voltage VAC, Battery Capacity: $battery_capacity_decimal %, Runtime Remaining: ${battery_run_time_remaining_array[1]} Hours: ${battery_run_time_remaining_array[2]} Minutes: ${battery_run_time_remaining_array[3]} Seconds." "$nas_name has FAILED to restart package \"SurveillanceStation\" after UPS power was restored" "$notification_file_location/$ups_email_notification_file" "SS restart failed" 60 ${7}
		fi
	fi
}

#####################################
#Function to turn the cyberpower PDU outlets on or off to act as load shedding
#####################################
function load_shed_PDU_ON_OFF(){
#outlet number=${1} (1 through 16)
#command=${2} ("on" or "off")
#load_shed_file_location=${3}
#PLEX_load_shed_active=${4}
#Surveillance_Station_Load_shed_active=${5}
#PDU_AuthPass1=${6}
#PDU_PrivPass2=${7}
#PDU_snmp_user=${8}
#PDU_IP=${9}
#PDU_snmp_auth_protocol=${10}
#PDU_snmp_privacy_protocol=${11}
#docker_installed=${12}

	if [ ${12} -eq 1 ]; then #is docker installed and running? 
		ping -c1 ${9} > /dev/null #ping the PDU to ensure it is on line
														
		if [ $? -eq 0 ]; then #the PDU is online 
			if [ "${9}" = "" ];then
				echo "PDU IP Address is BLANK, if using a PDU, please configure the SNMP settings"
			else
				if [ "${8}" = "" ];then
					echo "PDU Username is BLANK, if using a PDU, please configure the SNMP settings"
				else
					if [ "${7}" = "" ];then
						echo "PDU Privacy Password is BLANK, if using a PDU, please configure the SNMP settings"
					else
						if [ "${6}" = "" ];then
							echo "PDU Authentication Password is BLANK, if using a PDU, please configure the SNMP settings"
						else
							#get outlet state (ON/OFF) for each outlet of PDU
							local outlet_ON_OFF_status=$(snmpwalk -v3 -r 1 -l authPriv -u ${8} -a ${10} -A ${6} -x ${11} -X ${7} ${9}:161 1.3.6.1.4.1.3808.1.1.3.3.5.1.1.4.${1} -Oqv)
							
							if [ "${2}" = "on" ]; then #turn outlet ON
								echo "Turning outlet #${1} ON"
								if [ "$outlet_ON_OFF_status" = "1" ]; then
									echo "Outlet #${1} is already ON"
									#file contents: "PDU_load_shed_active"  ||  "PLEX_load_shed_active"  ||  "Surveillance_Station_Load_shed_active" 
									echo "0,${4},${5} " > "${3}"
								else
									#outlet is currently off, turn it on
									docker run --rm=true elcolio/net-snmp snmpset -v3 -l authPriv -u "${8}" -a "${10}" -A "${6}" -x "${11}" -X "${7}" "${9}":161 1.3.6.1.4.1.3808.1.1.3.3.3.1.1.4.${1} i 1
									
									#get the status to confirm the outlet is ON
									outlet_ON_OFF_status=$(snmpwalk -v3 -r 1 -l authPriv -u ${8} -a ${10} -A ${6} -x ${11} -X ${7} ${9}:161 1.3.6.1.4.1.3808.1.1.3.3.5.1.1.4.${1} -Oqv)
									if [ "$outlet_ON_OFF_status" = "1" ]; then
										echo "Outlet #${1} Successfully Turned ON"
										PDU_outlet_on_email ${1}
										#file contents: "PDU_load_shed_active"  ||  "PLEX_load_shed_active"  ||  "Surveillance_Station_Load_shed_active" 
										echo "0,${4},${5} " > "${3}"
									else
										echo "Outlet #${1} Failed To Turned ON"
										PDU_outlet_error_email ${1}
									fi
								fi
							fi
							
							if [ "${2}" = "off" ]; then #turn outlet OFF
								echo "Turning outlet #${1} OFF"
								if [ "$outlet_ON_OFF_status" = "2" ]; then
									echo "Outlet #${1} is already OFF"
									#file contents: "PDU_load_shed_active"  ||  "PLEX_load_shed_active"  ||  "Surveillance_Station_Load_shed_active" 
									echo "1,${4},${5} " > "${3}"
								else
									#outlet is currently ON, turn it OFF
									docker run --rm=true elcolio/net-snmp snmpset -v3 -l authPriv -u "${8}" -a "${10}" -A "${6}" -x "${11}" -X "${7}" "${9}":161 1.3.6.1.4.1.3808.1.1.3.3.3.1.1.4.${1} i 2
									
									#get the status to confirm the outlet is OFF
									outlet_ON_OFF_status=$(snmpwalk -v3 -r 1 -l authPriv -u ${8} -a ${10} -A ${6} -x ${11} -X ${7} ${9}:161 1.3.6.1.4.1.3808.1.1.3.3.5.1.1.4.${1} -Oqv)
									if [ "$outlet_ON_OFF_status" = "2" ]; then
										echo "Outlet #${1} Successfully Turned OFF"
										PDU_outlet_off_email ${1}
										#file contents: "PDU_load_shed_active"  ||  "PLEX_load_shed_active"  ||  "Surveillance_Station_Load_shed_active" 
										echo "1,${4},${5} " > "${3}"
									else
										echo "Outlet #${1} Failed To Turned OFF"
										PDU_outlet_error_email ${1}
									fi
								fi
							fi
						fi
					fi
				fi
			fi
		else
			echo -e "\n\nWARNING -- PDU did not respond to a PING, PDU may be off line, cannot turn outlet ${1} on/off\n\n"
		fi
	else
		echo -e "\n\nWARNING -- Outlet #${1} Failed To Turned OFF as Docker is not available\n\n"
	fi
}

#####################################
#Function to validate the SNMP data received from the UPS
#####################################
function UPS_SNMP_data_verification(){
#SNMP_result=${1}

	#different errors and responses can be received from the UPS network management card when SNMP fails
	
	#1.) wrong username --> "Authentication failed for"
	#2.) wrong authentication/privacy protocol/password --> "Timeout: No Response from"
	#3.) too short of auth/privacy password --> "Error: passphrase chosen is below the length requirements"
	#4.) wrong IP/Port --> "snmpwalk: Timeout"
	#5.) bad IOD --> "No Such Instance currently exists at this OID"
	#6.) result is blank

		
	if [[ "${1}" == "Authentication failed for"* ]]; then 
		echo -e "\n\n WARNING -- the SNMP username appears to be incorrect. Exiting Script"
		ups_snmp_data_bad_email
		exit 1
	fi
	
	if [[ "${1}" == "Timeout: No Response from"* ]]; then 
		echo -e "\n\n WARNING -- the SNMP authentication/privacy protocol/password appears to be incorrect. Exiting Script"
		ups_snmp_data_bad_email
		exit 1
	fi
	
	if [[ "${1}" == "Error: passphrase chosen is below the length requirements"* ]]; then 
		echo -e "\n\n WARNING -- the SNMP auth/privacy password are too short. Exiting Script"
		ups_snmp_data_bad_email
		exit 1
	fi
	
	if [[ "${1}" == "snmpwalk: Timeout"* ]]; then 
		echo -e "\n\n WARNING --  the SNMP IP address or port appear to be incorrect. Exiting Script"
		ups_snmp_data_bad_email
		exit 1
	fi
	
	if [[ "${1}" == "No Such Instance currently exists at this OID"* ]]; then 
		echo -e "\n\n WARNING --  the SNMP IOD appears to be incorrect. Exiting Script"
		ups_snmp_data_bad_email
		exit 1
	fi
	
	if [[ "${1}" == "" ]]; then 
		echo -e "\n\n WARNING --  the SNMP data received was blank. Exiting Script"
		ups_snmp_data_bad_email
		exit 1
	fi
}


#####################################
#Function to shutdown PLEX
#####################################
#plex_installed_on_system=${1}
#PLEX_load_shed_active=${2}
#PLEX_IP=${3}
#DSMVersion=${4}
#plex_installed_volume=${5}
#PDU_load_shed_active=${6}
#Surveillance_Station_Load_shed_active=${7}
#notification_file_location=${8}
#UPS_load_shed_status_file=${9}
#sendmail_installed=${10}
#ups_email_notification_last_sent_tracker=${11}
#plex_package_name=${12}
#nas_name=${13}
#ups_email_notification_file=${14}
#plex_load_shed_enable=${15}
function plex_shutdown(){
	if [[ ${15} == 1 ]]; then	#PLEX load shedding enabled					
		if [ ${1} -eq 1 ]; then #does the system have PLEX installed? if it does, perform PLEX load shedding
				#echo "PLEX Installed on System"
				if [ ${2} -eq 1 ]; then
					echo "PLEX has already been terminated"
				else
					#plex_IP_address || DSM_version || plex_installed_volume || PDU_load_shed_active || Surveillance_Station_Load_shed_active || load_shed_file_location
					plex_stream_terminate "${3}" "${4}" "${5}" "${6}" "${7}" "${8}/${9}"
							
					#give PLEX time to terminate stream
					echo "stopping PLEX package in 15 seconds"
					sleep 5
					echo "stopping PLEX package in 10 seconds"
					sleep 5
					echo "stopping PLEX package in 5 seconds"
					sleep 5
											
					#####################################
					#Stop PLEX package
					#####################################
					local plex_status=$(/usr/syno/bin/synopkg is_onoff "${12}")
					if [ "$plex_status" = "package ${12} is turned on" ]; then
						echo "Stopping ${12} ...."
						/usr/syno/bin/synopkg stop "${12}"
						sleep 1
					else
						echo "${12} Already Shutdown"
					fi
											
					plex_status=$(/usr/syno/bin/synopkg is_onoff "${12}")
					if [ "$plex_status" = "package ${12} is turned on" ]; then
						echo "Shutting Down PLEX Package Failed"
					else
						PLEX_load_shed_active=1
											
						#send an alert email to the email address configured in the web administration page
						send_mail "${8}/${11}" "ALERT ${13} has stopped the package \"${12}\"." "${13} Stopped package \"${12}\"" "${8}/${14}" "PLEX was shutdown" 0 ${10}
					fi	
				fi
			else
				echo "PLEX Not Installed on system"
		fi
	else
		echo "PLEX load shedding is disabled"
	fi
}
#####################################
#Function to perform PDU load shed
#####################################
#load_shed_control=${1}
#PDU_load_shed_active=${2}
#notification_file_location=${3}
#UPS_load_shed_status_file=${4}
#PLEX_load_shed_active=${5}
#Surveillance_Station_Load_shed_active=${6}
#PDU_AuthPass1=${7}
#PDU_PrivPass2=${8}
#PDU_snmp_user=${9}
#PDU_IP=${10}
#PDU_snmp_auth_protocol=${11}
#PDU_snmp_privacy_protocol=${12}
#docker_installed=${13}
#$pdu_outlet_failure_email_last_sent_tracker=${14}
#ups_email_notification_file=${15}
#sendmail_installed=${16}
function pdu_load_shed(){
	if [ ${1} -eq 1 ]; then #PDU load shed enabled?
		echo "The system is configured to control PDU load shedding"
		if [ ${2} -eq 0 ]; then
			#outlet number || command || load_shed_file_location || PLEX_load_shed_active || Surveillance_Station_Load_shed_active || PDU_AuthPass1 || PDU_PrivPass2 || PDU_snmp_user || PDU_IP || PDU_snmp_auth_protocol || PDU_snmp_privacy_protocol || docker_installed
			local outlets=1
			while [ $outlets -lt 17 ]; do
				if [ ${outlet_load_shed_yes_no[$outlets]} -eq 1 ]; then
					load_shed_PDU_ON_OFF "$outlets" "off" "${3}/${4}" "${5}" "${6}" "${7}" "${8}" "${9}" "${10}" "${11}" "${12}" "${13}" 
				fi
				let outlets=outlets+1
			done
			PDU_load_shed_active=1
		else
			echo "PDU load shed has already been performed"
		fi
	else
		echo "PDU Load Shedding Disabled"
	fi
}

#####################################
#Function to perform controlled shutdown of the system
#####################################
function system_shutdown(){
#input_voltage=${1}
#battery_capacity=${2}
#RuntimeRemaining_days=${3}
#RuntimeRemaining_hours=${4}
#RuntimeRemaining_min=${5}
#RuntimeRemaining_seconds=${6}
#notification_file_location=${7}
#UPS_shutdown_status_file=${8}
#ups_outlet_group_turn_off_enable=${9}
#UPS_snmp_user=${10}
#UPS_snmp_auth_protocol=${11}
#UPS_AuthPass1=${12}
#UPS_snmp_privacy_protocol=${13}
#UPS_PrivPass2=${14}
#UPS_url=${15}
#ups_outlet_group_turn_off_delay=${16}
#debug_mode=${17}
#UPS_on_battery=${18}
#$docker_installed=${19}
#battery_temperature=${20}
#battery_voltage=${21}
#Time_on_battery=${22}
	#save a log message to sys_log
	echo "save message to syslog"
	/usr/syno/bin/synologset1 sys err 0x11100000 "WARNING! - Initiating System Shutdown in 60 seconds -- UPS Active, UPS Voltage: ${1} VAC, Battery Capacity: ${2} %, Battery temperature: ${20}, Battery Voltage: ${21}, Runtime Remaining: ${4} Hours: ${5} Minutes: ${6} Seconds, UPS Runtime: ${22}"
			
	#save the fact that the system is shutting down. this will be used to prevent the script from running again during the 60 second delay before system shutdown
	UPS_Shutdown=1
	echo "$UPS_Shutdown,${18}" > "${7}/${8}"
						
	#command UPS outlets off if script is configured to do so. 
	if [ ${9} -eq 1 ]; then
		#get number of outlet groups in the UPS that require turning off
		local num_outlet_group=0
		num_outlet_group=$(snmpwalk -v3 -r 1 -l authPriv -u ${10} -a ${11} -A ${12} -x ${13} -X ${14} ${15}:161 1.3.6.1.4.1.318.1.1.1.12.1.1.0 -Oqv)
									
		if [ ${19} -eq 1 ]; then
			if [ $num_outlet_group -ge 1 ]; then
				local counter=0
				for (( counter=$num_outlet_group; counter>=1; counter-- )) #going backwards as the main outlet groups of APC UPS are the lower numbers. this will ensure the switched outlet groups are turned off before the main switch group(s)
				do
					echo -e "\nConfiguring UPS outlet group $counter to a Turn Off Delay Time of ${16} seconds"
					#configure the UPS outlet group off delay
					docker run --rm=true elcolio/net-snmp snmpset -v3 -l authPriv -u "${10}" -a "${11}" -A "${12}" -x "${13}" -X "${14}" "${15}":161 1.3.6.1.4.1.318.1.1.1.12.2.2.1.4.$counter i ${16}
										
					echo "Commanding UPS outlet group $counter to Turn Off with delay"
					#command the UPS outlet group to turn off with the off delay
					if [ ${17} -eq 1 ]; then
						echo "script is in debug mode - Not Actually Commanding the UPS outlet group $counter to turn off"
					else
						docker run --rm=true elcolio/net-snmp snmpset -v3 -l authPriv -u "${10}" -a "${11}" -A "${12}" -x "${13}" -X "${14}" "${15}":161 1.3.6.1.4.1.318.1.1.1.12.3.2.1.3.$counter i 5
					fi
					echo ""
				done
			else
				echo -e "\n\nWARNING -- Either no outlet groups are available to command or the UPS did not return useful data, Could not command UPS outlets to turn off after system shutdown\n\n"
			fi
		else
			echo -e "\n\nWARNING -- Could not command UPS outlets to turn off after system shutdown as Docker is not available\n\n"
		fi
	fi
								
	#wait 60 seconds to ensure the email and sys log activities are done
	echo "waiting 60 seconds"
	sleep 10
	echo "50 seconds remaining"
	sleep 10
	echo "40 seconds remaining"
	sleep 10
	echo "30 seconds remaining"
	sleep 10
	echo "20 seconds remaining"
	sleep 10
	echo "10 seconds remaining"
	sleep 10
								
	#shutdown the system
	echo "shutting down the system"
	if [ ${17} -eq 1 ]; then
		echo "script is in debug mode - not actually sending shutdown command"
	else
		shutdown -P now
		echo "shutting down system"
	fi
	exit
}

##########################################################################
#read in two variables stored in an external file "UPS_shutdown_status_file" to track the following two things:
#1.) is the system currently shutting down due to communications loss with the UPS from a previous script execution?
#2.) is the UPS on battery power as detected from a previous execution of the script?
##########################################################################

#if the UPS communications are not working while the system is actively shutting down, we want to skip this entire script to prevent it from commanding the system to shutdown again
#tracking if the UPS is on active battery power is needed so that if UPS communications are lost while on battery, monitoring of the UPS is not possible and for safety, shutdown the system immediately 

if [ -r "$notification_file_location/$UPS_shutdown_status_file" ]; then
	#file is available and readable 
	read input_read < "$notification_file_location/$UPS_shutdown_status_file"
	explode=(`echo $input_read | sed 's/,/\n/g'`)
	if [[ ! ${#explode[@]} == 2 ]]; then
		send_mail "$notification_file_location/$ups_email_notification_last_sent_tracker" "WARNING - the \"UPS_shutdown_status_file\" file is incorrect or corrupted. It should have 2 parameters, it currently has ${#explode[@]} parameters." "Warning UPS Monitoring Failed - Configuration has incorrect number of parameters" "$notification_file_location/$ups_email_notification_file" "script config file has wrong number of parameters" 60 0
		exit 1
	fi
	UPS_Shutdown=${explode[0]}
	UPS_on_battery=${explode[1]}
else
	#file is missing, let's write to disk some default values
	echo "$UPS_shutdown_status_file is unavailable, writing default values"
	echo "0,0" > "$notification_file_location/$UPS_shutdown_status_file"
	UPS_Shutdown=0
	UPS_on_battery=0
fi


#if the system is NOT actively shutting down due to either communications loss or low battery capacity remaining, we want to run this script to continue monitoring the UPS
if [ $UPS_Shutdown -eq 0 ]; then
	##########################################################################
	#reading in variables from configuration file "configuration_file"
	#these variables are controlled through a web enabled control administration page, or manually editing the .txt files
	#setting script global variables 
	##########################################################################
	
	
	if [[ -r "$config_file_location/$configuration_file" ]]; then
		#files are available and readable 
		read input_read < "$config_file_location/$configuration_file"
		explode=(`echo $input_read | sed 's/,/\n/g'`)
		
		#verify the correct number of configuration parameters are in the configuration file
		if [[ ! ${#explode[@]} == 63 ]]; then
			send_mail "$notification_file_location/$ups_email_notification_last_sent_tracker" "WARNING - the configuration file is incorrect or corrupted. It should have 63 parameters, it currently has ${#explode[@]} parameters." "Warning UPS Monitoring Failed - Configuration has incorrect number of parameters" "$notification_file_location/$ups_email_notification_file" "script config file has wrong number of parameters" 60 0
			exit 1
		fi
		
		#make empty array that we will be appending more values to. we want the array element 0 to be used already, so are loading it with a blank string
		outlet_load_shed_yes_no=("")
				
		#unused=${explode[0]}   
		UPS_input_Voltage_threashold=${explode[1]} #what is the lowest acceptable AC input voltage before the UPS is considered to be on battery power? this setting needs to be the same as what the UPS itself is configured 
		email_address=${explode[2]} #what email address will the alert messages be sent
		capture_interval=${explode[3]} #how often (in seconds) will this script poll the UPS for information?
		UPS_url=${explode[4]} #what is the IP address of the UPS network management card?
		script_enable=${explode[5]} #is the script enabled or disabled on the web administration page?
		UPS_comm_loss_shutdown_interval=${explode[6]} #[minutes] if communications with the UPS are lost BUT the UPS is running fine off AC power, how long before the system is commanded to shutdown? this if enabled is for safety as the system cannot safely shutdown if the UPS were to begin running off battery power
		UPS_comm_loss_shutdown_enable=${explode[7]} #is the option to shutdown enabled when the UPS is on AC power and UPS communications are lost for a set period of time?
		PDU_IP=${explode[8]}
		#if PLEX is installed, configure these settings
		PLEX_IP=${explode[9]}
		plex_installed_volume=${explode[10]}
		#unused=${explode[11]} 
		#unused=${explode[12]} 
		#authorization and privacy passwords and user name for the Synology SNMP V3. this is needed to get the NAS system name
		Syno_AuthPass1=${explode[13]}
		Syno_PrivPass2=${explode[14]}
		Syno_snmp_user=${explode[15]}
		Syno_snmp_auth_protocol=${explode[16]} #MD5  or SHA 
		Syno_snmp_privacy_protocol=${explode[17]} #AES or DES
		#authorization and privacy passwords and user name for the UPS network management SNMP V3
		UPS_AuthPass1=${explode[18]}
		UPS_PrivPass2=${explode[19]}
		UPS_snmp_user=${explode[20]}
		UPS_snmp_auth_protocol=${explode[21]} #MD5  or SHA 
		UPS_snmp_privacy_protocol=${explode[22]} #AES or DES
		#authorization and privacy passwords and user name for the PDU SNMP V3
		PDU_AuthPass1=${explode[23]}
		PDU_PrivPass2=${explode[24]}
		PDU_snmp_user=${explode[25]}
		PDU_snmp_auth_protocol=${explode[26]} #MD5  or SHA 
		PDU_snmp_privacy_protocol=${explode[27]} #AES or DES
		#which outlets are desired to perform load shedding? append each value to the array
		outlet_load_shed_yes_no=+${explode[28]}
		outlet_load_shed_yes_no=+${explode[29]}
		outlet_load_shed_yes_no=+${explode[30]}
		outlet_load_shed_yes_no=+${explode[31]}
		outlet_load_shed_yes_no=+${explode[32]}
		outlet_load_shed_yes_no=+${explode[33]}
		outlet_load_shed_yes_no=+${explode[34]}
		outlet_load_shed_yes_no=+${explode[35]}
		outlet_load_shed_yes_no=+${explode[36]}
		outlet_load_shed_yes_no=+${explode[37]}
		outlet_load_shed_yes_no=+${explode[38]}
		outlet_load_shed_yes_no=+${explode[39]}
		outlet_load_shed_yes_no=+${explode[40]}
		outlet_load_shed_yes_no=+${explode[41]}
		outlet_load_shed_yes_no=+${explode[42]}
		outlet_load_shed_yes_no=+${explode[43]}
		ups_outlet_group_turn_off_enable=${explode[44]}
		ups_outlet_group_turn_off_delay=${explode[45]}
		from_email_address=${explode[46]}
		shutdown_battery_voltage=${explode[47]}
		shutdown_battery_voltage_decimal="$(printf %.1f "$((10**4 * $shutdown_battery_voltage/10))e-4")"
		shutdown_run_time_hours=${explode[48]}
		shutdown_run_time_min=${explode[49]}
		shutdown_run_time_sec=${explode[50]}
		max_on_battery_temp=${explode[51]}
		max_on_battery_temp_decimal="$(printf %.1f "$((10**4 * $max_on_battery_temp/10))e-4")"
		shutdown_trigger=${explode[52]}
		load_shed_trigger=${explode[53]} 
		load_shed_voltage=${explode[54]} 
		load_shed_voltage_decimal="$(printf %.1f "$((10**4 * $load_shed_voltage/10))e-4")"		
		pdu_load_shed_enable=${explode[55]}
		synology_ss_load_shed_enable=${explode[56]}
		plex_load_shed_enable=${explode[57]}
		load_shed_run_time_hours=${explode[58]}
		load_shed_run_time_min=${explode[59]}
		load_shed_run_time_sec=${explode[60]}
		enable_notifications=${explode[61]}
		ups_email_delay=${explode[62]}

		APC_online=0 #initially set the UPS as off line and as we will check if the UPS is on line soon
		
		#initiate some additional variables which will be read from SNMP
		battery_capacity=""
		battery_run_time=""
		input_voltage=""
		
		##########################################################################
		#read in status of active/inactive load shedding
		##########################################################################
		if [ -r "$notification_file_location/$UPS_load_shed_status_file" ]; then
			read input_read < "$notification_file_location/$UPS_load_shed_status_file"
			explode=(`echo $input_read | sed 's/,/\n/g'`)
			if [[ ! ${#explode[@]} == 3 ]]; then
				send_mail "$notification_file_location/$ups_email_notification_last_sent_tracker" "WARNING - the \"UPS_load_shed_status_file\" file is incorrect or corrupted. It should have 3 parameters, it currently has ${#explode[@]} parameters." "Warning UPS Monitoring Failed - Configuration has incorrect number of parameters" "$notification_file_location/$ups_email_notification_file" "script config file has wrong number of parameters" 60 0
				exit 1
			fi
			PDU_load_shed_active=${explode[0]} 
			PLEX_load_shed_active=${explode[1]} 
			Surveillance_Station_Load_shed_active=${explode[2]} 
		else
			echo "0,0,0 " > "$notification_file_location/$UPS_load_shed_status_file"
			PDU_load_shed_active=0
			PLEX_load_shed_active=0 
			Surveillance_Station_Load_shed_active=0
		fi
			
		##########################################################################
		#is the script enabled through the web administrations page?
		##########################################################################
		if [ $script_enable -eq 1 ]; then
			
			##########################################################################
			#verify MailPlus Server package is installed and running as the "sendmail" command is not installed in synology by default. the MailPlus Server package is required
			##########################################################################
			install_check=$(/usr/syno/bin/synopkg list | grep MailPlus-Server)

			if [ "$install_check" = "" ];then
				sendmail_installed=0
			else
				status=$(/usr/syno/bin/synopkg is_onoff "MailPlus-Server")
				if [ "$status" = "package MailPlus-Server is turned on" ]; then
					sendmail_installed=1
				else
					sendmail_installed=0
				fi
			fi
			
			##########################################################################
			#collect the name of the server
			##########################################################################
			if [ "$Syno_snmp_user" = "" ];then
				echo "Synology NAS Username is BLANK, please configure the SNMP settings"
			else
				if [ "$Syno_AuthPass1" = "" ];then
					echo "Synology NAS Authentication Password is BLANK, please configure the SNMP settings"
				else
					if [ "$Syno_PrivPass2" = "" ];then
						echo "Synology NAS Privacy Password is BLANK, please configure the SNMP settings"
					else
						nas_name=$(snmpwalk -v3 -r 1 -l authPriv -u $Syno_snmp_user -a $Syno_snmp_auth_protocol -A $Syno_AuthPass1 -x $Syno_snmp_privacy_protocol -X $Syno_PrivPass2 $nas_url:161 SNMPv2-MIB::sysName.0 -Ovqt 2>&1)
						#since $nas_name is the first time we have performed a SNMP request to the NAS, let's make sure we did not receive any errors that could be caused by things like bad passwords, bad username, incorrect auth or privacy types etc
						#if we receive an error now, then something is wrong with the SNMP settings and this script will not be able to function so we should exit out of it. 
						#the five main error are
						#1 - too short of a password
							#Error: passphrase chosen is below the length requirements of the USM (min=8).
							#snmpwalk:  (The supplied password length is too short.)
							#Error generating a key (Ku) from the supplied privacy pass phrase.

						#2 #Timeout: No Response from localhost:161

						#3 #snmpwalk: Unknown user name

						#4 #snmpwalk: Authentication failure (incorrect password, community or key)
							
						#5 #we get nothing, the results are blank

						if [[ "$nas_name" == "Error:"* ]]; then #will search for the first error type
							echo "WARNING -- The SNMP Auth password and or the Privacy password supplied is below the minimum 8 characters required."
							echo "script will continue, NAS name is not 100% required for system down protection. Settings NAS Name to default value of \"Synology_NAS\""
							nas_name="Synology_NAS"
							NAS_name_error_email #send notification email that the NAS appears to have issues with SNMP
						fi
						
						if [[ "$nas_name" == "Timeout:"* ]]; then #will search for the second error type
							echo "WARNING -- The SNMP target did not respond. This could be the result of a bad SNMP privacy password, the wrong IP address, the wrong port, or SNMP services not being enabled on the target device"
							echo "script will continue, NAS name is not 100% required for system down protection. Settings NAS Name to default value of \"Synology_NAS\""
							nas_name="Synology_NAS"
							NAS_name_error_email #send notification email that the NAS appears to have issues with SNMP
						fi
						
						if [[ "$nas_name" == "snmpwalk: Unknown user name"* ]]; then #will search for the third error type
							echo "WARNING -- The supplied username is incorrect. Exiting Script"
							echo "script will continue, NAS name is not 100% required for system down protection. Settings NAS Name to default value of \"Synology_NAS\""
							nas_name="Synology_NAS"
							NAS_name_error_email #send notification email that the NAS appears to have issues with SNMP
						fi
						
						if [[ "$nas_name" == "snmpwalk: Authentication failure (incorrect password, community or key)"* ]]; then #will search for the fourth error type
							echo "WARNING -- The Authentication protocol or password is incorrect."
							echo "script will continue, NAS name is not 100% required for system down protection. Settings NAS Name to default value of \"Synology_NAS\""
							nas_name="Synology_NAS"
							NAS_name_error_email #send notification email that the NAS appears to have issues with SNMP
						fi
						
						if [[ "$nas_name" == "" ]]; then #will search for the fifth error type
							echo "WARNING -- Something is wrong with the SNMP settings, the results returned a blank/empty value."
							echo "script will continue, NAS name is not 100% required for system down protection. Settings NAS Name to default value of \"Synology_NAS\""
							nas_name="Synology_NAS"
							NAS_name_error_email #send notification email that the NAS appears to have issues with SNMP
						fi
					fi
				fi
			fi
			
			#determine DSM version to ensure the DSM6 vs DSM7 version of the synology
			DSMVersion=$(                   cat /etc.defaults/VERSION | grep -i 'productversion=' | cut -d"\"" -f 2)
			
			
			##########################################################################
			#check if the PlexMediaServer and SurveillanceStation are installed on the system
			#if they are installed, this will enable load shedding functions to turn off these apps during battery operation 
			##########################################################################
	
			#plex package name, and docker package name is different between DSM version 6 and version 7
			MinDSMVersion=7.0
			/usr/bin/dpkg --compare-versions "$MinDSMVersion" gt "$DSMVersion"
			if [ "$?" -eq "0" ]; then
				#DSM is less than version 7. 
				plex_package_name="Plex Media Server"
				
				#verify Docker is installed and running as the SNMP_SET commands require a docker container
				install_check=$(/usr/syno/bin/synopkg list | grep Docker)

				if [ "$install_check" = "" ];then
					echo "WARNING!  ----   Docker NOT is installed, cannot perform PDU outlet load shedding or configure the UPS input voltage or the UPS outlet shutdown"
					docker_installed=0
				else
					status=$(/usr/syno/bin/synopkg is_onoff "Docker")
					if [ "$status" = "package Docker is turned on" ]; then
						docker_installed=1
					else
						docker_installed=0
						echo "WARNING!  ----   Docker NOT is running, cannot perform PDU outlet load shedding or configure the UPS input voltage or the UPS outlet shutdown"
					fi
				fi
			
			else
				#DSM is version 7 or greater
				plex_package_name="PlexMediaServer"
				
				#verify Docker, now named "Container Manager" is installed and running as the SNMP_SET commands require a docker container
				install_check=$(/usr/syno/bin/synopkg list | grep ContainerManager)

				if [ "$install_check" = "" ];then
					echo "WARNING!  ----   ContainerManager NOT is installed, cannot perform PDU outlet load shedding or configure the UPS input voltage or the UPS outlet shutdown"
					docker_installed=0
				else
					status=$(/usr/syno/bin/synopkg is_onoff "ContainerManager")
					if [ "$status" = "package ContainerManager is turned on" ]; then
						docker_installed=1
					else
						docker_installed=0
						echo "WARNING!  ----   ContainerManager NOT is running, cannot perform PDU outlet load shedding or configure the UPS input voltage or the UPS outlet shutdown"
					fi
				fi
			fi
	
			install_check=$(/usr/syno/bin/synopkg list | grep $plex_package_name)

			if [ "$install_check" = "" ];then
				plex_installed_on_system=0
				plex_shutdown_time=0
			else
				plex_installed_on_system=1
			fi

			install_check=$(/usr/syno/bin/synopkg list | grep SurveillanceStation)

			if [ "$install_check" = "" ];then
				surveillance_station_installed_on_system=0
			else
				surveillance_station_installed_on_system=1
			fi
			
			if [ ! $capture_interval -eq 10 ]; then
				if [ ! $capture_interval -eq 15 ]; then
					if [ ! $capture_interval -eq 30 ]; then
						if [ ! $capture_interval -eq 60 ]; then
							echo "capture interval is not one of the allowable values of 10, 15, 30, or 60 seconds. Exiting the script"
							exit 1
						fi
					fi
				fi
			fi
			
			total_executions=$(( 60 / $capture_interval)) #based on the capture interval (10 seconds, 15 seconds, 30 seconds, 60 seconds) set in the web administration page, calculate the number of times this script will loop itself
			
			echo "Capturing $total_executions times"
			
			##########################################################################			
			#loop the script 
			##########################################################################
			i=0
			while [ $i -lt $total_executions ]; do
				
				##########################################################################
				#check if the UPS is on line
				#if UPS is on line get data from it
				#if UPS is off line, set a flag variable that UPS is off line
				##########################################################################
				if [ "$UPS_snmp_user" = "" ];then
					echo "UPS SNMP User is BLANK, please configure the UPS SNMP Settings"
					ups_snmp_data_bad_email
					exit 1
				else
					if [ "$UPS_AuthPass1" = "" ];then
						echo "UPS SNMP Authentication Password is BLANK, please configure the UPS SNMP Settings"
						ups_snmp_data_bad_email
						exit 1
					else
						if [ "$UPS_PrivPass2" = "" ];then
							echo "UPS SNMP Privacy Password is BLANK, please configure the UPS SNMP Settings"
							ups_snmp_data_bad_email
							exit 1
						else
							##########################################################################
							#check that the UPS NMC is available
							##########################################################################
							#let's make sure the target for SNMP walking is available on the network 
							ping -c1 $UPS_url > /dev/null
							if [ $? -eq 0 ]; then
									APC_online=1 #network communications are good
							else
								#ping failed
								#since the ping failed, let's do just one more ping juts in case
								echo "ping failed, trying one more time"
								ping -c1 $UPS_url > /dev/null
								if [ $? -eq 0 ]; then
									APC_online=1 #network communications are good
								fi
							fi
							
							##########################################################################
							#the UPS is online so use SNMP to collect the needed data from the UPS
							##########################################################################
							if [ $APC_online -eq 1 ]; then								
								# UPS Battery Capacity
								battery_capacity=$(snmpwalk -v3 -r 1 -l authPriv -u $UPS_snmp_user -a $UPS_snmp_auth_protocol -A $UPS_AuthPass1 -x $UPS_snmp_privacy_protocol -X $UPS_PrivPass2 $UPS_url:161 1.3.6.1.4.1.318.1.1.1.2.3.1.0 -Oqv)
								battery_capacity_decimal="$(printf %.1f "$((10**4 * $battery_capacity/10))e-4")"
								
								UPS_SNMP_data_verification $battery_capacity #battery_capacity is the first variable we are requesting from the UPS. if this request fails, then something is wrong and we should exit the entire script
											
								# UPS Battery remaining Run Time
								battery_run_time=$(snmpwalk -v3 -r 1 -l authPriv -u $UPS_snmp_user -a $UPS_snmp_auth_protocol -A $UPS_AuthPass1 -x $UPS_snmp_privacy_protocol -X $UPS_PrivPass2 $UPS_url:161 .1.3.6.1.4.1.318.1.1.1.2.2.3.0 -Oqv)
								
								# UPS Time On Battery
								Time_on_battery=$(snmpwalk -v3 -r 1 -l authPriv -u $UPS_snmp_user -a $UPS_snmp_auth_protocol -A $UPS_AuthPass1 -x $UPS_snmp_privacy_protocol -X $UPS_PrivPass2 $UPS_url:161 1.3.6.1.4.1.318.1.1.1.2.1.2.0 -Oqv)
							
								# UPS Input Voltage
								input_voltage=$(snmpwalk -v3 -r 1 -l authPriv -u $UPS_snmp_user -a $UPS_snmp_auth_protocol -A $UPS_AuthPass1 -x $UPS_snmp_privacy_protocol -X $UPS_PrivPass2 $UPS_url:161 .1.3.6.1.4.1.318.1.1.1.3.2.1.0 -Oqv)
								
								# UPS Minimum Input Transfer Voltage Threshold 
								input_threshold_NMC=$(snmpwalk -v3 -r 1 -l authPriv -u $UPS_snmp_user -a $UPS_snmp_auth_protocol -A $UPS_AuthPass1 -x $UPS_snmp_privacy_protocol -X $UPS_PrivPass2 $UPS_url:161 1.3.6.1.4.1.318.1.1.1.5.2.3.0 -Oqv)
								
								#battery temperature
								battery_temperature=$(snmpwalk -v3 -r 1 -l authPriv -u $UPS_snmp_user -a $UPS_snmp_auth_protocol -A $UPS_AuthPass1 -x $UPS_snmp_privacy_protocol -X $UPS_PrivPass2 $UPS_url:161 1.3.6.1.4.1.318.1.1.1.2.3.2.0 -Oqv)
								battery_temperature_decimal="$(printf %.1f "$((10**4 * $battery_temperature/10))e-4")"
								
								#battery voltage
								battery_voltage=$(snmpwalk -v3 -r 1 -l authPriv -u $UPS_snmp_user -a $UPS_snmp_auth_protocol -A $UPS_AuthPass1 -x $UPS_snmp_privacy_protocol -X $UPS_PrivPass2 $UPS_url:161 1.3.6.1.4.1.318.1.1.1.2.3.4.0 -Oqv)
								battery_voltage_decimal="$(printf %.1f "$((10**4 * $battery_voltage/10))e-4")"
								
								#split the run time from a string to individual numbers (days, hours, min, sec)
								delimiter=":"
								s=$battery_run_time$delimiter
								battery_run_time_remaining_array=();
								while [[ $s ]]; do
									battery_run_time_remaining_array+=( "${s%%"$delimiter"*}" )
									s=${s#*"$delimiter"}
								done;
								#[0]=days [1]=hours [2]=minutes [3]=seconds
								
								s=$Time_on_battery$delimiter
								Time_on_battery_array=();
								while [[ $s ]]; do
									Time_on_battery_array+=( "${s%%"$delimiter"*}" )
									s=${s#*"$delimiter"}
								done
							else
								battery_capacity=0
								battery_capacity_decimal="0.0"
								input_voltage=0
								input_threshold_NMC=0
								battery_temperature=0
								battery_temperature_decimal="0.0"
								battery_voltage=0
								battery_voltage_decimal="0.0"
								battery_run_time_remaining_array[0]=0
								battery_run_time_remaining_array[1]=0
								battery_run_time_remaining_array[2]=0
								battery_run_time_remaining_array[3]=0
								Time_on_battery_array[0]=0
								Time_on_battery_array[1]=0
								Time_on_battery_array[2]=0
								Time_on_battery_array[3]=0
							fi
						fi
					fi
				fi
				
				if [ $debug_mode -eq 1 ]; then
					##########################################################################
					#In debug mode we can test the script's functions
					#we will now overwrite the data collected above during the ping attempts 
					#the different "debug" variables at the beginning of this script can be set to make the script behave as desired
					##########################################################################
					APC_online=1
					battery_run_time_remaining_array[0]=0 #days
					battery_run_time_remaining_array[1]=0 #hours
					battery_run_time_remaining_array[2]=0 #minuets
					battery_run_time_remaining_array[3]=1 #seconds
					Time_on_battery_array[0]=0 #days
					Time_on_battery_array[1]=6	#hours
					Time_on_battery_array[2]=1	#minuets
					Time_on_battery_array[3]=0 #seconds
					battery_capacity=1000
					battery_capacity_decimal="$(printf %.1f "$((10**4 * $battery_capacity/10))e-4")"
					input_voltage=120
					UPS_comm_loss_shutdown_interval=60
					outlet_load_shed_yes_no[1]=0
					outlet_load_shed_yes_no[2]=0
					outlet_load_shed_yes_no[3]=0
					outlet_load_shed_yes_no[4]=0
					outlet_load_shed_yes_no[5]=0
					outlet_load_shed_yes_no[6]=0
					outlet_load_shed_yes_no[7]=0
					outlet_load_shed_yes_no[8]=0
					outlet_load_shed_yes_no[9]=0
					outlet_load_shed_yes_no[10]=0
					outlet_load_shed_yes_no[11]=0
					outlet_load_shed_yes_no[12]=0
					outlet_load_shed_yes_no[13]=0
					outlet_load_shed_yes_no[14]=1
					outlet_load_shed_yes_no[15]=0
					outlet_load_shed_yes_no[16]=0
					ups_outlet_group_turn_off_enable=1
					ups_outlet_group_turn_off_delay=480
					shutdown_battery_voltage=482 #UPS returns the value not in decimal format, 482 is equal to 48.2 volts
					shutdown_battery_voltage_decimal="$(printf %.1f "$((10**4 * $shutdown_battery_voltage/10))e-4")"
					shutdown_run_time_hours=0
					shutdown_run_time_min=30
					shutdown_run_time_sec=0
					max_on_battery_temp=350
					max_on_battery_temp_decimal="$(printf %.1f "$((10**4 * $max_on_battery_temp/10))e-4")"
					shutdown_trigger=5 #1=run time remaining only, 2=time on battery only, 3=run time remaining AND battery voltage, 4=time on battery AND battery voltage, 5=battery voltage Only
					load_shed_trigger=5 #1=run time remaining only, 2=time on battery only, 3=run time remaining AND battery voltage, 4=time on battery AND battery voltage, 5=battery voltage Only
					load_shed_voltage=490 #UPS returns the value not in decimal format, 490 is equal to 49.0 volts		 	
					load_shed_voltage_decimal="$(printf %.1f "$((10**4 * $load_shed_voltage/10))e-4")"
					pdu_load_shed_enable=1
					synology_ss_load_shed_enable=1
					plex_load_shed_enable=1
					load_shed_run_time_hours=0
					load_shed_run_time_min=20
					load_shed_run_time_sec=0
					battery_voltage=555
					battery_voltage_decimal="$(printf %.1f "$((10**4 * $battery_voltage/10))e-4")"
					battery_temperature=277
					battery_temperature_decimal="$(printf %.1f "$((10**4 * $battery_temperature/10))e-4")"
					echo "script is in debugging mode"
					echo "PDU_load_shed_active is $PDU_load_shed_active"
					echo "PLEX_load_shed_active is $PLEX_load_shed_active"
					echo "Surveillance_Station_Load_shed_active is $Surveillance_Station_Load_shed_active"
				fi
											
				##########################################################################
				#if UPS is off line
				##########################################################################
				if [ $APC_online -eq 0 ]; then
					#send notification email
					send_mail "$notification_file_location/$ups_email_notification_last_sent_tracker" "ALERT - $nas_name could NOT access the UPS unit at address $UPS_url for the last $ups_email_delay minutes" "ALERT - $nas_name Cannot Talk to UPS" "$notification_file_location/$ups_email_notification_file" "UPS is off line" $ups_email_delay $sendmail_installed
					
					##########################################################################
					#The UPS has been off line, handle shutting down the system if "UPS_comm_loss_shutdown_enable" is enabled
					##########################################################################
					
					if [ $UPS_comm_loss_shutdown_enable -eq 1 ]; then
						#when the UPS is on line, if the "ups_coms_fail_tracker" file exists it is deleted. 
						#with the UPS off line, either see when it was previously recorded to be off line, or save a new file with the current time to record when the UPS went off line
						current_time=$( date +%s )	
						if [ -r "$notification_file_location/$ups_coms_fail_tracker" ]; then
							read ups_coms_fail_delay_status < "$notification_file_location/$ups_coms_fail_tracker"
							ups_coms_fail_delay_time_diff=$((( $current_time - $ups_coms_fail_delay_status ) / 60 ))
						else 
							echo "$current_time" > "$notification_file_location/$ups_coms_fail_tracker"
							ups_coms_fail_delay_time_diff=0
						fi
						UPS_comm_loss_shutdown_time_remaining=$(( $UPS_comm_loss_shutdown_interval - $ups_coms_fail_delay_time_diff ))
												
							
						##########################################################################
						#when communications are lost and AC power is available and the the counter for shutdown is half-way to being exceeded, begin sending a warning message before the system is actually shutdown
						##########################################################################
						if [ $ups_coms_fail_delay_time_diff -ge $(( $UPS_comm_loss_shutdown_interval / 2 )) ]; then
							#note, saving to the PDU outlet last tracker as this email notification is send differently from other emails
							send_mail "$notification_file_location/$pdu_outlet_failure_email_last_sent_tracker" "WARNING - $nas_name will be shutting down soon in approximately ( $UPS_comm_loss_shutdown_time_remaining Minutes ) due to extended loss of network communications with the UPS." "WARNING - $nas_name Cannot Talk to UPS - Shutting Down $nas_name in approximately ( $UPS_comm_loss_shutdown_time_remaining Minutes )" "$notification_file_location/$ups_email_notification_file" "UPS communications have been off line for $(( $UPS_comm_loss_shutdown_interval / 2 )) minutes or more" $ups_email_delay $sendmail_installed
						fi

						##########################################################################
						#when communications are lost and AC power is available and the the counter for shutdown has been exceeded, shutdown the server as the upstream network devices may have lost power. now we cannot tell if the UPS is on battery or how much run time remains. 
						##########################################################################
						if [ $ups_coms_fail_delay_time_diff -ge $UPS_comm_loss_shutdown_interval ]; then
							send_mail "$notification_file_location/$ups_coms_fail_tracker" "CRITICAL - $nas_name is now shutting down due to extended loss of network communications with UPS" "CRITICAL - $nas_name Shutting Down Due to UPS Network Communications Loss" "$notification_file_location/$ups_email_notification_file" "UPS is off line" 0 $sendmail_installed
							
							#save a log message to sys_log
							echo "saving message to syslog"
							/usr/syno/bin/synologset1 sys err 0x11100000 "WARNING! - Initiating System Shutdown in 60 seconds -- UPS Communications Loss has Exceeded $UPS_comm_loss_shutdown_interval Minutes"
								
							#save the fact that we are shutting down the system. this will prevent this script from running again during the 60 second delay before the shutdown command is sent
							UPS_Shutdown=1
							echo "$UPS_Shutdown,$UPS_on_battery" > "$notification_file_location/$UPS_shutdown_status_file"
								
							#wait 60 seconds to ensure the email and syslog activities are done
							echo "waiting 60 seconds"
							sleep 10
							echo "50 seconds remaining"
							sleep 10
							echo "40 seconds remaining"
							sleep 10
							echo "30 seconds remaining"
							sleep 10
							echo "20 seconds remaining"
							sleep 10
							echo "10 seconds remaining"
							sleep 10
							
							#shutdown the system
							echo "shutting down the system"
							if [ $debug_mode -eq 1 ]; then
								echo "script is in debug mode - not actually sending shutdown command"
							else
								shutdown -P now
								echo "shutting down system"
							fi
							exit
						else
							echo "UPS Communication Loss System Shutdown is Enabled. $UPS_comm_loss_shutdown_time_remaining minutes remain before system shuts down unless communications are restored"
						fi
						
						##########################################################################
						#UPS is not available, however, per the last execution of the script when the UPS was available, the UPS may have been actively running off battery power, shutdown the server as the upstream network devices may have lost power. now we cannot tell if the UPS is still on battery or how much run time remains. 
						##########################################################################
						if [ $UPS_on_battery -eq 1 ]; then #yes it was running on battery power before communications were lost
							UPS_Shutdown=1
								
							#save to file that the status of the UPS so the next time this script runs from the beginning, the script is skipped. 
							echo "$UPS_Shutdown,$UPS_on_battery" > "$notification_file_location/$UPS_shutdown_status_file"
								
							send_mail "$notification_file_location/$ups_coms_fail_tracker" "CRITICAL - $nas_name is now shutting down due to loss of network communications with UPS while UPS was on battery power" "CRITICAL - $nas_name Shutting Down Due to UPS Network Communications Loss" "$notification_file_location/$ups_email_notification_file" "the system is shutting down" 0 $sendmail_installed
																					
							#save a log message to sys_log
							echo "saving message to syslog"
							/usr/syno/bin/synologset1 sys err 0x11100000 "WARNING! - Initiating System Shutdown in 60 seconds -- UPS Communications Loss has Occurred While UPS is on Battery Power"
								
							#wait 60 seconds to ensure the email and syslog activities are done
							echo "waiting 60 seconds"
							sleep 10
							echo "50 seconds remaining"
							sleep 10
							echo "40 seconds remaining"
							sleep 10
							echo "30 seconds remaining"
							sleep 10
							echo "20 seconds remaining"
							sleep 10
							echo "10 seconds remaining"
							sleep 10
							
							#shutdown the system
							echo "shutting down the system"
							if [ $debug_mode -eq 1 ]; then
								echo "script is in debug mode - not actually sending shutdown command"
							else
								shutdown -P now
								echo "shutting down system"
							fi
							exit
						fi
					fi
				else 
				
				##########################################################################
				#UPS has been determined to be on line and data has been received from the UPS
				#check if the UPS is on battery power
				##########################################################################
					if [ -r "$notification_file_location/$ups_coms_fail_tracker" ]; then
						echo "UPS back on-line, deleting time stamp when comms failed"
						rm "$notification_file_location/$ups_coms_fail_tracker"
						
						#send email that UPS comms have been restored
						send_mail "$notification_file_location/$ups_email_notification_last_sent_tracker" "ALERT - $nas_name - UPS has restored communications with UPS at $UPS_url" "ALERT - $nas_name UPS Comms have been restored" "$notification_file_location/$ups_email_notification_file" "UPS is no longer on battery power" 0 $sendmail_installed
					fi
					
					##########################################################################
					#determine if the NMC AC input voltage threshold configured value matches the value set in the web administration page
					##########################################################################
					if [ $docker_installed -eq 1 ]; then
						if [ $input_threshold_NMC -ne $UPS_input_Voltage_threashold ] && [ $input_threshold_NMC -ge 97 ] && [ $input_threshold_NMC -le 106 ]; then
							echo "setting NMC input voltage threshold to $UPS_input_Voltage_threashold volts"
							docker run --rm=true elcolio/net-snmp snmpset -v3 -l authPriv -u $UPS_snmp_user -a $UPS_snmp_auth_protocol -A $UPS_AuthPass1 -x $UPS_snmp_privacy_protocol -X $UPS_PrivPass2 $UPS_url:161 1.3.6.1.4.1.318.1.1.1.5.2.3.0 i $UPS_input_Voltage_threashold
						fi
					else
						echo "WARNING -- Could not set NMC input voltage threshold to $UPS_input_Voltage_threashold volts as Docker is not available"
					fi
					
					##########################################################################
					#determine if the NMC outlet group load shed settings occur before the script will have the chance to safely shut down the system
					##########################################################################
					total_run_time_allowed=$(( ( $shutdown_run_time_hours * 3600 ) + ( $shutdown_run_time_min * 60 ) + $shutdown_run_time_sec ))
					if [[ $shutdown_trigger == 1 ]] || [[ $shutdown_trigger == 3 ]]; then #run time remaining							
						upsoutletgroupconfigloadshedcontrolruntimeremaining=$(snmpwalk -v3 -r 1 -l authPriv -u $UPS_snmp_user -a $UPS_snmp_auth_protocol -A $UPS_AuthPass1 -x $UPS_snmp_privacy_protocol -X $UPS_PrivPass2 $UPS_url:161 1.3.6.1.4.1.318.1.1.1.12.2.2.1.11 -Oqv | grep 2) #1=load shed is disabled on the NMC, 2=load shed is enabled on the NMC						
						if [[ $upsoutletgroupconfigloadshedcontrolruntimeremaining != "" ]]; then #if the number "2" is NOT returned, then none of the outlet groups have load shed enabled
							upsoutletgroupconfigloadshedruntimeremaining=$(snmpwalk -v3 -r 1 -l authPriv -u $UPS_snmp_user -a $UPS_snmp_auth_protocol -A $UPS_AuthPass1 -x $UPS_snmp_privacy_protocol -X $UPS_PrivPass2 $UPS_url:161 1.3.6.1.4.1.318.1.1.1.12.2.2.1.14 -Oqv)
							
							explode=(`echo $upsoutletgroupconfigloadshedruntimeremaining | sed 's/,/\n/g'`)
							xx=0
							#as some UPS have multiple switched outlet groups, we need to loop through all of them to see if any of them are configured for load shedding
							for xx in "${!explode[@]}"; do
								if [[ $total_run_time_allowed -lt ${explode[$xx]} ]]; then
									send_mail "$notification_file_location/$ups_email_notification_last_sent_tracker" "Configuration Warning - The script is configured to shutdown the system if $total_run_time_allowed seconds of run time remains. However the UPS is configured to turn off outlet group # $xx at ${explode[$xx]} seconds. The UPS will turn off outlet group # $xx before the script commands the system to shutdown safely." "Configuration Warning - UPS outlet group(s) will turn off too soon" "$notification_file_location/$ups_email_notification_file" "before the system shuts down" 240 $sendmail_installed
								fi
							done
						fi
					elif [[ $shutdown_trigger == 2 ]] || [[ $shutdown_trigger == 4 ]]; then #time on battery
						upsoutletgroupconfigloadshedcontroltimeonbattery=$(snmpwalk -v3 -r 1 -l authPriv -u $UPS_snmp_user -a $UPS_snmp_auth_protocol -A $UPS_AuthPass1 -x $UPS_snmp_privacy_protocol -X $UPS_PrivPass2 $UPS_url:161 1.3.6.1.4.1.318.1.1.1.12.2.2.1.10 -Oqv | grep 2)
						if [[ $upsoutletgroupconfigloadshedcontroltimeonbattery != "" ]]; then
							upsoutletgroupconfigloadshedtimeonbattery=$(snmpwalk -v3 -r 1 -l authPriv -u $UPS_snmp_user -a $UPS_snmp_auth_protocol -A $UPS_AuthPass1 -x $UPS_snmp_privacy_protocol -X $UPS_PrivPass2 $UPS_url:161 1.3.6.1.4.1.318.1.1.1.12.2.2.1.13 -Oqv)
							
							explode=(`echo $upsoutletgroupconfigloadshedtimeonbattery | sed 's/,/\n/g'`)
							xx=0
							#as some UPS have multiple switched outlet groups, we need to loop through all of them to see if any of them are configured for load shedding
							for xx in "${!explode[@]}"; do
								if [[ $total_run_time_allowed -gt ${explode[$xx]} ]]; then
									send_mail "$notification_file_location/$ups_email_notification_last_sent_tracker" "Configuration Warning - The script is configured to shutdown the system after $total_run_time_allowed seconds of run time off battery have elapsed. However the UPS is configured to turn off outlet group # $xx after ${explode[$xx]} seconds of time on battery have elapsed. The UPS will turn off the outlet group $xx before the script commands the system to shutdown safely." "Configuration Warning - UPS outlet group(s) will turn off too soon" "$notification_file_location/$ups_email_notification_file" "before the system shuts down" 240 $sendmail_installed
								fi
							done
						fi
					fi
					
					##########################################################################
					#determine if the input voltage is below the allowable threshold. if the voltage is below this threshold, then the UPS will switch to battery
					##########################################################################
					if [ $input_voltage -le $UPS_input_Voltage_threashold ]; then 
											
						#save to a file that the UPS is on battery power. this will be used in the event UPS communications are lost while on battery power. this will allow the system to be shutdown if enabled in the web administration page
						if [ $UPS_on_battery -eq 0 ]; then
							UPS_on_battery=1
							echo "$UPS_Shutdown,$UPS_on_battery" > "$notification_file_location/$UPS_shutdown_status_file"							
						fi
						
						battery_voltage_exception=0
						run_time_exception=0
						battery_exception=0
						
						#if we are running off the battery, no matter what the shutdown trigger is, if the battery temp is too high, shutdown the system
						if [[ $battery_temperature -gt $max_on_battery_temp ]]; then
							battery_exception=1
						fi
			
			
						##########################################################################
						#process the 5x different triggers that can be configured to cause the system to shutdown
						##########################################################################
						if [[ $shutdown_trigger == 1 ]]; then #run time remaining only							
							send_mail "$notification_file_location/$ups_email_notification_last_sent_tracker" "Warning $nas_name is Operating on Battery Power for ${Time_on_battery_array[0]} days: ${Time_on_battery_array[1]} hours: ${Time_on_battery_array[2]} minutes: ${Time_on_battery_array[3]} seconds.\n\nIf power is not returned before the UPS run time remaining drops below $shutdown_run_time_hours hours: $shutdown_run_time_min minuets: $shutdown_run_time_sec seconds, the system will shutdown.\n\nUPS Voltage: $input_voltage VAC\nBattery Capacity: $battery_capacity_decimal %\nBattery Voltage: $battery_voltage_decimal\nBattery Temperature: $battery_temperature_decimal\nRuntime Remaining: ${battery_run_time_remaining_array[1]} Hours: ${battery_run_time_remaining_array[2]} Minutes: ${battery_run_time_remaining_array[3]} Seconds " "$nas_name Operating on Battery Power" "$notification_file_location/$ups_email_notification_file" "UPS is on battery power" $ups_email_delay $sendmail_installed
							total_run_time_seconds=$(( ( ${battery_run_time_remaining_array[1]} * 3600 ) + ( ${battery_run_time_remaining_array[2]} * 60 ) + ${battery_run_time_remaining_array[3]} ))
							total_run_time_allowed=$(( ( $shutdown_run_time_hours * 3600 ) + ( $shutdown_run_time_min * 60 ) + $shutdown_run_time_sec ))
												
							if [[ $total_run_time_seconds -lt $total_run_time_allowed ]]; then
								run_time_exception=1
							fi
							
							if [[ $run_time_exception == 1 ]] || [[ $battery_exception == 1 ]]; then

								send_mail "$notification_file_location/$ups_email_notification_last_sent_tracker" "CRITICAL - $nas_name is shutting down due to either:\n1.) battery temperature exceeding $max_on_battery_temp_decimal degrees C\n2.) UPS runtime remaining being less than $shutdown_run_time_hours hours: $shutdown_run_time_min minuets: $shutdown_run_time_sec seconds.\n\nThe UPS has been running off battery power for ${Time_on_battery_array[0]} days: ${Time_on_battery_array[1]} hours: ${Time_on_battery_array[2]} minutes: ${Time_on_battery_array[3]} seconds\n\nUPS Voltage: $input_voltage VAC\nBattery Capacity: $battery_capacity_decimal %\nRuntime Remaining: ${battery_run_time_remaining_array[1]} Hours: ${battery_run_time_remaining_array[2]} Minutes: ${battery_run_time_remaining_array[3]} Seconds\nBattery Temperature: $battery_temperature_decimal degrees C" "CRITICAL - $nas_name Shutting Down Due to Limited Battery Runtime" "$notification_file_location/$ups_email_notification_file" "before the system shuts down" 0 $sendmail_installed

								system_shutdown "$input_voltage" "$battery_capacity_decimal" "${battery_run_time_remaining_array[0]}" "${battery_run_time_remaining_array[1]}" "${battery_run_time_remaining_array[2]}" "${battery_run_time_remaining_array[3]}" "$notification_file_location" "$UPS_shutdown_status_file" "$ups_outlet_group_turn_off_enable" "$UPS_snmp_user" "$UPS_snmp_auth_protocol" "$UPS_AuthPass1" "$UPS_snmp_privacy_protocol" "$UPS_PrivPass2" "$UPS_url" "$ups_outlet_group_turn_off_delay" "$debug_mode" "$UPS_on_battery" "$docker_installed" "$battery_temperature_decimal" "$battery_voltage_decimal" "$Time_on_battery"
							fi
						elif [[ $shutdown_trigger == 2 ]]; then #time on battery only
							send_mail "$notification_file_location/$ups_email_notification_last_sent_tracker" "Warning $nas_name is Operating on Battery Power for ${Time_on_battery_array[0]} days: ${Time_on_battery_array[1]} hours: ${Time_on_battery_array[2]} minutes: ${Time_on_battery_array[3]} seconds. If power is not returned before the UPS time on battery exceeds $shutdown_run_time_hours hours: $shutdown_run_time_min minuets: $shutdown_run_time_sec seconds, the system will shutdown.\n\nUPS Voltage: $input_voltage VAC\nBattery Capacity: $battery_capacity_decimal %\nBattery Voltage: $battery_voltage_decimal\nBattery Temperature: $battery_temperature_decimal\nRuntime Remaining: ${battery_run_time_remaining_array[1]} Hours: ${battery_run_time_remaining_array[2]} Minutes: ${battery_run_time_remaining_array[3]} Seconds " "$nas_name Operating on Battery Power" "$notification_file_location/$ups_email_notification_file" "UPS is on battery power" $ups_email_delay $sendmail_installed
							total_run_time_seconds=$(( ( ${Time_on_battery_array[1]} * 3600 ) + ( ${Time_on_battery_array[2]} * 60 ) + ${Time_on_battery_array[3]} ))
							total_run_time_allowed=$(( ( $shutdown_run_time_hours * 3600 ) + ( $shutdown_run_time_min * 60 ) + $shutdown_run_time_sec ))
							
							if [[ $total_run_time_seconds -gt $total_run_time_allowed ]]; then
								run_time_exception=1
							fi
							
							if [[ $run_time_exception == 1 ]] || [[ $battery_exception == 1 ]]; then	
								
								send_mail "$notification_file_location/$ups_email_notification_last_sent_tracker" "CRITICAL - $nas_name is shutting down due to either:\n1.) battery temperature exceeding $max_on_battery_temp_decimal degrees C\n2.) UPS runtime on battery has exceeded $shutdown_run_time_hours hours $shutdown_run_time_min minuets: $shutdown_run_time_sec seconds.\n\nThe UPS has been running off battery power for ${Time_on_battery_array[0]} days: ${Time_on_battery_array[1]} hours: ${Time_on_battery_array[2]} minutes: ${Time_on_battery_array[3]} seconds.\n\nUPS Voltage: $input_voltage VAC\nBattery Capacity: $battery_capacity_decimal %\nRuntime Remaining: ${battery_run_time_remaining_array[1]} Hours: ${battery_run_time_remaining_array[2]} Minutes: ${battery_run_time_remaining_array[3]} Seconds\nBattery Temperature: $battery_temperature_decimal degrees C" "CRITICAL - $nas_name Shutting Down Due to extended run time" "$notification_file_location/$ups_email_notification_file" "before the system shuts down" 0 $sendmail_installed

								system_shutdown "$input_voltage" "$battery_capacity_decimal" "${battery_run_time_remaining_array[0]}" "${battery_run_time_remaining_array[1]}" "${battery_run_time_remaining_array[2]}" "${battery_run_time_remaining_array[3]}" "$notification_file_location" "$UPS_shutdown_status_file" "$ups_outlet_group_turn_off_enable" "$UPS_snmp_user" "$UPS_snmp_auth_protocol" "$UPS_AuthPass1" "$UPS_snmp_privacy_protocol" "$UPS_PrivPass2" "$UPS_url" "$ups_outlet_group_turn_off_delay" "$debug_mode" "$UPS_on_battery" "$docker_installed" "$battery_temperature_decimal" "$battery_voltage_decimal" "$Time_on_battery"
							fi
						elif [[ $shutdown_trigger == 3 ]]; then #run time remaining or battery voltage
							send_mail "$notification_file_location/$ups_email_notification_last_sent_tracker" "Warning $nas_name is Operating on Battery Power for ${Time_on_battery_array[0]} days: ${Time_on_battery_array[1]} hours: ${Time_on_battery_array[2]} minutes: ${Time_on_battery_array[3]} seconds.\n\nThe system will shutdown if power is not returned before:\n1.) UPS run time remaining drops below $shutdown_run_time_hours hours: $shutdown_run_time_min minuets: $shutdown_run_time_sec seconds\n2.) battery voltage drops below $shutdown_battery_voltage_decimal volts.\n\nUPS Voltage: $input_voltage VAC\nBattery Capacity: $battery_capacity_decimal %\nBattery Voltage: $battery_voltage_decimal\nBattery Temperature: $battery_temperature_decimal\nRuntime Remaining: ${battery_run_time_remaining_array[1]} Hours: ${battery_run_time_remaining_array[2]} Minutes: ${battery_run_time_remaining_array[3]} Seconds " "$nas_name Operating on Battery Power" "$notification_file_location/$ups_email_notification_file" "UPS is on battery power" $ups_email_delay $sendmail_installed
							total_run_time_seconds=$(( ( ${battery_run_time_remaining_array[1]} * 3600 ) + ( ${battery_run_time_remaining_array[2]} * 60 ) + ${battery_run_time_remaining_array[3]} ))
							total_run_time_allowed=$(( ( $shutdown_run_time_hours * 3600 ) + ( $shutdown_run_time_min * 60 ) + $shutdown_run_time_sec ))
							
							if [[ $total_run_time_seconds -lt $total_run_time_allowed ]]; then
								run_time_exception=1
							fi
							
							if [[ $battery_voltage -lt $shutdown_battery_voltage ]]; then
								battery_voltage_exception=1
							fi	

							if [[ $run_time_exception == 1 ]] || [[ $battery_exception == 1 ]] || [[ $battery_voltage_exception == 1 ]]; then	
								
								send_mail "$notification_file_location/$ups_email_notification_last_sent_tracker" "CRITICAL - $nas_name is shutting down due to either:\n1.) battery temperature exceeding $max_on_battery_temp_decimal degrees C\n2.) battery voltage dropping below $shutdown_battery_voltage_decimal\n3.) UPS runtime remaining being less than $shutdown_run_time_hours hours: $shutdown_run_time_min minuets: $shutdown_run_time_sec seconds.\n\nThe UPS has been running off battery power for ${Time_on_battery_array[0]} days: ${Time_on_battery_array[1]} hours: ${Time_on_battery_array[2]} minutes: ${Time_on_battery_array[3]} seconds.\n\nUPS Voltage: $input_voltage VAC\nBattery Capacity: $battery_capacity_decimal %\nBattery Voltage: $battery_voltage_decimal\nRuntime Remaining: ${battery_run_time_remaining_array[1]} Hours: ${battery_run_time_remaining_array[2]} Minutes: ${battery_run_time_remaining_array[3]} Seconds\nBattery Temperature: $battery_temperature_decimal degrees C" "CRITICAL - $nas_name Shutting Down Due to Limited Battery Runtime" "$notification_file_location/$ups_email_notification_file" "before the system shuts down" 0 $sendmail_installed

								system_shutdown "$input_voltage" "$battery_capacity_decimal" "${battery_run_time_remaining_array[0]}" "${battery_run_time_remaining_array[1]}" "${battery_run_time_remaining_array[2]}" "${battery_run_time_remaining_array[3]}" "$notification_file_location" "$UPS_shutdown_status_file" "$ups_outlet_group_turn_off_enable" "$UPS_snmp_user" "$UPS_snmp_auth_protocol" "$UPS_AuthPass1" "$UPS_snmp_privacy_protocol" "$UPS_PrivPass2" "$UPS_url" "$ups_outlet_group_turn_off_delay" "$debug_mode" "$UPS_on_battery" "$docker_installed" "$battery_temperature_decimal" "$battery_voltage_decimal" "$Time_on_battery"
							fi
						
						elif [[ $shutdown_trigger == 4 ]]; then #time on battery or battery voltage
							send_mail "$notification_file_location/$ups_email_notification_last_sent_tracker" "Warning $nas_name is Operating on Battery Power for ${Time_on_battery_array[0]} days: ${Time_on_battery_array[1]} hours: ${Time_on_battery_array[2]} minutes: ${Time_on_battery_array[3]} seconds.\n\nThe system will shutdown if power is not returned before\n\n1.) UPS time on battery exceeds $shutdown_run_time_hours hours: $shutdown_run_time_min minuets: $shutdown_run_time_sec seconds\n2.) battery voltage drops below $shutdown_battery_voltage_decimal volts\n\nUPS Voltage: $input_voltage VAC\nBattery Capacity: $battery_capacity_decimal %\nBattery Voltage: $battery_voltage_decimal\nBattery Temperature: $battery_temperature_decimal\nRuntime Remaining: ${battery_run_time_remaining_array[1]} Hours: ${battery_run_time_remaining_array[2]} Minutes: ${battery_run_time_remaining_array[3]} Seconds " "$nas_name Operating on Battery Power" "$notification_file_location/$ups_email_notification_file" "UPS is on battery power" $ups_email_delay $sendmail_installed
							total_run_time_seconds=$(( ( ${Time_on_battery_array[1]} * 3600 ) + ( ${Time_on_battery_array[2]} * 60 ) + ${Time_on_battery_array[3]} ))
							total_run_time_allowed=$(( ( $shutdown_run_time_hours * 3600 ) + ( $shutdown_run_time_min * 60 ) + $shutdown_run_time_sec ))
											
							if [[ $total_run_time_seconds -gt $total_run_time_allowed ]]; then
								run_time_exception=1
							fi
							
							if [[ $battery_voltage -lt $shutdown_battery_voltage ]]; then
								battery_voltage_exception=1
							fi	
							
							if [[ $run_time_exception == 1 ]] || [[ $battery_exception == 1 ]] || [[ $battery_voltage_exception == 1 ]]; then	
								
								send_mail "$notification_file_location/$ups_email_notification_last_sent_tracker" "CRITICAL - $nas_name is shutting down due to either:\n1.) battery temperature exceeding $max_on_battery_temp_decimal degrees C\n2.) battery voltage dropping below $shutdown_battery_voltage_decimal\n3.) UPS runtime on battery has exceeded $shutdown_run_time_hours hours: $shutdown_run_time_min minuets: $shutdown_run_time_sec seconds.\n\nThe UPS has been running off battery power for ${Time_on_battery_array[0]} days: ${Time_on_battery_array[1]} hours: ${Time_on_battery_array[2]} minutes: ${Time_on_battery_array[3]} seconds.\n\nUPS Voltage: $input_voltage VAC\nBattery Capacity: $battery_capacity_decimal %\nBattery Voltage: $battery_voltage_decimal\nRuntime Remaining: ${battery_run_time_remaining_array[1]} Hours: ${battery_run_time_remaining_array[2]} Minutes: ${battery_run_time_remaining_array[3]} Seconds\nBattery Temperature: $battery_temperature_decimal degrees C" "CRITICAL - $nas_name Shutting Down Due to Limited Battery Runtime" "$notification_file_location/$ups_email_notification_file" "before the system shuts down" 0 $sendmail_installed

								system_shutdown "$input_voltage" "$battery_capacity_decimal" "${battery_run_time_remaining_array[0]}" "${battery_run_time_remaining_array[1]}" "${battery_run_time_remaining_array[2]}" "${battery_run_time_remaining_array[3]}" "$notification_file_location" "$UPS_shutdown_status_file" "$ups_outlet_group_turn_off_enable" "$UPS_snmp_user" "$UPS_snmp_auth_protocol" "$UPS_AuthPass1" "$UPS_snmp_privacy_protocol" "$UPS_PrivPass2" "$UPS_url" "$ups_outlet_group_turn_off_delay" "$debug_mode" "$UPS_on_battery" "$docker_installed" "$battery_temperature_decimal" "$battery_voltage_decimal" "$Time_on_battery"
							fi
						elif [[ $shutdown_trigger == 5 ]]; then #battery voltage Only
							send_mail "$notification_file_location/$ups_email_notification_last_sent_tracker" "Warning $nas_name is Operating on Battery Power for ${Time_on_battery_array[0]} days: ${Time_on_battery_array[1]} hours: ${Time_on_battery_array[2]} minutes: ${Time_on_battery_array[3]} seconds. If power is not returned before the UPS battery voltage drops below $shutdown_battery_voltage_decimal volts, the system will shutdown\n\nUPS Voltage: $input_voltage VAC\nBattery Capacity: $battery_capacity_decimal %\nBattery Voltage: $battery_voltage_decimal\nBattery Temperature: $battery_temperature_decimal\nRuntime Remaining: ${battery_run_time_remaining_array[1]} Hours: ${battery_run_time_remaining_array[2]} Minutes: ${battery_run_time_remaining_array[3]} Seconds" "$nas_name Operating on Battery Power" "$notification_file_location/$ups_email_notification_file" "UPS is on battery power" $ups_email_delay $sendmail_installed
							
							if [[ $battery_voltage -lt $shutdown_battery_voltage ]]; then
								battery_voltage_exception=1
							fi	
							
							if [[ $battery_exception == 1 ]] || [[ $battery_voltage_exception == 1 ]]; then	
								
								send_mail "$notification_file_location/$ups_email_notification_last_sent_tracker" "CRITICAL - $nas_name is shutting down due to either\n1.) battery temperature exceeding $max_on_battery_temp_decimal degrees C\n2.) battery voltage dropping below $shutdown_battery_voltage_decimal.\n\nThe UPS has been running off battery power for ${Time_on_battery_array[0]} days: ${Time_on_battery_array[1]} hours: ${Time_on_battery_array[2]} minutes: ${Time_on_battery_array[3]} seconds.\n\nThe UPS Voltage: $input_voltage VAC\nBattery Capacity: $battery_capacity_decimal %\nBattery Voltage: $battery_voltage_decimal\nRuntime Remaining: ${battery_run_time_remaining_array[1]} Hours: ${battery_run_time_remaining_array[2]} Minutes: ${battery_run_time_remaining_array[3]} Seconds\nBattery Temperature: $battery_temperature_decimal degrees C" "CRITICAL - $nas_name Shutting Down Due to Limited Battery Runtime" "$notification_file_location/$ups_email_notification_file" "before the system shuts down" 0 $sendmail_installed

								system_shutdown "$input_voltage" "$battery_capacity_decimal" "${battery_run_time_remaining_array[0]}" "${battery_run_time_remaining_array[1]}" "${battery_run_time_remaining_array[2]}" "${battery_run_time_remaining_array[3]}" "$notification_file_location" "$UPS_shutdown_status_file" "$ups_outlet_group_turn_off_enable" "$UPS_snmp_user" "$UPS_snmp_auth_protocol" "$UPS_AuthPass1" "$UPS_snmp_privacy_protocol" "$UPS_PrivPass2" "$UPS_url" "$ups_outlet_group_turn_off_delay" "$debug_mode" "$UPS_on_battery" "$docker_installed" "$battery_temperature_decimal" "$battery_voltage_decimal" "$Time_on_battery"
							fi
						fi 
							
						##########################################################################
						#process the 5x different triggers that can be configured to cause load shedding to occur
						##########################################################################
						if [[ $load_shed_trigger == 1 ]]; then #run time remaining only							
							total_run_time_seconds=$(( ( ${battery_run_time_remaining_array[1]} * 3600 ) + ( ${battery_run_time_remaining_array[2]} * 60 ) + ${battery_run_time_remaining_array[3]} ))
							total_run_time_allowed=$(( ( $load_shed_run_time_hours * 3600 ) + ( $load_shed_run_time_min * 60 ) + $load_shed_run_time_sec ))
							
							if [[ $total_run_time_seconds -lt $total_run_time_allowed ]]; then
							
								echo "Performing load shedding activities as the battery run time remaining is too low"
								
								plex_shutdown "$plex_installed_on_system" "$PLEX_load_shed_active" "$PLEX_IP" "$DSMVersion" "$plex_installed_volume" "$PDU_load_shed_active" "$Surveillance_Station_Load_shed_active" "$notification_file_location" "$UPS_load_shed_status_file" "$sendmail_installed" "$ups_email_notification_last_sent_tracker" "$plex_package_name" "$nas_name" "$ups_email_notification_file" "$plex_load_shed_enable"
								
								shutdown_Synology_SS "" "$notification_file_location/$SS_notification_last_sent_tracker" "$notification_file_location/$ups_email_notification_file" "$PDU_load_shed_active" "$PLEX_load_shed_active" "$load_shed_file_location" "$sendmail_available" "$surveillance_station_installed_on_system" "$Surveillance_Station_Load_shed_active" "$synology_ss_load_shed_enable" "$nas_name"
								
								pdu_load_shed "$pdu_load_shed_enable" "$PDU_load_shed_active" "$notification_file_location" "$UPS_load_shed_status_file" "$PLEX_load_shed_active" "$Surveillance_Station_Load_shed_active" "$PDU_AuthPass1" "$PDU_PrivPass2" "$PDU_snmp_user" "$PDU_IP" "$PDU_snmp_auth_protocol" "$PDU_snmp_privacy_protocol" "$docker_installed" "$pdu_outlet_failure_email_last_sent_tracker" "$ups_email_notification_file" "$sendmail_installed"
							fi
						elif [[ $load_shed_trigger == 2 ]]; then #time on battery only
							total_run_time_seconds=$(( ( ${Time_on_battery_array[1]} * 3600 ) + ( ${Time_on_battery_array[2]} * 60 ) + ${Time_on_battery_array[3]} ))
							total_run_time_allowed=$(( ( $load_shed_run_time_hours * 3600 ) + ( $load_shed_run_time_min * 60 ) + $load_shed_run_time_sec ))
							
							if [[ $total_run_time_seconds -gt $total_run_time_allowed ]]; then

								echo "Performing load shedding activities as the time running on battery was too long"

								plex_shutdown "$plex_installed_on_system" "$PLEX_load_shed_active" "$PLEX_IP" "$DSMVersion" "$plex_installed_volume" "$PDU_load_shed_active" "$Surveillance_Station_Load_shed_active" "$notification_file_location" "$UPS_load_shed_status_file" "$sendmail_installed" "$ups_email_notification_last_sent_tracker" "$plex_package_name" "$nas_name" "$ups_email_notification_file" "$plex_load_shed_enable"
								
								shutdown_Synology_SS "" "$notification_file_location/$SS_notification_last_sent_tracker" "$notification_file_location/$ups_email_notification_file" "$PDU_load_shed_active" "$PLEX_load_shed_active" "$load_shed_file_location" "$sendmail_available" "$surveillance_station_installed_on_system" "$Surveillance_Station_Load_shed_active" "$synology_ss_load_shed_enable" "$nas_name"
								
								pdu_load_shed "$pdu_load_shed_enable" "$PDU_load_shed_active" "$notification_file_location" "$UPS_load_shed_status_file" "$PLEX_load_shed_active" "$Surveillance_Station_Load_shed_active" "$PDU_AuthPass1" "$PDU_PrivPass2" "$PDU_snmp_user" "$PDU_IP" "$PDU_snmp_auth_protocol" "$PDU_snmp_privacy_protocol" "$docker_installed" "$pdu_outlet_failure_email_last_sent_tracker" "$ups_email_notification_file" "$sendmail_installed"
							fi
						elif [[ $load_shed_trigger == 3 ]]; then #run time remaining or battery voltage
							total_run_time_seconds=$(( ( ${battery_run_time_remaining_array[1]} * 3600 ) + ( ${battery_run_time_remaining_array[2]} * 60 ) + ${battery_run_time_remaining_array[3]} ))
							total_run_time_allowed=$(( ( $load_shed_run_time_hours * 3600 ) + ( $load_shed_run_time_min * 60 ) + $load_shed_run_time_sec ))
							
							if [[ $total_run_time_seconds -lt $total_run_time_allowed ]]; then
								run_time_exception=1
							fi
							
							if [[ $battery_voltage -lt $load_shed_voltage ]]; then
								battery_voltage_exception=1
							fi	
							
							if [[ $run_time_exception == 1 ]] || [[ $battery_voltage_exception == 1 ]]; then

								echo "Performing load shedding activities as the battery run time remaining is too low or the battery voltage was too low"
								
								plex_shutdown "$plex_installed_on_system" "$PLEX_load_shed_active" "$PLEX_IP" "$DSMVersion" "$plex_installed_volume" "$PDU_load_shed_active" "$Surveillance_Station_Load_shed_active" "$notification_file_location" "$UPS_load_shed_status_file" "$sendmail_installed" "$ups_email_notification_last_sent_tracker" "$plex_package_name" "$nas_name" "$ups_email_notification_file" "$plex_load_shed_enable"
								
								shutdown_Synology_SS "" "$notification_file_location/$SS_notification_last_sent_tracker" "$notification_file_location/$ups_email_notification_file" "$PDU_load_shed_active" "$PLEX_load_shed_active" "$load_shed_file_location" "$sendmail_available" "$surveillance_station_installed_on_system" "$Surveillance_Station_Load_shed_active" "$synology_ss_load_shed_enable" "$nas_name"
								
								pdu_load_shed "$pdu_load_shed_enable" "$PDU_load_shed_active" "$notification_file_location" "$UPS_load_shed_status_file" "$PLEX_load_shed_active" "$Surveillance_Station_Load_shed_active" "$PDU_AuthPass1" "$PDU_PrivPass2" "$PDU_snmp_user" "$PDU_IP" "$PDU_snmp_auth_protocol" "$PDU_snmp_privacy_protocol" "$docker_installed" "$pdu_outlet_failure_email_last_sent_tracker" "$ups_email_notification_file" "$sendmail_installed"
							fi
						
						elif [[ $load_shed_trigger == 4 ]]; then #time on battery or battery voltage
							total_run_time_seconds=$(( ( ${Time_on_battery_array[1]} * 3600 ) + ( ${Time_on_battery_array[2]} * 60 ) + ${Time_on_battery_array[3]} ))
							total_run_time_allowed=$(( ( $load_shed_run_time_hours * 3600 ) + ( $load_shed_run_time_min * 60 ) + $load_shed_run_time_sec ))
							
							if [[ $total_run_time_seconds -gt $total_run_time_allowed ]]; then
								run_time_exception=1
							fi
							
							if [[ $battery_voltage -lt $load_shed_voltage ]]; then
								battery_voltage_exception=1
							fi	
							
							if [[ $run_time_exception == 1 ]] || [[ $battery_voltage_exception == 1 ]]; then	
								
								echo "Performing load shedding activities as the time running on battery is too long or the battery voltage was too low"
								
								plex_shutdown "$plex_installed_on_system" "$PLEX_load_shed_active" "$PLEX_IP" "$DSMVersion" "$plex_installed_volume" "$PDU_load_shed_active" "$Surveillance_Station_Load_shed_active" "$notification_file_location" "$UPS_load_shed_status_file" "$sendmail_installed" "$ups_email_notification_last_sent_tracker" "$plex_package_name" "$nas_name" "$ups_email_notification_file" "$plex_load_shed_enable"
								
								shutdown_Synology_SS "" "$notification_file_location/$SS_notification_last_sent_tracker" "$notification_file_location/$ups_email_notification_file" "$PDU_load_shed_active" "$PLEX_load_shed_active" "$load_shed_file_location" "$sendmail_available" "$surveillance_station_installed_on_system" "$Surveillance_Station_Load_shed_active" "$synology_ss_load_shed_enable" "$nas_name"
								
								pdu_load_shed "$pdu_load_shed_enable" "$PDU_load_shed_active" "$notification_file_location" "$UPS_load_shed_status_file" "$PLEX_load_shed_active" "$Surveillance_Station_Load_shed_active" "$PDU_AuthPass1" "$PDU_PrivPass2" "$PDU_snmp_user" "$PDU_IP" "$PDU_snmp_auth_protocol" "$PDU_snmp_privacy_protocol" "$docker_installed" "$pdu_outlet_failure_email_last_sent_tracker" "$ups_email_notification_file" "$sendmail_installed"
							fi
						elif [[ $load_shed_trigger == 5 ]]; then #battery voltage Only
							if [[ $battery_voltage -lt $load_shed_voltage ]]; then
								
								echo "Performing load shedding activities as the battery voltage was too low"
								
								plex_shutdown "$plex_installed_on_system" "$PLEX_load_shed_active" "$PLEX_IP" "$DSMVersion" "$plex_installed_volume" "$PDU_load_shed_active" "$Surveillance_Station_Load_shed_active" "$notification_file_location" "$UPS_load_shed_status_file" "$sendmail_installed" "$ups_email_notification_last_sent_tracker" "$plex_package_name" "$nas_name" "$ups_email_notification_file" "$plex_load_shed_enable"
								
								shutdown_Synology_SS "" "$notification_file_location/$SS_notification_last_sent_tracker" "$notification_file_location/$ups_email_notification_file" "$PDU_load_shed_active" "$PLEX_load_shed_active" "$load_shed_file_location" "$sendmail_available" "$surveillance_station_installed_on_system" "$Surveillance_Station_Load_shed_active" "$synology_ss_load_shed_enable" "$nas_name"
								
								pdu_load_shed "$pdu_load_shed_enable" "$PDU_load_shed_active" "$notification_file_location" "$UPS_load_shed_status_file" "$PLEX_load_shed_active" "$Surveillance_Station_Load_shed_active" "$PDU_AuthPass1" "$PDU_PrivPass2" "$PDU_snmp_user" "$PDU_IP" "$PDU_snmp_auth_protocol" "$PDU_snmp_privacy_protocol" "$docker_installed" "$pdu_outlet_failure_email_last_sent_tracker" "$ups_email_notification_file" "$sendmail_installed"
							fi	
						fi

					else
						#####################################################################
						#UPS input voltage is OK, nothing needs to be done
						#####################################################################
						echo "UPS OK, UPS Voltage: $input_voltage VAC, Battery Capacity: $battery_capacity_decimal %, Battery Voltage: $battery_voltage_decimal, Battery Temperature: $battery_temperature_decimal, Runtime Remaining ${battery_run_time_remaining_array[0]} days: ${battery_run_time_remaining_array[1]} hours: ${battery_run_time_remaining_array[2]} minutes: ${battery_run_time_remaining_array[3]} seconds"
						
						##########################################################################
						#once per hour save a "heart beat" date value to file so we can monitor that the script is operating properly
						##########################################################################
						current_time_min=$(date +"%M")
						current_time_sec=$(date +"%S")
						
						if [ "$current_time_min" == "00" ]; then
							if [[ $current_time_sec -lt 15 ]]; then
								current_time=$( date +%s )
								echo "$current_time" > "$notification_file_location/$UPS_monitor_Heartbeat"
							fi
						fi
						
						##########################################################################
						#if the UPS had previously been running on battery power, we need to save the fact that it is now on AC power
						##########################################################################
						if [ $UPS_on_battery -eq 1 ]; then
							UPS_on_battery=0
							echo "$UPS_Shutdown,$UPS_on_battery" > "$notification_file_location/$UPS_shutdown_status_file"
							
							#send email that UPS is no longer on battery power
							send_mail "$notification_file_location/$ups_email_notification_last_sent_tracker" "ALERT - $nas_name - UPS input power restored, UPS no longer operating on battery power -- UPS Voltage: $input_voltage VAC, Battery Capacity: $battery_capacity_decimal %, Battery Voltage: $battery_voltage_decimal, Battery Temperature: $battery_temperature_decimal, Runtime Remaining: ${battery_run_time_remaining_array[1]} Hours: ${battery_run_time_remaining_array[2]} Minutes: ${battery_run_time_remaining_array[3]} Seconds" "ALERT - $nas_name UPS Power has Been Restored" "$notification_file_location/$ups_email_notification_file" "UPS power has been restored" 0 $sendmail_installed
						fi
						
						##########################################################################
						#now that the UPS is running on AC power again, check if the PDU was commanded to load shed. if it had performed a load shed, turn the outlets back on
						##########################################################################
						if [ $pdu_load_shed_enable -eq 1 ]; then
							if [ $PDU_load_shed_active -eq 1 ]; then
								outlets=1
								while [ $outlets -lt 17 ]; do
									if [ ${outlet_load_shed_yes_no[$outlets]} -eq 1 ]; then
										load_shed_PDU_ON_OFF $outlets on "$notification_file_location/$UPS_load_shed_status_file" $PLEX_load_shed_active $Surveillance_Station_Load_shed_active "$PDU_AuthPass1" "$PDU_PrivPass2" "$PDU_snmp_user" "$PDU_IP" "$PDU_snmp_auth_protocol" "$PDU_snmp_privacy_protocol" $docker_installed
									fi
									let outlets=outlets+1
								done
								PDU_load_shed_active=0
							fi
						fi
						
						##########################################################################
						#now that the UPS is running on AC power again, check if surveillance station was shutdown, if it was, turn it back on
						##########################################################################
						if [ $synology_ss_load_shed_enable -eq 1 ]; then
							if [ $surveillance_station_installed_on_system -eq 1 ]; then
								if [ $Surveillance_Station_Load_shed_active -eq 1 ]; then
									#email_address || email file location || email file name || PDU_load_shed_active || PLEX_load_shed_active || load_shed_file_location || sendmail_installed || from_email_address
									restart_Synology_SS "$email_address" "$notification_file_location" "$ups_email_notification_file" $PDU_load_shed_active $PLEX_load_shed_active "$notification_file_location/$UPS_load_shed_status_file" $sendmail_installed "$from_email_address"
									Surveillance_Station_Load_shed_active=0
								fi
							fi
						fi
						
						##########################################################################
						#now that the UPS is running on AC power again, check if PLEX was shutdown
						##########################################################################
						if [ $plex_load_shed_enable -eq 1 ]; then
							if [ $plex_installed_on_system -eq 1 ]; then
								if [ $PLEX_load_shed_active -eq 1 ]; then
									
									#####################################
									#start PLEX Media Server Package 
									#####################################
									plex_status=$(/usr/syno/bin/synopkg is_onoff "$plex_package_name")
									if [ "$plex_status" = "package $plex_package_name is turned on" ]; then
										echo "$plex_package_name already active, skipping PLEX restart"
									else
										echo "Starting $plex_package_name...."
										/usr/syno/bin/synopkg start "$plex_package_name"
										sleep 1
									fi
									
									plex_status=$(/usr/syno/bin/synopkg is_onoff "$plex_package_name")
									if [ "$plex_status" = "package $plex_package_name is turned on" ]; then
										echo "$plex_package_name Successfully Restarted"
										PLEX_load_shed_active=0
										#file contents: "PDU_load_shed_active"  ||  "PLEX_load_shed_active"  ||  "Surveillance_Station_Load_shed_active" 
										echo "$PDU_load_shed_active,0,$Surveillance_Station_Load_shed_active " > $notification_file_location/$UPS_load_shed_status_file
										
										#send an alert email to the email address configured in the web administration page
										send_mail "$notification_file_location/$ups_email_notification_last_sent_tracker" "ALERT $nas_name has restarted the package \"$plex_package_name\" after UPS power was restored. The UPS Voltage: $input_voltage VAC, Battery Capacity: $battery_capacity_decimal %, Runtime Remaining: ${battery_run_time_remaining_array[1]} Hours: ${battery_run_time_remaining_array[2]} Minutes: ${battery_run_time_remaining_array[3]} Seconds. " "$nas_name has restarted package \"$plex_package_name\" after UPS power was restored" "$notification_file_location/$ups_email_notification_file" "PLEX was Re-started" 0 $sendmail_installed
									else
										echo "Failed to restart PLEX Package"
									fi
								fi
							fi
						fi
						
					fi			
				fi
				
				
				let i=i+1
				
				echo "Capture #$i complete"
				
				##########################################################################
				#Sleeping for capture interval unless its last capture then we don't sleep
				##########################################################################
				if [[ $i -lt $total_executions ]]; then
					sleep $(( $capture_interval -2))
				fi
				
			done;
		else
			#the script is disabled in the web administration web page
			echo "script is disabled"
		fi
	else
	##########################################################################
	#config file could not be loaded, send notification that script cannot run
	##########################################################################
		current_time=$( date +%s )
		if [ -r "$notification_file_location/$ups_email_notification_last_sent_tracker" ]; then
			read ups_email_time < "$notification_file_location/$ups_email_notification_last_sent_tracker" 
			ups_email_time_diff=$((( $current_time - $ups_email_time ) / 60 ))
		else 
			echo "$current_time" > "$notification_file_location/$ups_email_notification_last_sent_tracker"
			ups_email_time_diff=61
		fi
		if [ $ups_email_time_diff -ge 60 ]; then
			#send an email indicating script config file is missing and script will not run
			send_mail "$notification_file_location/$ups_email_notification_last_sent_tracker" "Warning $nas_name UPS Monitoring Failed - Configuration file is missing" "Warning $nas_name UPS Monitoring Failed - Configuration or username/password credential file is missing" "$notification_file_location/$ups_email_notification_file" "script config file is missing and script will not run" 0 $sendmail_installed
		else
			echo -e "\n\nAnother email notification will be sent in $(( 60 - $ups_email_time_diff)) Minutes"
		fi
	fi
else
	#the script is being skipped because the system is already shutting down
	echo "System is shutting down - Skipping Script"
fi
exit
				
