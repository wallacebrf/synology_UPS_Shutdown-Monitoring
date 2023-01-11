<div id="top"></div>
<!--
*** comments....
-->



<!-- PROJECT LOGO -->
<br />

<h3 align="center">Synology APC UPS SNMP Monitor and NAS Shutdown</h3>

  <p align="center">
    This project is comprised of a shell script that runs once per minute collecting data from a APC Network Management Card and if battery is low will shutdown the NAS 
    <br />
    <a href="https://github.com/wallacebrf/synology_UPS_Shutdown-Monitoring"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/wallacebrf/synology_UPS_Shutdown-Monitoring/issues">Report Bug</a>
    ·
    <a href="https://github.com/wallacebrf/synology_UPS_Shutdown-Monitoring/issues">Request Feature</a>
  </p>
</div>



<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#About_the_project_Details">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#roadmap">Road map</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
### About_the_project_Details

This script pulls data from an APC UPS with a Network Management Card version 2 or version 3 installed. if the UPS does not have a network management cad installed, this script cannot interface with a USB connected UPS.  

***************************************************
Power Distribution Unit (PDU) Outlet Control load shedding:
***************************************************
this script is written around the use of a cyberpower pdu81xxx series power distribution unit and the associated SNMP commands/IODs that it supports.  
If no PDU is available, use the web administration page to disable load shedding. 

If a different PDU model or manufacture is utilized the script will not work as the SNMP commands will  not match and the IODs would have to be updated within th script manually. 

If PDU load shedding is desired and the PDU is a cyberpower pdu81xxx series unit, the PDU must have SNMP enabled for communications and control. The SNMP settings used in the PDU will need to be entered into the web administration page to allow the script to talk to the PDU. 

The amount of time the load shedding occurs is configurable through the web administration page. This time is added onto the run time where the NAS is commanded to shut down. As an example if the shutdown run time is 15 minutes and the load shedding is configured for 5 minutes, the load shedding actions will occur when run time is less than 20 minuets. 

Outlets commanded off during a load shed event will turn back on when UPS power is restored ONLY IF the power is restored before the system is commanded to shutdown. If the system is commanded to shutdown, when the system is restarted, the PDU outlets commanded to turn off during load shed will remain off and will need to be manually re-enabled. This is to prevent constant power on/off fluctuations from causing the system to continuously turn the outlets on and off. 


***************************************************
Synology Surveillance Station Application Shutdown Load Shedding:
***************************************************
The script can terminate the Synology surveillance station application which can draw significant power from the CPU and GPU (GPU is used in the DVA series units)

The amount of time the load shedding occurs is configurable through the web administration page and will occur at the same time as a PDU load shed as explained above. 

Surveillance Station will be restarted when UPS power is restored ONLY IF the power is restored before the system is commanded to shutdown. If the system is commanded to shutdown, when the system is restarted, surveillance station will remain off and will need to be manually re-enabled. 


***************************************************
PLEX Media Server Application Shutdown Load Shedding:
***************************************************
The script can terminate any active PLEX streams which if performing transcoding can use high levels of CPU power and wattage. 

The amount of time the load shedding occurs is configurable through the web administration page. 

PLEX will be restarted when UPS power is restored ONLY IF the power is restored before the system is commanded to shutdown. If the system is commanded to shutdown, when the system is restarted, PLEX will remain off and will need to be manually re-enabled. 
	

***************************************************
UPS Communications Loss Handling:
***************************************************
This script supports shutting down the server in the event of extended duration UPS network communications failures. 
	This can be enabled and disabled in the web administration page. 
	The purpose is to protect the system during extended network failures as the script will not be able to determine if the UPS run time is low which could cause the system to lose power and shutdown un-gracefully. 

The script also allows for immediate shutdown of the system if the network communications are lost while the UPS is actively running on battery power which could happen if any network switches between the system and the UPS lose power before the system does. This protects the system as it would not be able to determine the remaining run time of the battery as it is not guaranteed that communications will resume before the run time goes too low.  

The amount of time [hours (1 through 20)] required to pass while UPS communications are down is user configurable in the web administration page. Starting half way through the configured delay time, a warning email will be sent to the configured email address that the system will be shutdown soon. During the entire duration of failed network communications, a warning email will be sent to the configured email address every 2 minutes to ensure the administrator of the system knows of the error. 

	

 ***************************************************
UPS Output Shutdown Post NAS System Shutdown:
***************************************************
This script supports commanding the UPS to turn off all outlet groups after the NAS system has been commanded to shutdown. The delay time between when the NAS system is shutdown and when the outlet groups are turned off is user configurable in the web administration page. If the outlet groups are commanded to turn off, they will NOT turn back on when AC power is restored to the UPS. 


<p align="right">(<a href="#top">back to top</a>)</p>



<!-- GETTING STARTED -->
## Getting Started

This project is written around a Synology NAS and their DSM specific SNMP OIDs and MIBs. 

### Prerequisites

1.) This script is designed to be executed every 60 seconds

2.) This script requires the installation of Synology MailPlus server package in package center in order to send emails. If it is not installed the script will still operate as only the notification emails functions will be skipped. 

	The mail plus server must be properly configured to relay received messages to another email account. This readme does not go into detail on that configuration process. 
	
3.) This script is Dependent on a docker container for SNMP_SET commands using the "elcolio/net-snmp" container located here: https://hub.docker.com/r/elcolio/net-snmp

	This is required as the synology system does not contain the snmp_set commands. The set command is used to control the PDU outlets and to command the UPS to shutdown
	the container does not always run, it is run once when a SET command needs to be executed and as such can remain in the "off" state within docker.
	
4.) This script only supports SNMP V3. This is because lower versions are less secure especially when using the set commands that have the ability to remove power to the systems

	SNMP must be enabled on the host NAS for the script to gather the NAS NAME
	
	SNNMP must be enabled on the target APC UPS network management card
	
	SNNMP must be enabled on the PDU
	
	The snmp settings for the NAS, UPS, and PDU can all be entered into the web administration page. 
	
6.) This script can be run through Synology Task Scheduler. However it has been observed that running large scripts like this as frequently as every 60 seconds causes the synoschedtask system application to use large amounts of resources and causes the script to execute slowly

	details of this issue can be seen here:
	https://www.reddit.com/r/synology/comments/kv7ufq/high_disk_usage_on_disk_1_caused_by_syno_task/
	to fix this it is recommend to directly edit the crontab at /etc/crontab
	
	this can be accomplished using vi /etc/crontab
	
	Details of how to edit the crontab file are detailed later in this readme. 
	
7.) This script only supports cyberpower pdu81xxx series power distribution units. Different units will require script updating due to different SNMP IODs and MIBs


### Installation

1. Create the following directories on the NAS

```
1. %PHP_Server_Root%/config
2. %PHP_Server_Root%/logging
3. %PHP_Server_Root%/logging/notifications
```

note: ```%PHP_Server_Root%``` is what ever shred folder location the PHP web server root directory is configured to be. PLease make sure to update the script accordingly to match your configuration. 

2. Place the ```functions.php``` file in the root of the PHP web server running on the NAS

3. Place the ```server_APC_UPS_Monitor.sh``` file in the ```/logging``` directory

4. Place the ```server2_UPS_config.php``` file in the ```/config``` directory

5. Create a scheduled task on boot up in Synology Task Scheduler to add the following line

```#!/bin/bash
echo "0,0" > $notification_file_location/$UPS_shutdown_status_file
```

where "$notification_file_location" is the location created above ```%PHP_Server_Root%/logging/notifications``` and $UPS_shutdown_status_file is the value entered for the file name within the .sh script file. Ensure the directory path is correct. 


### Configuration "server2_UPS_config.php"

1. open the ```server2_UPS_config.php``` file in a text editor to edit the following lines
```
$config_file="/volume1/web/config/config_files/config_files_local/server2_UPS_monitor_config2.txt";
$use_login_sessions=true; //set to false if not using user login sessions
$form_submittal_destination="index.php?page=6&config_page=server2_ups_monitor"; //set to the destination the HTML form submittal should be directed to
$page_title="Server2 Network UPS Shutdown Monitoring Configuration Settings";
```
2. Set "config_file" to where the script's configuration file will be stored. This MUST be the same as used in the .sh script file ```config_file_location``` configured below. 
3. If the PHP web server uses user log in sessions then set "use_login_sessions" to true, otherwise set to false. If set to true, when a user accesses the page and does not have a valid sesson, they will be redirected to ```login.php``` which is NOT included in this repository. Update accordingly to match your environment. 
4. "form_submittal_destination" controls what web-page is processing the PHP configuration page data. If accessing the ```server2_UPS_config.php``` directly in the web browser URL bar, set this variable to "server2_UPS_config.php", or if the configuration .php file is embedded in another file using "include_once" so similar, then that file will need to be used as it is currently in the .php file. 
5. "page_title" controls what the title of the PHP page will be when loaded into a browser. 
6. depending on the configuration of and the version of PHP used for the web server, if errors are received when using the .php file about undefined variables, edit the line:

```error_reporting(E_ALL ^ E_NOTICE);```

to instead read

```error_reporting(E_NOTICE);```


### Configuration "server_APC_UPS_Monitor.sh"

1. open the ```server_APC_UPS_Monitor.sh``` file in a text editor to edit the following lines 

```
nas_url="localhost" #needed to collect the name of the NAS running this script
config_file_location="/volume1/web/config/config_files/config_files_local"
notification_file_location="/volume1/web/logging/notifications"
lock_file_name="server_APC_UPS_Monitor2.lock"

```

2. Configure "nas_url" to be the URL of the NAS the script is running on and that the script will shutdown if needed
3. Set the "config_file_location" to be where the configuration file will be stored. This MUST be the same as used in the PHP file ```config_file``` variable configured previously. 
4. Set the location of the notification files to match the location of the ```%PHP_Server_Root%/logging/notifications``` folder created previously. 
5. Set the file name as desired for the lock file "lock_file_name". The lock file is used to prevent more than once instance of the script from running. 

### Configuration of Synology web server "http" user permissions

By default the Synology user "http" that web station uses does not have write permissions to the "web" file share. 

1. go to Control Panel -> User & Group -> "Group" tab
2. click on the "http" user and press the "edit" button
3. go to the "permissions" tab
4. scroll down the list of shared folders to find "web" and click on the right checkbox under "customize" 
5. check ALL boxes and click "done"
6. Verify the window indicates the "http" user group has "Full Control" and click the checkbox at the bottom "Apply to this folder, sub folders and files" and click "Save"

<img src="https://raw.githubusercontent.com/wallacebrf/synology_snmp/main/Images/http_user1.png" alt="1313">
<img src="https://raw.githubusercontent.com/wallacebrf/synology_snmp/main/Images/http_user2.png" alt="1314">
<img src="https://raw.githubusercontent.com/wallacebrf/synology_snmp/main/Images/http_user3.png" alt="1314">

### Configuration of Synology SNMP settings

by default Synology DSM does not have SNMP settings enabled. This script requires them to be enabled. 

1. Control Panel -> Terminal & SNMP -> "SNMP" tab
2. check the box "Enable SNMP Service"
3. Leave the following box UNCHECKED "SNMPv1, SNMPv2c service" as we only want SNMP version 3
4. check the box "SNMPv3 service"
5. enter a "Username" without spaces, choose a "protocol" and "password"
6. ensure the "Enable SNMP privacy" is checked and enter a desired protocol and a password. it may be the same password used above or can be a different password
7. click apply to save the settings

document all of the protocols, passwords and user information entered in Synology Control panel as this same information will need to entered into the configuration web page in the next steps

NOTE: if firewall rules are enabled on the synology system, the SNMP service port may need to be opened if this script is not running on this particular physical server. This set of instructions will not detail how to configure firewall rules. 

<img src="https://raw.githubusercontent.com/wallacebrf/synology_snmp/main/Images/snmp1.png" alt="1313">

### Configuration of required SNMP settings in APC network management cards
To Be Completed

### Configuration of required SNMP settings in the Cyberpower PDU
to be Completed 

### Configuration of required settings in the web-administration page

<img src="https://raw.githubusercontent.com/wallacebrf/synology_UPS_Shutdown-Monitoring/main/UPS_Config_page_part1.png" alt="1313">
<img src="https://raw.githubusercontent.com/wallacebrf/synology_UPS_Shutdown-Monitoring/main/UPS_Config_page_part2.png" alt="1314">

Once the files are copied to the NAS, properly edited, and device settings are configured as required above, using a web browser, navigate to where the "server2_UPS_config.php" file is located. 

when the web-page loads, it will automatically create a configuration file and populate it with default values. If an error occurs indicating permissions are denied or ther write errors, ensure the Synology http user permissions were configured correctly. 

edit the values as desired. 

1. Ensure the script is enabled
2. Configure at what point the NAS will be commanded to shutdown. The NAS will be shutdown when there is less than the configured number of minutes remaining. Ensure there are at least 3-5 minutes of run time to allow the system to actually gracefully shutdown. My personal DS920 can take up to 5 minutes to shutdown completely. 
3. What input voltage is the UPS configured to transition from AC power to battery? Ensure this value matches the value configured in the Network Management card's interface 
4. Who will receive alert email notifications and who will the email be from?
5. How often will be script be executed per minute? it is recommended to perform 3-4 polls per minute so the system can react to changes in the UPS fast enough
6. Enable or disable NAS shutdown if network communications with the UPS fail
--> how long to wait until NAS is shutdown
7. if PLEX is installed on the NAS (not docker, but the native version) then give the IP address of PLEX
8. if PLEX is installed, what volume is it installed on?
9. ensure SNMP version 3 is enabled and configured on the NAS and ensure the settings match between what DSM was configured and what is entered on this web-administration page 
10. ensure SNMP version 3 is enabled on the network management card and ensure the settings match between what the APC NMC was configured and what is entered on this web-administration page. 
11. if a PDU is available, configure the PDU for SNMP version 3 and ensure the settings match between what the PSU is configured and what is entered on this web-administration page 
12. if outlet level load shedding is desired, enable the setting
12 a. how many minutes prior to the NAS being commanded to shutdown shall the outlet load shedding occur?
12 b. select the desired outlets that will be turned off during the load shed. all other outlets will remain on during load shedding
13. if it is desired to turn off the output of the UPS (if it has switch outlets) enable the setting. 
13a. configure how many minutes after the NAS is commanded to turn off will be UPS turn off its outlets. ensure enough time is allowed to allow the NAS to gracefully shutdown. 
NOTE: if the outlets on the UPS are configured to turn off, they will NOT turn back on when power is restored. 

### Perform test run wihh the script in "debug" mode
to be Completed 

### Configuration of crontab
only configure the crontab file after everything else has been configured and the script has been tested and validated in "debug" mode

This script can be run through synology Task Scheduler. However it has been observed that running large scripts like this as frequently as every 60 seconds causes the synoschedtask system application to use large amounts of resources and causes the script to execute slowly
	#details of this issue can be seen here:
	#https://www.reddit.com/r/synology/comments/kv7ufq/high_disk_usage_on_disk_1_caused_by_syno_task/
	#to fix this it is recommend to directly edit the crontab at /etc/crontab
	
	#this can be accomplished using vi /etc/crontab
	
	#add the following line: 
	```	*	*	*	*	*	root	$path_to_file/$filename```
	#details on crontab can be found here: https://man7.org/linux/man-pages/man5/crontab.5.html
	
	
	
### Example Email Notifications
```
Title: Server2 Operating on Battery Power
11:58:23 - Warning Server2 is Operating on Battery Power for 0:0:00:00.00. If power is not returned soon, the system will shutdown if the runtime drops below 15 minutes. UPS Voltage: 0 VAC, Battery Capacity: 100 %, Runtime Remaining: 0 Hours : 19 Minutes : 59 Seconds
```

```
Title: Server2 has turned off PDU outlet #14
11:43:53 - ALERT Server2 has turned off PDU outlet #14 due to a load shed event caused by low UPS battery life
```

```
Title: Server2 has turned ON PDU outlet #14
11:48:56 - ALERT Server2 has turned ON PDU outlet #14 now that UPS power has been restored
```

```
Title: CRITICAL - Server2 Shutting Down Due to Limited Battery Runtime
11:46:46 - CRITICAL - Server2 is shutting down due to UPS runtime remaining on battery being less than 15 minutes. The UPS has been running off battery power for 0:0:00:00.00 minuets. The UPS Voltage: 0 VAC, Battery Capacity: 100 %, Runtime Remaining: 0 Hours : 14 Minutes : 59 Seconds
```

```
Title: ALERT - Server2 UPS Power has Been Restored
11:42:55 - ALERT - Server2 - UPS input power restored, UPS no longer operating on battery power -- UPS Voltage: 120 VAC, Battery Capacity: 100 %, Runtime Remaining: 0 Hours : 19 Minutes : 59 Seconds
```

```
Title: ALERT - Server2 Cannot Talk to UPS
11:19:14 - ALERT - Server2 could NOT access the UPS unit at address 192.168.20.13 for the last 2 minutes
```

```
Title: ALERT - Server2 UPS Comms have been restored
11:23:12 - ALERT - Server2 - UPS has restored communications with UPS at 192.168.20.13
```

```
Title: Warning UPS Monitoring Failed - Configuration or username/password credential file is missing
12:16:39 - Warning UPS Monitoring Failed - Configuration file is missing
```






<p align="right">(<a href="#top">back to top</a>)</p>



<!-- CONTRIBUTING -->
## Contributing

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- LICENSE -->
## License

This is free to use code, use as you wish

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- CONTACT -->
## Contact

Your Name - Brian Wallace - wallacebrf@hotmail.com

Project Link: [https://github.com/wallacebrf/synology_UPS_Shutdown-Monitoring)

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- ACKNOWLEDGMENTS -->
## Acknowledgments


<p align="right">(<a href="#top">back to top</a>)</p>
