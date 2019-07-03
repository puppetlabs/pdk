$fso = New-Object -ComObject Scripting.FileSystemObject

$env:DEVKIT_BASEDIR = (Get-ItemProperty -Path "HKLM:\Software\Puppet Labs\DevelopmentKit").RememberedInstallDir64
# Windows API GetShortPathName requires inline C#, so use COM instead
$env:DEVKIT_BASEDIR = $fso.GetFolder($env:DEVKIT_BASEDIR).ShortPath
$env:RUBY_DIR       = "$($env:DEVKIT_BASEDIR)\private\ruby\2.4.5"
$env:SSL_CERT_FILE  = "$($env:DEVKIT_BASEDIR)\ssl\cert.pem"
$env:SSL_CERT_DIR   = "$($env:DEVKIT_BASEDIR)\ssl\certs"

function pdk {
  if ($Host.Name -eq 'Windows PowerShell ISE Host') {
    Write-Error ("The Puppet Development Kit cannot be run in the Windows PowerShell ISE.`n" + `
                "Open a new Windows PowerShell Console, or 'Start-Process PowerShell', and use PDK within this new console.`n" + `
                "For more information see https://puppet.com/docs/pdk/latest/pdk_known_issues.html and https://devblogs.microsoft.com/powershell/console-application-non-support-in-the-ise.")
    return
  }
  if ($env:ConEmuANSI -eq 'ON') {
    &$env:RUBY_DIR\bin\ruby -S -- $env:RUBY_DIR\bin\pdk $args
  } else {
    &$env:DEVKIT_BASEDIR\private\tools\bin\ansicon.exe $env:RUBY_DIR\bin\ruby -S -- $env:RUBY_DIR\bin\pdk $args
  }
}

Export-ModuleMember -Function pdk -Variable *
