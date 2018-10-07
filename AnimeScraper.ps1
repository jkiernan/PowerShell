If ($env:COMPUTERNAME -eq "JPK-HTPC") {
    $Script:DownloadDirectory = "D:\Seedbox\Completed_Downloads"
    $Script:AnimeList = Get-Content ".\AnimeList.txt"
}
If ($env:COMPUTERNAME -eq "JPK-PC2") {
    $Script:DownloadDirectory = "Z:\Completed_Downloads"
    $Script:AnimeList = Get-Content "D:\Dropbox\Your team Dropbox\James Kiernan\Computer\Documents\GitHub\PowerShell\AnimeList.txt"
}
$FolderPath = Get-ChildItem -Path "Y:" | Select -ExpandProperty Name
$Downloads = Get-ChildItem -Path $DownloadDirectory -Filter "`[HorribleSubs`]*.mkv" -Recurse | Select -exp FullName
foreach ($Episode in $Downloads) {
    $EpisodeName = Split-Path $Episode -Leaf
    $EpisodePath = Split-Path $Episode -Parent
    foreach ($Anime in $AnimeList) {
        If ($EpisodeName -match $Anime) {
            Write-Host "'$EpisodeName' matches  '$Anime'." -ForegroundColor Green
            foreach ($Folder in $FolderPath) {
                If ($Anime -eq $Folder) {
                    $NewEpisodeName = $EpisodeName.Substring(15) # Trim "[HorribleSubs]" prefix
                    $NewEpisodeName = $NewEpisodeName.Substring(0,$NewEpisodeName.Length-11) # Trim "[720].mkv" suffix & extension
                    $NewEpisodeName = $NewEpisodeName +".mkv" # Add back ".mkv" extension
                    If (Test-Path "Y:\$Folder") {
                        Write-Host "Folder '$Folder' for '$Anime' exists." -ForegroundColor Green
                        #Write-Host "New filename will be '$NewEpisodeName'." -ForegroundColor Green
                        If(!(Test-Path -Path "Y:\$Folder\$NewEpisodeName")) {
                            Write-Host "'Y:\$Folder\$NewEpisodeName' does not exist. File will now be copied." -ForegroundColor Green
                            Robocopy.exe $EpisodePath "Y:\$Folder" $EpisodeName /copyall
                        }
                    }
                }
            }
        }
    }
}