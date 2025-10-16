## -
## - Downloaded from micro-one.com
## - Operational Security
## -
## - Antivirus test on network share (v.3.1)
## - Script to test the antivirus protection on network share
## - Creation date        :: 06/06/2014
## - Last update on       :: 16/10/2025
## - Author               :: Micro-one (contact@micro-one.com)
## -
## ------

##
## ============================================================================
## CONFIGURATION - Edit these variables to customize the script
## ============================================================================
##

## --
## Network paths to monitor
## --
$uncPaths = @(
    "\\192.168.1.60\Share1",
    "\\192.168.1.60\Share2"
)

## --
## Test timing configuration
## --
$intervalMinutes = 5                        # Interval between each test cycle (in minutes)
$waitAfterWriteSeconds = 10                 # Delay after writing EICAR file before verification (in seconds)

## --
## Log file configuration
## --
$logFile = ".\AVTestLog.txt"                # Log file path

## --
## Email notification configuration
## --
$adminEmail = "AntivirusTeam@example.org"   # Recipient email address (To)
$emailFrom = "ScriptAuto@example.org"       # Sender email address (From)
$emailSubject = "Antivirus not working - File not deleted"  # Email subject

## --
## SMTP server configuration
## --
## SMTP Configuration examples:
## - Port 587 with TLS (STARTTLS) : $smtpPort = 587, $smtpUseTLS = $true, $smtpUseSSL = $false
## - Port 465 with SSL            : $smtpPort = 465, $smtpUseTLS = $false, $smtpUseSSL = $true
## - Port 25 without encryption   : $smtpPort = 25, $smtpUseTLS = $false, $smtpUseSSL = $false

$smtpServer = "smtp.mycompany.com"          # SMTP server address
$smtpPort = 587                             # SMTP port (587=TLS, 465=SSL, 25=Clear)
$smtpUser = "ScriptAuto@example.org"        # SMTP username (usually full email address)
$smtpPassword = "Pa$$w0rd$!"                # SMTP password (in plain text - will be converted to secure string)
$smtpUseTLS = $true                         # Use TLS encryption (recommended for port 587)
$smtpUseSSL = $false                        # Use SSL encryption (for port 465)
$smtpTimeout = 30000                        # SMTP timeout in milliseconds (30 seconds)

## --
## Email template
## --
$emailTemplate = @"
Hello,

The EICAR test file was not deleted from the following path after $waitAfterWriteSeconds seconds:

Path: {0}
Date: {1}

Please check that your antivirus or security system is working properly.

Sincerely,
The monitoring script
"@

##
## ============================================================================
## END OF CONFIGURATION - Do not edit below this line unless you know what you're doing
## ============================================================================
##

## --
# EICAR string - DO NOT EDIT
$eicarContent = 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*'

## --
# SMTP Password data management - DO NOT EDIT
$securePassword = $smtpPassword | ConvertTo-SecureString -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($smtpUser, $securePassword)

## --
## Function to write to log file
## --
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "dd/MM/yyyy_HH:mm:ss"
    $logMessage = "$timestamp :: $Level :: $Message"
    Add-Content -Path $logFile -Value $logMessage
    Write-Host $logMessage
}

## --
## Function to show popup message
## --
function Show-Popup {
    param(
        [string]$Message,
        [string]$Title = "Antivirus Alert"
    )
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show($Message, $Title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
}

## --
## Function to send email with TLS/SSL support
## --
function Send-EmailNotification {
    param(
        [string]$To,
        [string]$Subject,
        [string]$Body
    )
    
    try {
        Write-Log "Attempting to send email to $To" "DEBUG"
        Write-Log "SMTP Server: ${smtpServer}:${smtpPort}" "DEBUG"
        Write-Log "Encryption mode: SSL=$smtpUseSSL, TLS=$smtpUseTLS" "DEBUG"
        
        # For SSL (port 465), we need to use .NET SmtpClient as Send-MailMessage has issues with SSL
        if ($smtpUseSSL) {
            Write-Log "Using SSL encryption with .NET SmtpClient" "DEBUG"
            
            # Create SMTP client
            $smtpClient = New-Object System.Net.Mail.SmtpClient($smtpServer, $smtpPort)
            $smtpClient.EnableSsl = $true
            $smtpClient.Timeout = $smtpTimeout
            $smtpClient.Credentials = New-Object System.Net.NetworkCredential($smtpUser, $credential.GetNetworkCredential().Password)
            
            # Create mail message
            $mailMessage = New-Object System.Net.Mail.MailMessage
            $mailMessage.From = $emailFrom
            $mailMessage.To.Add($To)
            $mailMessage.Subject = $Subject
            $mailMessage.Body = $Body
            $mailMessage.IsBodyHtml = $false
            
            # Send email
            $smtpClient.Send($mailMessage)
            
            # Cleanup
            $mailMessage.Dispose()
            $smtpClient.Dispose()
            
            Write-Log "Email successfully sent to $To via ${smtpServer}:${smtpPort} (SSL)" "SUCCESS"
            return $true
        }
        elseif ($smtpUseTLS) {
            # Use Send-MailMessage for TLS (port 587)
            Write-Log "Using TLS encryption (STARTTLS) with Send-MailMessage" "DEBUG"
            
            $mailParams = @{
                To         = $To
                From       = $emailFrom
                Subject    = $Subject
                Body       = $Body
                SmtpServer = $smtpServer
                Port       = $smtpPort
                Credential = $credential
                UseSsl     = $true
            }

            # Send the email
            Send-MailMessage @mailParams -ErrorAction Stop
            Write-Log "Email successfully sent to $To via ${smtpServer}:${smtpPort} (TLS)" "SUCCESS"
            return $true
        }
        else {
            # Clear text connection (port 25)
            Write-Log "Using unencrypted SMTP connection (not recommended)" "WARNING"
            
            $mailParams = @{
                To         = $To
                From       = $emailFrom
                Subject    = $Subject
                Body       = $Body
                SmtpServer = $smtpServer
                Port       = $smtpPort
                Credential = $credential
            }

            # Send the email
            Send-MailMessage @mailParams -ErrorAction Stop
            Write-Log "Email successfully sent to $To via ${smtpServer}:${smtpPort} (No encryption)" "SUCCESS"
            return $true
        }
        
    } catch {
        Write-Log "Failed to send email via SMTP: $($_.Exception.Message)" "ERROR"
        
        # Detailed error logging
        if ($_.Exception.InnerException) {
            Write-Log "Inner exception: $($_.Exception.InnerException.Message)" "ERROR"
        }
        
        # Additional troubleshooting info
        Write-Log "Troubleshooting: Verify SMTP server (${smtpServer}:${smtpPort}), credentials, and firewall rules" "INFO"
        
        return $false
    }
}

##
## ============================================================================
## MAIN SCRIPT - Antivirus monitoring loop
## ============================================================================
##

# Initialize log file
if (Test-Path $logFile) {
    Write-Log "### Begin antivirus test script for NAS ###" "START"
} else {
    "### Antivirus Test Log File ###" | Out-File -FilePath $logFile -Encoding UTF8
    Write-Log "### Log file created ###" "START"
}

Write-Log "Script started - Testing $($uncPaths.Count) network paths" "START"
Write-Log "Configuration: Check interval = $intervalMinutes min, Wait after write = $waitAfterWriteSeconds sec" "INFO"

# Main monitoring loop
while ($true) {
    Write-Log "### Starting new test cycle ###" "INFO"
    
    $testNumber = 0
    foreach ($path in $uncPaths) {
        $testNumber++
        
        try {
            $fileName = "EICAR_$(Get-Random).txt"
            $filePath = Join-Path -Path $path -ChildPath $fileName

            Write-Log "Testing path $testNumber/$($uncPaths.Count): $path" "INFO"

            # Write EICAR file
            Set-Content -Path $filePath -Value $eicarContent -Encoding ASCII -ErrorAction Stop
            Write-Log "EICAR file written: $filePath" "INFO"

            # Wait for antivirus to react
            Start-Sleep -Seconds $waitAfterWriteSeconds

            # Check if file still exists
            if (Test-Path -Path $filePath) {
                # File still present - ANTIVIRUS NOT ACTIVE
                $errorMessage = "Antivirus status $path : NOT ACTIVE"
                Write-Log $errorMessage "ERROR"

                # Show popup warning
                $popupMessage = "[$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')]`n`n$errorMessage`n`nFile: $filePath"
                Show-Popup -Message $popupMessage -Title "⚠️ Antivirus Alert - NOT ACTIVE"

                # Send email notification
                try {
                    $messageBody = [string]::Format($emailTemplate, $filePath, (Get-Date))
                    $emailSent = Send-EmailNotification -To $adminEmail -Subject $emailSubject -Body $messageBody
                    
                    if ($emailSent) {
                        Write-Log "Email notification successfully delivered" "SUCCESS"
                    } else {
                        Write-Log "Email notification failed - check SMTP configuration" "ERROR"
                    }
                } catch {
                    Write-Log "Exception during email sending: $_" "ERROR"
                }

                # Try to delete the file manually
                try {
                    Remove-Item -Path $filePath -Force -ErrorAction Stop
                    Write-Log "EICAR file manually deleted: $filePath" "INFO"
                } catch {
                    Write-Log "Failed to delete EICAR file: $_" "ERROR"
                }
            } else {
                # File was deleted - ANTIVIRUS ACTIVE
                Write-Log "Antivirus status $path : Active" "SUCCESS"
            }

        } catch {
            Write-Log "Error processing path '$path': $_" "ERROR"
        }
    }

    Write-Log "### Test cycle completed ###" "INFO"
    Write-Log "Waiting $intervalMinutes minute(s) before next test..." "INFO"
    Start-Sleep -Seconds ($intervalMinutes * 60)
}

## --
## End of script
##
