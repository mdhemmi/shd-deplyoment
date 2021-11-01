#My-Logger Function
Function My-Logger {
    param(
    [Parameter(Mandatory=$true)][String]$message,
    [Parameter(Mandatory=$true)][String]$color
    )

    #hh = 12h Format / HH = 24h Format
	$timeStamp = Get-Date -Format "MM-dd-yyyy_HH-mm-ss"

	#Orig - White + Green
    Write-Host -NoNewline -ForegroundColor White "[$timestamp]"
    Write-Host -ForegroundColor $color " $message"
}

#My-SeparationLine Function
Function My-SeparationLine{
	Write-Host "--------------------------------------------------------------------------------------------------------------"
}

#My-EmtpyLine Function
Function My-EmptyLine{
	Write-Host "  "
}

# Function to create Global Permissions from William Lam https://github.com/lamw/vghetto-scripts/blob/master/powershell/GlobalPermissions.ps1
Function New-GlobalPermission {
    param(
        [Parameter(Mandatory=$true)][string]$vc_server,
        [Parameter(Mandatory=$true)][String]$vc_username,
        [Parameter(Mandatory=$true)][String]$vc_password,
        [Parameter(Mandatory=$true)][String]$vc_user,
        [Parameter(Mandatory=$true)][String]$vc_role_id,
        [Parameter(Mandatory=$true)][String]$propagate
	)

    $secpasswd = ConvertTo-SecureString $vc_password -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($vc_username, $secpasswd)

    # vSphere MOB URL to private enableMethods
    $mob_url = "https://$vc_server/invsvc/mob3/?moid=authorizationService&method=AuthorizationService.AddGlobalAccessControlList"

	# Initial login to vSphere MOB using GET and store session using $vmware variable
    
    $results = Invoke-WebRequest -SkipCertificateCheck -Uri $mob_url -SessionVariable vmware -Credential $credential -Method GET
	
    # Extract hidden vmware-session-nonce which must be included in future requests to prevent CSRF error
    # Credit to https://blog.netnerds.net/2013/07/use-powershell-to-keep-a-cookiejar-and-post-to-a-web-form/ for parsing vmware-session-nonce via Powershell
    if($results.StatusCode -eq 200) {
        $null = $results -match 'name="vmware-session-nonce" type="hidden" value="?([^\s^"]+)"'
        $sessionnonce = $matches[1]
    } else {
        My-Logger -color "Red" -message "Failed to login to vSphere MOB"
        break
    }

    # Escape username
    $vc_user_escaped = [uri]::EscapeUriString($vc_user)

    # The POST data payload must include the vmware-session-nonce variable + URL-encoded
    $body = @"
vmware-session-nonce=$sessionnonce&permissions=%3Cpermissions%3E%0D%0A+++%3Cprincipal%3E%0D%0A++++++%3Cname%3E$vc_user_escaped%3C%2Fname%3E%0D%0A++++++%3Cgroup%3Efalse%3C%2Fgroup%3E%0D%0A+++%3C%2Fprincipal%3E%0D%0A+++%3Croles%3E$vc_role_id%3C%2Froles%3E%0D%0A+++%3Cpropagate%3E$propagate%3C%2Fpropagate%3E%0D%0A%3C%2Fpermissions%3E
"@
    # Second request using a POST and specifying our session from initial login + body request
    My-Logger -color "Green" -message "Adding Global Permission for $vc_user ..."
    $results = Invoke-WebRequest -SkipCertificateCheck -Uri $mob_url -WebSession $vmware -Method POST -Body $body

    # Logout out of vSphere MOB
    $mob_logout_url = "https://$vc_server/invsvc/mob3/logout"
	#$results = Invoke-WebRequest -SkipCertificateCheck -Uri $mob_logout_url -WebSession $vmware -Method GET1
	
}

# Change default admin password - Work in Progress
Function Update-AdminPass {
	param(
        [Parameter(Mandatory=$true)][string]$VarSkylineIP0,
        [Parameter(Mandatory=$true)][String]$VarAdminUserPass
	)
	$updatePassRequest = "https://$VarSkylineIP0/api/v1/auth/update"

	$updatePassJson = ('{
		"oldPassword": "default",
		"newPassword": "' + $VarAdminUserPass + '",
		"username": "admin"
	}') 

	Invoke-WebRequest -SkipCertificateCheck  -ContentType "application/json" -Method POST -Body $updatePassJson -SessionVariable session -Uri $updatePassRequest
}

# Register Collector to Skyline - Work in Progress
# Source: https://confluence.eng.vmware.com/display/DPE/REST+register+collector
Function Register-Collector {
    param(
        [Parameter(Mandatory=$true)][string]$VarTargetVMName,
        [Parameter(Mandatory=$true)][string]$VarRootPW,
        [Parameter(Mandatory=$true)][String]$VarSkylineToken
	)
    #$VarSkylineToken 
    $command = 'curl -X POST --header "Content-Type: application/json" --header "Accept: application/json" -d "{ 
        "token": "' + $VarSkylineToken + '" \
        }" "https://skyline.vmware.com/collector/api/anon/collectors"'

    $result = Invoke-VMScript -ScriptText "echo $VarRootPW | $command" -vm $VarTargetVMName -GuestUser "root" -GuestPassword $VarRootPW
}

# Get Collector API Session
Function Get-CollectorSession {
    param(
        [Parameter(Mandatory=$true)][string]$VarIP0,
        [Parameter(Mandatory=$true)][string]$VarAdminUserPass
	)
    $loginRequest = "https://$VarIP0/api/v1/auth?auto=false"

    $loginJson = '{
        "username": "admin",
        "newPassword": "' + $VarAdminUserPass + '",
        "provider": "Local"
    }'

    $Response = Invoke-WebRequest -SkipCertificateCheck  -ContentType "application/json" -Method POST -Body $loginJson -SessionVariable session -Uri $loginRequest
    $sessionId = $Response.Content | ConvertFrom-Json
    return $sessionId.sessionId
}

Function Get-CSPAccessToken {
    <#
        .NOTES
        ===========================================================================
        Created by:     William Lam
        Date:           07/23/2018
        Organization:   VMware
        Blog:           https://www.virtuallyghetto.com
        Twitter:        @lamw
        ===========================================================================
        .DESCRIPTION
            Converts a Refresh Token from the VMware Console Services Portal
            to CSP Access Token to access CSP API
        .PARAMETER RefreshToken
            The Refresh Token from the VMware Console Services Portal
        .EXAMPLE
            Get-CSPAccessToken -RefreshToken $RefreshToken
    #>
    Param (
        [Parameter(Mandatory=$true)][String]$RefreshToken
    )
    $results = Invoke-WebRequest -Uri "https://console.cloud.vmware.com/csp/gateway/am/api/auth/api-tokens/authorize?refresh_token=$RefreshToken" -Method POST -ContentType "application/json" -UseBasicParsing -Headers @{"csp-auth-token"="$RefreshToken"}
    if($results.StatusCode -ne 200) {
        Write-Host -ForegroundColor Red "Failed to retrieve Access Token, please ensure your VMC Refresh Token is valid and try again"
        break
    }
    $accessToken = ($results | ConvertFrom-Json).access_token
    Write-Host "CSP Auth Token has been successfully retrieved and saved to `$env:cspAuthToken"
    $env:cspAuthToken = $accessToken
}