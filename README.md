# Skyline Health Diagnostic deployment automation script

### config file

shd_config.json

```json
{
    "vcsa":  "VCENTER-FQDN",
    "vcsauser":  "administrator@vsphere.local",
    "vcsauserpass": "VMware123!",
    "PowerOnSkyline": "yes",
    "SHDUserPass": "VMware123!",
    "VMHost": "ESXI-FQDN",
    "TargetDS": "DATASTORE",
    "SourceOVFFile": "/PATH/TO/OVA/VMware-Skyline-HealthDiagnostics-Appliance-2.5.2-18570524_OVF10.ova",
    "TargetVMName": "skyline-health-diagnostics",
    "TargetVMStorageFormat": "Thin",
    "RootPW": "VMware123!",
    "NetworkMapping": "VM Network",
    "Hostname": "shd",
    "IP0": "SHD-IP",
    "Netmask0": "23",
    "Gateway": "GATEWAY-IP",
    "DNS": "DNS-SERVERS",
    "NTP": "NTP-SERVERS"
}
```
1. vCenter basic information
 - "vcsa": vCenter FQDN or IP
 - "vcsauser": vCenter admin user like administrator@vsphere.local
 - "vcsauserpass": vCenter admin user password

2. Power on SHD after deployment
 - "PowerOnSkyline": yes or no

3. Deployment information
 - "VMHost": Target ESXi host for the SHD appliance
 - "TargetDS": Target datastore for the SHD appliance

4. OVA file
 - "SourceOVFFile": Path to the OVA file

5. OVF settings
 - "TargetVMName": Virtual machine name of the SHD appliance
 - "TargetVMStorageFormat": Thin or Thick deployment
 - "RootPW": Root password for the SHD appliance
 - "SHDUserPass": shd-admin password
 - "NetworkMapping": Port group for network configuration
 - "Hostname": Hostname inside the SHD appliance
 - "IP0": IP of the SHD appliance
 - "Netmask0": Netmask of the SHD appliance
 - "Gateway": Gateway of the SHD appliance
 - "DNS": DNS server of the SHD appliance
 - "NTP": NTP server of the SHD appliance


### Script Output

```
--------------------------------------------------------------------------------------------------------------
[11-01-2021_14-17-40] Connect to vCenter 192.168.0.45
--------------------------------------------------------------------------------------------------------------
[11-01-2021_14-17-42] Debug

[11-01-2021_14-17-42] Source
[11-01-2021_14-17-42] VarSourceOVFFile                                                     /Users/mhempel/Downloads/VMware-Skyline-HealthDiagnostics-Appliance-2.5.2-18570524_OVF10.ova

[11-01-2021_14-17-42] Target
[11-01-2021_14-17-42] VarTargetVMName                                                      skyline-health-diagnostics
[11-01-2021_14-17-42] VarTargetVMStorageFormat                                             Thin

[11-01-2021_14-17-42] Configuration
[11-01-2021_14-17-42] VarOVFConfiguration.Common.netipaddress.value                       192.168.0.177
[11-01-2021_14-17-42] VarOVFConfiguration.Common.netprefix.value                          23
[11-01-2021_14-17-42] VarOVFConfiguration.Common.netgateway.value                         192.168.0.1
[11-01-2021_14-17-42] VarOVFConfiguration.Common.netdns.value                             192.168.0.2,192.168.0.3
[11-01-2021_14-17-42] VarOVFConfiguration.Common.netntp.value                             pool.ntp.org
--------------------------------------------------------------------------------------------------------------
[11-01-2021_14-17-42] Importing VM ...
--------------------------------------------------------------------------------------------------------------
[11-01-2021_14-19-02] Retrieving VM ...
[11-01-2021_14-19-02] VM imported
[11-01-2021_14-19-02] VM powered on
```
