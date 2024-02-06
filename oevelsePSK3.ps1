# Pre-requirements: To enable running of scripts - "Set-ExecutionPolicy RemoteSigned"
# Run scrip as Admin

#laptop modul 1 vs laptop modul 3 
#startup check, clean desktop, start, cancel
#modul3 laptop: do nothing 
#modul1 + PC modul3:  

#STEP 0: Clean up desktop?

## PROMPT, CLEANUP OPTIONS
$cleanSetup = New-Object System.Management.Automation.Host.ChoiceDescription '&Yes, clear desktop', 'Clean desktop `& start'
$onlySetup = New-Object System.Management.Automation.Host.ChoiceDescription '&No, keep desktop content', 'Start'
$cancelSetup = New-Object System.Management.Automation.Host.ChoiceDescription '&Cancel exercise', 'Cancel'
$options = [System.Management.Automation.Host.ChoiceDescription[]]($cleanSetup, $onlySetup, $cancelSetup)
$title = 'PSK exercise starting..'
$message = 'Start with a clean desktop?'
$result = $host.ui.PromptForChoice($title, $message, $options, 0)
if ($result -eq '2') {
    exit
}
else {
    #$result:  0 = clean desktop then start, 1 = just start, 2 = cancel 
    $keepDesktop=$result
} 
## END PROMPT LOGIC

#STEP 1: BRING THE DESKTOP CLUTTER!!  #Located in ovelser/PSK#/Desktop/(..)
#exercise script path, needed to reset desktop and exercise files. 
$scriptPath= split-path -parent $MyInvocation.MyCommand.Definition  #AKA $PSScriptRoot in PS3+
$desktopPath="$($env:USERPROFILE)\Desktop"

## REMOVE EXISTING DESKTOP CONTENT?
if($keepDesktop -eq 0) {
    $localDesktopContent = Get-ChildItem -Recurse $desktopPath
    try {
        Remove-Item -Recurse -path $desktopPath -erroraction 'silentlycontinue'
    } catch {
	#do nothing? 
    }
}
## ALSO REMOVE TMP NOTEPAD DOCS IF PRESENT

## ADD DESKTOP CLUTTER FROM Desktop FOLDER IN SCRIPT DIR
$scriptDesktopPath="$($scriptPath)\Desktop"

$desktopContent=Get-ChildItem -Recurse $scriptDesktopPath
$copySuccessFlag=0
$copyStatus="`tOriginal path: $($scriptDesktopPath)"
foreach ($file in $desktopContent) {
    $targetPath = "$($file.FullName.replace($scriptDesktopPath, $desktopPath) )"
    #write-host $targetPath
    if(-not (test-path $targetPath)) {
        $copySuccessFlag=1
        #write-host "Copying file" $file.FullName "-> " $targetPath
        Copy-Item -Path $file.FullName -Destination $targetPath
        $copyStatus = "$($copyStatus)`n`t$($targetPath)"
    }
    else {
        #write-host "SKIP"
        #write-host $file.FullName + " already exists on desktop, skipping"
    }
    #$file | get-member #inspect object, learning powershell like a baws (uncomment to see available obj.methods/properties)
}
if($copySuccessFlag) {
    write-host "The following files were copied to users Desktop:"
    write-host $copyStatus
}

#step 2: Add exercise files to desktop clutter #Located in ovelser/PSK#/Files
# NO FILES TO ADD! # REMOVE THIS STEP? 




#step 3: Mount exercise files
## 3.1: VIRTUAL HARDDRIVE
## Exercise element: Locked BitLocker drive
#  Attaching VHD drive
$UserVHDPath = "$($scriptPath)\Files\bitlocked.vhd"
# Check if vhd file exists
$VHDExists = Test-Path -Path $UserVHDPath

If($VHDExists){
	Try{
		Mount-DiskImage -ImagePath $UserVHDPath -ErrorAction Stop
	}
	Catch{
		#$ErrorMessage = $_.Exception.Message
		Write-Host ""
		Write-Host "Could not attach VHD, probably already attached!"
	}

## BITLOCKER UNLOCK PART. UNCOMMENT TO BITLOCKER UNLOCK THE ATTACHED VHD DRIVE. 
#	# Find drives and their bitlocker status: -Off (no bitlocker) -On (bitlocker and unlocked) -Unknown (bitlocker and locked)
#	# $BitLocked = Get-bitlockervolume | where-object -property ProtectionStatus -EQ On
#	$BitLocked = Get-bitlockervolume | where-object -property ProtectionStatus -EQ Unknown
#	# ClearTXT password
#	$SecureString = ConvertTo-SecureString "NC3-UDDNC3-UDD" -AsPlainText -Force
#
#	If($BitLocked){
#		Unlock-BitLocker -MountPoint "$BitLocked" -Password $SecureString
#	}Else{
#		Write-Host "There are no new bitlocker drives to mount!"
#		Write-Host ""
#	}
}
else {
    
	Write-Host ""
	Write-Host "There are no VHD drives to attach!"
	Write-Host ""
}

## 3.2: VERACRYPT
$pgf = $env:ProgramFiles
$VCPath = "$pgf/VeraCrypt/"
#using this while testing: 
#$VCPath = "$($env:USERPROFILE)\Desktop\VeraCrypt\"
$veraPath = "$($scriptPath)\Files\Veracrypt_container"
$veraExists = Test-Path -Path $veraPath
write-host "Checking for veracrypt container at: $veraPath"
if(!$veraExists){
    Write-Host "Container not found."
    write-host "Newer windows versions do not allow automated creation of VC containers.`nPlease manually create the following using Veracrypt:"
    write-host "`tFile: $($veraPath)"
    write-host "`tSize: 50ish mb"
    write-host "`tPassword: NC3-UDDNC3-UDDNC3-UDDNC3-UDD"
    write-host "`tEncryption: AES"
    write-host "`tHash Algorithm: SHA-512"
    #THE BELOW PART DOES NOT WORK ON NEWER MACHINES.
    #Start-Process -FilePath "$VCPath\VeraCrypt Format.exe" -ArgumentList "/create `"$veraPath`" /size `"200M`" /password NC3-UDDNC3-UDDNC3-UDDNC3-UDD /encryption AES /hash sha-512 /filesystem exfat /pim 0 /silent"
    #run in this thread instead 
    #& "$VCPath\`"VeraCrypt Format.exe`" /create `"$veraPath`" /size `"50M`" /password NC3-UDDNC3-UDDNC3-UDDNC3-UDD /encryption AES /hash sha-512 /filesystem exfat /pim 0 /silent"
}
else {
    write-host "Veracrypt container found, attempting to mount.."
    try {
        Start-process -FilePath "$VCPath\VeraCrypt.exe" -wait -ArgumentList "/volume `"$veraPath`" /letter k /password NC3-UDDNC3-UDDNC3-UDDNC3-UDD /quit /silent"
        #$success = &"$VCPath\VeraCrypt.exe" /volume `"$veraPath`" /letter k /password NC3-UDDNC3-UDDNC3-UDDNC3-UDD /quit /silent
        write-host "$success! Starting veracrypt window.."
        Start-process -FilePath "$VCPath\VeraCrypt.exe"
    }   
    Catch{
		$ErrorMessage = $_.Exception.Message
        write-host "Failed to initialize VeraCrypt container."
		Write-Host "$ErrorMessage"
    }
}

### VERACRYPT SECTION ### 

#step 4: Set lock modes for exercise files
#step 5: Launch additional gibberish
# https://www.reddit.com/r/VeraCrypt/comments/w4xtnb/how_secure_is_verycrypt/
# dropbox
# one drive
# 
$urls=@("https://www.youtube.com/watch?v=pxw-5qfJ1dk","https://www.onedrive.com/", "https://www.reddit.com/r/VeraCrypt/comments/w4xtnb/how_secure_is_verycrypt/")
$UserDelPath = "$($env:USERPROFILE)\Desktop\*.txt"
$UserAddPath = "$($env:USERPROFILE)\Desktop\"

$TextFile1 = @("Kode1: dke53Mk#!d98HF"," ", "Kode2: sts171287", " ", "https://www.dropbox.com/shared/viborgmappen")
$TextFile2 = @("http://sextortion.rapeweb.ru"," ", "fD3rets!1403", " ", "Delt billeder af:", " ", "Louise", "Anne", "Kimmi", "Sofie", "Stine")
$TextFile3 = "Bitlocker Recovery Key: 605440-445907-441859-019305-449163-286264-036322-660407"
$File1 = "koder_pigelisten.txt"
$File2 = "rapeweb.txt"
$File3 = "bitlocker_recovery.txt"

$VCPath = "C:\Program Files\VeraCrypt\"
$TVPath = "C:\Program Files\VeraCrypt\"

#Debug lines print content of variables - prob use for logging
#Write-Host $var
#Write-Host $UserDelPath
#Write-Host $UserAddPath
#Write-Host $BitLocked

#Clean up before starting over
Get-Process notepad | Stop-Process
Get-Process VeraCrypt | Stop-Process
Remove-Item -path $UserDelPath

#Create files
New-Item -path $UserAddPath -name $File1 -type file
New-Item -path $UserAddPath -name $File2 -type file
New-Item -path $UserAddPath -name $File3 -type file

#Add-Content to files
foreach($text in $TextFile1){
    Add-Content $UserAddPath\$File1 $text
}

foreach($text in $TextFile2){
    Add-Content $UserAddPath\$File2 $text
}

Add-Content $UserAddPath\$File3 $TextFile3

foreach($url in $urls){
    Start-Process $url
}

Start-Process notepad $UserAddPath\$File1
Start-Process notepad $UserAddPath\$File2
#Start-Process taskmgr
Start-Process -FilePath "$VCPath\VeraCrypt.exe"
#Start-Process -FilePath "$TVPath\.exe"

taskkill /IM "powershell.exe" /F

# Attaching VHD drive and bitlock unlocking
# Path to VHD drive
