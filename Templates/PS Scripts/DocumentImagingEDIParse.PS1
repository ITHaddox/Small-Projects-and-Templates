
$logPath = "C:\Users\TylerHadd\MTech\EDIProcessing_$(Get-Date -Format 'yyyyMMdd').log"
Start-Transcript -Path $logPath -Append

##ENABLE THESE 2 LINE FOR TESTING ONLY#################################################
$SourceDir = "C:\Users\TylerHadd\MTech\Testing EDI Files Mod Source\"
$MoveDir = "C:\Users\TylerHadd\MTech\Testing EDI Files Mod Dest\"
######################################################################################

##ENABLE THESE 2 LINE FOR LIVE
##$SourceDir = "..."
##$MoveDir = "..."
######################################################################################


function Test-FolderLock {
    param ([parameter(Mandatory=$true)][string]$Path)
    
    try {
        $folderItem = Get-Item -Path $Path -ErrorAction Stop
        $tempFilePath = Join-Path -Path $Path -ChildPath ([Guid]::NewGuid().ToString() + ".tmp")
        
        # Try to create a temporary file in the folder
        [IO.File]::Create($tempFilePath).Close()
        
        # If successful, delete the temporary file
        Remove-Item -Path $tempFilePath -Force
        
        return $false # Folder is not locked
    }
    catch {
        Write-Output "Folder $Path is locked or inaccessible: $_"
        return $true # Folder is locked or inaccessible
    }
}

function Test-FileLock {
    param ([parameter(Mandatory=$true)][string]$Path)
    $oFile = New-Object System.IO.FileInfo $Path
    if ((Test-Path -Path $Path) -eq $false) {
        return $false
    }
    try {
        $oStream = $oFile.Open([System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        if ($oStream) {
            $oStream.Close()
        }
        return $false
    } catch {
        # file is locked by a process
        return $true
    }
}

# Check if 
If(!(Test-Path $MoveDir)){
    New-Item -ItemType Directory -Path $MoveDir
}

# Check if source folder is accessible
if (Test-FolderLock -Path $SourceDir) {
    Write-Output "Source folder is locked or inaccessible. Exiting script."
    exit
}

# Check if destination folder is accessible
if (Test-FolderLock -Path $MoveDir) {
    Write-Output "Destination folder is locked or inaccessible. Exiting script."
    exit
}

If(test-path $SourceDir){
	$files = @(Get-ChildItem $SourceDir | Where-Object {!$_.PsIsContainer -and
														 $_.extension -eq ".EDI" -and
														 $_.length -gt 0})

	$x = $files | Sort-Object LastWriteTime | Select-Object -First 1
	"{0} files to process since {1}. . ." -f $files.Count, $x.LastWriteTime

	$DefaultLinDelim = "~"
	
	If($files.Count -gt 0){
		foreach ($file in $files){
			
			#Write-Output "Attempting to process file $($file.FullName)"
			
			try {
				if (Test-FileLock -Path $file.FullName) {
					Write-Output "File locked $($file.FullName) Skipping..."
					continue
				}
				
				$data = (get-content $file.fullname -raw)

				$IsEDIFile = $false

				If($data.Substring(0,3) -eq 'ISA'){

					$IsEDIFile = $true

					$segDelim = $data.substring(3,1)
					$ISASender = $data.substring(35,15).Trim()
					$linDelim = $data.substring(105,1)

					# If($linDelim -match '\w+'){
					#     $linDelim = '~'
					#     $data = $data -replace "`r","" -replace "`n",$linDelim
					# }
					If($linDelim -match '\w'){
						$data = $null
						$line = $null
						$msg = "* * * Error * * *  File ({0}) did not contain a valid line delimiter - Not processing" -f $file.FullName
						Write-Output $msg
					}
					# If($linDelim -eq "`r"){
					#     $linDelim = '~'
					#     $data = $data -replace "`r","~"
					# }
					# If($linDelim -eq "`n"){
					#     $linDelim = '~'
					#     $data = $data -replace "`n","~"
					# }
					# $data = $data -replace "`r","" -replace "`n",""
					If($linDelim -ne $DefaultLinDelim){
						$data = $data -replace $linDelim,$DefaultLinDelim
						$linDelim = $DefaultLinDelim
					}
					$data = $data -replace "`r","" -replace "`n",""

					$s = $data
					$x = 0
					$docType = $null
					$LineCount = 0
					$totalPOLines = 0 ##doc09092022BB
					$FileName = $MoveDir + 'out.working'
					If(Test-Path $FileName){
						$RenWorking = $FileName + '.' + (Get-Date -format "yyyyMMddHHmmsss")
						Rename-Item -Path $FileName -NewName $RenWorking
					}

					While($s.Length -gt 0){
						$x = $s.IndexOf($linDelim) + 1
						$line = $s.Substring(0,$x)
						$element = $line.Split($segDelim)

						If($element[0] -eq "ISA"){
							$EnvelopeControlNum = $element[13]
							$ISALine = $line
							$docType = $null
						}

						If($element[0] -eq "GS"){
							$DocDateTime = "{0}{1}" -f $element[4], $element[5]
							$GroupControlNum = $element[6]
							$GSLine = $line
						}

						If($element[0] -eq "ST"){
							$docType = $element[1]

							##If($docType -eq "850" -or $docType -eq "875" -or $docType -eq "860"){ ##doc09122022TH
							If($docType -eq "850" -or $docType -eq "875" -or $docType -eq "860" -or $docType -eq "880" -or $docType -eq "810"){ ##doc09122022TH
								Add-Content $FileName $ISALine -NoNewline
								Add-Content $FileName $GSLine -NoNewline
								
								$LineCount++
							}
						}

						If($element[0] -eq "BEG"){
							If($docType -eq "850"){
								$PONum = $element[3] -replace $linDelim,""
							}
						}

						If($element[0] -eq "BCH"){
							If($docType -eq "860"){
								[string]$PONum = $element[3] -replace $linDelim,""
							}
						}

						If($element[0] -eq "G50"){
							If($docType -eq "875"){
								$PONum = $element[3] -replace $linDelim,""
							}
						}

						###SPECIAL CUSTOMERS
						If($element[0] -eq "REF" -and $element[1] -eq "PO"){
							If($docType -eq "850" -and $ISASender -eq "3184834343"){
								$PONum = $element[2] -replace $linDelim,""
							}
						}

						##doc09092022BB--BEGIN

						If($element[0] -eq "CTT"){
							If(($docType -eq "850") -or ($docType -eq "860") -and $ISASender -eq "USDAWBSCM"){
								$totalPOLines = $element[1] -replace $linDelim,""  
							}     
						}
	  

						##doc09092022BB--END  
						
						##doc03012022TH--BEGIN

						If($element[0] -eq "REF" -and $element[1] -eq "1V"){
							If(($docType -eq "850") -or ($docType -eq "860") -and $ISASender -eq "0041498000097"){
								$PONum = $element[2] -replace $linDelim,""
							}
						}
						##doc03012022TH--END

						##doc09122022TH--BEGIN
						If($element[0] -eq "G01"){
							If($docType -eq "880"){
								$InvoiceNum = $element[2] -replace $linDelim,""
							}
						}

						If($element[0] -eq "BIG"){
							If($docType -eq "810"){
								$InvoiceNum = $element[2] -replace $linDelim,""
							}
						}
						##doc09122022TH--END

						##If($docType -eq "850" -or $docType -eq "875" -or $docType -eq "860"){ ##doc09122022TH
						If($docType -eq "850" -or $docType -eq "875" -or $docType -eq "860" -or $docType -eq "810" -or $docType -eq "880"){
							If($element[0] -eq "SE"){
								Add-Content $FileName $line -NoNewline
								$GELine = "GE*1*" + $GroupControlNum + $linDelim
								Add-Content $FileName $GELine -NoNewline
								$IEALine = "IEA*1*" + $EnvelopeControlNum + $linDelim
								Add-Content $FileName $IEALine -NoNewline
								
								If($docType -eq "850" -or $docType -eq "875" -or $docType -eq "860") {
									$FinalFileName = $MoveDir + "PO#" + $PONum + "~" + $DocDateTime + $GroupControlNum + ".hold"
									}
								ElseIf ($docType -eq "810" -or $docType -eq "880"){
									$FinalFileName = $MoveDir + "Invoice#" + $InvoiceNum + "~" + $DocDateTime + $GroupControlNum + ".hold"
									}     
								
								If(Test-Path $FinalFileName){
									$RenWorking = $FinalFileName + '.' + (Get-Date -format "yyyyMMddHHmmsss")
									Rename-Item -Path $FinalFileName -NewName $RenWorking
								}
								Rename-Item -Path $FileName -NewName $FinalFileName

								$LineCount = 0
							}
							Else {
								If($element[0] -ne "GE" -and $element[0] -ne "IEA"){
									Add-Content $FileName $line -NoNewline
								}
							}
						}
						## Do not remove this line ##
						$s = $s.Substring($x,$s.Length - $x)
					}
				}

				##Removes the source file if there were no errors, else renames source as .error##
				if($data.Length -gt 0){
					If (!($IsEDIFile)){
						$NonEDIMoveDir = $MoveDir + "nonEDI\"
						If(!(Test-Path $NonEDIMoveDir)){
							New-Item -ItemType Directory -Path $NonEDIMoveDir
						}
						Copy-Item -Path $file.FullName -Destination $NonEDIMoveDir
					}
					Remove-Item -Path $file.FullName
				}
				else{
					$RenameFullPath = $file.FullName + ".error"

					If (Test-Path $RenameFullPath){
						Remove-Item -Path $RenameFullPath
					}
					Rename-Item -Path $file.FullName -NewName $RenameFullPath
				}

				 ##doc09092022BB--BEGIN
				If ($ISASender -eq "USDAWBSCM"){
					for($i = 1; $i -le $totalPOLines; $i++){
						if($PONum.Length -gt 5){
							$PONum = $PONum.Substring($PONum.Length - 5) -replace $linDelim,""
						}
						$NewUSDAFileName = $MoveDir + "PO#" + ($PONum + "-" + $i.ToString().PadLeft(3,"0")) + "~" + $DocDateTime + $GroupControlNum + ".hold"
						Copy-Item $FinalFileName -Destination $NewUSDAFileName
					}
					Remove-Item -Path $FinalFileName
				}
				##doc09092022BB--END 
			
			} catch {
				Write-Output "Error processing file $($file.FullName)"
				continue
			}
		}
	}

	$Renames = Get-ChildItem $MoveDir -Filter *.hold
	foreach ($Rename in $Renames){
		$RenameFullPath = $MoveDir + $Rename.BaseName + ".edi"

		If (Test-Path $RenameFullPath){
			Remove-Item -Path $RenameFullPath
		}
			Rename-Item -Path $Rename.FullName -NewName $RenameFullPath
	}

	$OutMsg = "Script Complete - {0} files moved" -f $Renames.Count
}
Else
{
	$OutMsg = "ScriptComplete - * * * WARNING! * * *  Source folder ({0}) does not exist!" -f $sourceDir
}

Write-Output $OutMsg
		


Stop-Transcript
