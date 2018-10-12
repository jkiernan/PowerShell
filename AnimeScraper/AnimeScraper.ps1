$Script:LogFile = "C:\Github\Powershell\AnimeScraper\AnimeScraper.log"
$Script:AnimeList = Get-Content "C:\Github\Powershell\AnimeScraper\AnimeList.txt"
Start-Transcript -Path $LogFile -Append
$Script:SeasonIndex = Import-CSV "C:\Github\Powershell\AnimeScraper\AnimeSeasonIndex.csv"
$Script:TvDir = "\\JPK-NAS2\TV_Shows"
If ($env:COMPUTERNAME -eq "JPK-HTPC") {
    $Script:DownloadDirectory = "D:\Seedbox\Completed_Downloads"
}
If ($env:COMPUTERNAME -eq "JPK-PC2") {
    $Script:DownloadDirectory = "\\JPK-HTPC\Seedbox\Completed_Downloads"
}
$FolderPath = Get-ChildItem -Path $TvDir| Select -ExpandProperty Name # Get list of TV Show folders
$Downloads = Get-ChildItem -Path $DownloadDirectory -Filter "`[HorribleSubs`]*.mkv" -Recurse | Select -exp FullName # Get list of mkv files with "[HorribleSubs]" in filename
foreach ($Episode in $Downloads) {
    $EpisodeName = Split-Path $Episode -Leaf # obtain episode/filename
    $EpisodePath = Split-Path $Episode -Parent # obtain source path/folder structure
    foreach ($Anime in $AnimeList) {
        If ($EpisodeName -match $Anime) { # Filename needs to match an entry from the $AnimeList array
            #Write-Host "'$EpisodeName' matches  '$Anime'." -ForegroundColor Green
            foreach ($Folder in $FolderPath) {
                If ($Anime -eq $Folder) { # $Anime needs to match a folder under \\JPK-NAS2\TV_Shows
                    $NewEpisodeName = $EpisodeName.Substring(15) # Trim "[HorribleSubs]" prefix
                    $NewEpisodeName = $NewEpisodeName.Substring(0,$NewEpisodeName.Length-11) # Trim "[720].mkv" suffix & extension
                    $NewEpisodeName = $NewEpisodeName +".mkv" # Add back ".mkv" extension
                    If (Test-Path "$TvDir\$Folder") { # Verify Anime has a folder under \\JPK-NAS2\TV_Shows 
                        #Write-Host "Folder '$Folder' for '$Anime' exists." -ForegroundColor Green
                        #Write-Host "New filename will be '$NewEpisodeName'." -ForegroundColor Green
                        If ($EpisodeName -match "Shingeki no Kyojin" `
                        -or $EpisodeName -match "Ace Attorney" `
                        -or $EpisodeName -match "JoJo's Bizarre Adventure" `
                        -or $EpisodeName -match "Toaru Majutsu no Index") {
                            foreach ($AnimeSeason in $SeasonIndex) {
                                $Script:SeasonName = $AnimeSeason.Name # Anime Season Name
                                $Script:SeasonFolder = $AnimeSeason.Folder # Anime Season Folder
                                If ($NewEpisodeName -match $SeasonName) { # If name matches season - e.g. "'Shingeki no Kyojin S3 - 38.mkv' matches 'Shingeki no Kyojin S3'"
                                    # Change $TvDir\$Folder to $TvDir\$Folder\$Season
                                    If(Test-Path -Path "$TvDir\$Folder\$SeasonFolder\$NewEpisodeName") {
                                        Write-Host "$TvDir\$Folder\$SeasonFolder\$NewEpisodeName already exists." -ForegroundColor Green
                                        Break
                                    } 
                                    Else { # Verify if \\JPK-NAS\TV_Shows\$Anime\$Season\$Episode exists
                                        Write-Host "'$TvDir\$Folder\$SeasonFolder\$NewEpisodeName' does not exist. File will now be copied." -ForegroundColor Green
                                        Robocopy.exe $EpisodePath "$TvDir\$Folder\$SeasonFolder" $EpisodeName /copyall # Copy file to permanent folder
                                        Write-Host "New episode name will be $NewEpisodeName."
                                        Rename-Item -LiteralPath $TvDir\$Folder\$SeasonFolder\$EpisodeName -NewName $NewEpisodeName -Force # Rename file
                                    }
                                    Break
                                }
                            }
                            Break
                        }
                        If (!($EpisodeName -match "Shingeki no Kyojin" -or $EpisodeName -match "Ace Attorney" -or $EpisodeName -match "JoJo's Bizarre Adventure")) {
                            If (Test-Path -Path "$TvDir\$Folder\$NewEpisodeName") {
                                Write-Host "$TvDir\$Folder\$NewEpisodeName already exists." -ForegroundColor Green
                                Break
                            }
                            Else {
                                    Write-Host "'$TvDir\$Folder\$NewEpisodeName' does not exist. File will now be copied." -ForegroundColor Green
                                    Robocopy.exe $EpisodePath "$TvDir\$Folder" $EpisodeName /copyall # Copy file to permanent folder
                                    Write-Host "New episode name will be $NewEpisodeName." -ForegroundColor Green
                                    Rename-Item -LiteralPath $TvDir\$Folder\$EpisodeName -NewName $NewEpisodeName -Force # Rename file
                            }
                        }
                    }
                }
            }
        }
    }
}
Stop-Transcript