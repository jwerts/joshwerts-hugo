+++
date = "2015-12-18T19:28:31-05:00"
title = "ArcSOC Memory Footprint with Powershell"
draft = true
description = "Determining ArcGIS Server process (ArcSOC.exe) memory footprint with Powershell"
+++

For years, I've stubbornly avoided learning Powershell simply relying on batch files for whatever small tasks I needed to accomplish, but recently I ran into some batch file hell and decided it would be easier to learn Powershell than to figure out how to do it in a batch file.

It turns out Powershell can be pretty useful (and not really that hard to learn).  Pipes are an awesome and something they definitely got right.

So when the need arose to determine the memory footprint of some ArcGIS Server services, Powershell seemed the way to go.  I'm still pretty much a Powershell beginner but here's some useful commands that got the job done...

#### Get all ArcSOC.exe processes and their memory "working set"
```ps1
Get-WmiObject win32_process |
  Where-Object {$_.name -eq "ArcSOC.exe"} |
  Select-Object Name, Commandline, WS |
  Sort-Object WS -descending |
  Format-Table Name, @{Label="Memory (MB)"; Expression={($_.WS / 1MB)}}, CommandLine -AutoSize
```

#### Export those processes to .csv
```ps1
Get-WmiObject win32_process |
  Where-Object {$_.name -eq "ArcSOC.exe"} |
  Sort-Object WS -descending |
  Select-Object Name, @{Label="Memory (MB)"; Expression={($_.WS / 1MB)}}, Commandline |
  Export-Csv ArcSoc_Processes.csv
```

#### Get the full memory footprint of all ArcGIS Server service instances
```ps1
(Get-WmiObject win32_process |
  Where-Object {$_.name -eq "ArcSOC.exe"} |
  Select-Object Name, WS |
  Measure-Object WS -sum) |
  Format-Table @{Label="Count"; Expression={$_.Count}}, @{Label="Memory (MB)"; Expression={$_.Sum / 1MB}} -AutoSize
```


```ps1
# Get all ArcSOC.exe processes that match these service names
Get-WmiObject win32_process |
  Where-Object {$_.name -eq "ArcSOC.exe" -and
  ($_.commandline -like '*GPService_ProTools*' -or
   $_.commandline -like '*MapService_MIP*' -or
   $_.commandline -like '*NetworkRouter_Fiber*')} |
  Select-Object Name, Commandline, WS |
  Sort-Object WS -descending |
  Format-Table Name, @{Label="Memory (MB)"; Expression={($_.WS / 1KB)}}, commandline -AutoSize

# Export to csv
Get-WmiObject win32_process |
  Where-Object {$_.name -eq "ArcSOC.exe" -and
  ($_.commandline -like '*GPService_ProTools*' -or
   $_.commandline -like '*MapService_MIP*' -or
   $_.commandline -like '*NetworkRouter_Fiber*')} |
   Sort-Object WS -descending |
   Select-Object Name, @{Label="Memory (MB)"; Expression={($_.WS / 1MB)}}, Commandline |
   Export-Csv ArcSoc_MIP_Processes.csv

# Sum Working memory
(Get-WmiObject win32_process |
  Where-Object {$_.name -eq "ArcSOC.exe" -and
    ($_.commandline -like '*GPService_ProTools*' -or
     $_.commandline -like '*MapService_MIP*' -or
     $_.commandline -like '*NetworkRouter_Fiber*')} |
    Select-Object Name, WS |
    Measure-Object WS -sum) |
    Format-Table @{Label="Count"; Expression={$_.Count}}, @{Label="Memory (MB)"; Expression={$_.Sum / 1MB}} -AutoSize
```
