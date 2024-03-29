<#
	.SYNOPSIS
		A brief summary of the commands in the file.
	
	.DESCRIPTION
		A detailed description of the commands in the file.
	
	.NOTES
		========================================================================
		
		NAME: Build-vCenterFile.ps1
		
		AUTHOR: Jason Foy
		DATE  : 11/14/2018
		
		COMMENT: Build new or rebuild vCenter CONTROL file for a profile
		
		==========================================================================
#>
Clear-Host
$Version = "1.0.0"
$ScriptName = $MyInvocation.MyCommand.Name
$scriptPath = Split-Path $MyInvocation.MyCommand.Path
$userName = ($env:UserName).ToUpper()
$userDomain = ($env:UserDomain).ToUpper()
$Date = Get-Date -Format g
$dateSerial = Get-Date -Format yyyyMMddhhmmss
$traceFile = Join-Path -Path $scriptPath -ChildPath "ControlFileBuild.trace"
Start-Transcript $traceFile
Write-Host ("="*80) -ForegroundColor DarkGreen
Write-Host ""
Write-Host `t`t"$scriptName v$Version"
Write-Host `t`t"Started $Date"
Write-Host ""	
Write-Host ("="*80) -ForegroundColor DarkGreen
Write-Host ""
Write-Host "vCenter CONTROL File Build Utility"
Write-Host ("*"*80) -ForegroundColor Red -BackgroundColor Black
Write-Host "This File will only work when RunAs $userDomain \ $userName" -ForegroundColor Yellow
Write-Host ("*"*80) -ForegroundColor Red -BackgroundColor Black
Write-Host "Provide Build Information:" -ForegroundColor Yellow
$csvColumns = @('NAME','CLASS','LINKED','ID','HASH','ADMIN','HASH2')
$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","List them as Linked"
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No","List them as unlinked"
$prodCL = New-Object System.Management.Automation.Host.ChoiceDescription "&PROD","PRODUCTION CLASS"
$devCL = New-Object System.Management.Automation.Host.ChoiceDescription "&DEV","DEV CLASS (Lab Space)"
$sbxCL = New-Object System.Management.Automation.Host.ChoiceDescription "&SBX","SANDBOX CLASS"
$YNoptions = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
$CLoptions = [System.Management.Automation.Host.ChoiceDescription[]]($prodCL, $sbxCL, $devCL)
[array]$vCenterList = ((Read-Host "Provide Comma Seperated list of vCenter FQDN:") -split ",")
[array]$vCenterNames = $vCenterList|ForEach-Object{$_.trim()}
$roCreds = Get-Credential -Message "Provide READ ONLY credentials" -UserName "VMwareReports"
$rwCreds = Get-Credential -Message "Provide ADMINISTRATOR credentials" -UserName "administrator@vsphere.local"
$Linkmessage = "Are these vCenters in Linked Mode?  You can safely modify the CSV file later."
$Classmessage = "Which Environment are they for?"
$result = $host.ui.PromptForChoice("LINK MODE", $Linkmessage, $YNoptions, 0)
switch ($result) {
	0 {$linkMode = $true}
	1 {$linkMode = $false}
	default {$linkMode = $true}
}
$linkGroupName = "NO"
if($linkMode){$linkGroupName = ((Read-Host "Linked Group Name: i.e. SBX-LINKED, PROD-LINKED, VDI-LINKED").ToUpper()).Trim()}
$result = $host.ui.PromptForChoice("CLASS", $Classmessage, $CLoptions, 0)
switch ($result) {
	0 {$envClass = "PROD"}
	1 {$envClass = "SBX"}
	2 {$envClass = "DEV"}
	default {$envClass = "PROD"}
}
Write-Host "Building File for " -NoNewline;Write-Host $vCenterNames.Count -ForegroundColor Yellow -NoNewline;Write-Host " vCenter Stacks"
Write-Host "CLASS:" -NoNewline;Write-Host $envClass -ForegroundColor Yellow
Write-Host "LINKD:" -NoNewline;Write-Host $linkGroupName -ForegroundColor Yellow
Write-Host "RO USER:" -NoNewline;Write-Host $roCreds.UserName -ForegroundColor Cyan
Write-Host "RW USER:" -NoNewline;Write-Host $rwCreds.UserName -ForegroundColor Cyan
$outFileName = Join-Path -Path $scriptPath -ChildPath "vCenter-$envClass-$dateSerial.csv"
Write-Host "Building vCenterNames Content..."
$newControlFile = @()
$vCenterNames|ForEach-Object{
	$row = ""|Select-Object $csvColumns
	$row.NAME = $_
	$row.CLASS = $envClass
	$row.LINKED = $linkGroupName
	$row.ID = $roCreds.UserName
	$row.HASH = ConvertFrom-SecureString($roCreds.Password)
	$row.ADMIN = $rwCreds.UserName
	$row.HASH2 = ConvertFrom-SecureString($rwCreds.Password)
	$newControlFile+=$row
}
Write-Host "Writing to File:"
Write-Host $outFileName -ForegroundColor Cyan
$newControlFile|Export-Csv -NoTypeInformation $outFileName
Write-Host ("+"*80)
Write-Host "Process Complete"

Stop-Transcript