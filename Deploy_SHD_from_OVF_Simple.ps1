#########################################
#                                       #
#   Author: Michael Hempel              #
#   Email:  mhempel@xmsoft.de           #
#                                       #
#   Credits:                            #
#           Thomas Dietl                #
#           Matthias Branzko            #
#                                       #
#########################################

# Set PowerCli Configurations
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false
Set-PowerCLIConfiguration -InvalidCertificateAction ignore -Scope Session -confirm:$false 
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Import-Module -Force $PSScriptRoot\helper_functions.psm1

# Read config file and assign variables

$configfile = "$PSScriptRoot/shd_config.json"
$config = Get-Content $configfile -raw | ConvertFrom-Json

$VarvCenter = $config.vcsa
$VarvCenterUser = $config.vcsauser
$VarvCenterUserPass = $config.vcsauserpass
$PowerOnSkyline = $config.PowerOnSkyline
$VarSkylineUserPass = $config.SHDUserPass
$VarSourceOVFFile = $config.SourceOVFFile 
$VarTargetVMName = $config.TargetVMName
$VarTargetVMStorageFormat = $config.TargetVMStorageFormat
$VarRootPW = $config.RootPW
$VarNetworkMapping = $config.NetworkMapping
$VarHostname = $config.Hostname
$VarIP0 = $config.IP0
$VarNetmask0 = $config.Netmask0
$VarGateway = $config.Gateway
$VarDNS = $config.DNS
$VarVMHost = $config.VMHost
$VarTargetDS = $config.TargetDS
$VarNTP = $config.NTP


#Clear Screen
Clear-Host

# Start Preparation and deployment
My-SeparationLine
My-Logger -color "Green" -message "Connect to vCenter $VarvCenter"

#Connect vCenter
$connection = Connect-VIServer -server $VarvCenter -User $VarvCenterUser -Password $VarvCenterUserPass 

#OVF Configuration
#Get-OVFConfiguration requires a vCenter Connection
$VarOVFConfiguration = Get-OVFConfiguration $VarSourceOVFFile

#General
$VarOVFConfiguration.Common.root_password.value = $VarRootPW
$VarOVFConfiguration.Common.shd_admin_password.value = $VarSkylineUserPass

#Neworking
$VarOVFConfiguration.NetworkMapping.VM_Network.value = Get-VMHost -Name $VarVMHost | Get-VirtualPortGroup -Name $VarNetworkMapping
$VarOVFConfiguration.Common.netipaddress.value = $VarIP0
$VarOVFConfiguration.Common.netprefix.value = $VarNetmask0
$VarOVFConfiguration.Common.netgateway.value = $VarGateway
$VarOVFConfiguration.Common.netdns.value = $VarDNS
$VarOVFConfiguration.Common.hostname.value = $VarHostname
$VarOVFConfiguration.Common.netntp.value = $VarNTP

#Hosting Environment / Objects

$VarTargetVMHost = Get-VMHost -Name $VarVMHost

IF(($Null -ne $VarTargetVMHost) -and ($Null -ne $VarTargetDS)){
	$StartTime = Get-Date

	#No Progress Bar / ErrorAction
	# My-SeparationLine
	# My-Logger -color "Green" -message "Setting Progress Bar and Error Action ..."
	$ProgressPreference = 'SilentlyContinue'
	$ErrorActionPreference = 'SilentlyContinue'

	#Debug
	My-SeparationLine
	My-Logger -color "Blue" -message "Debug"
	My-EmptyLine
	My-Logger -color "Green" -message "Source"
	My-Logger -color "Green" -message "VarSourceOVFFile                                                     $VarSourceOVFFile"
	My-EmptyLine
	My-Logger -color "Blue" -message "Target"
	My-Logger -color "Green" -message "VarTargetVMName                                                      $VarTargetVMName" 
	My-Logger -color "Green" -message "VarTargetVMStorageFormat                                             $VarTargetVMStorageFormat"
	My-EmptyLine
	My-Logger -color "Blue" -message "Configuration"
	My-Logger -color "Green" -message  "VarOVFConfiguration.Common.netipaddress.value                       $VarIP0"
	My-Logger -color "Green" -message  "VarOVFConfiguration.Common.netprefix.value                          $VarNetmask0"
	My-Logger -color "Green" -message  "VarOVFConfiguration.Common.netgateway.value                         $VarGateway"
	My-Logger -color "Green" -message  "VarOVFConfiguration.Common.netdns.value                             $VarDNS"
	My-Logger -color "Green" -message  "VarOVFConfiguration.Common.netntp.value                             $VarNTP"
	My-SeparationLine

	#Check if VM already exists
	$VarTestTargetVMalreadyexists = Get-VM -Name $VarTargetVMName #| Out-Null -ErrorAction SilentlyContinue

	IF($VarTestTargetVMalreadyexists -eq $Null){

		#Import VM
		My-Logger -color "Green" -message  "Importing VM ..."
		Import-VApp -confirm:$false -force:$true -Source $VarSourceOVFFile -OvfConfiguration $VarOVFConfiguration -Name $VarTargetVMName -VMHost $VarTargetVMHost -Datastore $VarTargetDS -DiskStorageFormat $VarTargetVMStorageFormat | Out-Null| Out-Null
		My-SeparationLine

		#---------------------------------------------------------------------------------------------------------------------
		#Check if VM is Imported On
		
		while(1){
			try{
				My-Logger -color "Green" -message  "Retrieving VM ..."
				#$VarTestTargetVM = Get-VM -Name $VarTargetVMName | Out-Null -ErrorAction SilentlyContinue
				$VarTestTargetVM = Get-VM -Name $VarTargetVMName
				if($VarTestTargetVM -ne $Null){
					My-Logger -color "Green" -message  "VM imported"
					$VarSuccessfulImported = $true
					if ($VarSuccessfulImported -eq $true) {
						if ($PowerOnSkyline -like "yes"){
							# Power On Skyline Collector
							My-Logger -color "Green" -message  "VM powered on"
							$poweredon = $VarTestTargetVM | Start-VM -Confirm:$false 
						}
					}
					break
				}
			}
			catch{
				IF($VarCounterinSeconds -lt $VarCounterLimitinSeconds){
					#Sleeping for 10 Seconds
					My-Logger -color "Green" -message  "VM not imported yet, sleeping for 10 seconds ..."
					$VarCounterinSeconds = $VarCounterinSeconds + 10
					sleep -s 10
				}
				ELSE{
					#Stop script if Skyline VM is not online after $VarCounterLimit seconds
					My-Logger -color "Red" -message  "VM not imported after $VarCounterLimit seconds"
					My-Logger -color "Red" -message  "Deployment went wrong"
					My-Logger -color "Red" -message  "Script is cancelled/stopped"
					My-Logger -color "Red" -message  "Please check manual"
					My-SeparationLine
					$VarSkylineSuccessfulImported = $false
					break
				}
			}
		}
		#---------------------------------------------------------------------------------------------------------------------
		
	}
	IF($VarTestTargetVMalreadyexists -ne $Null){
		My-Logger -color "Red" -message "VM $VarTestTargetVMalreadyexists already exists!"
		My-Logger -color "Red" -message "Deployment went wrong"
		My-Logger -color "Red" -message "Script is cancelled/stopped"
		My-Logger -color "Red" -message "Please check manual"
		My-SeparationLine
	}
	ELSE{
		#Nothing To Do
	}
}
ELSE{
	My-SeparationLine
	My-Logger -color "Red" -message "Host and/or Datastore not found !!!"
	My-SeparationLine
}
