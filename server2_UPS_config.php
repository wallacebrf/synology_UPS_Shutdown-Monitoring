<?php
//Version 6/30/2022
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

$config_file="/volume1/web/config/config_files/config_files_local/server2_UPS_monitor_config2.txt";
$use_login_sessions=true; //set to false if not using user login sessions
$form_submittal_destination="index.php?page=6&config_page=server2_ups_monitor"; //set to the destination the HTML form submital should be directed to
$page_title="Server2 Network UPS Shutdown Monitoring Configuration Settings";

///////////////////////////////////////////////////
//Beginning of configuration page
///////////////////////////////////////////////////
if($use_login_sessions){


	if($_SERVER['HTTPS']!="on") {

	$redirect= "https://".$_SERVER['HTTP_HOST'].$_SERVER['REQUEST_URI'];

	header("Location:$redirect"); } 

	// Initialize the session
	if(session_status() !== PHP_SESSION_ACTIVE) session_start();
	 
	// Check if the user is logged in, if not then redirect him to login page
	if(!isset($_SESSION["loggedin"]) || $_SESSION["loggedin"] !== true){
		header("location: login.php");
		exit;
	}
}
error_reporting(E_ALL ^ E_NOTICE);
include $_SERVER['DOCUMENT_ROOT']."/functions.php";
$ups_monitor_email_error="";
$UPS_monitor_url_error="";
$UPS_monitor_runtime_error="";
$UPS_monitor_voltage_error="";
$UPS_PDU_IP_error="";
$UPS_PLEX_IP_error="";
$UPS_plex_installed_volume_error="";
$UPS_load_shed_early_time_error="";
$UPS_Syno_AuthPass1_error="";
$UPS_Syno_PrivPass2_error="";
$UPS_Syno_snmp_user_error="";
$UPS_UPS_AuthPass1_error="";
$UPS_UPS_PrivPass2_error="";
$UPS_UPS_snmp_user_error="";
$UPS_PDU_AuthPass1_error="";
$UPS_PDU_PrivPass2_error="";
$UPS_PDU_snmp_user_error="";
$generic_error="";
$from_email_error="";
	
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
		   
		   //perform data verification of submitted values
	if ($_POST['UPS_Syno_snmp_auth_protocol']=="MD5" || $_POST['UPS_Syno_snmp_auth_protocol']=="SHA"){
		[$UPS_Syno_snmp_auth_protocol, $generic_error] = test_input_processing($_POST['UPS_Syno_snmp_auth_protocol'], $pieces[16], "name", 0, 0);
	}else{
		$UPS_Syno_snmp_auth_protocol=$pieces[16];
	}
		   
	[$UPS_Syno_snmp_user, $UPS_Syno_snmp_user_error] = test_input_processing($_POST['UPS_Syno_snmp_user'], $pieces[15], "name", 0, 0);
		
	[$UPS_Syno_PrivPass2, $UPS_Syno_PrivPass2_error] = test_input_processing($_POST['UPS_Syno_PrivPass2'], $pieces[14], "password", 0, 0);
		  
	[$UPS_Syno_AuthPass1, $UPS_Syno_AuthPass1_error] = test_input_processing($_POST['UPS_Syno_AuthPass1'], $pieces[13], "password", 0, 0);   
		  
	[$UPS_load_shed_control, $generic_error] = test_input_processing($_POST['UPS_load_shed_control'], "", "checkbox", 0, 0);   

	[$UPS_load_shed_early_time, $UPS_load_shed_early_time_error] = test_input_processing($_POST['UPS_load_shed_early_time'], $pieces[11], "numeric", 1, 15);   
		   
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
	  
	$put_contents_string="".$UPS_monitor_runtime.",".$UPS_monitor_voltage.",".$ups_monitor_email.",".$ups_monitor_capture_interval.",".$UPS_url.",".$UPS_monitor_enable.",".$UPS_comm_loss_shutdown_interval.",".$UPS_comm_loss_shutdown_enable.",".$UPS_PDU_IP.",".$UPS_PLEX_IP.",".$UPS_plex_installed_volume.",".$UPS_load_shed_early_time.",".$UPS_load_shed_control.",".$UPS_Syno_AuthPass1.",".$UPS_Syno_PrivPass2.",".$UPS_Syno_snmp_user.",".$UPS_Syno_snmp_auth_protocol.",".$UPS_Syno_snmp_privacy_protocol.",".$UPS_UPS_AuthPass1.",".$UPS_UPS_PrivPass2.",".$UPS_UPS_snmp_user.",".$UPS_UPS_snmp_auth_protocol.",".$UPS_UPS_snmp_privacy_protocol.",".$UPS_PDU_AuthPass1.",".$UPS_PDU_PrivPass2.",".$UPS_PDU_snmp_user.",".$UPS_PDU_snmp_auth_protocol.",".$UPS_PDU_snmp_privacy_protocol.",".$UPS_outlet_1_load_shed_yes_no.",".$UPS_outlet_2_load_shed_yes_no.",".$UPS_outlet_3_load_shed_yes_no.",".$UPS_outlet_4_load_shed_yes_no.",".$UPS_outlet_5_load_shed_yes_no.",".$UPS_outlet_6_load_shed_yes_no.",".$UPS_outlet_7_load_shed_yes_no.",".$UPS_outlet_8_load_shed_yes_no.",".$UPS_outlet_9_load_shed_yes_no.",".$UPS_outlet_10_load_shed_yes_no.",".$UPS_outlet_11_load_shed_yes_no.",".$UPS_outlet_12_load_shed_yes_no.",".$UPS_outlet_13_load_shed_yes_no.",".$UPS_outlet_14_load_shed_yes_no.",".$UPS_outlet_15_load_shed_yes_no.",".$UPS_outlet_16_load_shed_yes_no.",".$UPS_ups_outlet_group_turn_off_enable.",".$UPS_ups_outlet_group_turn_off_delay.",".$from_email."";
		  
	file_put_contents("$config_file",$put_contents_string );
		  
}else{
	if (file_exists("$config_file")) {
		$data = file_get_contents("$config_file");
		$pieces = explode(",", $data);
		$UPS_monitor_runtime=$pieces[0];
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
		$UPS_load_shed_early_time=$pieces[11];
		$UPS_load_shed_control=$pieces[12];
		$UPS_Syno_AuthPass1=$pieces[13];
		$UPS_Syno_PrivPass2=$pieces[14];
		$UPS_Syno_snmp_user=$pieces[15];
		$UPS_Syno_snmp_auth_protocol=$pieces[16];
		$UPS_Syno_snmp_privacy_protocol=$pieces[17];
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
	}else{
		$UPS_monitor_runtime=5;
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
		$UPS_load_shed_early_time=5;
		$UPS_load_shed_control=0;
		$UPS_Syno_AuthPass1="password1";
		$UPS_Syno_PrivPass2="password2";
		$UPS_Syno_snmp_user="Syno_user";
		$UPS_Syno_snmp_auth_protocol="MD5";
		$UPS_Syno_snmp_privacy_protocol="AES";
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
		$put_contents_string="".$UPS_monitor_runtime.",".$UPS_monitor_voltage.",".$ups_monitor_email.",".$ups_monitor_capture_interval.",".$UPS_url.",".$UPS_monitor_enable.",".$UPS_comm_loss_shutdown_interval.",".$UPS_comm_loss_shutdown_enable.",".$UPS_PDU_IP.",".$UPS_PLEX_IP.",".$UPS_plex_installed_volume.",".$UPS_load_shed_early_time.",".$UPS_load_shed_control.",".$UPS_Syno_AuthPass1.",".$UPS_Syno_PrivPass2.",".$UPS_Syno_snmp_user.",".$UPS_Syno_snmp_auth_protocol.",".$UPS_Syno_snmp_privacy_protocol.",".$UPS_UPS_AuthPass1.",".$UPS_UPS_PrivPass2.",".$UPS_UPS_snmp_user.",".$UPS_UPS_snmp_auth_protocol.",".$UPS_UPS_snmp_privacy_protocol.",".$UPS_PDU_AuthPass1.",".$UPS_PDU_PrivPass2.",".$UPS_PDU_snmp_user.",".$UPS_PDU_snmp_auth_protocol.",".$UPS_PDU_snmp_privacy_protocol.",".$UPS_outlet_1_load_shed_yes_no.",".$UPS_outlet_2_load_shed_yes_no.",".$UPS_outlet_3_load_shed_yes_no.",".$UPS_outlet_4_load_shed_yes_no.",".$UPS_outlet_5_load_shed_yes_no.",".$UPS_outlet_6_load_shed_yes_no.",".$UPS_outlet_7_load_shed_yes_no.",".$UPS_outlet_8_load_shed_yes_no.",".$UPS_outlet_9_load_shed_yes_no.",".$UPS_outlet_10_load_shed_yes_no.",".$UPS_outlet_10_load_shed_yes_no.",".$UPS_outlet_12_load_shed_yes_no.",".$UPS_outlet_13_load_shed_yes_no.",".$UPS_outlet_14_load_shed_yes_no.",".$UPS_outlet_15_load_shed_yes_no.",".$UPS_outlet_16_load_shed_yes_no.",".$UPS_ups_outlet_group_turn_off_enable.",".$UPS_ups_outlet_group_turn_off_delay.",".$from_email."";
		  
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
					<p><input type=\"checkbox\" name=\"UPS_monitor_enable\" value=\"1\" ";
					if ($UPS_monitor_enable==1){
						print "checked";
					}
					print ">Enable Entire Script?</p>
					<p>UPS Runtime System Shutdown Threshold [Minuets]: <input type=\"text\" name=\"UPS_monitor_runtime\" value=".$UPS_monitor_runtime."><font size=\"1\">Lowest UPS Runtime Remaining Before NAS System Shuts Down</font> ".$UPS_monitor_runtime_error."</p>
					<p>UPS Minimum Input Voltage [Volts]: <input type=\"text\" name=\"UPS_monitor_voltage\" value=".$UPS_monitor_voltage."><font size=\"1\">Ensure it is the same as the UPS activation voltage Configured on the Management Card</font> ".$UPS_monitor_voltage_error."</p>
					<p>Alert Email Recipient: <input type=\"text\" name=\"ups_monitor_email\" value=".$ups_monitor_email."><font size=\"1\">Separate Addresses by a semicolon</font> ".$ups_monitor_email_error."</p>
					<p>From Email: <input type=\"text\" name=\"from_email\" value=".$from_email."> ".$from_email_error."</p>
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
print "				</select></p>
					<p><input type=\"checkbox\" name=\"UPS_comm_loss_shutdown_enable\" value=\"1\" ";
					if ($UPS_comm_loss_shutdown_enable==1){
						print "checked";
					}
					print ">Shutdown NAS System When UPS network Communications Fail</p>
					<p>NAS System Shutdown Delay - UPS Network Communications Fail [Hours]: <select name=\"UPS_comm_loss_shutdown_interval\">";
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
print "				</select></p>
					<p>Load Shed - Plex Media Server IP Address: <input type=\"text\" name=\"UPS_PLEX_IP\" value=".$UPS_PLEX_IP."><font size=\"1\">If PLEX is not installed on the system, leave as default</font> ".$UPS_PLEX_IP_error."</p>
					<p>Load Shed - Plex Media Server Installed Volume on NAS: <input type=\"text\" name=\"UPS_plex_installed_volume\" value=".$UPS_plex_installed_volume."><font size=\"1\">Do not include lead slash \"/\". If PLEX is not installed on the system, leave as default</font> ".$UPS_plex_installed_volume_error."</p>
					<br>
					<p>SYNOLOGY SNMP SETTINGS</p>
					<p>-> Authorization Password: <input type=\"text\" name=\"UPS_Syno_AuthPass1\" value=".$UPS_Syno_AuthPass1."> ".$UPS_Syno_AuthPass1_error."</p>
					<p>-> Privacy Password: <input type=\"text\" name=\"UPS_Syno_PrivPass2\" value=".$UPS_Syno_PrivPass2."> ".$UPS_Syno_PrivPass2_error."</p>
					<p>-> User Name: <input type=\"text\" name=\"UPS_Syno_snmp_user\" value=".$UPS_Syno_snmp_user."> ".$UPS_Syno_snmp_user_error."</p>
					<p>-> Authorization Protocol: <select name=\"UPS_Syno_snmp_auth_protocol\">";
					if ($UPS_Syno_snmp_auth_protocol=="MD5"){
						print "<option value=\"MD5\" selected>MD5</option>
						<option value=\"SHA\">SHA</option>";
					}else if ($UPS_Syno_snmp_auth_protocol=="SHA"){
						print "<option value=\"MD5\">MD5</option>
						<option value=\"SHA\" selected>SHA</option>";
					}
print "				</select></p>
					<p>-> Privacy Protocol: <select name=\"UPS_Syno_snmp_privacy_protocol\">";
					if ($UPS_Syno_snmp_privacy_protocol=="AES"){
						print "<option value=\"AES\" selected>AES</option>
						<option value=\"DES\">DES</option>";
					}else if ($UPS_Syno_snmp_privacy_protocol=="DES"){
						print "<option value=\"AES\">AES</option>
						<option value=\"DES\" selected>DES</option>";
					}
print "				</select></p>
					<br>
					<p>UPS SNMP SETTINGS</p>	
					<p>-> UPS IP: <input type=\"text\" name=\"UPS_url\" value=".$UPS_url."> ".$UPS_monitor_url_error."</p>
					<p>-> Authorization Password: <input type=\"text\" name=\"UPS_UPS_AuthPass1\" value=".$UPS_UPS_AuthPass1."> ".$UPS_UPS_AuthPass1_error."</p>
					<p>-> Privacy Password: <input type=\"text\" name=\"UPS_UPS_PrivPass2\" value=".$UPS_UPS_PrivPass2."> ".$UPS_UPS_PrivPass2_error."</p>
					<p>-> User Name: <input type=\"text\" name=\"UPS_UPS_snmp_user\" value=".$UPS_UPS_snmp_user."> ".$UPS_UPS_snmp_user_error." </p>
					<p>-> Authorization Protocol: <select name=\"UPS_UPS_snmp_auth_protocol\">";
					if ($UPS_UPS_snmp_auth_protocol=="MD5"){
						print "<option value=\"MD5\" selected>MD5</option>
						<option value=\"SHA\">SHA</option>";
					}else if ($UPS_UPS_snmp_auth_protocol=="SHA"){
						print "<option value=\"MD5\">MD5</option>
						<option value=\"SHA\" selected>SHA</option>";
					}
print "				</select></p>
					<p>-> Privacy Protocol: <select name=\"UPS_UPS_snmp_privacy_protocol\">";
					if ($UPS_UPS_snmp_privacy_protocol=="AES"){
						print "<option value=\"AES\" selected>AES</option>
						<option value=\"DES\">DES</option>";
					}else if ($UPS_UPS_snmp_privacy_protocol=="DES"){
						print "<option value=\"AES\">AES</option>
						<option value=\"DES\" selected>DES</option>";
					}
print "				</select></p>
					<br>
					<p>POWER DISTRIBUTION UNIT (PDU) SNMP SETTINGS</p>
					<p>-> Power Distribution Unit (PDU) IP: <input type=\"text\" name=\"UPS_PDU_IP\" value=".$UPS_PDU_IP."><font size=\"1\">If no PDU is used, leave as default</font> ".$UPS_PDU_IP_error."</p>
					<p>-> Authorization Password: <input type=\"text\" name=\"UPS_PDU_AuthPass1\" value=".$UPS_PDU_AuthPass1."><font size=\"1\">If no PDU is used, leave as default</font> ".$UPS_PDU_AuthPass1_error."</p>
					<p>-> Privacy Password: <input type=\"text\" name=\"UPS_PDU_PrivPass2\" value=".$UPS_PDU_PrivPass2."><font size=\"1\">If no PDU is used, leave as default</font> ".$UPS_PDU_PrivPass2_error."</p>
					<p>-> User Name: <input type=\"text\" name=\"UPS_PDU_snmp_user\" value=".$UPS_PDU_snmp_user."><font size=\"1\">If no PDU is used, leave as default</font> ".$UPS_PDU_snmp_user_error."</p>
					<p>-> Authorization Protocol: <select name=\"UPS_PDU_snmp_auth_protocol\">";
					if ($UPS_PDU_snmp_auth_protocol=="MD5"){
						print "<option value=\"MD5\" selected>MD5</option>
						<option value=\"SHA\">SHA</option>";
					}else if ($UPS_PDU_snmp_auth_protocol=="SHA"){
						print "<option value=\"MD5\">MD5</option>
						<option value=\"SHA\" selected>SHA</option>";
					}
print "				</select></p>
					<p>-> Privacy Protocol: <select name=\"UPS_PDU_snmp_privacy_protocol\">";
					if ($UPS_PDU_snmp_privacy_protocol=="AES"){
						print "<option value=\"AES\" selected>AES</option>
						<option value=\"DES\">DES</option>";
					}else if ($UPS_PDU_snmp_privacy_protocol=="DES"){
						print "<option value=\"AES\">AES</option>
						<option value=\"DES\" selected>DES</option>";
					}
print "				</select></p>
					<br><p><input type=\"checkbox\" name=\"UPS_load_shed_control\" value=\"1\" ";
					if ($UPS_load_shed_control==1){
						print "checked";
					}
					print ">Enable Load Shed Control of Power Distribution Unit (PDU) Outlets?</p>
					<p>Time Prior to System Shutdown to Initiate Load Shedding [Minutes]: <select name=\"UPS_load_shed_early_time\">";
					if ($UPS_load_shed_early_time==1){
						print "<option value=\"1\" selected>1</option>
						<option value=\"2\">2</option>
						<option value=\"3\">3</option>
						<option value=\"4\">4</option>
						<option value=\"5\">5</option>
						<option value=\"6\">6</option>
						<option value=\"7\">7</option>
						<option value=\"8\">8</option>
						<option value=\"9\">9</option>
						<option value=\"10\">10</option>
						<option value=\"11\">11</option>
						<option value=\"12\">12</option>
						<option value=\"13\">13</option>
						<option value=\"14\">14</option>
						<option value=\"15\">15</option>";
					}else if ($UPS_load_shed_early_time==2){
						print "<option value=\"1\">1</option>
						<option value=\"2\" selected>2</option>
						<option value=\"3\">3</option>
						<option value=\"4\">4</option>
						<option value=\"5\">5</option>
						<option value=\"6\">6</option>
						<option value=\"7\">7</option>
						<option value=\"8\">8</option>
						<option value=\"9\">9</option>
						<option value=\"10\">10</option>
						<option value=\"11\">11</option>
						<option value=\"12\">12</option>
						<option value=\"13\">13</option>
						<option value=\"14\">14</option>
						<option value=\"15\">15</option>";
					}else if ($UPS_load_shed_early_time==3){
						print "<option value=\"1\">1</option>
						<option value=\"2\">2</option>
						<option value=\"3\" selected>3</option>
						<option value=\"4\">4</option>
						<option value=\"5\">5</option>
						<option value=\"6\">6</option>
						<option value=\"7\">7</option>
						<option value=\"8\">8</option>
						<option value=\"9\">9</option>
						<option value=\"10\">10</option>
						<option value=\"11\">11</option>
						<option value=\"12\">12</option>
						<option value=\"13\">13</option>
						<option value=\"14\">14</option>
						<option value=\"15\">15</option>";
					}else if ($UPS_load_shed_early_time==4){
						print "<option value=\"1\">1</option>
						<option value=\"2\">2</option>
						<option value=\"3\">3</option>
						<option value=\"4\" selected>4</option>
						<option value=\"5\">5</option>
						<option value=\"6\">6</option>
						<option value=\"7\">7</option>
						<option value=\"8\">8</option>
						<option value=\"9\">9</option>
						<option value=\"10\">10</option>
						<option value=\"11\">11</option>
						<option value=\"12\">12</option>
						<option value=\"13\">13</option>
						<option value=\"14\">14</option>
						<option value=\"15\">15</option>";
					}else if ($UPS_load_shed_early_time==5){
						print "<option value=\"1\">1</option>
						<option value=\"2\">2</option>
						<option value=\"3\">3</option>
						<option value=\"4\">4</option>
						<option value=\"5\" selected>5</option>
						<option value=\"6\">6</option>
						<option value=\"7\">7</option>
						<option value=\"8\">8</option>
						<option value=\"9\">9</option>
						<option value=\"10\">10</option>
						<option value=\"11\">11</option>
						<option value=\"12\">12</option>
						<option value=\"13\">13</option>
						<option value=\"14\">14</option>
						<option value=\"15\">15</option>";
					}else if ($UPS_load_shed_early_time==6){
						print "<option value=\"1\">1</option>
						<option value=\"2\">2</option>
						<option value=\"3\">3</option>
						<option value=\"4\">4</option>
						<option value=\"5\">5</option>
						<option value=\"6\" selected>6</option>
						<option value=\"7\">7</option>
						<option value=\"8\">8</option>
						<option value=\"9\">9</option>
						<option value=\"10\">10</option>
						<option value=\"11\">11</option>
						<option value=\"12\">12</option>
						<option value=\"13\">13</option>
						<option value=\"14\">14</option>
						<option value=\"15\">15</option>";
					}else if ($UPS_load_shed_early_time==7){
						print "<option value=\"1\">1</option>
						<option value=\"2\">2</option>
						<option value=\"3\">3</option>
						<option value=\"4\">4</option>
						<option value=\"5\">5</option>
						<option value=\"6\">6</option>
						<option value=\"7\" selected>7</option>
						<option value=\"8\">8</option>
						<option value=\"9\">9</option>
						<option value=\"10\">10</option>
						<option value=\"11\">11</option>
						<option value=\"12\">12</option>
						<option value=\"13\">13</option>
						<option value=\"14\">14</option>
						<option value=\"15\">15</option>";
					}else if ($UPS_load_shed_early_time==8){
						print "<option value=\"1\">1</option>
						<option value=\"2\">2</option>
						<option value=\"3\">3</option>
						<option value=\"4\">4</option>
						<option value=\"5\">5</option>
						<option value=\"6\">6</option>
						<option value=\"7\">7</option>
						<option value=\"8\" selected>8</option>
						<option value=\"9\">9</option>
						<option value=\"10\">10</option>
						<option value=\"11\">11</option>
						<option value=\"12\">12</option>
						<option value=\"13\">13</option>
						<option value=\"14\">14</option>
						<option value=\"15\">15</option>";
					}else if ($UPS_load_shed_early_time==9){
						print "<option value=\"1\">1</option>
						<option value=\"2\">2</option>
						<option value=\"3\">3</option>
						<option value=\"4\">4</option>
						<option value=\"5\">5</option>
						<option value=\"6\">6</option>
						<option value=\"7\">7</option>
						<option value=\"8\">8</option>
						<option value=\"9\" selected>9</option>
						<option value=\"10\">10</option>
						<option value=\"11\">11</option>
						<option value=\"12\">12</option>
						<option value=\"13\">13</option>
						<option value=\"14\">14</option>
						<option value=\"15\">15</option>";
					}else if ($UPS_load_shed_early_time==10){
						print "<option value=\"1\">1</option>
						<option value=\"2\">2</option>
						<option value=\"3\">3</option>
						<option value=\"4\">4</option>
						<option value=\"5\">5</option>
						<option value=\"6\">6</option>
						<option value=\"7\">7</option>
						<option value=\"8\">8</option>
						<option value=\"9\">9</option>
						<option value=\"10\" selected>10</option>
						<option value=\"10\">11</option>
						<option value=\"12\">12</option>
						<option value=\"13\">13</option>
						<option value=\"14\">14</option>
						<option value=\"15\">15</option>";
					}else if ($UPS_load_shed_early_time==11){
						print "<option value=\"1\">1</option>
						<option value=\"2\">2</option>
						<option value=\"3\">3</option>
						<option value=\"4\">4</option>
						<option value=\"5\">5</option>
						<option value=\"6\">6</option>
						<option value=\"7\">7</option>
						<option value=\"8\">8</option>
						<option value=\"9\">9</option>
						<option value=\"10\">10</option>
						<option value=\"11\" selected>11</option>
						<option value=\"10\">12</option>
						<option value=\"13\">13</option>
						<option value=\"14\">14</option>
						<option value=\"15\">15</option>";
					}else if ($UPS_load_shed_early_time==12){
						print "<option value=\"1\">1</option>
						<option value=\"2\">2</option>
						<option value=\"3\">3</option>
						<option value=\"4\">4</option>
						<option value=\"5\">5</option>
						<option value=\"6\">6</option>
						<option value=\"7\">7</option>
						<option value=\"8\">8</option>
						<option value=\"9\">9</option>
						<option value=\"10\">10</option>
						<option value=\"11\">11</option>
						<option value=\"12\" selected>12</option>
						<option value=\"13\">13</option>
						<option value=\"14\">14</option>
						<option value=\"15\">15</option>";
					}else if ($UPS_load_shed_early_time==13){
						print "<option value=\"1\">1</option>
						<option value=\"2\">2</option>
						<option value=\"3\">3</option>
						<option value=\"4\">4</option>
						<option value=\"5\">5</option>
						<option value=\"6\">6</option>
						<option value=\"7\">7</option>
						<option value=\"8\">8</option>
						<option value=\"9\">9</option>
						<option value=\"10\">10</option>
						<option value=\"11\">11</option>
						<option value=\"12\">12</option>
						<option value=\"13\" selected>13</option>
						<option value=\"14\">14</option>
						<option value=\"15\">15</option>";
					}else if ($UPS_load_shed_early_time==14){
						print "<option value=\"1\">1</option>
						<option value=\"2\">2</option>
						<option value=\"3\">3</option>
						<option value=\"4\">4</option>
						<option value=\"5\">5</option>
						<option value=\"6\">6</option>
						<option value=\"7\">7</option>
						<option value=\"8\">8</option>
						<option value=\"9\">9</option>
						<option value=\"10\">10</option>
						<option value=\"11\">11</option>
						<option value=\"12\">12</option>
						<option value=\"13\">13</option>
						<option value=\"14\" selected>14</option>
						<option value=\"15\">15</option>";
					}else if ($UPS_load_shed_early_time==15){
						print "<option value=\"1\"d>1</option>
						<option value=\"2\">2</option>
						<option value=\"3\">3</option>
						<option value=\"4\">4</option>
						<option value=\"5\">5</option>
						<option value=\"6\">6</option>
						<option value=\"7\">7</option>
						<option value=\"8\">8</option>
						<option value=\"9\">9</option>
						<option value=\"10\">10</option>
						<option value=\"11\">11</option>
						<option value=\"12\">12</option>
						<option value=\"13\">13</option>
						<option value=\"14\">14</option>
						<option value=\"15\" selected>15</option>";
					}
print "				</select><font size=\"1\">Controls PDU outlet control, PLEX Shutdown and Surveillance Station Shutdown</font> ".$UPS_load_shed_early_time_error."</p>
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
					<br>
					<p><input type=\"checkbox\" name=\"UPS_ups_outlet_group_turn_off_enable\" value=\"1\" ";
					if ($UPS_ups_outlet_group_turn_off_enable==1){
						print "checked";
					}
					print "> Enable UPS Outlet Group Turn-Off <font size=\"1\">After the NAS System is Turned off, should the UPS outlet groups be turned off?</font></p>
					<p>Number of Minutes the UPS outlet groups will delay before turning off [Minutes]: <select name=\"UPS_ups_outlet_group_turn_off_delay\">";
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
print "				</select>
					<font size=\"1\">Ensure there is at least 2 minutes of time or enough time for the system to shutdown plus the 1 minute NAS shutdown delay</font></p>
					<center><input type=\"submit\" name=\"submit_ups_monitor\" value=\"Submit\" /></center>
				</form>
			</td>
		</tr>
	</table>
</fieldset>";
?>
