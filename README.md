# Synology APC UPS SNMP NAS Shutdown and Monitoring
<a href="https://github.com/wallacebrf/synology_UPS_Shutdown-Monitoring/releases"><img src="https://img.shields.io/github/v/release/wallacebrf/synology_UPS_Shutdown-Monitoring.svg"></a>
<a href="https://hits.seeyoufarm.com"><img src="https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2Fwallacebrf%2Fsynology_UPS_Shutdown-Monitoring&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=hits&edge_flat=false"/></a>

<div id="top"></div>
<!--
*** comments....
-->



<!-- PROJECT LOGO -->
<br />

<h3 align="center">Synology APC UPS SNMP Monitor and NAS Shutdown</h3>

  <p align="center">
    This project is comprised of a shell script that runs once per minute collecting data from a APC Network Management Card to shutdown the NAS or perform load shedding of outlets and services 
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

The script can perform a system shutdown during a power outage using the following triggers

1.) run time remaining only
2.) time on battery only
3.) run time remaining or battery voltage
4.) time on battery or battery voltage
5.) battery voltage only

in addition, for all five options, if the battery temperature exceeds a configurable threshold, then the system will also be commanded to shutdown regardless of the run time or battery voltage. this is to prevent damage to the battery. 

The voltage threshold and the temperature threshold can be configured in tenths of a volt/degree respectively. 

Depending on the model of the UPS, it may have a 12-volt, 24-volt, 48-volt, or even higher battery voltage. Please note this script currently supports up to 48 volt batteries. 
when a 12 volt battery is fully charged, it's voltage will typically be 13.0 volts (or possibly higher) and the recommended 50% "state of discharge" of lead acid batteries is around 12.0 volts. 

As such, the lowest recommended shutdown voltages for the three types of batteries are:

1.) 12-volt systems: 12.0 volts
2.) 24-volt systems: 24.0 volts
3.) 48-volt systems: 48 volts

Lower voltages can be used however going below 12-volts puts the battery at more stress. Never discharge a 12-volt battery below 10.5 volts. this is important as the system will take several minutes to shutdown and during this time the battery voltage will continue to drop. It is recommended to perform battery "run time calibrations" to see how quickly the battery voltage trips over a period of time. failure to set the battery voltage correctly may cause the UPS to run out of power before the system has had a chance to fully shut down. 

***************************************************
Power Distribution Unit (PDU) Outlet Control load shedding:
***************************************************
this script is written around the use of a cyberpower pdu81xxx series power distribution unit and the associated SNMP commands/IODs that it supports.  
If no PDU is available, use the web administration page to disable load shedding. 

If a different PDU model or manufacture is utilized the script will not work as the SNMP commands will  not match and the IODs would have to be updated within th script manually. 

If PDU load shedding is desired and the PDU is a cyberpower pdu81xxx series unit, the PDU must have SNMP enabled for communications and control. The SNMP settings used in the PDU will need to be entered into the web administration page to allow the script to talk to the PDU. 

PDU load shedding can be enabled or disabled independently of Synology Surveillance Station and PLEX load shedding. How load shedding occurs is configurable through the web administration page. There are five options for load shed triggering

1.) run time remaining only
2.) time on battery only
3.) run time remaining or battery voltage
4.) time on battery or battery voltage
5.) battery voltage only

the load shed battery voltage threshold and or time duration is configured independently from the shutdown settings. 

the lowest load shed battery voltage recommended based on battery voltage is:
1.) 12-volt systems: 12.2 to 12.3 volts
2.) 24-volt systems: 24.5 to 24.7 volts
3.) 48-volt systems: 49 to 49.1 volts

Lower voltages can be used however going below 12-volts puts the battery at more stress. Never discharge a 12-volt battery below 10.5 volts. this is important as the system will take several minutes to shutdown and during this time the battery voltage will continue to drop. It is recommended to perform battery "run time calibrations" to see how quickly the battery voltage trips over a period of time. failure to set the battery voltage correctly may cause the UPS to run out of power before the system has had a chance to fully shut down.

If the system is commanded to shutdown, when the system is restarted, the PDU outlets commanded to turn off during load shed will turn back on.


***************************************************
Synology Surveillance Station Application Shutdown Load Shedding:
***************************************************
The script can terminate the Synology surveillance station application which can draw significant power from the CPU and GPU (GPU is used in the DVA series units)

Synology Surveillance Station load shedding can be enabled or disabled independently of PDU and PLEX load shedding. All load shedding uses the same trigger and threshold values as detailed in the PDU explanation above. 

Surveillance Station will be restarted when UPS power is restored. 


***************************************************
PLEX Media Server Application Shutdown Load Shedding:
***************************************************
The script can terminate any active PLEX streams which if performing transcoding can use high levels of CPU power and wattage. 

PLEX load shedding can be enabled or disabled independently of PDU and Synology Surveillance Station load shedding. All load shedding uses the same trigger and threshold values as detailed in the PDU explanation above. 

PLEX will be restarted when UPS power is restored. 
	

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

2.) This script recommends the installation of Synology MailPlus server package in package center in order to send emails. If Synology MailPlus server package is not installed, the script can still send emails using the Synology email client settings for notifications in the Synology Control Panel. 

	The mail plus server must be properly configured to relay received messages to another email account. This readme does not go into detail on that configuration process. 
	
3.) This script is Dependent on a docker container for SNMP_SET commands using the "elcolio/net-snmp" container located here: https://hub.docker.com/r/elcolio/net-snmp

	This is required as the Synology system does not contain the snmp_set commands. The set command is used to control the PDU outlets and to command the UPS to shutdown
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
$config_file_location="/volume1/web/config/config_files/config_files_local";
$config_file_name="server2_UPS_monitor_config2.txt";
$use_login_sessions=true; //set to false if not using user login sessions
$form_submittal_destination="index.php?page=6&config_page=server2_ups_monitor";
$page_title="Server2 APC Network Management Card UPS Monitoring and Shutdown/Load Shed Configuration Settings";
```
2. Set ```config_file_location``` and ```config_file_name``` to where the script's configuration file will be stored. This MUST be the same as used in the .sh script file ```configuration_file``` and ```config_file_location``` configured below. 
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
configuration_file="server2_UPS_monitor_config2.txt"
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

<img src="https://raw.githubusercontent.com/wallacebrf/synology_UPS_Shutdown-Monitoring/main/UPS_monitor_settings.png" alt="1313">

Once the files are copied to the NAS, properly edited, and device settings are configured as required above, using a web browser, navigate to where the "server2_UPS_config.php" file is located. 

when the web-page loads, it will automatically create a configuration file and populate it with default values. If an error occurs indicating permissions are denied or the write errors, ensure the Synology http user permissions were configured correctly. 

Note: for the 7/26/24 release, if upgrading from a previous version, the existing configuration file will be backed up and additional configuration settings will be saved to the config file. all of the new parameters that need configuration will be highlighted in red. 

edit the values as desired. 

1. Ensure the script is enabled
2. How often will be script be executed per minute? it is recommended to perform 3-4 polls per minute so the system can react to changes in the UPS fast enough
3. What input voltage is the UPS configured to transition from AC power to battery? Ensure this value matches the value configured in the Network Management card's interface 
4. Shutdown Trigger. This can be either 1.) ```Run Time Remaining``` 2.) ```Time On Battery``` 3.) ```Run Time Remaining OR Battery Voltage``` 4.) ```Time On Battery OR Battery Voltage``` 5.) ```Battery Voltage Only```
5. If the shutdown trigger is either options 3, 4, or 5, configure the desired battery voltage to initiate a shutdown
6. If the shutdown trigger is either options 1, 2, 3, or 4, configure the time time threshold in hours, minuets, and seconds
7. Configure the maximum allowable battery temperature while the UPS is operating on battery power
8. If desired enable and configure the number of hours between when UPS network communications are lost and when the system will be commanded to shutdown while operating on AC power. This is important because if network communications fail between the system and the UPS NMC, this script will not be able to protect the system if power is lost during this time. 
9. If desired enable and configure the number of minuets after the system is commanded to shutdown that the UPS outlet groups are commanded by the UPS to turn off. This option will only work if the UPS in question supports switched outlet groups. 
10. If desired enable PDU load shedding and select the outlet(s) desired to be turned off during a load shed event
11. If desired enable Synology Surveillance Station load shedding
12. If desired enable PLEX Media Server load shedding. If PLEX load shedding is enabled, ensure the installed volume and IP address settings are also configured
13. Load Shed Trigger. This can be either 1.) ```Run Time Remaining``` 2.) ```Time On Battery``` 3.) ```Run Time Remaining OR Battery Voltage``` 4.) ```Time On Battery OR Battery Voltage``` 5.) ```Battery Voltage Only```
14. If the Load Shed trigger is either options 3, 4, or 5, configure the desired battery voltage to initiate a load shed
15. If the Load Shed trigger is either options 1, 2, 3, or 4, configure the time time threshold in hours, minuets, and seconds
16. Enable Email notifications and configure from what email address they will show as coming from, and to whom the email notifications will be sent. The duration of time between notifications can also be configured
17. ensure SNMP version 3 is enabled and configured on the NAS and ensure the settings match between what DSM was configured and what is entered on this web-administration page 
18. ensure SNMP version 3 is enabled on the network management card and ensure the settings match between what the APC NMC was configured and what is entered on this web-administration page. 
19. if a PDU is available, configure the PDU for SNMP version 3 and ensure the settings match between what the PSU is configured and what is entered on this web-administration page 


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

 ### Configuration of startup script
on every boot of the system, we need to reset the shutdown tracker and update the UPS heartbeat files. if we do not then the system will either think we are alreadyt shutting down and the scriupt basically stopps protecting the system, or the system will think UPS network comms are still down and shut down the NAS shortly after reboot. 

On synology, go to Control Panel --> Task Scheduler --> create --> Triggered Task --> User-defined script

Ensure the script is eanbled and choose root as the user. Choose "boot-up" for the event

Under task settings tab, enter the following code for the task
```
#!/bin/bash
echo "0,0" > /volume1/web/logging/notifications/UPS_shutdown_status.txt
current_time=$( date +%s )
echo "$current_time" > "/volume1/web/logging/notifications/UPS_monitor_Heartbeat.txt"
```

ensure the ```/volume1/web/logging/notifications/UPS_shutdown_status.txt``` matches the same location as configured inside the ```server_APC_UPS_Monitor.sh``` script

ensure the ```/volume1/web/logging/notifications/UPS_monitor_Heartbeat.txt``` matches the same location as configured inside the ```server_APC_UPS_Monitor.sh``` script

Click OK and when asked enter your admin password

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
