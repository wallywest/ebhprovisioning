<?php
$xml=simplexml_load_file('/var/www/lighttpd/whmcs/modules/servers/virtuozzo/config.xml');

$value=(int)$_GET['userid'];
$productid=(int)$_GET['id'];
$hostingid=(int)$_GET['hostingid'];
$path=$xml->path;
$scriptpath=$path."lib/";

$host=$xml->host;
$user=$xml->user;
$pass=$xml->pass;
$db=$xml->db;
$conn=mysql_connect($host,$user,$pass) or die('Error connecting to mysql');
mysql_select_db($db);

if ($productid==0 && $hostingid==0 ){
	$status=mysql_fetch_row(mysql_query("select domainstatus from tblhosting where userid=$value ORDER BY id DESC"));
}
else{
$status=mysql_fetch_row(mysql_query("select domainstatus from tblhosting where userid=$value and (id='$hostingid' or id='$productid')")); 
}

function virtuozzo_ConfigOptions() {
	# Should return an array of the module options for each product - maximum of 24
    $configarray = array(
	# "Creation Node" => array( "Type" => "text", "Size" => "25", ),
	);
	return $configarray;
}
#function virtuozzo_AdminCustomButtonArray() {
	# This function can define additional functions your module supports, the example here is a reboot button and then the reboot function is defined below
#    	$buttonarray=array("License Control Panel"=>"clicense");
#        return $buttonarray;
#}


if ($status[0]=="Pending" || $status[0]=="Terminated"){
	function virtuozzo_CreateAccount($params) {

		global $scriptpath;
        	#if (isEmpty($params)) {
                #return 'Check Hostname and Password fields';
        	#}
	chdir($scriptpath);
	writeJson($params);
	$output=shell_exec("ruby ".$scriptpath."virtuozzo.rb create .= 2>&1");
	$successful=rtrim($output,"\0");
	outputwind($successful);
	if ($successful=="success") {
		return "success";
	} else {
		mail('justin@eboundhost.com','virtuozzo error',$output);
		return $output;
		}
	}
}
if ($status[0]=="Active"){
	global $scriptpath;
	function virtuozzo_AdminCustomButtonArray() {
        # This function can define additional functions your module supports, the example here is a reboot button and then the reboot function is defined below
        $buttonarray=array("License Control Panel"=>"clicense");
        return $buttonarray;
	
	}

	function virtuozzo_TerminateAccount($params) {
	global $scriptpath;
	
	chdir($scriptpath);
	writeJson($params);
	$output=shell_exec("ruby ".$scriptpath."virtuozzo.rb destroy .= 2>&1");
	# Code to perform action goes here...
		outputwind($output);
		if ($output=='success') {
		return "success";
		} else {
		mail('justin@eboundhost.com','virtuozzo error',$output);
		return $output;

		}
	}


	function virtuozzo_SuspendAccount($params) {
	global $scriptpath;

	chdir($scriptpath);
	writeJson($params);
	$output=shell_exec("ruby ".$scriptpath."virtuozzo.rb suspend .= 2>&1");
	outputwind($output);
	if ($output=='success') {
		return "success";
	} else {
		mail('justin@eboundhost.com','virtuozzo error',$output);
		return $output;
	}
	}
	function virtuozzo_clicense($params) {
		global $scriptpath;
		chdir($scriptpath);
		writeJson($params);
		$output=shell_exec("ruby ".$scriptpath."license.rb .= 2>&1");
		outputwind($output);
		if ($output=='success') {
        	        return "success";
        	} 
		else {
                mail('justin@eboundhost.com','virtuozzo error',$output);
                return $output;
        	}
	}
}

if ($status[0]=="Suspended"){
	global $scriptpath;
	function virtuozzo_UnsuspendAccount($params) {
		chdir($scriptpath);
		writeJson($params);
		$output=shell_exec("ruby ".$scriptpath."virtuozzo.rb unsuspend .= 2>&1");
		outputwind($output);
		if ($output=='success') {
                return "success";
        	} else {
		mail('justin@eboundhost.com','virtuozzo error',$output);
                return $output;
        	}
	}
	
	function virtuozzo_TerminateAccount($params) {

        	chdir($scriptpath);
		writeJson($params);
        	$output=shell_exec("ruby ".$scriptpath."virtuozzo.rb destroy .= 2>&1");
        	# Code to perform action goes here...
        	outputwind($output);
        	if ($output=='success') {
               	    return "success";
        	} else {
                	mail('justin@eboundhost.com','virtuozzo error',$output);
                return $output;

        	}	
	}
}

#--------------------------------------------------------------------------------------------------------------------
#Custom Functions
function isEmpty($params){
	if ( empty($params["domain"]) || empty($params["password"]) || empty($params["serverip"]) ) {
		return true;
	} 
}
function writeJson($params){
	$jparam=json_encode($params);
	$fp = fopen($scriptpath."data.json", 'w');
        fwrite($fp,$jparam);
        fclose($fp);
}
function outputwind($status){
		$value=$_GET['userid'];
		$productid=$_GET['id'];
		if ($status=='success') {
			echo "<BODY onLoad=\"javascript: alert('Zug Zug'); location='clientshosting.php?userid=$value&id=$productid';\">";
		} else {
                	echo "<BODY onLoad=\"javascript: alert('Error: There was an error with the module, bother Justin'); location='clientshosting.php?userid=$value&id=$productid';\">";
		}	
}
?>
<script>
$(document).ready(function(){
        //HIDE UNECCESSARY TABLES
        $("tr:contains(Subscription ID),tr:contains(Username),tr:contains(Nameserver),tr:contains(Promotion),tr:contains(Overide),tr:contains(Auto-Terminate)").hide();
	//HIDE LICENSE BUTTON IF FIELDS ARE FULL
	if ( $("input[type=text][name=customfield[11]]").val() != "" || $("input[type=text][name=customfield[12]]").val() != "" ) { 
		$(":input[type=button][value=License Control Panel]").hide()
	}
});
</script>
