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

This script pulls data from an APC UPS with a Network Management Card version 2 or version 3 installed. if the UPS does not have a network management cad installed, this script cannot interface with a USB connected UPS. This script has been coded to utilize the network management card  version 2 and version 3 from APC. 

***************************************************
Power Distribution Unit (PDU) Outlet Control load shedding:
***************************************************
this script is written around the use of a cyberpower pdu81003 power distribution unit and the associated SNMP commands/IODs that it support.  
if no PDU is available, set the variable "load_shed_control" to a zero or use the web administration page to disable load shedding. 

if a different PDU model or manufacture is utilized the script may not work as the SNMP commands will likely not match. 

if PDU load shedding is desired, the PDU must have SNMP enabled for communications and control. 

the amount of time the load shedding occurs is configurable through "load_shed_early_time" or through the web administration page. 

this will cause load shedding to occur x number of minutes earlier than the system shutdown command configured in the web administration page

outlets will be turned back on when UPS power is restored ONLY IF the power is restored before the system is commanded to shutdown. 

if the system is commanded to shutdown, when the system is restarted, the PDU outlets commanded to turn off during load shed will remain off and will need to be manually re-enabled. 

this is to prevent constant power on/off fluctuations from causing the system to continuously turn the outlets on and off. 


***************************************************
Synology Surveillance Station Application Shutdown Load Shedding:
***************************************************
the script can terminate the synology surveillance station application which can draw significant power from the CPU and GPU

the amount of time the load shedding occurs is configurable through "load_shed_early_time" or through the web administration page. 

this will cause load shedding to occur x number of minutes earlier than the system shutdown command

surveillance Station will be restarted when UPS power is restored ONLY IF the power is restored before the system is commanded to shutdown. 

if the system is commanded to shutdown, when the system is restarted, surveillance station will remain off and will need to be manually re-enabled. 

this is to prevent constant power on/off fluctuations from causing the system to continuously turn the services on and off. 


***************************************************
PLEX Media Server Application Shutdown Load Shedding:
***************************************************
the script can terminate any active PLEX streams which if performing transcoding can use high levels of CPU power and wattage

the amount of time the load shedding occurs is configurable through "load_shed_early_time" or through the web administration page. this will cause load shedding to occur x number of minutes earlier than the system shutdown command

PLEX will be restarted when UPS power is restored ONLY IF the power is restored before the system is commanded to shutdown. 

if the system is commanded to shutdown, when the system is restarted, PLEX will remain off and will need to be manually re-enabled. 

this is to prevent constant power on/off fluctuations from causing the system to continuously turn the services on and off.
	

***************************************************
UPS Communications Loss Handling:
***************************************************
this script supports shutting down the server in the event of extended duration UPS network communications failures. 
	This can be enabled and disabled in the web administration page. 
	the purpose is to protect the system during extended network failures as the script will not be able to determine if the UPS run time is low which could cause the system to lose power and shutdown un-gracefully. 
the script also allows for immediate shutdown of the system if the network communications are lost while the UPS is actively running on battery power. 
	this is in case network switches between the system and the UPS lose power before the system does. 
	this protects the system as it would not be able to determine the remaining run time of the battery as it is not guaranteed that communications will resume before the run time goes too low.  
the amount of time [hours (1 through 20)] required to pass while UPS communications are down is user configurable in the web administration page
starting half way through the configured delay time, a warning email will be sent to the configured email address warning that the system will be shutdown soon
during the entire duration of failed network communications, a warning email will be sent to the configured email address every 2 minutes to ensure the administrator of the system knows of the error. 

	

 ***************************************************
UPS Output Shutdown Post NAS System Shutdown:
***************************************************
this script supports commanding the UPS to turn off all outlet groups after the NAS system has been commanded to shutdown. 
The delay time between when the NAS system is shutdown and when the outlet groups are turned off is user configurable. 
if the outlet groups are commanded to turn off, they will NOT turn back on when AC power is restored to the UPS


<p align="right">(<a href="#top">back to top</a>)</p>



<!-- GETTING STARTED -->
## Getting Started

This project is written around a Synology NAS and their DSM specific SNMP OIDs and MIBs. 

### Prerequisites

1.) this script is designed to be executed every 60 seconds

2.) this script requires the installation of synology MailPlus server package in package center in order to send emails. 

	the mail plus server must be properly configured to relay received messages to another email account. 
	
3.) this script is Dependent on a docker container for SNMP_SET commands using the "elcolio/net-snmp" container located here: https://hub.docker.com/r/elcolio/net-snmp

	this is required as the synology system does not contain the snmp_set commands. the set command is used to control the PDU outlets and to command the UPS to shutdown
	the container does not always run, it is run once when a SET command needs to be executed 
	
4.) RAMDISK
	NOTE: to reduce disk IOPS activity, it is recommended to create a RAMDISK for the temp files this script uses
	to do so, create a scheduled task on boot up in Synology Task Scheduler to add the following line

		mount -t tmpfs -o size=1% ramdisk $notification_file_location

		where "$notification_file_location" is the location you want the files stored and is a variable configured below

		as this is a RAMDISK folder, upon boot up the contents will be empty which is required for the script to operate after it has commanded a shutdown. 
	if not using a RAM disk folder, then a scheduled task to re-set the shutdown log file is required
	to do so, create a scheduled task on boot up in Synology Task Scheduler to add the following line

		echo "0,0" > $notification_file_location/$UPS_shutdown_log_file
		where "$notification_file_location/$UPS_shutdown_log_file" is the location you want the files stored and are variables configured below
5.) this script only supports SNMP V3. This is because lower versions are less secure especially when using the set commands that have the ability to remove power to the systems

	SNMP must be enabled on the host NAS for the script to gather the NAS NAME
	
	SNNMP must be enabled on the target APC UPS network management card
	
	SNNMP must be enabled on the PDU
	
	the snmp settings for the NAS, UPS, and PDU can all be entered into the web administration page
	
6.) This script can be run through synology Task Scheduler. However it has been observed that running large scripts like this as frequently as every 60 seconds causes the synoschedtask system application to use large amounts of resources and causes the script to execute slowly

	details of this issue can be seen here:
	https://www.reddit.com/r/synology/comments/kv7ufq/high_disk_usage_on_disk_1_caused_by_syno_task/
	to fix this it is recommend to directly edit the crontab at /etc/crontab
	
	this can be accomplished using vi /etc/crontab
	
	add the following line: 
		*	*	*	*	*	root	$path_to_file/$filename
	details on crontab can be found here: https://man7.org/linux/man-pages/man5/crontab.5.html 
7.) This script only supports cyberpower pdu81003 power distribution units. different units will require script updating due to different SNMP IODs and MIBs


### Installation



### Configuration 




### Configuration of required settings

<img src="" alt="1313">
<img src="" alt="1314">




### Configuration of crontab


This script can be run through synology Task Scheduler. However it has been observed that running large scripts like this as frequently as every 60 seconds causes the synoschedtask system application to use large amounts of resources and causes the script to execute slowly
	#details of this issue can be seen here:
	#https://www.reddit.com/r/synology/comments/kv7ufq/high_disk_usage_on_disk_1_caused_by_syno_task/
	#to fix this it is recommend to directly edit the crontab at /etc/crontab
	
	#this can be accomplished using vi /etc/crontab
	
	#add the following line: 
	```	*	*	*	*	*	root	$path_to_file/$filename```
	#details on crontab can be found here: https://man7.org/linux/man-pages/man5/crontab.5.html


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
