#!/bin/bash
VERSION="2/02/2022"
#By Brian Wallace

#This script pulls data from an APC UPS with a Network Management Card 2 installed. if the UPS does not have a network management cad installed, this script cannot interface with a USB connected UPS. 
#This script has been coded to utilize the network management card 2 from APC and has not been tested with the version 3 of the card however it is unknown if the script will still function. 


#***************************************************
#Dependencies:
#***************************************************
#1.) this script is designed to be executed every 60 seconds
#2.) this script requires the installation of synology MailPlus server package in package center in order to send emails. 
	#the mail plus server must be properly configured to relay received messages to another email account. 
#3.) this script is Dependent on a docker container for SNMP_SET commands using the "elcolio/net-snmp" container located here: https://hub.docker.com/r/elcolio/net-snmp
	#this is required as the synology system does not contain the snmp_set commands. the set command is used to control the PDU outlets and to command the UPS to shutdown
	#the container does not always run, it is run once when a SET command needs to be executed 
#4.) RAMDISK
	#NOTE: to reduce disk IOPS activity, it is recommended to create a RAMDISK for the temp files this script uses
	#to do so, create a scheduled task on boot up in Synology Task Scheduler to add the following line

		#mount -t tmpfs -o size=1% ramdisk $notification_file_location

		#where "$notification_file_location" is the location you want the files stored and is a variable configured below

		#as this is a RAMDISK folder, upon boot up the contents will be empty which is required for the script to operate after it has commanded a shutdown. 
	#if not using a RAM disk folder, then a scheduled task to re-set the shutdown log file is required
	#to do so, create a scheduled task on boot up in Synology Task Scheduler to add the following line

		#echo "0,0" > $notification_file_location/$UPS_shutdown_log_file
		#where "$notification_file_location/$UPS_shutdown_log_file" is the location you want the files stored and are variables configured below
#5.) this script only supports SNMP V3. This is because lower versions are less secure especially when using the set commands that have the ability to remove power to the systems
	#SNMP must be enabled on the host NAS for the script to gather the NAS NAME
	#SNNMP must be enabled on the target APC UPS network management card
	#SNNMP must be enabled on the PDU
	#the snmp settings for the NAS, UPS, and PDU can all be entered into the web administration page
#6.) This script can be run through synology Task Scheduler. However it has been observed that running large scripts like this as frequently as every 60 seconds causes the synoschedtask system application to use large amounts of resources and causes the script to execute slowly
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
#if no PDU is available, set the variable "load_shed_control" to a zero or use the web administration page to disable load shedding. 
#if a different PDU model or manufacture is utilized the script may not work as the SNMP commands will likely not match. 
#if PDU load shedding is desired, the PDU must have SNMP enabled for communications and control. 
#the amount of time the load shedding occurs is configurable through "load_shed_early_time" or through the web administration page. 
#this will cause load shedding to occur x number of minutes earlier than the system shutdown command configured in the web administration page
#outlets will be turned back on when UPS power is restored ONLY IF the power is restored before the system is commanded to shutdown. 
#if the system is commanded to shutdown, when the system is restarted, the PDU outlets commanded to turn off during load shed will remain off and will need to be manually re-enabled. 
#this is to prevent constant power on/off fluctuations from causing the system to continuously turn the outlets on and off. 


#***************************************************
#Synology Surveillance Station Application Shutdown Load Shedding:
#***************************************************
#the script can terminate the synology surveillance station application which can draw significant power from the CPU and GPU
#the amount of time the load shedding occurs is configurable through "load_shed_early_time" or through the web administration page. 
#this will cause load shedding to occur x number of minutes earlier than the system shutdown command
#surveillance Station will be restarted when UPS power is restored ONLY IF the power is restored before the system is commanded to shutdown. 
#if the system is commanded to shutdown, when the system is restarted, surveillance station will remain off and will need to be manually re-enabled. 
#this is to prevent constant power on/off fluctuations from causing the system to continuously turn the services on and off. 


#***************************************************
#PLEX Media Server Application Shutdown Load Shedding:
#***************************************************
#the script can terminate any active PLEX streams which if performing transcoding can use high levels of CPU power and wattage
#the amount of time the load shedding occurs is configurable through "load_shed_early_time" or through the web administration page. this will cause load shedding to occur x number of minutes earlier than the system shutdown command
#PLEX will be restarted when UPS power is restored ONLY IF the power is restored before the system is commanded to shutdown. 
#if the system is commanded to shutdown, when the system is restarted, PLEX will remain off and will need to be manually re-enabled. 
#this is to prevent constant power on/off fluctuations from causing the system to continuously turn the services on and off.
	

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


#note if getting errors about syntax error near unexpected token `$'in\r''
#then run command sed -i 's/\r//' script.sh

#Debug Log dated 12/15/2021
#1.) everything OK ------------------------------------------------------------------------------------------------------------- VERIFIED OK
#2.) UPS communications Offline while AC is OK
#	2 a.) Verify email sent every 2 minutes------------------------------------------------------------------------------------- VERIFIED OK
#	2 b.) verify email sent when UPS communications are down for too long, should get email when time delay is at 50%----------- VERIFIED OK 
#	2 c.) verify when UPS communications are down for too long, the system shuts down------------------------------------------- VERIFIED OK 
#	2 d.) verify while system is shutting down script does not run-------------------------------------------------------------- VERIFIED OK  
#3.) UPS communications Online, no AC power
#	3 a.) verify email sent every 2 minutes when on battery power--------------------------------------------------------------- VERIFIED OK  
#	3 b.) while communications remain ONLINE, verify system shuts down when run time too low------------------------------------ VERIFIED OK  
#	3 c.) verify load shed occurs----------------------------------------------------------------------------------------------- VERIFIED OK 
#	3 d.) verify plex is commanded to turn off---------------------------------------------------------------------------------- VERIFIED OK 
#	3 e.) verify SS is commanded to turn off------------------------------------------------------------------------------------ VERIFIED OK 
#	3 f.) while on battery, kill UPS communications, verify system shuts down immediately--------------------------------------- VERIFIED OK  
#   3 g.) while on battery, when system shuts down, UPS outlet group delay time is properly commanded -------------------------- VERIFIED OK
#   3 h.) while on battery, when system shuts down, UPS turns outlets off after set delay period ------------------------------- NOT Yet Verified 
#4.) after load shedding and before system shutdown, power comes back
#	4 a.) verify outlets turn back on------------------------------------------------------------------------------------------- VERIFIED OK
#	4 b.) verify plex turns back on--------------------------------------------------------------------------------------------- VERIFIED OK 
#	4 c.) verify SS turns back on----------------------------------------------------------------------------------------------- VERIFIED OK 

##########################################################################
##########################################################################
#variable handling and initialization
##########################################################################
##########################################################################

UPS_shutdown_log_file="UPS_Shutdown2.txt"
UPS_load_shed_log_file="UPS_LoadShed2.txt"
ups_coms_fail_counter="ups_coms_fail_delay_status2.txt"
ups_email_delay_counter="ups_email2.txt"
ups_notification_file="ups_notifiation2.txt"
shutdown_email_contents="shutdown_contents2.txt"
sendmail_installed=0
from_email_address="admin@admin.com"

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

debug_mode=0 #set to 1 to make script use debug variables below
runtime_remaining_debug=(); #make debug array
runtime_remaining_debug_days=0
runtime_remaining_debug_hours=0
runtime_remaining_debug_min=20
runtime_remaining_debug_sec=59
APC_online_debug=1
battery_capacity_debug=100
input_voltage_debug=120
UPS_comm_loss_shutdown_interval_debug=6
ups_outlet_group_turn_off_enable_debug=1
ups_outlet_group_turn_off_delay_debug=20


##########################################################################
#create a lock file in the ramdisk directory to prevent more than one instance of this script from executing  at once
##########################################################################

if ! mkdir $notification_file_location/$lock_file_name; then
	echo "Failed to acquire lock.\n" >&2
	exit 1
fi
trap 'rm -rf $notification_file_location/$lock_file_name' EXIT #remove the lockdir on exit


##########################################################################
#Main Script start
##########################################################################


#read in two variables stored in an external file "UPS_shutdown_log_file" to track the following two things:
#1.) is the system currently shutting down due to communications loss with the UPS?
#2.) is the UPS on battery power?

#if the UPS communications are not working while the system is actively shutting down, we want to skip this entire script to prevent it from commanding the system to shutdown again
#tracking if the UPS is on active battery power is needed so that if UPS communications are lost while on battery, monitoring of the UPS is not possible and for safety, shutdown the system immediately 

if [ -r "$notification_file_location/$UPS_shutdown_log_file" ]; then
	#file is available and readable 
	#echo "$UPS_shutdown_log_file is available, reading file contents"
	read input_read < $notification_file_location/$UPS_shutdown_log_file
	explode=(`echo $input_read | sed 's/,/\n/g'`)
	UPS_Shutdown=${explode[0]}
	UPS_on_battery=${explode[1]}
else
	#file is missing, let's write to disk some default values
	echo "$UPS_shutdown_log_file is unavailable, writing default values"
	echo "0,0" > $notification_file_location/$UPS_shutdown_log_file
	UPS_Shutdown=0
	UPS_on_battery=0
fi

##########################################################################
#Functions used within the script
##########################################################################


#####################################
#Function to perform shutdown of active plex streams
#####################################
function plex_stream_terminate(){
#plex_IP_address=${1}
#DSM_version=${2}
#plex_installed_volume=${3} 	  volume2 for example
#PDU_load_shed_active=${4}
#Surveillance_Station_Load_shed_active=${5}
#load_shed_file_location=${6}
	if [ "${3}" = "" ];then
		echo "PLEX Installed Volume is BLANK, If Plex is installed, please configure the volume details"
	else
		if [ "${1}" = "" ];then
			echo "PLEX IP Address is BLANK, If Plex is installed, please configure IP Address"
		else
			echo "UPS on battery power, need to shutdown active plex streams to reduce system power usage"
			
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

			#if plex is running we want to terminate any active users, this can also save some battery run time
				
			local PMS_IP=${1} #IP of PLEX server
			local TOKEN=$(cat "$plex_Preferences_loction" | grep -oP 'PlexOnlineToken="\K[^"]+')
			#echo "Token is $TOKEN"
			#message sent to plex client (no spaces allowed)
			local MSG='Power_Outtage_--_UPS_Runtime_Low_--_Shutting_Down_Plex'
			local CLIENT_IDENT='123456'


			#Start by getting the active sessions

			local sessionURL="http://$PMS_IP:32400/status/sessions?X-Plex-Client-Identifier=$CLIENT_IDENT&X-Plex-Token=$TOKEN"
			#echo "sessionURL is $sessionURL"
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
				#echo $killURL
				if [ $http_status -eq "200" ]
				then
					echo "Success with killing of stream ${array_sess[z]}"
				else
					echo "Something went wrong here"
				fi
			done
			#file contents: "PDU_load_shed_active"  ||  "PLEX_load_shed_active"  ||  "Surveillance_Station_Load_shed_active" 
			echo "${4},1,${5} " > ${6}
		fi
	fi
}

#####################################
#Function to Stop Synology Surveillance Station package to reduce system power draw
#####################################
function shutdown_Synology_SS(){
#email_address=${1}
#email file location=${2}
#email file name=${3}
#PDU_load_shed_active=${4}
#PLEX_load_shed_active=${5}
#load_shed_file_location=${6}
#sendmail_available=${7}
#from=${8}
	echo "UPS on battery power, need to shutdown the package SurveillanceStation to reduce system power usage"
	local status=$(/usr/syno/bin/synopkg is_onoff "SurveillanceStation")
	if [ "$status" = "package SurveillanceStation is turned on" ]; then
		echo "Stopping Synology Surveillance Station...."
		/usr/syno/bin/synopkg stop "SurveillanceStation"
		sleep 1
		
		status=$(/usr/syno/bin/synopkg is_onoff "SurveillanceStation")
		if [ "$status" = "package SurveillanceStation is turned on" ]; then
			echo "Stopping Synology Surveillance Station has failed"
		else
			echo "Surveillance Station Successfully Shutdown"
			
			#file contents: "PDU_load_shed_active"  ||  "PLEX_load_shed_active"  ||  "Surveillance_Station_Load_shed_active" 
			echo "${4},${5},1 " > ${6}
			
			local now=$(date +"%T")
			echo "sending email notification that package SurveillanceStation has been shutdown"
			#send an email before the system shuts down
			local mailbody="$now - ALERT $nas_name has stopped the package \"SurveillanceStation\" due to UPS runtime remaining on battery being too low. The UPS Voltage: $input_voltage VAC, Battery Capacity: $battery_capacity %, Runtime Remaining: ${array[1]} Hours : ${array[2]} Minutes : ${array[3]} Seconds. "
			echo "from: ${8} " > ${2}/${3}
			echo "to: ${1} " >> ${2}/${3}
			echo "subject: $nas_name Stopped package \"SurveillanceStation\" Due to Limited Battery Runtime " >> ${2}/${3}
			echo "" >> ${2}/${3}
			echo $mailbody >> ${2}/${3}
			
			if [ "${1}" = "" ];then
				echo "no email address is configured, Cannot send alert email that package \"SurveillanceStation\" was shutdown"
			else
				if [ ${7} -eq 1 ]; then
					cat ${2}/${3} | sendmail -t
				else
					echo "ERROR -- Could not send alert email that package \"SurveillanceStation\" was shutdown -- command \"sendmail\" is not available"
				fi
			fi
			
		fi
	else
		echo "Surveillance Station Already Shutdown, no need to stop the package"
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
		echo "Synology Surveillance Station is already running"
	else
		echo "Restarting Synology Surveillance Station...."
		/usr/syno/bin/synopkg start "SurveillanceStation"
		sleep 1
		
		status=$(/usr/syno/bin/synopkg is_onoff "SurveillanceStation")
		if [ "$status" = "package SurveillanceStation is turned on" ]; then
			echo "Surveillance Station Successfully Restarted"
			
			#file contents: "PDU_load_shed_active"  ||  "PLEX_load_shed_active"  ||  "Surveillance_Station_Load_shed_active" 
			echo "${4},${5},0 " > ${6}
			
			local now=$(date +"%T")
			echo "sending email notification that package SurveillanceStation has been Restarted After UPS Power was restored"
			#send an email before the system shuts down
			local mailbody="$now - ALERT $nas_name has restarted the package \"SurveillanceStation\" after UPS power was restored. The UPS Voltage: $input_voltage VAC, Battery Capacity: $battery_capacity %, Runtime Remaining: ${array[1]} Hours : ${array[2]} Minutes : ${array[3]} Seconds. "
			echo "from: ${8} " > ${2}/${3}
			echo "to: ${1} " >> ${2}/${3}
			echo "subject: $nas_name has restarted package \"SurveillanceStation\" after UPS power was restored " >> ${2}/${3}
			echo "" >> ${2}/${3}
			echo $mailbody >> ${2}/${3}
			
			if [ "${1}" = "" ];then
				echo "no email address is configured, Cannot send alert email that package \"SurveillanceStation\" was restarted"
			else
				if [ ${7} -eq 1 ]; then
					cat ${2}/${3} | sendmail -t	
				else
					echo "ERROR -- Could not send alert email that package \"SurveillanceStation\" was restarted -- command \"sendmail\" is not available"
				fi
			fi
		else
			echo "Surveillance Station Restart has failed"
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
							local outlet_ON_OFF_status=`snmpwalk -v3 -l authPriv -u ${8} -a ${10} -A ${6} -x ${11} -X ${7} ${9}:161 1.3.6.1.4.1.3808.1.1.3.3.5.1.1.4.${1} -Oqv`
							
							if [ "${2}" = "on" ]; then #turn outlet ON
								echo "Turning outlet #${1} ON"
								if [ "$outlet_ON_OFF_status" = "1" ]; then
									echo "Outlet #${1} is already ON"
								else
									#outlet is currently off, turn it on
									docker run --rm=true elcolio/net-snmp snmpset -v3 -l authPriv -u ${8} -a ${10} -A ${6} -x ${11} -X ${7} ${9}:161 1.3.6.1.4.1.3808.1.1.3.3.3.1.1.4.${1} i 1
									
									#get the status to confirm the outlet is ON
									outlet_ON_OFF_status=`snmpwalk -v3 -l authPriv -u ${8} -a ${10} -A ${6} -x ${11} -X ${7} ${9}:161 1.3.6.1.4.1.3808.1.1.3.3.5.1.1.4.${1} -Oqv`
									if [ "$outlet_ON_OFF_status" = "1" ]; then
										echo "Outlet #${1} Successfully Turned ON"
										#file contents: "PDU_load_shed_active"  ||  "PLEX_load_shed_active"  ||  "Surveillance_Station_Load_shed_active" 
										echo "0,${4},${5} " > ${3}
									else
										echo "Outlet #${1} Failed To Turned ON"
									fi
								fi
							fi
							
							if [ "${2}" = "off" ]; then #turn outlet OFF
								echo "Turning outlet #${1} OFF"
								if [ "$outlet_ON_OFF_status" = "2" ]; then
									echo "Outlet #${1} is already OFF"
								else
									#outlet is currently ON, turn it OFF
									docker run --rm=true elcolio/net-snmp snmpset -v3 -l authPriv -u ${8} -a ${10} -A ${6} -x ${11} -X ${7} ${9}:161 1.3.6.1.4.1.3808.1.1.3.3.3.1.1.4.${1} i 2
									
									#get the status to confirm the outlet is OFF
									outlet_ON_OFF_status=`snmpwalk -v3 -l authPriv -u ${8} -a ${10} -A ${6} -x ${11} -X ${7} ${9}:161 1.3.6.1.4.1.3808.1.1.3.3.5.1.1.4.${1} -Oqv`
									if [ "$outlet_ON_OFF_status" = "2" ]; then
										echo "Outlet #${1} Successfully Turned OFF"
										#file contents: "PDU_load_shed_active"  ||  "PLEX_load_shed_active"  ||  "Surveillance_Station_Load_shed_active" 
										echo "1,${4},${5} " > ${3}
									else
										echo "Outlet #${1} Failed To Turned OFF"
									fi
								fi
							fi
						fi
					fi
				fi
			fi
		else
			echo "PDU did not respond to a PING, PDU may be offline, cannot turn outlet ${1} on/off"
		fi
	else
		echo "WARNING -- Outlet #${1} Failed To Turned OFF as Docker is not available"
	fi
}




#if the system is NOT actively shutting down due to either communications loss or low battery capacity remaining, we want to run this script to continue monitoring the UPS
if [ $UPS_Shutdown -eq 0 ]; then
	#echo "No Shutdowns Active, running script normally"
	
	##########################################################################
	#reading in variables from configuration file "configuration_file"
	#these variables are controlled through a web enabled control administration page, or manually editing the .txt files
	#setting script global variables 
	##########################################################################
	
	
	if [[ -r "$config_file_location/$configuration_file" ]]; then
		#files are available and readable 
		read input_read < $config_file_location/$configuration_file
		explode=(`echo $input_read | sed 's/,/\n/g'`)
		shutdown_runtime=${explode[0]} #how much battery run time is allowed to remain before the system is commanded to shutdown
		UPS_input_Voltage_threashold=${explode[1]} #what is the lowest acceptable AC input voltage before the UPS is considered to be on battery power? this setting needs to be the same as what the UPS itself is configured 
		email_address=${explode[2]} #what email address will the alert messages be sent
		capture_interval=${explode[3]} #how often (in seconds) will this script poll the UPS for information?
		UPS_url=${explode[4]} #what is the IP address of the UPS network management card?
		script_enable=${explode[5]} #is the script enabled or disabled on the web administration page?
		UPS_comm_loss_shutdown_interval=${explode[6]} #if communications with the UPS are lost BUT the UPS is running fine off AC power, how long before the system is commanded to shutdown? this if enabled is for safety as the system cannot safely shutdown if the UPS were to begin running off battery power
		UPS_comm_loss_shutdown_enable=${explode[7]} #is the option to shutdown enabled when the UPS is on AC power and UPS communications are lost for a set period of time?
		PDU_IP=${explode[8]}
		#if PLEX is installed, configure these settings
		PLEX_IP=${explode[9]}
		plex_installed_volume=${explode[10]}
		#how many minutes should load shedding occur before the UPS commands the server to shutdown 
		load_shed_early_time=${explode[11]}
		load_shed_control=${explode[12]} #is load shed control of the PDU enabled or disabled
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
		#which outlets are desired to perform load shedding? 
		outlet_1_load_shed_yes_no=${explode[28]}
		outlet_2_load_shed_yes_no=${explode[29]}
		outlet_3_load_shed_yes_no=${explode[30]}
		outlet_4_load_shed_yes_no=${explode[31]}
		outlet_5_load_shed_yes_no=${explode[32]}
		outlet_6_load_shed_yes_no=${explode[33]}
		outlet_7_load_shed_yes_no=${explode[34]}
		outlet_8_load_shed_yes_no=${explode[35]}
		outlet_9_load_shed_yes_no=${explode[36]}
		outlet_10_load_shed_yes_no=${explode[37]}
		outlet_11_load_shed_yes_no=${explode[38]}
		outlet_12_load_shed_yes_no=${explode[39]}
		outlet_13_load_shed_yes_no=${explode[40]}
		outlet_14_load_shed_yes_no=${explode[41]}
		outlet_15_load_shed_yes_no=${explode[42]}
		outlet_16_load_shed_yes_no=${explode[43]}
		ups_outlet_group_turn_off_enable=${explode[44]}
		ups_outlet_group_turn_off_delay=${explode[45]}

		APC_online=0 #initially set the UPS as off line and as we will check if the UPS is on line soon
		
		#initiate some additional variables which will be read from SNMP
		battery_capacity=""
		battery_run_time=""
		input_voltage=""
		
		
		#read in status of active/inactive load shedding
		if [ -r "$notification_file_location/$UPS_load_shed_log_file" ]; then
			read input_read < $notification_file_location/$UPS_load_shed_log_file
			explode=(`echo $input_read | sed 's/,/\n/g'`)
			PDU_load_shed_active=${explode[0]} 
			PLEX_load_shed_active=${explode[1]} 
			Surveillance_Station_Load_shed_active=${explode[2]} 
		else
			echo "0,0,0 " > $notification_file_location/$UPS_load_shed_log_file
			PDU_load_shed_active=0
			PLEX_load_shed_active=0 
			Surveillance_Station_Load_shed_active=0
		fi
		
		if [ $debug_mode -eq 1 ]; then
			echo "PDU_load_shed_active is $PDU_load_shed_active"
			echo "PLEX_load_shed_active is $PLEX_load_shed_active"
			echo "Surveillance_Station_Load_shed_active is $Surveillance_Station_Load_shed_active"
		fi
				
		
		#is the script enabled through the web administrations page?
		if [ $script_enable -eq 1 ]; then
			#echo "script is enabled, running script normally"
			
			#verify MailPlus Server package is installed and running as the "sendmail" command is not installed in synology by default. the MailPlus Server package is required
			install_check=$(/usr/syno/bin/synopkg list | grep MailPlus-Server)

			if [ "$install_check" = "" ];then
				echo "WARNING!  ----   MailPlus Server NOT is installed, cannot send email notifications"
				sendmail_installed=0
			else
				#echo "MailPlus Server is installed, verify it is running and not stopped"
				status=$(/usr/syno/bin/synopkg is_onoff "MailPlus-Server")
				if [ "$status" = "package MailPlus-Server is turned on" ]; then
					sendmail_installed=1
				else
					sendmail_installed=0
					echo "WARNING!  ----   MailPlus Server NOT is running, cannot send email notifications"
				fi
			fi
			
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
			
			#collect the name of the server
			if [ "$Syno_snmp_user" = "" ];then
				echo "Synology NAS Username is BLANK, please configure the SNMP settings"
			else
				if [ "$Syno_AuthPass1" = "" ];then
					echo "Synology NAS Authentication Password is BLANK, please configure the SNMP settings"
				else
					if [ "$Syno_PrivPass2" = "" ];then
						echo "Synology NAS Privacy Password is BLANK, please configure the SNMP settings"
					else
						nas_name=`snmpwalk -v3 -l authPriv -u $Syno_snmp_user -a $Syno_snmp_auth_protocol -A $Syno_AuthPass1 -x $Syno_snmp_privacy_protocol -X $Syno_PrivPass2 $nas_url:161 SNMPv2-MIB::sysName.0 -Ovqt`
						
						if [ "$nas_name" = "" ];then
							echo "NAS Name returned Blank, using default value, check NAS system SNMP settings"
							nas_name="Synology_NAS"
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
	
			#plex package name is different between DSM version 6 and version 7
			MinDSMVersion=7.0
			/usr/bin/dpkg --compare-versions "$MinDSMVersion" gt "$DSMVersion"
			if [ "$?" -eq "0" ]; then
				plex_package_name="Plex Media Server"
			else
				plex_package_name="PlexMediaServer"
			fi
	
			install_check=$(/usr/syno/bin/synopkg list | grep $plex_package_name)

			if [ "$install_check" = "" ];then
				#echo "PlexMediaServer NOT is installed"
				plex_installed_on_system=0
				plex_shutdown_time=0
			else
				#echo "PlexMediaServer is installed"
				plex_installed_on_system=1
				#shutdown active plex streams 5 minutes before the main system is commanded to shutdown
				plex_shutdown_time=$(( $shutdown_runtime + $load_shed_early_time ))
			fi

			install_check=$(/usr/syno/bin/synopkg list | grep SurveillanceStation)

			if [ "$install_check" = "" ];then
				#echo "SurveillanceStation NOT is installed"
				surveillance_station_installed_on_system=0
				surveillance_station_shutdown_time=0
			else
				#echo "SurveillanceStation is installed"
				surveillance_station_installed_on_system=1
				#shutdown surveillance station 5 minutes before the main system is commanded to shutdown
				surveillance_station_shutdown_time=$(( $shutdown_runtime + $load_shed_early_time ))
			fi
			
			total_executions=$(( 60 / $capture_interval)) #based on the capture interval (10 seconds, 15 seconds, 30 seconds, 60 seconds) set in the web administration page, calculate the number of times this script will loop itself
			
			#the two following variables are incremented every loop of this script meaning they may be incremented multiple times per minute
			ups_email_delay=$(( 2 * $total_executions)) #as this script runs multiple times per minute and we want to send UPS comm loss or UPS is on battery power emails every 2 minutes, calculate the number of script loops will occur in two minutes
			ups_coms_fail_delay=$(( $UPS_comm_loss_shutdown_interval * $total_executions)) #as this script runs multiple times per minute and we want to shutdown the system after a set number of minutes, calculate the number of loops the scrip must run in that time frame
			
			echo "Capturing $total_executions times"
						
			#loop the script 
			i=0
			while [ $i -lt $total_executions ]; do
			
			
				##########################################################################
				#check if the UPS is on line
				#if UPS is on line get data from it
				#if UPS is off line, set a flag variable that UPS is offline
				##########################################################################
				if [ "$UPS_snmp_user" = "" ];then
					echo "UPS SNMP User is BLANK, please configure the UPS SNMP Settings"
				else
					if [ "$UPS_AuthPass1" = "" ];then
						echo "UPS SNMP Authentication Password is BLANK, please configure the UPS SNMP Settings"
					else
						if [ "$UPS_PrivPass2" = "" ];then
							echo "UPS SNMP Privacy Password is BLANK, please configure the UPS SNMP Settings"
						else
							echo "pinging UPS"
							ping -c1 $UPS_url > /dev/null #ping the UPS to ensure it is on line
							
							
							if [ $? -eq 0 ]; then
								##########################################################################
								#the UPS is online so use SNMP to collect the needed data from the UPS
								##########################################################################
								
								# UPS Battery Capacity
								#battery_capacity=`snmpwalk -v 2c -c public $UPS_url .1.3.6.1.4.1.318.1.1.1.2.2.1.0 -Oqv`
								battery_capacity=`snmpwalk -v3 -l authPriv -u $UPS_snmp_user -a $UPS_snmp_auth_protocol -A $UPS_AuthPass1 -x $UPS_snmp_privacy_protocol -X $UPS_PrivPass2 $UPS_url:161 .1.3.6.1.4.1.318.1.1.1.2.2.1.0 -Oqv`
								
								# UPS Battery remaining Run Time
								#battery_run_time=`snmpwalk -v 2c -c public $UPS_url .1.3.6.1.4.1.318.1.1.1.2.2.3.0 -Oqv`
								battery_run_time=`snmpwalk -v3 -l authPriv -u $UPS_snmp_user -a $UPS_snmp_auth_protocol -A $UPS_AuthPass1 -x $UPS_snmp_privacy_protocol -X $UPS_PrivPass2 $UPS_url:161 .1.3.6.1.4.1.318.1.1.1.2.2.3.0 -Oqv`
							
								# UPS Input Voltage
								#input_voltage=`snmpwalk -v 2c -c public $UPS_url .1.3.6.1.4.1.318.1.1.1.3.2.1.0 -Oqv`
								input_voltage=`snmpwalk -v3 -l authPriv -u $UPS_snmp_user -a $UPS_snmp_auth_protocol -A $UPS_AuthPass1 -x $UPS_snmp_privacy_protocol -X $UPS_PrivPass2 $UPS_url:161 .1.3.6.1.4.1.318.1.1.1.3.2.1.0 -Oqv`
								
								# UPS Minimum Input Transfer Voltage Threshold 
								#input_voltage=`snmpwalk -v 2c -c public $UPS_url .1.3.6.1.4.1.318.1.1.1.3.2.1.0 -Oqv`
								input_threshold_NMC=`snmpwalk -v3 -l authPriv -u $UPS_snmp_user -a $UPS_snmp_auth_protocol -A $UPS_AuthPass1 -x $UPS_snmp_privacy_protocol -X $UPS_PrivPass2 $UPS_url:161 1.3.6.1.4.1.318.1.1.1.5.2.3.0 -Oqv`
								
								APC_online=1
								
								#split the run time from a string to individual numbers (days, hours, min, sec)
								delimiter=":"
								s=$battery_run_time$delimiter
								array=();
								while [[ $s ]]; do
									array+=( "${s%%"$delimiter"*}" );
									s=${s#*"$delimiter"};
								done;
								#declare -p array    #([0]=days [1]=hours [2]=minutes [3]=seconds
								
							else
								echo "first ping failed, performing second ping"
								#first ping attempt did not work! let's try one more time just in case
								ping -c1 $UPS_url > /dev/null #try one more ping test
								
								if [ $? -eq 0 ]; then
									##########################################################################
									#The second Ping worked, the UPS is online so use SNMP to collect the needed data from the UPS
									##########################################################################
									
									# UPS Battery Capacity
									#battery_capacity=`snmpwalk -v 2c -c public $UPS_url .1.3.6.1.4.1.318.1.1.1.2.2.1.0 -Oqv`
									battery_capacity=`snmpwalk -v3 -l authPriv -u $UPS_snmp_user -a $UPS_snmp_auth_protocol -A $UPS_AuthPass1 -x $UPS_snmp_privacy_protocol -X $UPS_PrivPass2 $UPS_url:161 .1.3.6.1.4.1.318.1.1.1.2.2.1.0 -Oqv`
									
									# UPS Battery remaining Run Time
									#battery_run_time=`snmpwalk -v 2c -c public $UPS_url .1.3.6.1.4.1.318.1.1.1.2.2.3.0 -Oqv`
									battery_run_time=`snmpwalk -v3 -l authPriv -u $UPS_snmp_user -a $UPS_snmp_auth_protocol -A $UPS_AuthPass1 -x $UPS_snmp_privacy_protocol -X $UPS_PrivPass2 $UPS_url:161 .1.3.6.1.4.1.318.1.1.1.2.2.3.0 -Oqv`
									
									# UPS Input Voltage
									#input_voltage=`snmpwalk -v 2c -c public $UPS_url .1.3.6.1.4.1.318.1.1.1.3.2.1.0 -Oqv`
									input_voltage=`snmpwalk -v3 -l authPriv -u $UPS_snmp_user -a $UPS_snmp_auth_protocol -A $UPS_AuthPass1 -x $UPS_snmp_privacy_protocol -X $UPS_PrivPass2 $UPS_url:161 .1.3.6.1.4.1.318.1.1.1.3.2.1.0 -Oqv`
									
									# UPS Minimum Input Transfer Voltage Threshold 
									#input_voltage=`snmpwalk -v 2c -c public $UPS_url .1.3.6.1.4.1.318.1.1.1.3.2.1.0 -Oqv`
									input_threshold_NMC=`snmpwalk -v3 -l authPriv -u $UPS_snmp_user -a $UPS_snmp_auth_protocol -A $UPS_AuthPass1 -x $UPS_snmp_privacy_protocol -X $UPS_PrivPass2 $UPS_url:161 1.3.6.1.4.1.318.1.1.1.5.2.3.0 -Oqv`
								
									APC_online=1
									
									#split the run time from a string to individual numbers (days, hours, min, sec)
									delimiter=":"
									s=$battery_run_time$delimiter
									array=();
									while [[ $s ]]; do
										array+=( "${s%%"$delimiter"*}" );
										s=${s#*"$delimiter"};
									done;
									#declare -p array    #([0]=days [1]=hours [2]=minutes [3]=seconds
								
								else	
									#both ping attempts failed
									#UPS is off line
									echo "2 pings failed in a row, UPS appears offline"
									APC_online=0
								fi
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
					
					APC_online=$APC_online_debug
					array[0]=$runtime_remaining_debug_days
					array[1]=$runtime_remaining_debug_hours
					array[2]=$runtime_remaining_debug_min
					array[3]=$runtime_remaining_debug_sec
					battery_capacity=$battery_capacity_debug
					input_voltage=$input_voltage_debug
					UPS_comm_loss_shutdown_interval=$UPS_comm_loss_shutdown_interval_debug
					ups_coms_fail_delay=$(( $UPS_comm_loss_shutdown_interval * $total_executions)) 
					outlet_1_load_shed_yes_no=0
					outlet_2_load_shed_yes_no=0
					outlet_3_load_shed_yes_no=0
					outlet_4_load_shed_yes_no=0
					outlet_5_load_shed_yes_no=0
					outlet_6_load_shed_yes_no=0
					outlet_7_load_shed_yes_no=0
					outlet_8_load_shed_yes_no=0
					outlet_9_load_shed_yes_no=0
					outlet_10_load_shed_yes_no=0
					outlet_11_load_shed_yes_no=0
					outlet_12_load_shed_yes_no=0
					outlet_13_load_shed_yes_no=0
					outlet_14_load_shed_yes_no=1
					outlet_15_load_shed_yes_no=0
					outlet_16_load_shed_yes_no=0
					ups_outlet_group_turn_off_enable=$ups_outlet_group_turn_off_enable_debug
					ups_outlet_group_turn_off_delay=$ups_outlet_group_turn_off_delay_debug
					echo ""
					echo ""
					echo "############################"
					echo "script is in debugging mode"
					echo "APC_online is $APC_online"
					echo "run time remaining is ${array[0]} days || ${array[1]} hours || ${array[2]} minutes || ${array[3]} seconds"
					echo "battery_capacity is $battery_capacity %"
					echo "input_voltage is $input_voltage volts"
					echo "UPS_input_Voltage_threashold is $UPS_input_Voltage_threashold volts"
					echo "shutdown_runtime is $shutdown_runtime minutes"
					echo "plex_shutdown_time is $plex_shutdown_time minutes"
					echo "surveillance_station_shutdown_time is $surveillance_station_shutdown_time minutes"
					echo "UPS_comm_loss_shutdown_interval is $UPS_comm_loss_shutdown_interval minutes"
					echo "-----"
					echo "-----"
					echo "PDU_IP is $PDU_IP"
					echo "PLEX_IP is $PLEX_IP"
					echo "plex_installed_volume is $plex_installed_volume"
					echo "load_shed_early_time is $load_shed_early_time"
					echo "Syno_AuthPass1 is $Syno_AuthPass1"
					echo "Syno_PrivPass2 is $Syno_PrivPass2"
					echo "Syno_snmp_auth_protocol is $Syno_snmp_auth_protocol"
					echo "Syno_snmp_privacy_protocol is $Syno_snmp_privacy_protocol"
					echo "Syno_snmp_user is $Syno_snmp_user"
					echo "UPS_AuthPass1 is $UPS_AuthPass1"
					echo "UPS_PrivPass2 is $UPS_PrivPass2"
					echo "UPS_snmp_auth_protocol is $UPS_snmp_auth_protocol"
					echo "UPS_snmp_privacy_protocol is $UPS_snmp_privacy_protocol"
					echo "UPS_snmp_user is $UPS_snmp_user"
					echo "PDU_AuthPass1 is $PDU_AuthPass1"
					echo "PDU_PrivPass2 is $PDU_PrivPass2"
					echo "PDU_snmp_auth_protocol is $PDU_snmp_auth_protocol"
					echo "PDU_snmp_privacy_protocol is $PDU_snmp_privacy_protocol"
					echo "PDU_snmp_user is $PDU_snmp_user"
					if [ $outlet_1_load_shed_yes_no -eq 1 ]; then
						echo "Outlet 1 configured for load shed"
					fi
					if [ $outlet_2_load_shed_yes_no -eq 1 ]; then
						echo "Outlet 2 configured for load shed"
					fi
					if [ $outlet_3_load_shed_yes_no -eq 1 ]; then
						echo "Outlet 3 configured for load shed"
					fi
					if [ $outlet_4_load_shed_yes_no -eq 1 ]; then
						echo "Outlet 4 configured for load shed"
					fi
					if [ $outlet_5_load_shed_yes_no -eq 1 ]; then
						echo "Outlet 5 configured for load shed"
					fi
					if [ $outlet_6_load_shed_yes_no -eq 1 ]; then
						echo "Outlet 6 configured for load shed"
					fi
					if [ $outlet_7_load_shed_yes_no -eq 1 ]; then
						echo "Outlet 7 configured for load shed"
					fi
					if [ $outlet_8_load_shed_yes_no -eq 1 ]; then
						echo "Outlet 8 configured for load shed"
					fi
					if [ $outlet_9_load_shed_yes_no -eq 1 ]; then
						echo "Outlet 9 configured for load shed"
					fi
					if [ $outlet_10_load_shed_yes_no -eq 1 ]; then
						echo "Outlet 10 configured for load shed"
					fi
					if [ $outlet_11_load_shed_yes_no -eq 1 ]; then
						echo "Outlet 11 configured for load shed"
					fi
					if [ $outlet_12_load_shed_yes_no -eq 1 ]; then
						echo "Outlet 12 configured for load shed"
					fi
					if [ $outlet_13_load_shed_yes_no -eq 1 ]; then
						echo "Outlet 13 configured for load shed"
					fi
					if [ $outlet_14_load_shed_yes_no -eq 1 ]; then
						echo "Outlet 14 configured for load shed"
					fi
					if [ $outlet_15_load_shed_yes_no -eq 1 ]; then
						echo "Outlet 15 configured for load shed"
					fi
					if [ $outlet_16_load_shed_yes_no -eq 1 ]; then
						echo "Outlet 16 configured for load shed"
					fi
					echo "ups_outlet_group_turn_off_enable is $ups_outlet_group_turn_off_enable"
					echo "ups_outlet_group_turn_off_delay is $ups_outlet_group_turn_off_delay"
					echo "############################"
					echo ""
					echo ""
				fi
				
				
				##########################################################################
				#if UPS is off line, handle error notifications to the configured email address
				##########################################################################
				
				if [ $APC_online -eq 1 ]; then
					#UPS is on line after all
					echo "0" > $notification_file_location/$ups_coms_fail_counter #since the UPS is on line let's reset the UPS communications loss counter to zero 
					
					#determine if the NMC AC input voltage threshold configured value matches the value set in the web administration page
					if [ $docker_installed -eq 1 ]; then
						if [ $input_threshold_NMC -ne $UPS_input_Voltage_threashold ]; then
							echo "setting NMC input voltage threshold to $UPS_input_Voltage_threashold volts"
							docker run --rm=true elcolio/net-snmp snmpset -v3 -l authPriv -u $UPS_snmp_user -a $UPS_snmp_auth_protocol -A $UPS_AuthPass1 -x $UPS_snmp_privacy_protocol -X $UPS_PrivPass2 $UPS_url:161 1.3.6.1.4.1.318.1.1.1.5.2.3.0 i $UPS_input_Voltage_threashold
						fi
					else
						echo "WARNING -- Could not set NMC input voltage threshold to $UPS_input_Voltage_threashold volts as Docker is not available"
					fi
				else
					#read in two new variables
					#let's see how many script loops have occurred while the UPS is off line?
					if [ -r "$notification_file_location/$ups_coms_fail_counter" ]; then
						read ups_coms_fail_delay_status < $notification_file_location/$ups_coms_fail_counter
					else 
						echo "0" > $notification_file_location/$ups_coms_fail_counter
						ups_coms_fail_delay_status=0
					fi
					
					#determine when the last email was sent out. this will make sure we send an email only every 2 minutes
					if [ -r "$notification_file_location/$ups_email_delay_counter" ]; then
						read ups_email_time < $notification_file_location/$ups_email_delay_counter 
					else 
						echo "0" > $notification_file_location/$ups_email_delay_counter
						ups_email_time=0
					fi
					
					if [ $debug_mode -eq 1 ]; then
						echo ""
						echo ""
						echo "if ups_email_time ($ups_email_time) is greater than or equal to ups_email_delay ($ups_email_delay) then a notification email will be sent out that the system cannot talk to the UPS"
						echo ""
						echo "if ups_coms_fail_delay_status ($ups_coms_fail_delay_status) is greater than or equal to half the value of ups_coms_fail_delay ($ups_coms_fail_delay) which is $(( $ups_coms_fail_delay / 2)) then a shutdown soon warning will be emailed out"
						echo ""
						echo "if ups_coms_fail_delay_status ($ups_coms_fail_delay_status) is greater than or equal to ups_coms_fail_delay ($ups_coms_fail_delay) then the system will be shutdown due to excessive length of loss of UPS communications"
						echo ""
						echo ""
					fi
					
					#display a message on the terminal showing how long until the system will shutdown if UPS communications do not return
					if [ $UPS_comm_loss_shutdown_enable -eq 1 ] 
					then
						echo ""
						echo "Approximately ( $(( ( $ups_coms_fail_delay / $total_executions ) - ( $ups_coms_fail_delay_status / $total_executions ) )) Minutes ) until system shutdown if the UPS does not come back online"
						echo ""
					fi
					
					##########################################################################
					##has it been more than 2 minutes since the last email?
					##########################################################################
					if [ $ups_email_time -ge $ups_email_delay ] #yes, it has been more than 2 minutes
					then
						#send an alert email to the email address configured in the web administration page
						now=$(date +"%T")
						echo "sending alert email that UPS is off line"
						mailbody="$now - ALERT - $nas_name could NOT access the UPS unit at address $UPS_url for the last 2 minutes"
						echo "from: $from_email_address " > $notification_file_location/$ups_notification_file
						echo "to: $email_address " >> $notification_file_location/$ups_notification_file
						echo "subject: ALERT - $nas_name Cannot Talk to UPS " >> $notification_file_location/$ups_notification_file
						echo "" >> $notification_file_location/$ups_notification_file
						echo $mailbody >> $notification_file_location/$ups_notification_file
						
						if [ "$email_address" = "" ];then
							echo "no email address is configured, cannot send alert email that UPS is off line"
						else
							if [ $sendmail_installed -eq 1 ]; then
								cat $notification_file_location/$ups_notification_file | sendmail -t
							else
								echo "ERROR -- Could not send alert email that UPS is off line -- command \"sendmail\" is not available"
							fi
						fi
							
						#has the option to shutdown the system if UPS communications are lost been enabled in the web administration page?
						if [ $UPS_comm_loss_shutdown_enable -eq 1 ] #yes it has been enabled 
						then
							
							##########################################################################
							#when communications are lost and AC power is available and the the counter for shutdown is half-way to being exceeded, send a warning message before the system is actually shutdown
							##########################################################################
							
							if [ $ups_coms_fail_delay_status -ge $(( $ups_coms_fail_delay / 2 )) ]
							then
								now=$(date +"%T")
								echo "sending warning that UPS communications have been off line for $(( $ups_coms_fail_delay / 2 )) loops"
								mailbody="$now - WARNING - $nas_name will be shutting down soon in approximately $(( ( $ups_coms_fail_delay / $total_executions ) - ( $ups_coms_fail_delay_status / $total_executions ) )) Minutes due to extended loss of network communications with the UPS. "
								echo "from: $from_email_address " > $notification_file_location/$ups_notification_file
								echo "to: $email_address " >> $notification_file_location/$ups_notification_file
								echo "subject: WARNING - $nas_name Cannot Talk to UPS - Shutting Down $nas_name in approximately $(( ( $ups_coms_fail_delay / $total_executions ) - ( $ups_coms_fail_delay_status / $total_executions ) )) Minutes" >> $notification_file_location/$ups_notification_file
								echo "" >> $notification_file_location/$ups_notification_file
								echo $mailbody >> $notification_file_location/$ups_notification_file
								
								if [ "$email_address" = "" ];then
									echo "no email address is configured, Cannot send warning that UPS communications have been off line for $(( $ups_coms_fail_delay / 2 )) loops"
								else
									if [ $sendmail_installed -eq 1 ]; then
										cat $notification_file_location/$ups_notification_file | sendmail -t
									else
										echo "ERROR -- Could not send warning that UPS communications have been off line for $(( $ups_coms_fail_delay / 2 )) loops -- command \"sendmail\" is not available"
									fi
								fi
							fi
						fi
							
						#since we have sent an email that communications are lost, let's reset the 2 minute counter
						ups_email_time=0
						echo "$ups_email_time" > $notification_file_location/$ups_email_delay_counter
					else
						#since we have NOT YET sent an email let's increment the counter
						let ups_email_time=ups_email_time+1
						echo "$ups_email_time" > $notification_file_location/$ups_email_delay_counter
					fi
						
						
					##########################################################################
					#The UPS has been off line, handle shutting down the system 
					##########################################################################
					
					#has the option to shutdown the system if UPS communications are lost been enabled in the web administration page?
					if [ $UPS_comm_loss_shutdown_enable -eq 1 ] #yes it has been enabled
					then
						#since the UPS communications are down, check to see if the last time communications were good, was the UPS running on battery power?
						if [ $UPS_on_battery -eq 1 ] #yes it was running on battery power before communications were lost
						then
							#since the UPS is running on battery power and communications have been lost, we do not know why communications were lost, or when they will come back, so let's shut down the system now
							echo "While the UPS was on battery power, the network communications have failed, performing shutdown of system now"
							UPS_Shutdown=1
								
							#save to file that the status of the UPS so the next time this script runs from the beginning, the script is skipped. 
							echo "$UPS_Shutdown,$UPS_on_battery" > $notification_file_location/$UPS_shutdown_log_file
								
							now=$(date +"%T")
							echo "sending shutdown alert email"
							#send out an alert email that the system is shutting down
							mailbody="$now - CRITICAL - $nas_name is now shutting down due to loss of network communications with UPS while UPS was on battery power"
							echo "from: $from_email_address " > $notification_file_location/$ups_notification_file
							echo "to: $email_address " >> $notification_file_location/$ups_notification_file
							echo "subject: CRITICAL - $nas_name Shutting Down Due to UPS Network Communications Loss" >> $notification_file_location/$ups_notification_file
							echo "" >> $notification_file_location/$ups_notification_file
							echo $mailbody >> $notification_file_location/$ups_notification_file
							
							if [ "$email_address" = "" ];then
								echo "no email address is configured, Cannot send out an alert email that the system is shutting down"
							else
								if [ $sendmail_installed -eq 1 ]; then
									cat $notification_file_location/$ups_notification_file | sendmail -t
								else
									echo "ERROR -- Could not send out an alert email that the system is shutting down -- command \"sendmail\" is not available"
								fi
							fi
															
							#save a log message to sys_log
							echo "saving message to syslog"
							/usr/syno/bin/synologset1 sys err 0x11100000 "WARNING! - Initiating System Shutdown in 60 seconds -- UPS Communications Loss has Occurred While UPS is on Battery Power"
								
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
							if [ $debug_mode -eq 1 ]; then
								echo "script is in debug mode - not actually sending shutdown command"
							else
								shutdown -P now
								echo "shutting down system"
							fi
							exit
						fi
						
						#if communications have been lost, but the UPS is still on AC power, AND the time the UPS has been off line is exceeding the allowable time in the web administration page, we need to shutdown the system
						if [ $ups_coms_fail_delay_status -ge $ups_coms_fail_delay ]
						then
							echo "UPS on AC power, but communications have been off line too long"
							
							now=$(date +"%T")
							#send out an alert email that the system is shutting down
							echo "sending alert email that UPS has been off line too long"
							mailbody="$now - CRITICAL - $nas_name is now shutting down due to extended loss of network communications with UPS"
							echo "from: $from_email_address " > $notification_file_location/$ups_notification_file
							echo "to: $email_address " >> $notification_file_location/$ups_notification_file
							echo "subject: CRITICAL - $nas_name Shutting Down Due to UPS Network Communications Loss" >> $notification_file_location/$ups_notification_file
							echo "" >> $notification_file_location/$ups_notification_file
							echo $mailbody >> $notification_file_location/$ups_notification_file
							
							if [ "$email_address" = "" ];then
								echo "no email address is configured, Cannot send alert email that UPS is off line"
							else
								if [ $sendmail_installed -eq 1 ]; then
									cat $notification_file_location/$ups_notification_file | sendmail -t
								else
									echo "ERROR -- Could not send alert email that UPS is off line -- command \"sendmail\" is not available"
								fi
							fi
								
							#now that we are shutting down, reset the counter 
							echo "0" > $notification_file_location/$ups_coms_fail_counter
								
							#save a log message to sys_log
							echo "saving message to syslog"
							/usr/syno/bin/synologset1 sys err 0x11100000 "WARNING! - Initiating System Shutdown in 60 seconds -- UPS Communications Loss has Exceeded $UPS_comm_loss_shutdown_interval Minutes"
								
							#save the fact that we are shutting down the system. this will prevent this script from running again during the 60 second delay before the shutdown command is sent
							UPS_Shutdown=1
							echo "$UPS_Shutdown,$UPS_on_battery" > $notification_file_location/$UPS_shutdown_log_file
								
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
							if [ $debug_mode -eq 1 ]; then
								echo "script is in debug mode - not actually sending shutdown command"
							else
								shutdown -P now
								echo "shutting down system"
							fi
							exit
						fi
					fi
					
					#we have NOT exceeded the time delay configured in the web administration page where the UPS is off line and we will shutdown the system
					#as such increment the counter
					let ups_coms_fail_delay_status=ups_coms_fail_delay_status+1
					echo $ups_coms_fail_delay_status > $notification_file_location/$ups_coms_fail_counter
				fi
				
				#####################################
				#UPS has been determined to be on line and data has been received from the UPS
				#check if the UPS is on battery power
				#if on battery power and the run time is too low, send notifications and perform a shutdown
				#####################################
				
				
				if [ $APC_online -eq 1 ] #was the UPS available and data received from it? YES
				then
					if [ $input_voltage -le $UPS_input_Voltage_threashold ] #if the UPS input voltage is below the configured threshold the UPS should be on line/on battery power. This should be set to the same value as the UPS is configured
					then
										
						echo "UPS now on battery power -- UPS Voltage: $input_voltage VAC, Battery Capacity: $battery_capacity %, Runtime Remaining: ${array[1]} Hours : ${array[2]} Minutes : ${array[3]} Seconds "
						#save to a file that the UPS is on battery power. this will be used in the event UPS communications are lost while on battery power. this will allow the system to be shutdown if enabled in the web administration page
						if [ $UPS_on_battery -eq 0 ] #if we already saved this information, don't bother doing it again
						then
							UPS_on_battery=1
							echo "$UPS_Shutdown,$UPS_on_battery" > $notification_file_location/$UPS_shutdown_log_file
							
							#send email that UPS is now on battery power
							now=$(date +"%T")
							mailbody="$now - ALERT - $nas_name - UPS now on battery power -- UPS Voltage: $input_voltage VAC, Battery Capacity: $battery_capacity %, Runtime Remaining: ${array[1]} Hours : ${array[2]} Minutes : ${array[3]} Seconds "
							echo "from: $from_email_address " > $notification_file_location/$ups_notification_file
							echo "to: $email_address " >> $notification_file_location/$ups_notification_file
							echo "subject: ALERT - $nas_name UPS Now on Battery Power " >> $notification_file_location/$ups_notification_file
							echo "" >> $notification_file_location/$ups_notification_file
							echo $mailbody >> $notification_file_location/$ups_notification_file
							
							if [ "$email_address" = "" ];then
								echo "no email address is configured, Cannot send alert email that UPS is on battery power"
							else
								if [ $sendmail_installed -eq 1 ]; then
									cat $notification_file_location/$ups_notification_file | sendmail -t
								else
									echo "ERROR -- Could not send alert email that UPS is on battery power -- command \"sendmail\" is not available"
								fi
							fi
						fi
						
						#determine when the last email was sent out. this will make sure we send an email only every 2 minutes
						if [ -r "$notification_file_location/$ups_email_delay_counter" ]; then
							read ups_email_time < $notification_file_location/$ups_email_delay_counter #determine when the last email was sent out
						else 
							echo "0" > $notification_file_location/$ups_email_delay_counter
							ups_email_time=0
						fi
						
						if [ $debug_mode -eq 1 ]; then
							echo ""
							echo ""
							echo "if ups_email_time ($ups_email_time) is greater than ups_email_delay ($ups_email_delay) then a notification email will be sent out that the system is operating off battery power"
							echo ""
							echo ""
						fi
						
						#####################################
						#has it been more than 2 minutes since the last email?
						#if it has, send out an email notifying the user that the system is on battery power
						#####################################
						
						if [ $ups_email_time -ge $ups_email_delay ] #yes it has been more than 2 minutes
						then
							now=$(date +"%T")
							echo "sending email notification that UPS is on battery power"
							#send out a notification email. this email will include the battery information, run time remaining
							mailbody="$now - Warning $nas_name is Operating on Battery Power. If power is not returned soon, the system will shutdown if the runtime drops below $shutdown_runtime minutes. UPS Voltage: $input_voltage VAC, Battery Capacity: $battery_capacity %, Runtime Remaining: ${array[1]} Hours : ${array[2]} Minutes : ${array[3]} Seconds "
							echo "from: $from_email_address " > $notification_file_location/$ups_notification_file
							echo "to: $email_address " >> $notification_file_location/$ups_notification_file
							echo "subject: $nas_name Operating on Battery Power " >> $notification_file_location/$ups_notification_file
							echo "" >> $notification_file_location/$ups_notification_file
							echo $mailbody >> $notification_file_location/$ups_notification_file
							
							if [ "$email_address" = "" ];then
								echo "no email address is configured, Cannot send alert email that UPS is on battery power"
							else
								if [ $sendmail_installed -eq 1 ]; then
									cat $notification_file_location/$ups_notification_file | sendmail -t
								else
									echo "ERROR -- Could not send alert email that UPS is on battery power -- command \"sendmail\" is not available"
								fi
							fi
							
							#we have sent the email, let's reset the delay counter
							ups_email_time=0
							echo "$ups_email_time" > $notification_file_location/$ups_email_delay_counter
						else
							#no email has been sent yet, let's increment the delay counter 
							let ups_email_time=ups_email_time+1
							echo "$ups_email_time" > $notification_file_location/$ups_email_delay_counter
						fi

						if [ ${array[1]} -eq 0 ] #make sure the hours are zero on the UPS run time remaining 
						then
						
							#####################################
							#perform any required load shedding activities
							#####################################
							
							if [ $plex_installed_on_system -eq 1 ] #does the system have plex installed? if it does, perform plex load shedding
							then
								#echo "PLex Installed on System"
								if [ $PLEX_load_shed_active -eq 1 ]
								then
									echo "Plex has already been terminated"
								else
									if [ ${array[2]} -lt $plex_shutdown_time ] #if the number of UPS run-time minutes is less than the user defined set point (with 5 minutes added), shutdown active plex streams
									then
										#plex_IP_address || DSM_version || plex_installed_volume || PDU_load_shed_active || Surveillance_Station_Load_shed_active || load_shed_file_location
										plex_stream_terminate $PLEX_IP $DSMVersion $plex_installed_volume $PDU_load_shed_active $Surveillance_Station_Load_shed_active $notification_file_location/$UPS_load_shed_log_file
										
										#give plex time to terminate stream
										echo "stopping plex package in 15 seconds"
										sleep 5
										echo "stopping plex package in 10 seconds"
										sleep 5
										echo "stopping plex package in 5 seconds"
										sleep 5
										
										#####################################
										#Stop plex package
										#####################################
										plex_status=$(/usr/syno/bin/synopkg is_onoff "$plex_package_name")
										if [ "$plex_status" = "package $plex_package_name is turned on" ]; then
											echo "Stopping $plex_package_name ...."
											/usr/syno/bin/synopkg stop "$plex_package_name"
											sleep 1
										else
											echo "$plex_package_name Already Shutdown"
										fi
										
										plex_status=$(/usr/syno/bin/synopkg is_onoff "$plex_package_name")
										if [ "$plex_status" = "package $plex_package_name is turned on" ]; then
											echo "Shutting Down Plex Package Failed"
										else
											PLEX_load_shed_active=1
										
											#send an alert email to the email address configured in the web administration page
											now=$(date +"%T")
											echo "sending alert that PLEX was shutdown"
											mailbody="$now - ALERT $nas_name has stopped the package \"$plex_package_name\" due to UPS runtime remaining on battery being too low. The UPS Voltage: $input_voltage VAC, Battery Capacity: $battery_capacity %, Runtime Remaining: ${array[1]} Hours : ${array[2]} Minutes : ${array[3]} Seconds. "
											echo "from: $from_email_address " > $notification_file_location/$ups_notification_file
											echo "to: $email_address " >> $notification_file_location/$ups_notification_file
											echo "subject: $nas_name Stopped package \"$plex_package_name\" Due to Limited Battery Runtime " >> $notification_file_location/$ups_notification_file
											echo "" >> $notification_file_location/$ups_notification_file
											echo $mailbody >> $notification_file_location/$ups_notification_file
											
											if [ "$email_address" = "" ];then
												echo "no email address is configured, Cannot send alert that PLEX was shutdown"
											else
												if [ $sendmail_installed -eq 1 ]; then
													cat $notification_file_location/$ups_notification_file | sendmail -t
												else
													echo "ERROR -- Could not send alert that PLEX was shutdown -- command \"sendmail\" is not available"
												fi
											fi
										fi
									fi
								fi
							else
								echo "Plex Not Installed on system"
							fi
							
							if [ $surveillance_station_installed_on_system -eq 1 ] #does the system have Surveillance Station installed? if it does, perform load shedding
							then
								#echo "Surveillance Station Installed on System"
								if [ $Surveillance_Station_Load_shed_active -eq 0 ]
								then
									if [ ${array[2]} -lt $surveillance_station_shutdown_time ] #if the number of UPS run-time minutes is less than the user defined set point (with 5 minutes added), shutdown Surveillance Station
									then
										#email_address || email file location= || email file name || PDU_load_shed_active || PLEX_load_shed_active || load_shed_file_location || sendmail_installed || from_email_address
										shutdown_Synology_SS $email_address $notification_file_location $ups_notification_file $PDU_load_shed_active $PLEX_load_shed_active $notification_file_location/$UPS_load_shed_log_file $sendmail_installed $from_email_address
										Surveillance_Station_Load_shed_active=1
									fi
								else
									echo "Surveillance Station load shed has already been performed"
								fi
							else
								echo "Surveillance Station Not Installed on system"
							fi
							
							if [ $load_shed_control -eq 1 ] #is the system designated as the unit to control the cyber power PDU to turn off un-needed outlets?
							then
								echo "The system is configured to control PDU load shedding"
								if [ $PDU_load_shed_active -eq 0 ]
								then
									if [ ${array[2]} -lt $(( $shutdown_runtime + $load_shed_early_time )) ] #if the number of UPS run-time minutes is less than the user defined set point (with 5 minutes added), shutdown several PDU outlets
									then

										#outlet number || command || load_shed_file_location || PLEX_load_shed_active || Surveillance_Station_Load_shed_active || PDU_AuthPass1 || PDU_PrivPass2 || PDU_snmp_user || PDU_IP || PDU_snmp_auth_protocol || PDU_snmp_privacy_protocol || docker_installed
										if [ $outlet_1_load_shed_yes_no -eq 1 ]; then
											load_shed_PDU_ON_OFF 1 off $notification_file_location/$UPS_load_shed_log_file $PLEX_load_shed_active $Surveillance_Station_Load_shed_active $PDU_AuthPass1 $PDU_PrivPass2 $PDU_snmp_user $PDU_IP $PDU_snmp_auth_protocol $PDU_snmp_privacy_protocol $docker_installed 
										fi
										if [ $outlet_2_load_shed_yes_no -eq 1 ]; then
											load_shed_PDU_ON_OFF 2 off $notification_file_location/$UPS_load_shed_log_file $PLEX_load_shed_active $Surveillance_Station_Load_shed_active $PDU_AuthPass1 $PDU_PrivPass2 $PDU_snmp_user $PDU_IP $PDU_snmp_auth_protocol $PDU_snmp_privacy_protocol $docker_installed 
										fi
										if [ $outlet_3_load_shed_yes_no -eq 1 ]; then
											load_shed_PDU_ON_OFF 3 off $notification_file_location/$UPS_load_shed_log_file $PLEX_load_shed_active $Surveillance_Station_Load_shed_active $PDU_AuthPass1 $PDU_PrivPass2 $PDU_snmp_user $PDU_IP $PDU_snmp_auth_protocol $PDU_snmp_privacy_protocol $docker_installed 
										fi
										if [ $outlet_4_load_shed_yes_no -eq 1 ]; then
											load_shed_PDU_ON_OFF 4 off $notification_file_location/$UPS_load_shed_log_file $PLEX_load_shed_active $Surveillance_Station_Load_shed_active $PDU_AuthPass1 $PDU_PrivPass2 $PDU_snmp_user $PDU_IP $PDU_snmp_auth_protocol $PDU_snmp_privacy_protocol $docker_installed 
										fi
										if [ $outlet_5_load_shed_yes_no -eq 1 ]; then
											load_shed_PDU_ON_OFF 5 off $notification_file_location/$UPS_load_shed_log_file $PLEX_load_shed_active $Surveillance_Station_Load_shed_active $PDU_AuthPass1 $PDU_PrivPass2 $PDU_snmp_user $PDU_IP $PDU_snmp_auth_protocol $PDU_snmp_privacy_protocol $docker_installed
										fi
										if [ $outlet_6_load_shed_yes_no -eq 1 ]; then
											load_shed_PDU_ON_OFF 6 off $notification_file_location/$UPS_load_shed_log_file $PLEX_load_shed_active $Surveillance_Station_Load_shed_active $PDU_AuthPass1 $PDU_PrivPass2 $PDU_snmp_user $PDU_IP $PDU_snmp_auth_protocol $PDU_snmp_privacy_protocol $docker_installed
										fi
										if [ $outlet_7_load_shed_yes_no -eq 1 ]; then
											load_shed_PDU_ON_OFF 7 off $notification_file_location/$UPS_load_shed_log_file $PLEX_load_shed_active $Surveillance_Station_Load_shed_active $PDU_AuthPass1 $PDU_PrivPass2 $PDU_snmp_user $PDU_IP $PDU_snmp_auth_protocol $PDU_snmp_privacy_protocol $docker_installed
										fi
										if [ $outlet_8_load_shed_yes_no -eq 1 ]; then
											load_shed_PDU_ON_OFF 8 off $notification_file_location/$UPS_load_shed_log_file $PLEX_load_shed_active $Surveillance_Station_Load_shed_active $PDU_AuthPass1 $PDU_PrivPass2 $PDU_snmp_user $PDU_IP $PDU_snmp_auth_protocol $PDU_snmp_privacy_protocol $docker_installed
										fi
										if [ $outlet_9_load_shed_yes_no -eq 1 ]; then
											load_shed_PDU_ON_OFF 9 off $notification_file_location/$UPS_load_shed_log_file $PLEX_load_shed_active $Surveillance_Station_Load_shed_active $PDU_AuthPass1 $PDU_PrivPass2 $PDU_snmp_user $PDU_IP $PDU_snmp_auth_protocol $PDU_snmp_privacy_protocol $docker_installed
										fi
										if [ $outlet_10_load_shed_yes_no -eq 1 ]; then
											load_shed_PDU_ON_OFF 10 off $notification_file_location/$UPS_load_shed_log_file $PLEX_load_shed_active $Surveillance_Station_Load_shed_active $PDU_AuthPass1 $PDU_PrivPass2 $PDU_snmp_user $PDU_IP $PDU_snmp_auth_protocol $PDU_snmp_privacy_protocol $docker_installed
										fi
										if [ $outlet_11_load_shed_yes_no -eq 1 ]; then
											load_shed_PDU_ON_OFF 11 off $notification_file_location/$UPS_load_shed_log_file $PLEX_load_shed_active $Surveillance_Station_Load_shed_active $PDU_AuthPass1 $PDU_PrivPass2 $PDU_snmp_user $PDU_IP $PDU_snmp_auth_protocol $PDU_snmp_privacy_protocol $docker_installed
										fi
										if [ $outlet_12_load_shed_yes_no -eq 1 ]; then
											load_shed_PDU_ON_OFF 12 off $notification_file_location/$UPS_load_shed_log_file $PLEX_load_shed_active $Surveillance_Station_Load_shed_active $PDU_AuthPass1 $PDU_PrivPass2 $PDU_snmp_user $PDU_IP $PDU_snmp_auth_protocol $PDU_snmp_privacy_protocol $docker_installed
										fi
										if [ $outlet_13_load_shed_yes_no -eq 1 ]; then
											load_shed_PDU_ON_OFF 13 off $notification_file_location/$UPS_load_shed_log_file $PLEX_load_shed_active $Surveillance_Station_Load_shed_active $PDU_AuthPass1 $PDU_PrivPass2 $PDU_snmp_user $PDU_IP $PDU_snmp_auth_protocol $PDU_snmp_privacy_protocol $docker_installed
										fi
										if [ $outlet_14_load_shed_yes_no -eq 1 ]; then
											load_shed_PDU_ON_OFF 14 off $notification_file_location/$UPS_load_shed_log_file $PLEX_load_shed_active $Surveillance_Station_Load_shed_active $PDU_AuthPass1 $PDU_PrivPass2 $PDU_snmp_user $PDU_IP $PDU_snmp_auth_protocol $PDU_snmp_privacy_protocol $docker_installed
										fi
										if [ $outlet_15_load_shed_yes_no -eq 1 ]; then
											load_shed_PDU_ON_OFF 15 off $notification_file_location/$UPS_load_shed_log_file $PLEX_load_shed_active $Surveillance_Station_Load_shed_active $PDU_AuthPass1 $PDU_PrivPass2 $PDU_snmp_user $PDU_IP $PDU_snmp_auth_protocol $PDU_snmp_privacy_protocol $docker_installed
										fi
										if [ $outlet_16_load_shed_yes_no -eq 1 ]; then
											load_shed_PDU_ON_OFF 16 off $notification_file_location/$UPS_load_shed_log_file $PLEX_load_shed_active $Surveillance_Station_Load_shed_active $PDU_AuthPass1 $PDU_PrivPass2 $PDU_snmp_user $PDU_IP $PDU_snmp_auth_protocol $PDU_snmp_privacy_protocol $docker_installed
										fi
										PDU_load_shed_active=1
									fi
								else
									echo "PDU load shed has already been performed"
								fi
							else
								echo "System is configured not to control load shedding"
							fi
						
							#####################################
							#Actually shutdown system if run time is too low
							#####################################
							
							if [ ${array[2]} -lt $shutdown_runtime ] #if the number of UPS run-time minutes is less than the user defined set point, shutdown the system
							then
								now=$(date +"%T")
								echo "UPS has ${array[2]} minutes run-time remaining which is below the set-point of $shutdown_runtime minutes, performing system shutdown"
								echo "sending email notification that system is shutting down"
								#send an email before the system shuts down
								mailbody="$now - CRITICAL - $nas_name is shutting down due to UPS runtime remaining on battery being less than $shutdown_runtime minutes. The UPS Voltage: $input_voltage VAC, Battery Capacity: $battery_capacity %, Runtime Remaining: ${array[1]} Hours : ${array[2]} Minutes : ${array[3]} Seconds "
								echo "from: $from_email_address " > $notification_file_location/$shutdown_email_contents
								echo "to: $email_address " >> $notification_file_location/$shutdown_email_contents
								echo "subject: CRITICAL - $nas_name Shutting Down Due to Limited Battery Runtime " >> $notification_file_location/$shutdown_email_contents
								echo "" >> $notification_file_location/$shutdown_email_contents
								echo $mailbody >> $notification_file_location/$shutdown_email_contents
								
								if [ "$email_address" = "" ];then
									echo "no email address is configured, Cannot send an email before the system shuts down"
								else
									if [ $sendmail_installed -eq 1 ]; then
										cat $notification_file_location/$shutdown_email_contents | sendmail -t
									else
										echo "ERROR -- Could not send an email before the system shuts down -- command \"sendmail\" is not available"
									fi
								fi
							
								#save a log message to sys_log
								echo "save message to syslog"
								/usr/syno/bin/synologset1 sys err 0x11100000 "WARNING! - Initiating System Shutdown in 60 seconds as UPS runtime has dropped below $shutdown_runtime minutes -- UPS Active, UPS Voltage: $input_voltage VAC, Battery Capacity: $battery_capacity %, Runtime Remaining: ${array[1]} Hours : ${array[2]} Minutes : ${array[3]} Seconds"
							
								#save the fact that the system is shutting down. this will be used to prevent the script from running again during the 60 second delay before system shutdown
								UPS_Shutdown=1
								echo "$UPS_Shutdown,$UPS_on_battery" > $notification_file_location/$UPS_shutdown_log_file
								
								#command UPS outlets off if script is configured to do so. 
								if [ $ups_outlet_group_turn_off_enable -eq 1 ]; then
									#get number of outlet groups in the UPS that require turning off
									num_outlet_group=0
									num_outlet_group=`snmpwalk -v3 -l authPriv -u $UPS_snmp_user -a $UPS_snmp_auth_protocol -A $UPS_AuthPass1 -x $UPS_snmp_privacy_protocol -X $UPS_PrivPass2 $UPS_url:161 1.3.6.1.4.1.318.1.1.1.12.1.1.0 -Oqv`
									
									if [ $docker_installed -eq 1 ]; then
										if [ $num_outlet_group -ge 1 ]; then
											for (( counter=$num_outlet_group; counter>=1; counter-- )) #going backwards as the main outlet groups of APC UPS are the lower numbers. this will ensure the switched outlet groups are turned off before the main switch group(s)
											do
												echo ""
												echo "configuring UPS outlet group $counter to a Turn Off Delay Time of $ups_outlet_group_turn_off_delay seconds"
												#configure the UPS outlet group off delay
												docker run --rm=true elcolio/net-snmp snmpset -v3 -l authPriv -u $UPS_snmp_user -a $UPS_snmp_auth_protocol -A $UPS_AuthPass1 -x $UPS_snmp_privacy_protocol -X $UPS_PrivPass2 $UPS_url:161 1.3.6.1.4.1.318.1.1.1.12.2.2.1.4.$counter i $ups_outlet_group_turn_off_delay
										
												echo "Commanding UPS outlet group $counter to Turn Off with delay"
												#command the UPS outlet group to turn off with the off delay
												if [ $debug_mode -eq 1 ]; then
													echo "script is in debug mode - Not Actually Commanding the UPS outlet group $counter to turn off"
												else
													docker run --rm=true elcolio/net-snmp snmpset -v3 -l authPriv -u $UPS_snmp_user -a $UPS_snmp_auth_protocol -A $UPS_AuthPass1 -x $UPS_snmp_privacy_protocol -X $UPS_PrivPass2 $UPS_url:161 1.3.6.1.4.1.318.1.1.1.12.3.2.1.3.$counter i 5
												fi
												echo ""
											done
										else
											echo "either no outlet groups are available to command or the UPS did not return useful data, Could not command UPS outlets to turn off after system shutdown"
										fi
									else
										echo "WARNING -- Could not command UPS outlets to turn off after system shutdown as Docker is not available"
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
						#UPS input voltage is OK, nothing needs to be done
						echo "UPS OK, UPS Voltage: $input_voltage VAC, Battery Capacity: $battery_capacity %, Runtime Remaining ${array[0]} days || ${array[1]} hours || ${array[2]} minutes || ${array[3]} seconds"
						#if the UPS had previously been running on battery power, we need to save the fact that it is now on AC power
						if [ $UPS_on_battery -eq 1 ]
						then
							UPS_on_battery=0
							echo "$UPS_Shutdown,$UPS_on_battery" > $notification_file_location/$UPS_shutdown_log_file
							
							#send email that UPS is no longer on battery power
							now=$(date +"%T")
							mailbody="$now - ALERT - $nas_name - UPS input power restored, UPS no longer operating on battery power -- UPS Voltage: $input_voltage VAC, Battery Capacity: $battery_capacity %, Runtime Remaining: ${array[1]} Hours : ${array[2]} Minutes : ${array[3]} Seconds "
							echo "from: $from_email_address " > $notification_file_location/$ups_notification_file
							echo "to: $email_address " >> $notification_file_location/$ups_notification_file
							echo "subject: ALERT - $nas_name UPS Power has Been Restored " >> $notification_file_location/$ups_notification_file
							echo "" >> $notification_file_location/$ups_notification_file
							echo $mailbody >> $notification_file_location/$ups_notification_file
							
							if [ "$email_address" = "" ];then
								echo "no email address is configured, Cannot send alert email that UPS power has been restored"
							else
								if [ $sendmail_installed -eq 1 ]; then
									cat $notification_file_location/$ups_notification_file | sendmail -t
								else
									echo "ERROR -- Could not send alert email that UPS power has been restored -- command \"sendmail\" is not available"
								fi
							fi
						fi
						
						#now that the UPS is running on AC power again, check if the PDU was commanded to load shed. if it had performed a load shed, turn the outlets back on
						if [ $load_shed_control -eq 1 ]
						then
							if [ $PDU_load_shed_active -eq 1 ]
							then
								#outlet number || command || load_shed_file_location || PLEX_load_shed_active || Surveillance_Station_Load_shed_active || PDU_AuthPass1 || PDU_PrivPass2 || PDU_snmp_user || PDU_IP || PDU_snmp_auth_protocol || PDU_snmp_privacy_protocol || $docker_installed
								if [ $outlet_1_load_shed_yes_no -eq 1 ]; then
								load_shed_PDU_ON_OFF 1 on $notification_file_location/$UPS_load_shed_log_file $PLEX_load_shed_active $Surveillance_Station_Load_shed_active $PDU_AuthPass1 $PDU_PrivPass2 $PDU_snmp_user $PDU_IP $PDU_snmp_auth_protocol $PDU_snmp_privacy_protocol $docker_installed
								fi
								if [ $outlet_2_load_shed_yes_no -eq 1 ]; then
									load_shed_PDU_ON_OFF 2 on $notification_file_location/$UPS_load_shed_log_file $PLEX_load_shed_active $Surveillance_Station_Load_shed_active $PDU_AuthPass1 $PDU_PrivPass2 $PDU_snmp_user $PDU_IP $PDU_snmp_auth_protocol $PDU_snmp_privacy_protocol $docker_installed
								fi
								if [ $outlet_3_load_shed_yes_no -eq 1 ]; then
									load_shed_PDU_ON_OFF 3 on $notification_file_location/$UPS_load_shed_log_file $PLEX_load_shed_active $Surveillance_Station_Load_shed_active $PDU_AuthPass1 $PDU_PrivPass2 $PDU_snmp_user $PDU_IP $PDU_snmp_auth_protocol $PDU_snmp_privacy_protocol $docker_installed
								fi
								if [ $outlet_4_load_shed_yes_no -eq 1 ]; then
									load_shed_PDU_ON_OFF 4 on $notification_file_location/$UPS_load_shed_log_file $PLEX_load_shed_active $Surveillance_Station_Load_shed_active $PDU_AuthPass1 $PDU_PrivPass2 $PDU_snmp_user $PDU_IP $PDU_snmp_auth_protocol $PDU_snmp_privacy_protocol $docker_installed
								fi
								if [ $outlet_5_load_shed_yes_no -eq 1 ]; then
									load_shed_PDU_ON_OFF 5 on $notification_file_location/$UPS_load_shed_log_file $PLEX_load_shed_active $Surveillance_Station_Load_shed_active $PDU_AuthPass1 $PDU_PrivPass2 $PDU_snmp_user $PDU_IP $PDU_snmp_auth_protocol $PDU_snmp_privacy_protocol $docker_installed
								fi
								if [ $outlet_6_load_shed_yes_no -eq 1 ]; then
									load_shed_PDU_ON_OFF 6 on $notification_file_location/$UPS_load_shed_log_file $PLEX_load_shed_active $Surveillance_Station_Load_shed_active $PDU_AuthPass1 $PDU_PrivPass2 $PDU_snmp_user $PDU_IP $PDU_snmp_auth_protocol $PDU_snmp_privacy_protocol $docker_installed
								fi
								if [ $outlet_7_load_shed_yes_no -eq 1 ]; then
									load_shed_PDU_ON_OFF 7 on $notification_file_location/$UPS_load_shed_log_file $PLEX_load_shed_active $Surveillance_Station_Load_shed_active $PDU_AuthPass1 $PDU_PrivPass2 $PDU_snmp_user $PDU_IP $PDU_snmp_auth_protocol $PDU_snmp_privacy_protocol $docker_installed
								fi
								if [ $outlet_8_load_shed_yes_no -eq 1 ]; then
									load_shed_PDU_ON_OFF 8 on $notification_file_location/$UPS_load_shed_log_file $PLEX_load_shed_active $Surveillance_Station_Load_shed_active $PDU_AuthPass1 $PDU_PrivPass2 $PDU_snmp_user $PDU_IP $PDU_snmp_auth_protocol $PDU_snmp_privacy_protocol $docker_installed
								fi
								if [ $outlet_9_load_shed_yes_no -eq 1 ]; then
									load_shed_PDU_ON_OFF 9 on $notification_file_location/$UPS_load_shed_log_file $PLEX_load_shed_active $Surveillance_Station_Load_shed_active $PDU_AuthPass1 $PDU_PrivPass2 $PDU_snmp_user $PDU_IP $PDU_snmp_auth_protocol $PDU_snmp_privacy_protocol $docker_installed
								fi
								if [ $outlet_10_load_shed_yes_no -eq 1 ]; then
									load_shed_PDU_ON_OFF 10 on $notification_file_location/$UPS_load_shed_log_file $PLEX_load_shed_active $Surveillance_Station_Load_shed_active $PDU_AuthPass1 $PDU_PrivPass2 $PDU_snmp_user $PDU_IP $PDU_snmp_auth_protocol $PDU_snmp_privacy_protocol $docker_installed
								fi
								if [ $outlet_11_load_shed_yes_no -eq 1 ]; then
									load_shed_PDU_ON_OFF 11 on $notification_file_location/$UPS_load_shed_log_file $PLEX_load_shed_active $Surveillance_Station_Load_shed_active $PDU_AuthPass1 $PDU_PrivPass2 $PDU_snmp_user $PDU_IP $PDU_snmp_auth_protocol $PDU_snmp_privacy_protocol $docker_installed
								fi
								if [ $outlet_12_load_shed_yes_no -eq 1 ]; then
									load_shed_PDU_ON_OFF 12 on $notification_file_location/$UPS_load_shed_log_file $PLEX_load_shed_active $Surveillance_Station_Load_shed_active $PDU_AuthPass1 $PDU_PrivPass2 $PDU_snmp_user $PDU_IP $PDU_snmp_auth_protocol $PDU_snmp_privacy_protocol $docker_installed
								fi
								if [ $outlet_13_load_shed_yes_no -eq 1 ]; then
									load_shed_PDU_ON_OFF 13 on $notification_file_location/$UPS_load_shed_log_file $PLEX_load_shed_active $Surveillance_Station_Load_shed_active $PDU_AuthPass1 $PDU_PrivPass2 $PDU_snmp_user $PDU_IP $PDU_snmp_auth_protocol $PDU_snmp_privacy_protocol $docker_installed
								fi
								if [ $outlet_14_load_shed_yes_no -eq 1 ]; then
									load_shed_PDU_ON_OFF 14 on $notification_file_location/$UPS_load_shed_log_file $PLEX_load_shed_active $Surveillance_Station_Load_shed_active $PDU_AuthPass1 $PDU_PrivPass2 $PDU_snmp_user $PDU_IP $PDU_snmp_auth_protocol $PDU_snmp_privacy_protocol $docker_installed
								fi
								if [ $outlet_15_load_shed_yes_no -eq 1 ]; then
									load_shed_PDU_ON_OFF 15 on $notification_file_location/$UPS_load_shed_log_file $PLEX_load_shed_active $Surveillance_Station_Load_shed_active $PDU_AuthPass1 $PDU_PrivPass2 $PDU_snmp_user $PDU_IP $PDU_snmp_auth_protocol $PDU_snmp_privacy_protocol $docker_installed
								fi
								if [ $outlet_16_load_shed_yes_no -eq 1 ]; then
									load_shed_PDU_ON_OFF 16 on $notification_file_location/$UPS_load_shed_log_file $PLEX_load_shed_active $Surveillance_Station_Load_shed_active $PDU_AuthPass1 $PDU_PrivPass2 $PDU_snmp_user $PDU_IP $PDU_snmp_auth_protocol $PDU_snmp_privacy_protocol $docker_installed
								fi
								PDU_load_shed_active=0
							fi
						fi
						
						
						#now that the UPS is running on AC power again, check if surveillance station was shutdown, if it was, turn it back on
						if [ $surveillance_station_installed_on_system -eq 1 ]
						then
							if [ $Surveillance_Station_Load_shed_active -eq 1 ]
							then
								#email_address || email file location || email file name || PDU_load_shed_active || PLEX_load_shed_active || load_shed_file_location || sendmail_installed || from_email_address
								restart_Synology_SS $email_address $notification_file_location $ups_notification_file $PDU_load_shed_active $PLEX_load_shed_active $notification_file_location/$UPS_load_shed_log_file $sendmail_installed $from_email_address
								Surveillance_Station_Load_shed_active=0
							fi
						fi
						
						
						
						#now that the UPS is running on AC power again, check if PLEX was shutdown
						if [ $plex_installed_on_system -eq 1 ]
						then
							if [ $PLEX_load_shed_active -eq 1 ]
							then
								
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
									echo "$PDU_load_shed_active,0,$Surveillance_Station_Load_shed_active " > $notification_file_location/$UPS_load_shed_log_file
									
									#send an alert email to the email address configured in the web administration page
									now=$(date +"%T")
									echo "sending alert that PLEX was Re-started"
									mailbody="$now - ALERT $nas_name has restarted the package \"$plex_package_name\" after UPS power was restored. The UPS Voltage: $input_voltage VAC, Battery Capacity: $battery_capacity %, Runtime Remaining: ${array[1]} Hours : ${array[2]} Minutes : ${array[3]} Seconds. "
									echo "from: $from_email_address " > $notification_file_location/$ups_notification_file
									echo "to: $email_address " >> $notification_file_location/$ups_notification_file
									echo "subject: $nas_name has restarted package \"$plex_package_name\" after UPS power was restored " >> $notification_file_location/$ups_notification_file
									echo "" >> $notification_file_location/$ups_notification_file
									echo $mailbody >> $notification_file_location/$ups_notification_file
									
									if [ "$email_address" = "" ];then
										echo "no email address is configured, Cannot send alert that PLEX was Re-started"
									else
										if [ $sendmail_installed -eq 1 ]; then
											cat $notification_file_location/$ups_notification_file | sendmail -t
										else
											echo "ERROR -- Could not send alert that PLEX was Re-started -- command \"sendmail\" is not available"
										fi
									fi
								else
									echo "Failed to restart PLEX Package"
								fi
							fi
						fi
						
					fi
				else
					#UPS is off line
					echo "UPS is off line - Skipping voltage/runtime Shutdown Checks"
				fi
				
				
				let i=i+1
				
				echo "Capture #$i complete"
				
				#Sleeping for capture interval unless its last capture then we don't sleep
				if (( $i < $total_executions)); then
					sleep $(( $capture_interval -2))
				fi
				
			done;
		else
			#the script is disabled in the web administration web page
			echo "script is disabled"
		fi
	else
		now=$(date +"%T")
		echo "Configuration Script file is missing, skipping script and sending alert email"
		#send an email indicating script config file is missing and script will not run
		mailbody="$now - Warning $nas_name UPS Monitoring Failed - Configuration file is missing "
		echo "from: $from_email_address " > $notification_file_location/$shutdown_email_contents
		echo "to: $email_address " >> $notification_file_location/$shutdown_email_contents
		echo "subject: Warning $nas_name UPS Monitoring Failed - Configuration or username/password credential file is missing " >> $notification_file_location/$shutdown_email_contents
		echo "" >> $notification_file_location/$shutdown_email_contents
		echo $mailbody >> $notification_file_location/$shutdown_email_contents
		
		if [ "$email_address" = "" ];then
			echo "no email address is configured, Cannot send an email indicating script config file is missing and script will not run"
		else
			if [ $sendmail_installed -eq 1 ]; then
				cat $notification_file_location/$shutdown_email_contents | sendmail -t
			else
				echo "ERROR -- Could not send an email indicating script config file is missing and script will not run -- command \"sendmail\" is not available"
			fi
		fi
	fi
else
	#the script is being skipped because the system is already shutting down
	echo "System is shutting down - Skipping Script"
fi
exit
