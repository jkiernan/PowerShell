<#PSScriptInfo

.VERSION 2.0

.GUID a6048a09-3e66-467a-acd4-ce3e97098a65

.AUTHOR velecky@velecky.onmicrosoft.com

.COMPANYNAME

.COPYRIGHT

.TAGS

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


#>

<#

.DESCRIPTION
 WAN speed test

#>

Param()
$Script:SpeedResults = $null
$Script:UnsortedResults = $null
$Script:WanSpeed = $null
$Logfile1 = "C:\Scripts\SpeedTest-Results.csv"
$Logfile2 = "E:\Google Drive\Logs\SpeedTest-Results.log"
$DataTable = New-Object psobject

function LogWriteLocal(){
    Param ([String]$logString)
    $logString | Export-Csv -Path $Logfile1 -Append -NoTypeInformation
}
function LogWriteGoogle(){
    Param ([String]$logString)
	Add-Content $Logfile2 -Value $logString
}

Function downloadSpeed($strUploadUrl)
{
    $topServerUrlSpilt = $strUploadUrl -split 'upload'
    $url = $topServerUrlSpilt[0] + 'random2000x2000.jpg'
    $col = new-object System.Collections.Specialized.NameValueCollection
    $wc = new-object system.net.WebClient
    $wc.QueryString = $col
    $downloadElaspedTime = (measure-command {$webpage1 = $wc.DownloadData($url)}).totalmilliseconds
    $string = [System.Text.Encoding]::ASCII.GetString($webpage1)
    $downSize = ($webpage1.length + $webpage2.length) / 1Mb
    $downloadSize = [Math]::Round($downSize, 2)
    $downloadTimeSec = $downloadElaspedTime * 0.001
    $downSpeed = ($downloadSize / $downloadTimeSec) * 8
    $downloadSpeed = [Math]::Round($downSpeed, 2)
    return $downloadSpeed
}

<#
Using this method to make the submission to speedtest. Its the only way i could figure out how to interact with the page since there is no API. 
More information for later here: https://support.microsoft.com/en-us/kb/290591
#>
$objXmlHttp = New-Object -ComObject MSXML2.ServerXMLHTTP
$objXmlHttp.Open("GET", "http://www.speedtest.net/speedtest-config.php", $False)
$objXmlHttp.Send()

#Retrieving the content of the response.
[xml]$content = $objXmlHttp.responseText

<#
Gives me the Latitude and Longitude so i can pick the closer server to me to actually test against. It doesnt seem to automatically do this. 
Lat and Longitude for tampa at my house are $orilat = 27.9238 and $orilon = -82.3505
This is corroborated against: http://www.travelmath.com/cities/Tampa,+FL - It checks out.
#>
$oriLat = $content.settings.client.lat
$oriLon = $content.settings.client.lon

#Making another request. This time to get the server list from the site.
$objXmlHttp1 = New-Object -ComObject MSXML2.ServerXMLHTTP
$objXmlHttp1.Open("GET", "http://www.speedtest.net/speedtest-servers.php", $False)
$objXmlHttp1.Send()

#Retrieving the content of the response.
[xml]$ServerList = $objXmlHttp1.responseText

<#
$Cons contains all of the information about every server in the speedtest.net database.
I was going to filter this to US servers only which would speed this up a lot but i know we have overseas partners we run this against. 
Results returned look like this for each individual server:

url : http://nyc.speedtest.net/speedtest/upload.php
lat : 40.7127
lon : -74.0059
name : New York City, NY
country : United States
cc : US
sponsor : Speedtest.net
id : 10390

#>
$cons = $ServerList.settings.servers.server

#Below we calculate servers relative closeness to you by doing some math against latitude and longitude. 
foreach($val in $cons)
{
    $R = 6371;
    [float]$dlat = ([float]$oriLat - [float]$val.lat) * 3.14 / 180;
    [float]$dlon = ([float]$oriLon - [float]$val.lon) * 3.14 / 180;
    [float]$a = [math]::Sin([float]$dLat/2) * [math]::Sin([float]$dLat/2) + [math]::Cos([float]$oriLat * 3.14 / 180 ) * [math]::Cos([float]$val.lat * 3.14 / 180 ) * [math]::Sin([float]$dLon/2) * [math]::Sin([float]$dLon/2);
    [float]$c = 2 * [math]::Atan2([math]::Sqrt([float]$a ), [math]::Sqrt(1 - [float]$a));
    [float]$d = [float]$R * [float]$c;

    $ServerInformation +=
@([pscustomobject]@{Distance = $d; Country = $val.country; Sponsor = $val.sponsor; Url = $val.url })

}

$serverinformation = $serverinformation | Sort-Object -Property distance

#Runs the functions 4 times and takes the highest result.
$DLResults1 = downloadSpeed($serverinformation[0].url)
$SpeedResults += @([pscustomobject]@{Speed = $DLResults1;})

$DLResults2 = downloadSpeed($serverinformation[1].url)
$SpeedResults += @([pscustomobject]@{Speed = $DLResults2;})

$DLResults3 = downloadSpeed($serverinformation[2].url)
$SpeedResults += @([pscustomobject]@{Speed = $DLResults3;})

$DLResults4 = downloadSpeed($serverinformation[3].url)
$SpeedResults += @([pscustomobject]@{Speed = $DLResults4;})

$UnsortedResults = $SpeedResults | Sort-Object -Property speed
$WanSpeed = $UnsortedResults[3].speed
$DateTime = Get-Date -Format "MM-dd-yyyy HH:mm"
$DataTable | Add-Member -MemberType NoteProperty -Name "Time" -Value $DateTime
$DataTable | Add-Member -MemberType NoteProperty -Name "Mbps" -Value $WanSpeed
$Results = $DataTable | Select-Object "Time","Mbps"
$Results | Export-CSV $Logfile1 -Append -NoTypeInformation -Force