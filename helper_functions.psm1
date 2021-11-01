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
