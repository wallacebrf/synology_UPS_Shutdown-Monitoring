<?php
//Version 7/27/2024
//By Brian Wallace
//Note Ensure the location and file name of the configuration file matches the values in the server_APC_UPS_Monitor.sh script 
/*This web administration page allows for the configuration of all settings used in the server_APC_UPS_Monitor.sh script file
ensure to visit this web page and configure all settings as required prior to running the server_APC_UPS_Monitor.sh script for the first time. 
this html file has no major formatting as it is intended to be included in a larger php file using the command include_once"

include_once 'UPS_config.php';

that file with the above line would include the needed headers, footers, and call outs for formatting*/


///////////////////////////////////////////////////
//User Defined Variables
///////////////////////////////////////////////////

$config_file_location="/var/www/html/config/config_files";
$config_file_name="server_UPS_monitor_config.txt";
$use_login_sessions=true; //set to false if not using user login sessions
$form_submittal_destination="index.php?page=6&config_page=server2_ups_monitor";
$page_title="TrueNAS APC Network Management Card UPS Monitoring and Shutdown/Load Shed Configuration Settings";


///////////////////////////////////////////////////
//Beginning of configuration page
///////////////////////////////////////////////////
if($use_login_sessions){


	if($_SERVER['HTTPS']!="on") {

	$redirect= "https://".$_SERVER['HTTP_HOST'].$_SERVER['REQUEST_URI'];

	header("Location:$redirect"); } 

	// Initialize the session
	if(session_status() !== PHP_SESSION_ACTIVE) session_start();
	 
	$current_time=time();

	if(!isset($_SESSION["session_start_time"])){
		$expire_time=$current_time-60;
	}else{
		$expire_time=$_SESSION["session_start_time"]+3600; #un-refreshed session will only be good for 1 hour
	}


	// Check if the user is logged in, if not then redirect him to login page
	if(!isset($_SESSION["loggedin"]) || $_SESSION["loggedin"] !== true || $current_time > $expire_time || !isset($_SESSION["session_user_id"])){
		// Unset all of the session variables
		$_SESSION = array();
		// Destroy the session.
		session_destroy();
		header("location: ../login.php");
		exit;
	}else{
		$_SESSION["session_start_time"]=$current_time; //refresh session start time
	}
}

$config_file="".$config_file_location."/".$config_file_name."";
error_reporting(E_NOTICE);
include $_SERVER['DOCUMENT_ROOT']."/functions.php";

//define empty variables
$ups_monitor_email_error="";
$UPS_monitor_url_error="";
$UPS_monitor_runtime_error="";
$UPS_monitor_voltage_error="";
$UPS_PDU_IP_error="";
$UPS_PLEX_IP_error="";
$UPS_plex_installed_volume_error="";
$server_name_error="";
$plex_jelly_fin_installed_on_system_error="";
$plex_container_name_error="";
$jellyfin_container_name_error="";
$UPS_UPS_AuthPass1_error="";
$UPS_UPS_PrivPass2_error="";
$UPS_UPS_snmp_user_error="";
$UPS_PDU_AuthPass1_error="";
$UPS_PDU_PrivPass2_error="";
$UPS_PDU_snmp_user_error="";
$generic_error="";
$from_email_error="";
$shutdown_battery_voltage_error="";
$shutdown_run_time_error="";
$max_on_battery_temp_error="";
$load_shed_voltage_error="";
$ups_email_delay_error="";
$load_shed_run_time_error="";
$location_of_email_python_file_error="";
$surveillance_container_name_error="";
	
if(isset($_POST['submit_ups_monitor'])){
	if (file_exists("$config_file")) {
		$data = file_get_contents("$config_file");
		$pieces = explode(",", $data);
	}
		   
	//perform data verification of submitted values
			
	[$UPS_ups_outlet_group_turn_off_delay, $generic_error] = test_input_processing($_POST['UPS_ups_outlet_group_turn_off_delay'], $pieces[45], "numeric", 60, 900);
	[$UPS_ups_outlet_group_turn_off_enable, $generic_error] = test_input_processing($_POST['UPS_ups_outlet_group_turn_off_enable'], "", "checkbox", 0, 0);
	
	[$UPS_outlet_1_load_shed_yes_no, $generic_error] = test_input_processing($_POST['UPS_outlet_1_load_shed_yes_no'], "", "checkbox", 0, 0);
	[$UPS_outlet_2_load_shed_yes_no, $generic_error] = test_input_processing($_POST['UPS_outlet_2_load_shed_yes_no'], "", "checkbox", 0, 0);
	[$UPS_outlet_3_load_shed_yes_no, $generic_error] = test_input_processing($_POST['UPS_outlet_3_load_shed_yes_no'], "", "checkbox", 0, 0);
	[$UPS_outlet_4_load_shed_yes_no, $generic_error] = test_input_processing($_POST['UPS_outlet_4_load_shed_yes_no'], "", "checkbox", 0, 0);
	[$UPS_outlet_5_load_shed_yes_no, $generic_error] = test_input_processing($_POST['UPS_outlet_5_load_shed_yes_no'], "", "checkbox", 0, 0);
	[$UPS_outlet_6_load_shed_yes_no, $generic_error] = test_input_processing($_POST['UPS_outlet_6_load_shed_yes_no'], "", "checkbox", 0, 0);
	[$UPS_outlet_7_load_shed_yes_no, $generic_error] = test_input_processing($_POST['UPS_outlet_7_load_shed_yes_no'], "", "checkbox", 0, 0);
	[$UPS_outlet_8_load_shed_yes_no, $generic_error] = test_input_processing($_POST['UPS_outlet_8_load_shed_yes_no'], "", "checkbox", 0, 0);
	[$UPS_outlet_9_load_shed_yes_no, $generic_error] = test_input_processing($_POST['UPS_outlet_9_load_shed_yes_no'], "", "checkbox", 0, 0);
	[$UPS_outlet_10_load_shed_yes_no, $generic_error] = test_input_processing($_POST['UPS_outlet_10_load_shed_yes_no'], "", "checkbox", 0, 0);
	[$UPS_outlet_11_load_shed_yes_no, $generic_error] = test_input_processing($_POST['UPS_outlet_11_load_shed_yes_no'], "", "checkbox", 0, 0);
	[$UPS_outlet_12_load_shed_yes_no, $generic_error] = test_input_processing($_POST['UPS_outlet_12_load_shed_yes_no'], "", "checkbox", 0, 0);
	[$UPS_outlet_13_load_shed_yes_no, $generic_error] = test_input_processing($_POST['UPS_outlet_13_load_shed_yes_no'], "", "checkbox", 0, 0);
	[$UPS_outlet_14_load_shed_yes_no, $generic_error] = test_input_processing($_POST['UPS_outlet_14_load_shed_yes_no'], "", "checkbox", 0, 0);
	[$UPS_outlet_15_load_shed_yes_no, $generic_error] = test_input_processing($_POST['UPS_outlet_15_load_shed_yes_no'], "", "checkbox", 0, 0);
	[$UPS_outlet_16_load_shed_yes_no, $generic_error] = test_input_processing($_POST['UPS_outlet_16_load_shed_yes_no'], "", "checkbox", 0, 0);
		   
	if ($_POST['UPS_PDU_snmp_privacy_protocol']=="AES" || $_POST['UPS_PDU_snmp_privacy_protocol']=="DES"){
		[$UPS_PDU_snmp_privacy_protocol, $generic_error] = test_input_processing($_POST['UPS_PDU_snmp_privacy_protocol'], $pieces[27], "name", 0, 0);
	}else{
		$UPS_PDU_snmp_privacy_protocol=$pieces[27];
	}
		   

	if ($_POST['UPS_PDU_snmp_auth_protocol']=="MD5" || $_POST['UPS_PDU_snmp_auth_protocol']=="SHA"){
		[$UPS_PDU_snmp_auth_protocol, $generic_error] = test_input_processing($_POST['UPS_PDU_snmp_auth_protocol'], $pieces[26], "name", 0, 0);
	}else{
		$UPS_PDU_snmp_auth_protocol=$pieces[26];
	}
		   
	[$UPS_PDU_snmp_user, $UPS_PDU_snmp_user_error] = test_input_processing($_POST['UPS_PDU_snmp_user'], $pieces[25], "name", 0, 0);
	  
	[$UPS_PDU_PrivPass2, $UPS_PDU_PrivPass2_error] = test_input_processing($_POST['UPS_PDU_PrivPass2'], $pieces[24], "password", 0, 0);
		
	[$UPS_PDU_AuthPass1, $UPS_PDU_AuthPass1_error] = test_input_processing($_POST['UPS_PDU_AuthPass1'], $pieces[23], "password", 0, 0);
		
	if ($_POST['UPS_UPS_snmp_privacy_protocol']=="AES" || $_POST['UPS_UPS_snmp_privacy_protocol']=="DES"){
		[$UPS_UPS_snmp_privacy_protocol, $generic_error] = test_input_processing($_POST['UPS_UPS_snmp_privacy_protocol'], $pieces[22], "name", 0, 0);
	}else{
		$UPS_UPS_snmp_privacy_protocol=$pieces[22];
	}
		   
	if ($_POST['UPS_UPS_snmp_auth_protocol']=="MD5" || $_POST['UPS_UPS_snmp_auth_protocol']=="SHA"){
		[$UPS_UPS_snmp_auth_protocol, $generic_error] = test_input_processing($_POST['UPS_UPS_snmp_auth_protocol'], $pieces[21], "name", 0, 0);
	}else{
		$UPS_UPS_snmp_auth_protocol=$pieces[21];
	}
		   
	[$UPS_UPS_snmp_user, $UPS_UPS_snmp_user_error] = test_input_processing($_POST['UPS_UPS_snmp_user'], $pieces[20], "name", 0, 0);
		  
	[$UPS_UPS_PrivPass2, $UPS_UPS_PrivPass2_error] = test_input_processing($_POST['UPS_UPS_PrivPass2'], $pieces[19], "password", 0, 0);
		
	[$UPS_UPS_AuthPass1, $UPS_UPS_AuthPass1_error] = test_input_processing($_POST['UPS_UPS_AuthPass1'], $pieces[18], "password", 0, 0);
		
	if ($_POST['UPS_Syno_snmp_privacy_protocol']=="AES" || $_POST['UPS_Syno_snmp_privacy_protocol']=="DES"){
		[$UPS_Syno_snmp_privacy_protocol, $generic_error] = test_input_processing($_POST['UPS_Syno_snmp_privacy_protocol'], $pieces[17], "name", 0, 0);
	}else{
		$UPS_Syno_snmp_privacy_protocol=$pieces[17];
	}
		   
	[$surveillance_container_name, $surveillance_container_name_error] = test_input_processing($_POST['surveillance_container_name'], $pieces[16], "name", 0, 0);
		   
	[$jellyfin_container_name, $jellyfin_container_name_error] = test_input_processing($_POST['jellyfin_container_name'], $pieces[15], "name", 0, 0);
		
	[$plex_container_name, $plex_container_name_error] = test_input_processing($_POST['plex_container_name'], $pieces[14], "name", 0, 0);
		  
	[$plex_jelly_fin_installed_on_system, $plex_jelly_fin_installed_on_system_error] = test_input_processing($_POST['plex_jelly_fin_installed_on_system'], "", "checkbox", 0, 0);   
		  
	[$location_of_email_python_file, $location_of_email_python_file_error] = test_input_processing($_POST['location_of_email_python_file'], "", "dir", 0, 0);   

	[$server_name, $server_name_error] = test_input_processing($_POST['server_name'], $pieces[11], "name", 0, 0);   
		   
	[$UPS_plex_installed_volume, $UPS_plex_installed_volume_error] = test_input_processing($_POST['UPS_plex_installed_volume'], $pieces[10], "dir", 0, 0);    
		   
	[$UPS_PDU_IP, $UPS_PDU_IP_error] = test_input_processing($_POST['UPS_PDU_IP'], $pieces[8], "ip", 0, 0);    
		
	[$UPS_PLEX_IP, $UPS_PLEX_IP_error] = test_input_processing($_POST['UPS_PLEX_IP'], $pieces[9], "ip", 0, 0);    
		  
	[$UPS_monitor_enable, $generic_error] = test_input_processing($_POST['UPS_monitor_enable'], "", "checkbox", 0, 0); 
		   
	[$UPS_monitor_runtime, $UPS_monitor_runtime_error] = test_input_processing($_POST['UPS_monitor_runtime'], $pieces[0], "numeric", 0, 200);
		   
	[$UPS_monitor_voltage, $UPS_monitor_voltage_error] = test_input_processing($_POST['UPS_monitor_voltage'], $pieces[1], "numeric", 90, 140);
		  
	[$ups_monitor_email, $ups_monitor_email_error] = test_input_processing($_POST['ups_monitor_email'], $pieces[2], "email", 0, 0);
		  
	if ($_POST['ups_monitor_capture_interval']==10 || $_POST['ups_monitor_capture_interval']==15 || $_POST['ups_monitor_capture_interval']==30 || $_POST['ups_monitor_capture_interval']==60){
		$ups_monitor_capture_interval=trim(stripslashes(strip_tags(htmlspecialchars(filter_var($_POST['ups_monitor_capture_interval'], FILTER_SANITIZE_NUMBER_INT)))));
	}else{
		$ups_monitor_capture_interval=$pieces[3];
	}
		  
	if ($_POST['UPS_comm_loss_shutdown_interval']==60 || $_POST['UPS_comm_loss_shutdown_interval']==120 || $_POST['UPS_comm_loss_shutdown_interval']==180 || $_POST['UPS_comm_loss_shutdown_interval']==240 || $_POST['UPS_comm_loss_shutdown_interval']==300 || $_POST['UPS_comm_loss_shutdown_interval']==360 || $_POST['UPS_comm_loss_shutdown_interval']==420 || $_POST['UPS_comm_loss_shutdown_interval']==480 || $_POST['UPS_comm_loss_shutdown_interval']==540 || $_POST['UPS_comm_loss_shutdown_interval']==600 || $_POST['UPS_comm_loss_shutdown_interval']==660 || $_POST['UPS_comm_loss_shutdown_interval']==720 || $_POST['UPS_comm_loss_shutdown_interval']==780 || $_POST['UPS_comm_loss_shutdown_interval']==840 || $_POST['UPS_comm_loss_shutdown_interval']==900 || $_POST['UPS_comm_loss_shutdown_interval']==960 || $_POST['UPS_comm_loss_shutdown_interval']==1020 || $_POST['UPS_comm_loss_shutdown_interval']==1080 || $_POST['UPS_comm_loss_shutdown_interval']==1140 || $_POST['UPS_comm_loss_shutdown_interval']==1200){
		$UPS_comm_loss_shutdown_interval=trim(stripslashes(strip_tags(htmlspecialchars(filter_var($_POST['UPS_comm_loss_shutdown_interval'], FILTER_SANITIZE_NUMBER_INT)))));
	}else{
		$UPS_comm_loss_shutdown_interval=$pieces[6];
	}
		  
	[$UPS_comm_loss_shutdown_enable, $generic_error] = test_input_processing($_POST['UPS_comm_loss_shutdown_enable'], "", "checkbox", 0, 0);
	 
	[$UPS_url, $UPS_monitor_url_error] = test_input_processing($_POST['UPS_url'], $pieces[4], "ip", 0, 0);
	
	[$from_email, $from_email_error] = test_input_processing($_POST['from_email'], $pieces[46], "email", 0, 0);
	  
	  
	  
	  
	  
	  
	[$shutdown_battery_voltage, $shutdown_battery_voltage_error] = test_input_processing(($_POST['shutdown_battery_voltage']*10), $pieces[47], "float", 100.0, 600.0);  
	$shutdown_battery_voltage_decimal=round(($shutdown_battery_voltage*1.0)/10.0,1);
	
	[$shutdown_run_time_hours, $shutdown_run_time_error] = test_input_processing($_POST['shutdown_run_time_hours'], $pieces[48], "numeric", 0, 24); 
	
	[$shutdown_run_time_min, $shutdown_run_time_error] = test_input_processing($_POST['shutdown_run_time_min'], $pieces[49], "numeric", 0, 59); 

	[$shutdown_run_time_sec, $shutdown_run_time_error] = test_input_processing($_POST['shutdown_run_time_sec'], $pieces[50], "numeric", 0, 59); 

	[$max_on_battery_temp, $max_on_battery_temp_error] = test_input_processing(($_POST['max_on_battery_temp']*10), $pieces[51], "float", 100.0, 400.0); 
	$max_on_battery_temp_decimal=round(($max_on_battery_temp*1.0)/10.0,1);
	
	[$shutdown_trigger, $generic_error] = test_input_processing($_POST['shutdown_trigger'], $pieces[52], "numeric", 1, 5); 

	[$load_shed_trigger, $generic_error] = test_input_processing($_POST['load_shed_trigger'], $pieces[53], "numeric", 1, 5); 

	[$load_shed_voltage, $load_shed_voltage_error] = test_input_processing(($_POST['load_shed_voltage']*10), $pieces[54], "float", 100.0, 600.0); 
	$load_shed_voltage_decimal=round(($load_shed_voltage*1.0)/10.0,1);	
	
	[$pdu_load_shed_enable, $generic_error] = test_input_processing($_POST['pdu_load_shed_enable'], "", "checkbox", 0, 0);
	
	[$synology_ss_load_shed_enable, $generic_error] = test_input_processing($_POST['synology_ss_load_shed_enable'], "", "checkbox", 0, 0);

	[$plex_load_shed_enable, $generic_error] = test_input_processing($_POST['plex_load_shed_enable'], "", "checkbox", 0, 0);

	[$load_shed_run_time_hours, $load_shed_run_time_error] = test_input_processing($_POST['load_shed_run_time_hours'], $pieces[58], "numeric", 0, 24); 
	
	[$load_shed_run_time_min, $load_shed_run_time_error] = test_input_processing($_POST['load_shed_run_time_min'], $pieces[59], "numeric", 0, 59); 

	[$load_shed_run_time_sec, $load_shed_run_time_error] = test_input_processing($_POST['load_shed_run_time_sec'], $pieces[60], "numeric", 0, 59); 
	
	[$enable_notifications, $generic_error] = test_input_processing($_POST['enable_notifications'], "", "checkbox", 0, 0);
	
	[$ups_email_delay, $ups_email_delay_error] = test_input_processing($_POST['ups_email_delay'], $pieces[62], "numeric", 0, 59); 	  
	  
	$put_contents_string="".$UPS_monitor_runtime.",".$UPS_monitor_voltage.",".$ups_monitor_email.",".$ups_monitor_capture_interval.",".$UPS_url.",".$UPS_monitor_enable.",".$UPS_comm_loss_shutdown_interval.",".$UPS_comm_loss_shutdown_enable.",".$UPS_PDU_IP.",".$UPS_PLEX_IP.",".$UPS_plex_installed_volume.",".$server_name.",".$location_of_email_python_file.",".$plex_jelly_fin_installed_on_system.",".$plex_container_name.",".$jellyfin_container_name.",".$surveillance_container_name.",".$UPS_Syno_snmp_privacy_protocol.",".$UPS_UPS_AuthPass1.",".$UPS_UPS_PrivPass2.",".$UPS_UPS_snmp_user.",".$UPS_UPS_snmp_auth_protocol.",".$UPS_UPS_snmp_privacy_protocol.",".$UPS_PDU_AuthPass1.",".$UPS_PDU_PrivPass2.",".$UPS_PDU_snmp_user.",".$UPS_PDU_snmp_auth_protocol.",".$UPS_PDU_snmp_privacy_protocol.",".$UPS_outlet_1_load_shed_yes_no.",".$UPS_outlet_2_load_shed_yes_no.",".$UPS_outlet_3_load_shed_yes_no.",".$UPS_outlet_4_load_shed_yes_no.",".$UPS_outlet_5_load_shed_yes_no.",".$UPS_outlet_6_load_shed_yes_no.",".$UPS_outlet_7_load_shed_yes_no.",".$UPS_outlet_8_load_shed_yes_no.",".$UPS_outlet_9_load_shed_yes_no.",".$UPS_outlet_10_load_shed_yes_no.",".$UPS_outlet_11_load_shed_yes_no.",".$UPS_outlet_12_load_shed_yes_no.",".$UPS_outlet_13_load_shed_yes_no.",".$UPS_outlet_14_load_shed_yes_no.",".$UPS_outlet_15_load_shed_yes_no.",".$UPS_outlet_16_load_shed_yes_no.",".$UPS_ups_outlet_group_turn_off_enable.",".$UPS_ups_outlet_group_turn_off_delay.",".$from_email.",".$shutdown_battery_voltage.",".$shutdown_run_time_hours.",".$shutdown_run_time_min.",".$shutdown_run_time_sec.",".$max_on_battery_temp.",".$shutdown_trigger.",".$load_shed_trigger.",".$load_shed_voltage.",".$pdu_load_shed_enable.",".$synology_ss_load_shed_enable.",".$plex_load_shed_enable.",".$load_shed_run_time_hours.",".$load_shed_run_time_min.",".$load_shed_run_time_sec.",".$enable_notifications.",".$ups_email_delay."";
		  
	file_put_contents("$config_file",$put_contents_string );
		  
}else{
	if (file_exists("$config_file")) {
		$data = file_get_contents("$config_file");
		$pieces = explode(",", $data);
		
		//Previous version of the script used only 47 configuration parameters. The new version uses 63. if the old configuration version is being used, make a backup and add the remaining values to the file
		if (sizeof($pieces)!=63){
			print "<h1><font color=\"red\">Attention, config file is incorrect, config file should have 63 paramters, current file has ".sizeof($pieces)." paramters</font></h1>";
			exit;
		}
			
		//$unused=$pieces[0];
		$UPS_monitor_voltage=$pieces[1];
		$ups_monitor_email=$pieces[2];
		$ups_monitor_capture_interval=$pieces[3];
		$UPS_url=$pieces[4];
		$UPS_monitor_enable=$pieces[5];
		$UPS_comm_loss_shutdown_interval=$pieces[6];
		$UPS_comm_loss_shutdown_enable=$pieces[7];
		$UPS_PDU_IP=$pieces[8];
		$UPS_PLEX_IP=$pieces[9];
		$UPS_plex_installed_volume=$pieces[10];
		
		
		
		
		$server_name=$pieces[11];
		$location_of_email_python_file=$pieces[12];
		$plex_jelly_fin_installed_on_system=$pieces[13];
		$plex_container_name=$pieces[14];
		$jellyfin_container_name=$pieces[15];
		$surveillance_container_name=$pieces[16];
		$UPS_Syno_snmp_privacy_protocol=0;
		
		
		
		
		
		$UPS_UPS_AuthPass1=$pieces[18];
		$UPS_UPS_PrivPass2=$pieces[19];
		$UPS_UPS_snmp_user=$pieces[20];
		$UPS_UPS_snmp_auth_protocol=$pieces[21];
		$UPS_UPS_snmp_privacy_protocol=$pieces[22];
		$UPS_PDU_AuthPass1=$pieces[23];
		$UPS_PDU_PrivPass2=$pieces[24];
		$UPS_PDU_snmp_user=$pieces[25];
		$UPS_PDU_snmp_auth_protocol=$pieces[26];
		$UPS_PDU_snmp_privacy_protocol=$pieces[27];
		$UPS_outlet_1_load_shed_yes_no=$pieces[28];
		$UPS_outlet_2_load_shed_yes_no=$pieces[29];
		$UPS_outlet_3_load_shed_yes_no=$pieces[30];
		$UPS_outlet_4_load_shed_yes_no=$pieces[31];
		$UPS_outlet_5_load_shed_yes_no=$pieces[32];
		$UPS_outlet_6_load_shed_yes_no=$pieces[33];
		$UPS_outlet_7_load_shed_yes_no=$pieces[34];
		$UPS_outlet_8_load_shed_yes_no=$pieces[35];
		$UPS_outlet_9_load_shed_yes_no=$pieces[36];
		$UPS_outlet_10_load_shed_yes_no=$pieces[37];
		$UPS_outlet_11_load_shed_yes_no=$pieces[38];
		$UPS_outlet_12_load_shed_yes_no=$pieces[39];
		$UPS_outlet_13_load_shed_yes_no=$pieces[40];
		$UPS_outlet_14_load_shed_yes_no=$pieces[41];
		$UPS_outlet_15_load_shed_yes_no=$pieces[42];
		$UPS_outlet_16_load_shed_yes_no=$pieces[43];
		$UPS_ups_outlet_group_turn_off_enable=$pieces[44];
		$UPS_ups_outlet_group_turn_off_delay=$pieces[45];
		$from_email=$pieces[46];
		$shutdown_battery_voltage=$pieces[47];
		$shutdown_battery_voltage_decimal=round(($shutdown_battery_voltage*1.0)/10.0,1);
		$shutdown_run_time_hours=$pieces[48];
		$shutdown_run_time_min=$pieces[49];
		$shutdown_run_time_sec=$pieces[50];
		$max_on_battery_temp=$pieces[51];
		$max_on_battery_temp_decimal=round(($max_on_battery_temp*1.0)/10.0,1);
		$shutdown_trigger=$pieces[52];
		$load_shed_trigger=$pieces[53]; 
		$load_shed_voltage=$pieces[54];
		$load_shed_voltage_decimal=round(($load_shed_voltage*1.0)/10.0,1);	
		$pdu_load_shed_enable=$pieces[55];
		$synology_ss_load_shed_enable=$pieces[56];
		$plex_load_shed_enable=$pieces[57];
		$load_shed_run_time_hours=$pieces[58];
		$load_shed_run_time_min=$pieces[59];
		$load_shed_run_time_sec=$pieces[60];
		$enable_notifications=$pieces[61];
		$ups_email_delay=$pieces[62];
	}else{
		$UPS_monitor_runtime=0;
		$UPS_monitor_voltage=105;
		$ups_monitor_email="admin@admin.com";
		$ups_monitor_capture_interval=30;
		$UPS_url="localhost";
		$UPS_monitor_enable=0;
		$UPS_comm_loss_shutdown_interval=1200;
		$UPS_comm_loss_shutdown_enable=0;
		$UPS_PDU_IP="0.0.0.0";
		$UPS_PLEX_IP="0.0.0.0";
		$UPS_plex_installed_volume="volume1";
		
		
		
		
		
		
		$server_name=TrueNAS;
		$location_of_email_python_file="/mnt/volume1/logging/multireport_sendemail.py";
		$plex_jelly_fin_installed_on_system=0;
		$plex_container_name="plex";
		$jellyfin_container_name="jellyfin";
		$surveillance_container_name="frigate";
		
		
		
		
		$UPS_Syno_snmp_privacy_protocol=0; //unused
		$UPS_UPS_AuthPass1="password3";
		$UPS_UPS_PrivPass2="password4";
		$UPS_UPS_snmp_user="UPS_user";
		$UPS_UPS_snmp_auth_protocol="MD5";
		$UPS_UPS_snmp_privacy_protocol="AES";
		$UPS_PDU_AuthPass1="password5";
		$UPS_PDU_PrivPass2="password6";
		$UPS_PDU_snmp_user="PDU_user";
		$UPS_PDU_snmp_auth_protocol="MD5";
		$UPS_PDU_snmp_privacy_protocol="AES";
		$UPS_outlet_1_load_shed_yes_no=0;
		$UPS_outlet_2_load_shed_yes_no=0;
		$UPS_outlet_3_load_shed_yes_no=0;
		$UPS_outlet_4_load_shed_yes_no=0;
		$UPS_outlet_5_load_shed_yes_no=0;
		$UPS_outlet_6_load_shed_yes_no=0;
		$UPS_outlet_7_load_shed_yes_no=0;
		$UPS_outlet_8_load_shed_yes_no=0;
		$UPS_outlet_9_load_shed_yes_no=0;
		$UPS_outlet_10_load_shed_yes_no=0;
		$UPS_outlet_11_load_shed_yes_no=0;
		$UPS_outlet_12_load_shed_yes_no=0;
		$UPS_outlet_13_load_shed_yes_no=0;
		$UPS_outlet_14_load_shed_yes_no=0;
		$UPS_outlet_15_load_shed_yes_no=0;
		$UPS_outlet_16_load_shed_yes_no=0;
		$UPS_ups_outlet_group_turn_off_enable=0;
		$UPS_ups_outlet_group_turn_off_delay=240;
		$from_email="admin@admin.com";
		$shutdown_battery_voltage=480;
		$shutdown_battery_voltage_decimal=round(($shutdown_battery_voltage*1.0)/10.0,1);
		$shutdown_run_time_hours=0;
		$shutdown_run_time_min=15;
		$shutdown_run_time_sec=0;
		$max_on_battery_temp=100;
		$max_on_battery_temp_decimal=round(($max_on_battery_temp*1.0)/10.0,1);
		$shutdown_trigger=1;
		$load_shed_trigger=1;
		$load_shed_voltage=490;
		$load_shed_voltage_decimal=round(($load_shed_voltage*1.0)/10.0,1);	
		$pdu_load_shed_enable=0;
		$synology_ss_load_shed_enable=0;
		$plex_load_shed_enable=0;
		$load_shed_run_time_hours=0;
		$load_shed_run_time_min=20;
		$load_shed_run_time_sec=0;
		$enable_notifications=1;
		$ups_email_delay=5;
		$put_contents_string="".$UPS_monitor_runtime.",".$UPS_monitor_voltage.",".$ups_monitor_email.",".$ups_monitor_capture_interval.",".$UPS_url.",".$UPS_monitor_enable.",".$UPS_comm_loss_shutdown_interval.",".$UPS_comm_loss_shutdown_enable.",".$UPS_PDU_IP.",".$UPS_PLEX_IP.",".$UPS_plex_installed_volume.",".$server_name.",".$location_of_email_python_file.",".$plex_jelly_fin_installed_on_system.",".$plex_container_name.",".$jellyfin_container_name.",".$surveillance_container_name.",".$UPS_Syno_snmp_privacy_protocol.",".$UPS_UPS_AuthPass1.",".$UPS_UPS_PrivPass2.",".$UPS_UPS_snmp_user.",".$UPS_UPS_snmp_auth_protocol.",".$UPS_UPS_snmp_privacy_protocol.",".$UPS_PDU_AuthPass1.",".$UPS_PDU_PrivPass2.",".$UPS_PDU_snmp_user.",".$UPS_PDU_snmp_auth_protocol.",".$UPS_PDU_snmp_privacy_protocol.",".$UPS_outlet_1_load_shed_yes_no.",".$UPS_outlet_2_load_shed_yes_no.",".$UPS_outlet_3_load_shed_yes_no.",".$UPS_outlet_4_load_shed_yes_no.",".$UPS_outlet_5_load_shed_yes_no.",".$UPS_outlet_6_load_shed_yes_no.",".$UPS_outlet_7_load_shed_yes_no.",".$UPS_outlet_8_load_shed_yes_no.",".$UPS_outlet_9_load_shed_yes_no.",".$UPS_outlet_10_load_shed_yes_no.",".$UPS_outlet_10_load_shed_yes_no.",".$UPS_outlet_12_load_shed_yes_no.",".$UPS_outlet_13_load_shed_yes_no.",".$UPS_outlet_14_load_shed_yes_no.",".$UPS_outlet_15_load_shed_yes_no.",".$UPS_outlet_16_load_shed_yes_no.",".$UPS_ups_outlet_group_turn_off_enable.",".$UPS_ups_outlet_group_turn_off_delay.",".$from_email.",".$shutdown_battery_voltage.",".$shutdown_run_time_hours.",".$shutdown_run_time_min.",".$shutdown_run_time_sec.",".$max_on_battery_temp.",".$shutdown_trigger.",".$load_shed_trigger.",".$load_shed_voltage.",".$pdu_load_shed_enable.",".$synology_ss_load_shed_enable.",".$plex_load_shed_enable.",".$load_shed_run_time_hours.",".$load_shed_run_time_min.",".$load_shed_run_time_sec.",".$enable_notifications.",".$ups_email_delay."";
		  
		file_put_contents("$config_file",$put_contents_string );
	}
}
	   
print "<br>
<fieldset>
	<legend>
		<h3>$page_title</h3>
	</legend>
	<table border=\"0\">
		<tr>
			<td>";
				if ($UPS_monitor_enable==1){
					print "<font color=\"green\"><h3>Script Status: Active</h3></font>";
				}else{
					print "<font color=\"red\"><h3>Script Status: Inactive</h3></font>";
				}
print "		</td>
		</tr>
		<tr>
			<td align=\"left\">
				<form action=\"$form_submittal_destination\" method=\"post\">
					<fieldset>
						<legend>
							<b>General Settings</b>
						</legend>
						<p><input type=\"checkbox\" name=\"UPS_monitor_enable\" value=\"1\" ";
						if ($UPS_monitor_enable==1){
							print "checked";
						}
						print ">Enable Entire Script?</p>
						<p>UPS Status Polls Per Minute : <select name=\"ups_monitor_capture_interval\">";
						if ($ups_monitor_capture_interval==10){
							print "<option value=\"10\" selected>6</option>
							<option value=\"15\">4</option>
							<option value=\"30\">2</option>
							<option value=\"60\">1</option>";
						}else if ($ups_monitor_capture_interval==15){
							print "<option value=\"10\">6</option>
							<option value=\"15\" selected>4</option>
							<option value=\"30\">2</option>
							<option value=\"60\">1</option>";
						}else if ($ups_monitor_capture_interval==30){
							print "<option value=\"10\">6</option>
							<option value=\"15\">4</option>
							<option value=\"30\" selected>2</option>
							<option value=\"60\">1</option>";
						}else if ($ups_monitor_capture_interval==60){
							print "<option value=\"10\">6</option>
							<option value=\"15\">4</option>
							<option value=\"30\">2</option>
							<option value=\"60\" selected>1</option>";
						}
print "					</select></p>
						<p>UPS Minimum Input Voltage [Volts]: <input type=\"text\" maxlength=\"3\" size=\"3\" name=\"UPS_monitor_voltage\" value=".$UPS_monitor_voltage."><font size=\"1\">Ensure it is the same as the UPS activation voltage Configured on the Management Card</font> ".$UPS_monitor_voltage_error."</p>
						<p>Server Name: <input type=\"text\" name=\"server_name\" value=".$server_name."> ".$server_name_error."</p>
					</fieldset>	
					<fieldset>
						<legend>
							<b>System Shutdown Settings</b>
						</legend>
						<p>Shutdown Trigger : <select name=\"shutdown_trigger\">";
						if ($shutdown_trigger==1){
							print "<option value=\"1\" selected>UPS Run Time Remaining</option>
							<option value=\"2\">UPS Time On Battery</option>
							<option value=\"3\">UPS Run Time Remaining OR Battery Voltage</option>
							<option value=\"4\">UPS Time On Battery OR Battery Voltage</option>
							<option value=\"5\">Battery Voltage ONLY</option>";
						}else if ($shutdown_trigger==2){
							print "<option value=\"1\">UPS Run Time Remaining</option>
							<option value=\"2\" selected>UPS Time On Battery</option>
							<option value=\"3\">UPS Run Time Remaining OR Battery Voltage</option>
							<option value=\"4\">UPS Time On Battery OR Battery Voltage</option>
							<option value=\"5\">Battery Voltage ONLY</option>";
						}else if ($shutdown_trigger==3){
							print "<option value=\"1\">UPS Run Time Remaining</option>
							<option value=\"2\">UPS Time On Battery</option>
							<option value=\"3\" selected>UPS Run Time Remaining OR Battery Voltage</option>
							<option value=\"4\">UPS Time On Battery OR Battery Voltage</option>
							<option value=\"5\">Battery Voltage ONLY</option>";
						}else if ($shutdown_trigger==4){
							print "<option value=\"1\">UPS Run Time Remaining</option>
							<option value=\"2\">UPS Time On Battery</option>
							<option value=\"3\">UPS Run Time Remaining OR Battery Voltage</option>
							<option value=\"4\" selected>UPS Time On Battery OR Battery Voltage</option>
							<option value=\"5\">Battery Voltage ONLY</option>";
						}else if ($shutdown_trigger==5){
							print "<option value=\"1\">UPS Run Time Remaining</option>
							<option value=\"2\">UPS Time On Battery</option>
							<option value=\"3\">UPS Run Time Remaining OR Battery Voltage</option>
							<option value=\"4\">UPS Time On Battery OR Battery Voltage</option>
							<option value=\"5\" selected>Battery Voltage ONLY</option>";
						}
print "					</select>".$trigger_error."</p>
						<p>Battery Voltage Threshold [Volts]: <input type=\"text\" maxlength=\"4\" size=\"4\" name=\"shutdown_battery_voltage\" value=".$shutdown_battery_voltage_decimal.">".$shutdown_battery_voltage_error."</p>
						<p>Run Time: <input type=\"text\" name=\"shutdown_run_time_hours\" maxlength=\"2\" size=\"2\" value=".$shutdown_run_time_hours."> Hours <input type=\"text\" maxlength=\"2\" size=\"2\" name=\"shutdown_run_time_min\" value=".$shutdown_run_time_min."> Minuets <input type=\"text\" maxlength=\"2\" size=\"2\" name=\"shutdown_run_time_sec\" value=".$shutdown_run_time_sec."> Seconds ".$shutdown_run_time_error."</p>
						<p>Max \"ON Battery\" UPS Battery Temperature [C]: <input type=\"text\" maxlength=\"4\" size=\"4\" name=\"max_on_battery_temp\" value=".$max_on_battery_temp_decimal.">".$max_on_battery_temp_error."</p>
						<p><input type=\"checkbox\" name=\"UPS_comm_loss_shutdown_enable\" value=\"1\" ";
						if ($UPS_comm_loss_shutdown_enable==1){
							print "checked";
						}
						print ">Shutdown System <u>when on Utility Power</u> if UPS Network Communications fail after <select name=\"UPS_comm_loss_shutdown_interval\">";
						if ($UPS_comm_loss_shutdown_interval==60){
							print "<option value=\"60\" selected>1</option>
							<option value=\"120\">2</option>
							<option value=\"180\">3</option>
							<option value=\"240\">4</option>
							<option value=\"300\">5</option>
							<option value=\"360\">6</option>
							<option value=\"420\">7</option>
							<option value=\"480\">8</option>
							<option value=\"540\">9</option>
							<option value=\"600\">10</option>
							<option value=\"660\">11</option>
							<option value=\"720\">12</option>
							<option value=\"780\">13</option>
							<option value=\"840\">14</option>
							<option value=\"900\">15</option>
							<option value=\"960\">16</option>
							<option value=\"1020\">17</option>
							<option value=\"1080\">18</option>
							<option value=\"1140\">19</option>
							<option value=\"1200\">20</option>";
						}else if ($UPS_comm_loss_shutdown_interval==120){
							print "<option value=\"60\">1</option>
							<option value=\"120\" selected>2</option>
							<option value=\"180\">3</option>
							<option value=\"240\">4</option>
							<option value=\"300\">5</option>
							<option value=\"360\">6</option>
							<option value=\"420\">7</option>
							<option value=\"480\">8</option>
							<option value=\"540\">9</option>
							<option value=\"600\">10</option>
							<option value=\"660\">11</option>
							<option value=\"720\">12</option>
							<option value=\"780\">13</option>
							<option value=\"840\">14</option>
							<option value=\"900\">15</option>
							<option value=\"960\">16</option>
							<option value=\"1020\">17</option>
							<option value=\"1080\">18</option>
							<option value=\"1140\">19</option>
							<option value=\"1200\">20</option>";
						}else if ($UPS_comm_loss_shutdown_interval==180){
							print "<option value=\"60\">1</option>
							<option value=\"120\">2</option>
							<option value=\"180\" selected>3</option>
							<option value=\"240\">4</option>
							<option value=\"300\">5</option>
							<option value=\"360\">6</option>
							<option value=\"420\">7</option>
							<option value=\"480\">8</option>
							<option value=\"540\">9</option>
							<option value=\"600\">10</option>
							<option value=\"660\">11</option>
							<option value=\"720\">12</option>
							<option value=\"780\">13</option>
							<option value=\"840\">14</option>
							<option value=\"900\">15</option>
							<option value=\"960\">16</option>
							<option value=\"1020\">17</option>
							<option value=\"1080\">18</option>
							<option value=\"1140\">19</option>
							<option value=\"1200\">20</option>";
						}else if ($UPS_comm_loss_shutdown_interval==240){
							print "<option value=\"60\">1</option>
							<option value=\"120\">2</option>
							<option value=\"180\">3</option>
							<option value=\"240\" selected>4</option>
							<option value=\"300\">5</option>
							<option value=\"360\">6</option>
							<option value=\"420\">7</option>
							<option value=\"480\">8</option>
							<option value=\"540\">9</option>
							<option value=\"600\">10</option>
							<option value=\"660\">11</option>
							<option value=\"720\">12</option>
							<option value=\"780\">13</option>
							<option value=\"840\">14</option>
							<option value=\"900\">15</option>
							<option value=\"960\">16</option>
							<option value=\"1020\">17</option>
							<option value=\"1080\">18</option>
							<option value=\"1140\">19</option>
							<option value=\"1200\">20</option>";
						}else if ($UPS_comm_loss_shutdown_interval==300){
							print "<option value=\"60\">1</option>
							<option value=\"120\">2</option>
							<option value=\"180\">3</option>
							<option value=\"240\">4</option>
							<option value=\"300\" selected>5</option>
							<option value=\"360\">6</option>
							<option value=\"420\">7</option>
							<option value=\"480\">8</option>
							<option value=\"540\">9</option>
							<option value=\"600\">10</option>
							<option value=\"660\">11</option>
							<option value=\"720\">12</option>
							<option value=\"780\">13</option>
							<option value=\"840\">14</option>
							<option value=\"900\">15</option>
							<option value=\"960\">16</option>
							<option value=\"1020\">17</option>
							<option value=\"1080\">18</option>
							<option value=\"1140\">19</option>
							<option value=\"1200\">20</option>";
						}else if ($UPS_comm_loss_shutdown_interval==360){
							print "<option value=\"60\">1</option>
							<option value=\"120\">2</option>
							<option value=\"180\">3</option>
							<option value=\"240\">4</option>
							<option value=\"300\">5</option>
							<option value=\"360\" selected>6</option>
							<option value=\"420\">7</option>
							<option value=\"480\">8</option>
							<option value=\"540\">9</option>
							<option value=\"600\">10</option>
							<option value=\"660\">11</option>
							<option value=\"720\">12</option>
							<option value=\"780\">13</option>
							<option value=\"840\">14</option>
							<option value=\"900\">15</option>
							<option value=\"960\">16</option>
							<option value=\"1020\">17</option>
							<option value=\"1080\">18</option>
							<option value=\"1140\">19</option>
							<option value=\"1200\">20</option>";
						}else if ($UPS_comm_loss_shutdown_interval==420){
							print "<option value=\"60\">1</option>
							<option value=\"120\">2</option>
							<option value=\"180\">3</option>
							<option value=\"240\">4</option>
							<option value=\"300\">5</option>
							<option value=\"360\">6</option>
							<option value=\"420\" selected>7</option>
							<option value=\"480\">8</option>
							<option value=\"540\">9</option>
							<option value=\"600\">10</option>
							<option value=\"660\">11</option>
							<option value=\"720\">12</option>
							<option value=\"780\">13</option>
							<option value=\"840\">14</option>
							<option value=\"900\">15</option>
							<option value=\"960\">16</option>
							<option value=\"1020\">17</option>
							<option value=\"1080\">18</option>
							<option value=\"1140\">19</option>
							<option value=\"1200\">20</option>";
						}else if ($UPS_comm_loss_shutdown_interval==480){
							print "<option value=\"60\">1</option>
							<option value=\"120\">2</option>
							<option value=\"180\">3</option>
							<option value=\"240\">4</option>
							<option value=\"300\">5</option>
							<option value=\"360\">6</option>
							<option value=\"420\">7</option>
							<option value=\"480\" selected>8</option>
							<option value=\"540\">9</option>
							<option value=\"600\">10</option>
							<option value=\"660\">11</option>
							<option value=\"720\">12</option>
							<option value=\"780\">13</option>
							<option value=\"840\">14</option>
							<option value=\"900\">15</option>
							<option value=\"960\">16</option>
							<option value=\"1020\">17</option>
							<option value=\"1080\">18</option>
							<option value=\"1140\">19</option>
							<option value=\"1200\">20</option>";
						}else if ($UPS_comm_loss_shutdown_interval==540){
							print "<option value=\"60\">1</option>
							<option value=\"120\">2</option>
							<option value=\"180\">3</option>
							<option value=\"240\">4</option>
							<option value=\"300\">5</option>
							<option value=\"360\">6</option>
							<option value=\"420\">7</option>
							<option value=\"480\">8</option>
							<option value=\"540\" selected>9</option>
							<option value=\"600\">10</option>
							<option value=\"660\">11</option>
							<option value=\"720\">12</option>
							<option value=\"780\">13</option>
							<option value=\"840\">14</option>
							<option value=\"900\">15</option>
							<option value=\"960\">16</option>
							<option value=\"1020\">17</option>
							<option value=\"1080\">18</option>
							<option value=\"1140\">19</option>
							<option value=\"1200\">20</option>";
						}else if ($UPS_comm_loss_shutdown_interval==600){
							print "<option value=\"60\">1</option>
							<option value=\"120\">2</option>
							<option value=\"180\">3</option>
							<option value=\"240\">4</option>
							<option value=\"300\">5</option>
							<option value=\"360\">6</option>
							<option value=\"420\">7</option>
							<option value=\"480\">8</option>
							<option value=\"540\">9</option>
							<option value=\"600\" selected>10</option>
							<option value=\"660\">11</option>
							<option value=\"720\">12</option>
							<option value=\"780\">13</option>
							<option value=\"840\">14</option>
							<option value=\"900\">15</option>
							<option value=\"960\">16</option>
							<option value=\"1020\">17</option>
							<option value=\"1080\">18</option>
							<option value=\"1140\">19</option>
							<option value=\"1200\">20</option>";
						}else if ($UPS_comm_loss_shutdown_interval==660){
							print "<option value=\"60\">1</option>
							<option value=\"120\">2</option>
							<option value=\"180\">3</option>
							<option value=\"240\">4</option>
							<option value=\"300\">5</option>
							<option value=\"360\">6</option>
							<option value=\"420\">7</option>
							<option value=\"480\">8</option>
							<option value=\"540\">9</option>
							<option value=\"600\">10</option>
							<option value=\"660\" selected>11</option>
							<option value=\"720\">12</option>
							<option value=\"780\">13</option>
							<option value=\"840\">14</option>
							<option value=\"900\">15</option>
							<option value=\"960\">16</option>
							<option value=\"1020\">17</option>
							<option value=\"1080\">18</option>
							<option value=\"1140\">19</option>
							<option value=\"1200\">20</option>";
						}else if ($UPS_comm_loss_shutdown_interval==720){
							print "<option value=\"60\">1</option>
							<option value=\"120\">2</option>
							<option value=\"180\">3</option>
							<option value=\"240\">4</option>
							<option value=\"300\">5</option>
							<option value=\"360\">6</option>
							<option value=\"420\">7</option>
							<option value=\"480\">8</option>
							<option value=\"540\">9</option>
							<option value=\"600\">10</option>
							<option value=\"660\">11</option>
							<option value=\"720\" selected>12</option>
							<option value=\"780\">13</option>
							<option value=\"840\">14</option>
							<option value=\"900\">15</option>
							<option value=\"960\">16</option>
							<option value=\"1020\">17</option>
							<option value=\"1080\">18</option>
							<option value=\"1140\">19</option>
							<option value=\"1200\">20</option>";
						}else if ($UPS_comm_loss_shutdown_interval==780){
							print "<option value=\"60\">1</option>
							<option value=\"120\">2</option>
							<option value=\"180\">3</option>
							<option value=\"240\">4</option>
							<option value=\"300\">5</option>
							<option value=\"360\">6</option>
							<option value=\"420\">7</option>
							<option value=\"480\">8</option>
							<option value=\"540\">9</option>
							<option value=\"600\">10</option>
							<option value=\"660\">11</option>
							<option value=\"720\">12</option>
							<option value=\"780\" selected>13</option>
							<option value=\"840\">14</option>
							<option value=\"900\">15</option>
							<option value=\"960\">16</option>
							<option value=\"1020\">17</option>
							<option value=\"1080\">18</option>
							<option value=\"1140\">19</option>
							<option value=\"1200\">20</option>";
						}else if ($UPS_comm_loss_shutdown_interval==840){
							print "<option value=\"60\">1</option>
							<option value=\"120\">2</option>
							<option value=\"180\">3</option>
							<option value=\"240\">4</option>
							<option value=\"300\">5</option>
							<option value=\"360\">6</option>
							<option value=\"420\">7</option>
							<option value=\"480\">8</option>
							<option value=\"540\">9</option>
							<option value=\"600\">10</option>
							<option value=\"660\">11</option>
							<option value=\"720\">12</option>
							<option value=\"780\">13</option>
							<option value=\"840\" selected>14</option>
							<option value=\"900\">15</option>
							<option value=\"960\">16</option>
							<option value=\"1020\">17</option>
							<option value=\"1080\">18</option>
							<option value=\"1140\">19</option>
							<option value=\"1200\">20</option>";
						}else if ($UPS_comm_loss_shutdown_interval==900){
							print "<option value=\"10\"d>10</option>
							<option value=\"120\">2</option>
							<option value=\"180\">3</option>
							<option value=\"240\">4</option>
							<option value=\"300\">5</option>
							<option value=\"360\">6</option>
							<option value=\"420\">7</option>
							<option value=\"480\">8</option>
							<option value=\"540\">9</option>
							<option value=\"600\">10</option>
							<option value=\"660\">11</option>
							<option value=\"720\">12</option>
							<option value=\"780\">13</option>
							<option value=\"840\">14</option>
							<option value=\"900\" selected>15</option>
							<option value=\"960\">16</option>
							<option value=\"1020\">17</option>
							<option value=\"1080\">18</option>
							<option value=\"1140\">19</option>
							<option value=\"1200\">20</option>";
						}else if ($UPS_comm_loss_shutdown_interval==960){
							print "<option value=\"60\">1</option>
							<option value=\"120\">2</option>
							<option value=\"180\">3</option>
							<option value=\"240\">4</option>
							<option value=\"300\">5</option>
							<option value=\"360\">6</option>
							<option value=\"420\">7</option>
							<option value=\"480\">8</option>
							<option value=\"540\">9</option>
							<option value=\"600\">10</option>
							<option value=\"660\">11</option>
							<option value=\"720\">120/option>
							<option value=\"780\">13</option>
							<option value=\"840\">14</option>
							<option value=\"900\">15</option>
							<option value=\"960\" selected>16</option>
							<option value=\"1020\">17</option>
							<option value=\"1080\">18</option>
							<option value=\"1140\">19</option>
							<option value=\"1200\">20</option>";
						}else if ($UPS_comm_loss_shutdown_interval==120){
							print "<option value=\"60\">1</option>
							<option value=\"120\">2</option>
							<option value=\"180\">3</option>
							<option value=\"240\">4</option>
							<option value=\"300\">5</option>
							<option value=\"360\">6</option>
							<option value=\"420\">7</option>
							<option value=\"480\">8</option>
							<option value=\"540\">9</option>
							<option value=\"600\">10</option>
							<option value=\"660\">11</option>
							<option value=\"720\">12</option>
							<option value=\"780\">13</option>
							<option value=\"840\">14</option>
							<option value=\"900\">15</option>
							<option value=\"960\">16</option>
							<option value=\"1020\" selected>17</option>
							<option value=\"1080\">18</option>
							<option value=\"1140\">19</option>
							<option value=\"1200\">20</option>";
						}else if ($UPS_comm_loss_shutdown_interval==1080){
							print "<option value=\"60\">1</option>
							<option value=\"120\">2</option>
							<option value=\"180\">3</option>
							<option value=\"240\">4</option>
							<option value=\"300\">5</option>
							<option value=\"360\">6</option>
							<option value=\"420\">7</option>
							<option value=\"480\">8</option>
							<option value=\"540\">9</option>
							<option value=\"600\">10</option>
							<option value=\"660\">11</option>
							<option value=\"720\">12</option>
							<option value=\"780\">13</option>
							<option value=\"840\">14</option>
							<option value=\"900\">15</option>
							<option value=\"960\">16</option>
							<option value=\"1020\">17</option>
							<option value=\"1080\" selected>18</option>
							<option value=\"1140\">19</option>
							<option value=\"1200\">20</option>";
						}else if ($UPS_comm_loss_shutdown_interval==1140){
							print "<option value=\"60\">1</option>
							<option value=\"120\">2</option>
							<option value=\"180\">3</option>
							<option value=\"240\">4</option>
							<option value=\"300\">5</option>
							<option value=\"360\">6</option>
							<option value=\"420\">7</option>
							<option value=\"480\">8</option>
							<option value=\"540\">9</option>
							<option value=\"600\">10</option>
							<option value=\"660\">11</option>
							<option value=\"720\">12</option>
							<option value=\"780\">13</option>
							<option value=\"840\">14</option>
							<option value=\"900\">15</option>
							<option value=\"960\">16</option>
							<option value=\"1020\">17</option>
							<option value=\"1080\">18</option>
							<option value=\"1140\" selected>19</option>
							<option value=\"1200\">20</option>";
						}else if ($UPS_comm_loss_shutdown_interval==1200){
							print "<option value=\"60\">1</option>
							<option value=\"120\">2</option>
							<option value=\"180\">3</option>
							<option value=\"240\">4</option>
							<option value=\"300\">5</option>
							<option value=\"360\">6</option>
							<option value=\"420\">7</option>
							<option value=\"480\">8</option>
							<option value=\"540\">9</option>
							<option value=\"600\">10</option>
							<option value=\"660\">11</option>
							<option value=\"720\">12</option>
							<option value=\"780\">13</option>
							<option value=\"840\">14</option>
							<option value=\"900\">15</option>
							<option value=\"960\">16</option>
							<option value=\"1020\">17</option>
							<option value=\"1080\">18</option>
							<option value=\"1140\">19</option>
							<option value=\"1200\" selected>20</option>";
						}
print "					</select> Hours</p>
						<p><input type=\"checkbox\" name=\"UPS_ups_outlet_group_turn_off_enable\" value=\"1\" ";
						if ($UPS_ups_outlet_group_turn_off_enable==1){
							print "checked";
						}
						print ">Enable UPS Outlet Group Turn-Off <select name=\"UPS_ups_outlet_group_turn_off_delay\">";
						if ($UPS_ups_outlet_group_turn_off_delay==60){
							print "<option value=\"60\" selected>1</option>
							<option value=\"120\">2</option>
							<option value=\"180\">3</option>
							<option value=\"240\">4</option>
							<option value=\"300\">5</option>
							<option value=\"360\">6</option>
							<option value=\"420\">7</option>
							<option value=\"480\">8</option>
							<option value=\"540\">9</option>
							<option value=\"600\">10</option>
							<option value=\"660\">11</option>
							<option value=\"720\">12</option>
							<option value=\"780\">13</option>
							<option value=\"840\">14</option>
							<option value=\"900\">15</option>";
						}else if ($UPS_ups_outlet_group_turn_off_delay==120){
							print "<option value=\"60\">1</option>
							<option value=\"120\" selected>2</option>
							<option value=\"180\">3</option>
							<option value=\"240\">4</option>
							<option value=\"300\">5</option>
							<option value=\"360\">6</option>
							<option value=\"420\">7</option>
							<option value=\"480\">8</option>
							<option value=\"540\">9</option>
							<option value=\"600\">10</option>
							<option value=\"660\">11</option>
							<option value=\"720\">12</option>
							<option value=\"780\">13</option>
							<option value=\"840\">14</option>
							<option value=\"900\">15</option>";
						}else if ($UPS_ups_outlet_group_turn_off_delay==180){
							print "<option value=\"60\">1</option>
							<option value=\"120\">2</option>
							<option value=\"180\" selected>3</option>
							<option value=\"240\">4</option>
							<option value=\"300\">5</option>
							<option value=\"360\">6</option>
							<option value=\"420\">7</option>
							<option value=\"480\">8</option>
							<option value=\"540\">9</option>
							<option value=\"600\">10</option>
							<option value=\"660\">11</option>
							<option value=\"720\">12</option>
							<option value=\"780\">13</option>
							<option value=\"840\">14</option>
							<option value=\"900\">15</option>";
						}else if ($UPS_ups_outlet_group_turn_off_delay==240){
							print "<option value=\"60\">1</option>
							<option value=\"120\">2</option>
							<option value=\"180\">3</option>
							<option value=\"240\" selected>4</option>
							<option value=\"300\">5</option>
							<option value=\"360\">6</option>
							<option value=\"420\">7</option>
							<option value=\"480\">8</option>
							<option value=\"540\">9</option>
							<option value=\"600\">10</option>
							<option value=\"660\">11</option>
							<option value=\"720\">12</option>
							<option value=\"780\">13</option>
							<option value=\"840\">14</option>
							<option value=\"900\">15</option>";
						}else if ($UPS_ups_outlet_group_turn_off_delay==300){
							print "<option value=\"60\">1</option>
							<option value=\"120\">2</option>
							<option value=\"180\">3</option>
							<option value=\"240\">4</option>
							<option value=\"300\" selected>5</option>
							<option value=\"360\">6</option>
							<option value=\"420\">7</option>
							<option value=\"480\">8</option>
							<option value=\"540\">9</option>
							<option value=\"600\">10</option>
							<option value=\"660\">11</option>
							<option value=\"720\">12</option>
							<option value=\"780\">13</option>
							<option value=\"840\">14</option>
							<option value=\"900\">15</option>";
						}else if ($UPS_ups_outlet_group_turn_off_delay==360){
							print "<option value=\"60\">1</option>
							<option value=\"120\">2</option>
							<option value=\"180\">3</option>
							<option value=\"240\">4</option>
							<option value=\"300\">5</option>
							<option value=\"360\" selected>6</option>
							<option value=\"420\">7</option>
							<option value=\"480\">8</option>
							<option value=\"540\">9</option>
							<option value=\"600\">10</option>
							<option value=\"660\">11</option>
							<option value=\"720\">12</option>
							<option value=\"780\">13</option>
							<option value=\"840\">14</option>
							<option value=\"900\">15</option>";
						}else if ($UPS_ups_outlet_group_turn_off_delay==420){
							print "<option value=\"60\">1</option>
							<option value=\"120\">2</option>
							<option value=\"180\">3</option>
							<option value=\"240\">4</option>
							<option value=\"300\">5</option>
							<option value=\"360\">6</option>
							<option value=\"420\" selected>7</option>
							<option value=\"480\">8</option>
							<option value=\"540\">9</option>
							<option value=\"600\">10</option>
							<option value=\"660\">11</option>
							<option value=\"720\">12</option>
							<option value=\"780\">13</option>
							<option value=\"840\">14</option>
							<option value=\"900\">15</option>";
						}else if ($UPS_ups_outlet_group_turn_off_delay==480){
							print "<option value=\"60\">1</option>
							<option value=\"120\">2</option>
							<option value=\"180\">3</option>
							<option value=\"240\">4</option>
							<option value=\"300\">5</option>
							<option value=\"360\">6</option>
							<option value=\"420\">7</option>
							<option value=\"480\" selected>8</option>
							<option value=\"540\">9</option>
							<option value=\"600\">10</option>
							<option value=\"660\">11</option>
							<option value=\"720\">12</option>
							<option value=\"780\">13</option>
							<option value=\"840\">14</option>
							<option value=\"900\">15</option>";
						}else if ($UPS_ups_outlet_group_turn_off_delay==540){
							print "<option value=\"60\">1</option>
							<option value=\"120\">2</option>
							<option value=\"180\">3</option>
							<option value=\"240\">4</option>
							<option value=\"300\">5</option>
							<option value=\"360\">6</option>
							<option value=\"420\">7</option>
							<option value=\"480\">8</option>
							<option value=\"540\" selected>9</option>
							<option value=\"600\">10</option>
							<option value=\"660\">11</option>
							<option value=\"720\">12</option>
							<option value=\"780\">13</option>
							<option value=\"840\">14</option>
							<option value=\"900\">15</option>";
						}else if ($UPS_ups_outlet_group_turn_off_delay==600){
							print "<option value=\"60\">1</option>
							<option value=\"120\">2</option>
							<option value=\"180\">3</option>
							<option value=\"240\">4</option>
							<option value=\"300\">5</option>
							<option value=\"360\">6</option>
							<option value=\"420\">7</option>
							<option value=\"480\">8</option>
							<option value=\"540\">9</option>
							<option value=\"600\" selected>10</option>
							<option value=\"660\">11</option>
							<option value=\"720\">12</option>
							<option value=\"780\">13</option>
							<option value=\"840\">14</option>
							<option value=\"900\">15</option>";
						}else if ($UPS_ups_outlet_group_turn_off_delay==660){
							print "<option value=\"60\">1</option>
							<option value=\"120\">2</option>
							<option value=\"180\">3</option>
							<option value=\"240\">4</option>
							<option value=\"300\">5</option>
							<option value=\"360\">6</option>
							<option value=\"420\">7</option>
							<option value=\"480\">8</option>
							<option value=\"540\">9</option>
							<option value=\"600\">10</option>
							<option value=\"660\" selected>11</option>
							<option value=\"720\">12</option>
							<option value=\"780\">13</option>
							<option value=\"840\">14</option>
							<option value=\"900\">15</option>";
						}else if ($UPS_ups_outlet_group_turn_off_delay==720){
							print "<option value=\"60\">1</option>
							<option value=\"120\">2</option>
							<option value=\"180\">3</option>
							<option value=\"240\">4</option>
							<option value=\"300\">5</option>
							<option value=\"360\">6</option>
							<option value=\"420\">7</option>
							<option value=\"480\">8</option>
							<option value=\"540\">9</option>
							<option value=\"600\">10</option>
							<option value=\"660\">11</option>
							<option value=\"720\" selected>12</option>
							<option value=\"780\">13</option>
							<option value=\"840\">14</option>
							<option value=\"900\">15</option>";
						}else if ($UPS_ups_outlet_group_turn_off_delay==780){
							print "<option value=\"60\">1</option>
							<option value=\"120\">2</option>
							<option value=\"180\">3</option>
							<option value=\"240\">4</option>
							<option value=\"300\">5</option>
							<option value=\"360\">6</option>
							<option value=\"420\">7</option>
							<option value=\"480\">8</option>
							<option value=\"540\">9</option>
							<option value=\"600\">10</option>
							<option value=\"660\">11</option>
							<option value=\"720\">12</option>
							<option value=\"780\" selected>13</option>
							<option value=\"840\">14</option>
							<option value=\"900\">15</option>";
						}else if ($UPS_ups_outlet_group_turn_off_delay==840){
							print "<option value=\"60\">1</option>
							<option value=\"120\">2</option>
							<option value=\"180\">3</option>
							<option value=\"240\">4</option>
							<option value=\"300\">5</option>
							<option value=\"360\">6</option>
							<option value=\"420\">7</option>
							<option value=\"480\">8</option>
							<option value=\"540\">9</option>
							<option value=\"600\">10</option>
							<option value=\"660\">11</option>
							<option value=\"720\">12</option>
							<option value=\"780\">13</option>
							<option value=\"840\" selected>14</option>
							<option value=\"900\">15</option>";
						}else if ($UPS_ups_outlet_group_turn_off_delay==900){
							print "<option value=\"60\"d>1</option>
							<option value=\"120\">2</option>
							<option value=\"180\">3</option>
							<option value=\"240\">4</option>
							<option value=\"300\">5</option>
							<option value=\"360\">6</option>
							<option value=\"420\">7</option>
							<option value=\"480\">8</option>
							<option value=\"540\">9</option>
							<option value=\"600\">10</option>
							<option value=\"660\">11</option>
							<option value=\"720\">12</option>
							<option value=\"780\">13</option>
							<option value=\"840\">14</option>
							<option value=\"900\" selected>15</option>";
						}
	print "				</select> Minuets After System Shutdown is Commanded</p>
						
					</fieldset>	
					<fieldset>
						<legend>
							<b>Load Shed Settings</b>
						</legend>
						<p><input type=\"checkbox\" name=\"pdu_load_shed_enable\" value=\"1\" ";
						if ($pdu_load_shed_enable==1){
							print "checked";
						}
						print ">Enable Load Shed Control of Power Distribution Unit (PDU) Outlets</p>
						<p>POWER DISTRIBUTION UNIT (PDU) OUTLES TO TURN OFF DURING LOAD SHED</p>
						<table border=\"1\">
							<tr>
								<td>
									<input type=\"checkbox\" name=\"UPS_outlet_1_load_shed_yes_no\" value=\"1\" ";
									if ($UPS_outlet_1_load_shed_yes_no==1){
										print "checked";
									}
									print "> 1 
								</td>
								<td>
									<input type=\"checkbox\" name=\"UPS_outlet_2_load_shed_yes_no\" value=\"1\" ";
									if ($UPS_outlet_2_load_shed_yes_no==1){
										print "checked";
									}
									print "> 2 
								</td>
								<td>
									<input type=\"checkbox\" name=\"UPS_outlet_3_load_shed_yes_no\" value=\"1\" ";
									if ($UPS_outlet_3_load_shed_yes_no==1){
										print "checked";
									}
									print "> 3 
								</td>
								<td>
									<input type=\"checkbox\" name=\"UPS_outlet_4_load_shed_yes_no\" value=\"1\" ";
									if ($UPS_outlet_4_load_shed_yes_no==1){
										print "checked";
									}
									print "> 4 
								</td>
								<td>
									<input type=\"checkbox\" name=\"UPS_outlet_5_load_shed_yes_no\" value=\"1\" ";
									if ($UPS_outlet_5_load_shed_yes_no==1){
										print "checked";
									}
									print "> 5 
								</td>
								<td>
									<input type=\"checkbox\" name=\"UPS_outlet_6_load_shed_yes_no\" value=\"1\" ";
									if ($UPS_outlet_6_load_shed_yes_no==1){
										print "checked";
									}
									print "> 6 
								</td>
								<td>
									<input type=\"checkbox\" name=\"UPS_outlet_7_load_shed_yes_no\" value=\"1\" ";
									if ($UPS_outlet_7_load_shed_yes_no==1){
										print "checked";
									}
									print "> 7 
								</td>
								<td>
									<input type=\"checkbox\" name=\"UPS_outlet_8_load_shed_yes_no\" value=\"1\" ";
									if ($UPS_outlet_8_load_shed_yes_no==1){
										print "checked";
									}
									print "> 8 
								</td>
							</tr>
							<tr>
								<td>
									<input type=\"checkbox\" name=\"UPS_outlet_9_load_shed_yes_no\" value=\"1\" ";
									if ($UPS_outlet_9_load_shed_yes_no==1){
										print "checked";
									}
									print "> 9 
								</td>
								<td>
									<input type=\"checkbox\" name=\"UPS_outlet_10_load_shed_yes_no\" value=\"1\" ";
									if ($UPS_outlet_10_load_shed_yes_no==1){
										print "checked";
									}
									print "> 10 
								</td>
								<td>
									<input type=\"checkbox\" name=\"UPS_outlet_11_load_shed_yes_no\" value=\"1\" ";
									if ($UPS_outlet_11_load_shed_yes_no==1){
										print "checked";
									}
									print "> 11 
								</td>
								<td>
									<input type=\"checkbox\" name=\"UPS_outlet_12_load_shed_yes_no\" value=\"1\" ";
									if ($UPS_outlet_12_load_shed_yes_no==1){
										print "checked";
									}
									print "> 12 
								</td>
								<td>
									<input type=\"checkbox\" name=\"UPS_outlet_13_load_shed_yes_no\" value=\"1\" ";
									if ($UPS_outlet_13_load_shed_yes_no==1){
										print "checked";
									}
									print "> 13 
								</td>
								<td>
									<input type=\"checkbox\" name=\"UPS_outlet_14_load_shed_yes_no\" value=\"1\" ";
									if ($UPS_outlet_14_load_shed_yes_no==1){
										print "checked";
									}
									print "> 14 
								</td>
								<td>
									<input type=\"checkbox\" name=\"UPS_outlet_15_load_shed_yes_no\" value=\"1\" ";
									if ($UPS_outlet_15_load_shed_yes_no==1){
										print "checked";
									}
									print "> 15 
								</td>
								<td>
									<input type=\"checkbox\" name=\"UPS_outlet_16_load_shed_yes_no\" value=\"1\" ";
									if ($UPS_outlet_16_load_shed_yes_no==1){
										print "checked";
									}
									print "> 16 
								</td>
							<tr>
						</table>
						
						<p><input type=\"checkbox\" name=\"synology_ss_load_shed_enable\" value=\"1\" ";
						if ($synology_ss_load_shed_enable==1){
							print "checked";
						}
						print ">Enable Load Shed of Surveillance Docker Container ".$trigger_error."</p>
						<p>Load Shed - Surveillance Docker Container Name: <input type=\"text\" name=\"surveillance_container_name\" value=".$surveillance_container_name."><font size=\"1\">Do not include lead slash \"/\". If Surveillance Container is not installed on the system, leave as default</font> ".$surveillance_container_name_error."</p>
						<p><input type=\"checkbox\" name=\"plex_jelly_fin_installed_on_system\" value=\"1\" ";
						if ($plex_jelly_fin_installed_on_system==1){
							print "checked";
						}
						print ">Plex and or JellyFin Docker Apps Installed on System?".$trigger_error."</p>
						<p><input type=\"checkbox\" name=\"plex_load_shed_enable\" value=\"1\" ";
						if ($plex_load_shed_enable==1){
							print "checked";
						}
						print ">Enable Load Shed of PLEX and or JellyFin Docker Containers ".$trigger_error."</p>
						<p>Load Shed - Plex Media Server IP Address: <input type=\"text\" name=\"UPS_PLEX_IP\" value=".$UPS_PLEX_IP."><font size=\"1\">If PLEX is not installed on the system, leave as default</font> ".$UPS_PLEX_IP_error."</p>
						<p>Load Shed - Plex Media Server Installed Volume: <input type=\"text\" name=\"UPS_plex_installed_volume\" value=".$UPS_plex_installed_volume."><font size=\"1\">Do not include lead slash \"/\". If PLEX is not installed on the system, leave as default</font> ".$UPS_plex_installed_volume_error."</p>
						
						<p>Load Shed - Plex Media Server Docker Container Name: <input type=\"text\" name=\"plex_container_name\" value=".$plex_container_name."><font size=\"1\">Do not include lead slash \"/\". If PLEX is not installed on the system, leave as default</font> ".$plex_container_name_error."</p>
						<p>Load Shed - JellyFin Docker Container Name: <input type=\"text\" name=\"jellyfin_container_name\" value=".$jellyfin_container_name."><font size=\"1\">Do not include lead slash \"/\". If JellyFin is not installed on the system, leave as default</font> ".$jellyfin_container_name_error."</p>
						
						
						
						<p>Load Shed Trigger : <select name=\"load_shed_trigger\">";
						if ($load_shed_trigger==1){
							print "<option value=\"1\" selected>UPS Run Time Remaining</option>
							<option value=\"2\">UPS Time On Battery</option>
							<option value=\"3\">UPS Run Time Remaining OR Battery Voltage</option>
							<option value=\"4\">UPS Time On Battery OR Battery Voltage</option>
							<option value=\"5\">Battery Voltage ONLY</option>";
						}else if ($load_shed_trigger==2){
							print "<option value=\"1\">UPS Run Time Remaining</option>
							<option value=\"2\" selected>UPS Time On Battery</option>
							<option value=\"3\">UPS Run Time Remaining OR Battery Voltage</option>
							<option value=\"4\">UPS Time On Battery OR Battery Voltage</option>
							<option value=\"5\">Battery Voltage ONLY</option>";
						}else if ($load_shed_trigger==3){
							print "<option value=\"1\">UPS Run Time Remaining</option>
							<option value=\"2\">UPS Time On Battery</option>
							<option value=\"3\" selected>UPS Run Time Remaining OR Battery Voltage</option>
							<option value=\"4\">UPS Time On Battery OR Battery Voltage</option>
							<option value=\"5\">Battery Voltage ONLY</option>";
						}else if ($load_shed_trigger==4){
							print "<option value=\"1\">UPS Run Time Remaining</option>
							<option value=\"2\">UPS Time On Battery</option>
							<option value=\"3\">UPS Run Time Remaining OR Battery Voltage</option>
							<option value=\"4\" selected>UPS Time On Battery OR Battery Voltage</option>
							<option value=\"5\">Battery Voltage ONLY</option>";
						}else if ($load_shed_trigger==5){
							print "<option value=\"1\">UPS Run Time Remaining</option>
							<option value=\"2\">UPS Time On Battery</option>
							<option value=\"3\">UPS Run Time Remaining OR Battery Voltage</option>
							<option value=\"4\">UPS Time On Battery OR Battery Voltage</option>
							<option value=\"5\" selected>Battery Voltage ONLY</option>";
						}
print "					</select>".$trigger_error."</p>
						<p>Battery Voltage Threshold [Volts]: <input type=\"text\" maxlength=\"4\" size=\"4\" name=\"load_shed_voltage\" value=".$load_shed_voltage_decimal.">".$load_shed_voltage_error."</p>
						<p>Run Time: <input type=\"text\" maxlength=\"2\" size=\"2\" name=\"load_shed_run_time_hours\" value=".$load_shed_run_time_hours."> Hours <input type=\"text\" maxlength=\"2\" size=\"2\" name=\"load_shed_run_time_min\" value=".$load_shed_run_time_min."> Minuets <input type=\"text\" maxlength=\"2\" size=\"2\" name=\"load_shed_run_time_sec\" value=".$load_shed_run_time_sec."> Seconds ".$load_shed_run_time_error."</p>

					</fieldset>
					<fieldset>
						<legend>
							<b>Email Notification Settings</b>
						</legend>	
						<p>Alert Email Recipient: <input type=\"text\" name=\"ups_monitor_email\" value=".$ups_monitor_email."><font size=\"1\">Separate Addresses by a semicolon</font> ".$ups_monitor_email_error."</p>
						<p>From Email: <input type=\"text\" name=\"from_email\" value=".$from_email."> ".$from_email_error."</p>
						<p><input type=\"checkbox\" name=\"enable_notifications\" value=\"1\" ";
						if ($enable_notifications==1){
							print "checked";
						}
						print ">Enable Email Notifications ".$ups_email_delay_error."</p>
						<p>Email Notification Every: <input type=\"text\" maxlength=\"2\" size=\"2\" name=\"ups_email_delay\" value=".$ups_email_delay."> Minuets ".$ups_email_delay_error."</p>
						<p>Email Script File Location: <input type=\"text\" name=\"location_of_email_python_file\" value=".$location_of_email_python_file.">".$location_of_email_python_file_error."</p>
					</fieldset>
					<fieldset>
						<legend>
							<b>SNMP Settings</b>
						</legend>	
						<p><u>UPS NMC SNMP SETTINGS</u></p>	
						<p>UPS IP: <input type=\"text\" name=\"UPS_url\" value=".$UPS_url."> ".$UPS_monitor_url_error."</p>
						<p>Authorization Password: <input type=\"text\" name=\"UPS_UPS_AuthPass1\" value=".$UPS_UPS_AuthPass1."> ".$UPS_UPS_AuthPass1_error."</p>
						<p>Privacy Password: <input type=\"text\" name=\"UPS_UPS_PrivPass2\" value=".$UPS_UPS_PrivPass2."> ".$UPS_UPS_PrivPass2_error."</p>
						<p>User Name: <input type=\"text\" name=\"UPS_UPS_snmp_user\" value=".$UPS_UPS_snmp_user."> ".$UPS_UPS_snmp_user_error." </p>
						<p>Authorization Protocol: <select name=\"UPS_UPS_snmp_auth_protocol\">";
						if ($UPS_UPS_snmp_auth_protocol=="MD5"){
							print "<option value=\"MD5\" selected>MD5</option>
							<option value=\"SHA\">SHA</option>";
						}else if ($UPS_UPS_snmp_auth_protocol=="SHA"){
							print "<option value=\"MD5\">MD5</option>
							<option value=\"SHA\" selected>SHA</option>";
						}
print "					</select></p>
						<p>Privacy Protocol: <select name=\"UPS_UPS_snmp_privacy_protocol\">";
						if ($UPS_UPS_snmp_privacy_protocol=="AES"){
							print "<option value=\"AES\" selected>AES</option>
							<option value=\"DES\">DES</option>";
						}else if ($UPS_UPS_snmp_privacy_protocol=="DES"){
							print "<option value=\"AES\">AES</option>
							<option value=\"DES\" selected>DES</option>";
						}
print "					</select></p>
						<br>
						<p><u>POWER DISTRIBUTION UNIT (PDU) SNMP SETTINGS</u></p>
						<p>Power Distribution Unit (PDU) IP: <input type=\"text\" name=\"UPS_PDU_IP\" value=".$UPS_PDU_IP."><font size=\"1\">If no PDU is used, leave as default</font> ".$UPS_PDU_IP_error."</p>
						<p>Authorization Password: <input type=\"text\" name=\"UPS_PDU_AuthPass1\" value=".$UPS_PDU_AuthPass1."><font size=\"1\">If no PDU is used, leave as default</font> ".$UPS_PDU_AuthPass1_error."</p>
						<p>Privacy Password: <input type=\"text\" name=\"UPS_PDU_PrivPass2\" value=".$UPS_PDU_PrivPass2."><font size=\"1\">If no PDU is used, leave as default</font> ".$UPS_PDU_PrivPass2_error."</p>
						<p>User Name: <input type=\"text\" name=\"UPS_PDU_snmp_user\" value=".$UPS_PDU_snmp_user."><font size=\"1\">If no PDU is used, leave as default</font> ".$UPS_PDU_snmp_user_error."</p>
						<p>Authorization Protocol: <select name=\"UPS_PDU_snmp_auth_protocol\">";
						if ($UPS_PDU_snmp_auth_protocol=="MD5"){
							print "<option value=\"MD5\" selected>MD5</option>
							<option value=\"SHA\">SHA</option>";
						}else if ($UPS_PDU_snmp_auth_protocol=="SHA"){
							print "<option value=\"MD5\">MD5</option>
							<option value=\"SHA\" selected>SHA</option>";
						}
print "					</select></p>
						<p>Privacy Protocol: <select name=\"UPS_PDU_snmp_privacy_protocol\">";
						if ($UPS_PDU_snmp_privacy_protocol=="AES"){
							print "<option value=\"AES\" selected>AES</option>
							<option value=\"DES\">DES</option>";
						}else if ($UPS_PDU_snmp_privacy_protocol=="DES"){
							print "<option value=\"AES\">AES</option>
							<option value=\"DES\" selected>DES</option>";
						}
print "					</select></p>
					</fieldset>
					<center><input type=\"submit\" name=\"submit_ups_monitor\" value=\"Submit\" /></center>
				</form>
			</td>
		</tr>
	</table>
</fieldset>";
?>
