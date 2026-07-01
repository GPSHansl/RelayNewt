# ------------------------------------------------------------
# SMTP Test Sender
# Reads all settings from config.json
#
# Example config.json:
#
# {
#   "SMTPHost": "127.0.0.1",
#   "SMTPPort": 587,
#
#   "Recipients": [
#     {
#       "Name": "sender legal",
#       "From": "firstname.lastname@gmx.de",
#       "To": "firstname.lastname@gmail.com"
#     },
#     {
#       "Name": "sender illegal",
#       "From": "lastname@gmx.de",
#       "To": "firstname.lastname@gmail.com",
#       "ExpectSuccess": false
#     }
#   ]
# }
# ------------------------------------------------------------

$configFile = Join-Path $PSScriptRoot "config.json"

if (!(Test-Path $configFile)) {
    Write-Error "Konfigurationsdatei '$configFile' nicht gefunden."
    exit 1
}

$config = Get-Content $configFile -Raw | ConvertFrom-Json

$SMTPHost = $config.SMTPHost
$SMTPPort = [int]$config.SMTPPort
$DebugSMTP   = $config.DebugSMTP

$testsTotal  = 0
$testsPassed = 0
$testsFailed = 0

Write-Host ""
Write-Host "========================================"
Write-Host " SMTP SEND TEST START"
Write-Host "========================================"

function Send($writer, $reader, $cmd) {

    if ($DebugSMTP) {
        Write-Host ">> $cmd"
    }

    $writer.WriteLine($cmd)
    $writer.Flush()

    # read response after a short delay to give the server time to respond
    Start-Sleep -Milliseconds 300

    $lines = @()

    while ($stream.DataAvailable)
    {
        $line = $reader.ReadLine()
        if ($DebugSMTP) {
            Write-Host $line
        }
        $lines += $line
    }

    return $lines
}

foreach ($entry in $config.Recipients)
{
    $testsTotal++

    $testName = $entry.Name
    if ([string]::IsNullOrWhiteSpace($testName))
    {
        $testName = "Test $testsTotal"
    }

    $From = $entry.From
    $To   = $entry.To

    # Default: Erfolg wird erwartet
    $expectSuccess = $true
    if ($null -ne $entry.ExpectSuccess)
    {
        $expectSuccess = [bool]$entry.ExpectSuccess
    }

    # --------------------------------------------------------
    # New UID
    # --------------------------------------------------------

    $uid = -join ((1..4) | ForEach-Object { '{0:X2}' -f (Get-Random -Maximum 256) })

    # --------------------------------------------------------
    # SMTP connection and test
    # --------------------------------------------------------

    $client = New-Object System.Net.Sockets.TcpClient
    $client.Connect($SMTPHost, $SMTPPort)

    $stream = $client.GetStream()
    $writer = New-Object System.IO.StreamWriter($stream)
    $reader = New-Object System.IO.StreamReader($stream)

    function Test-SMTPResult($response, $expectedStatus, $executedCommand)
    {
        if ($response.Count -gt 0 -and $response -match "^$expectedStatus")
        {
            return $true
        }
        if ($debugSMTP)
        {
            Write-Host ""
            Write-Host "#############################################"
            Write-Host "# TEST FAILED"
            Write-Host "#############################################"
            Write-Host "Test            : $testName"
            Write-Host "UID             : $uid"
            Write-Host "From            : $From"
            Write-Host "To              : $To"
            Write-Host "Expected Status : $expectedStatus"
            Write-Host "Actual Response : $($response -join "`n")"
            Write-Host "Executed Command: $executedCommand"
            Write-Host "#############################################"
        }
        return $false
    }

    Write-Host ""
    Write-Host "--------------------------------------------------"
    Write-Host "Test           : $testName"
    Write-Host "UID            : $uid"
    Write-Host "From           : $From"
    Write-Host "To             : $To"
    Write-Host "ExpectSuccess  : $expectSuccess"
    Write-Host "--------------------------------------------------"

    $ok = $true

    $response = Send $writer $reader "EHLO test.local"
    $ok = $ok -and (Test-SMTPResult $response "(2\d\d)" "EHLO")

    if ($ok)
    {
        $response = Send $writer $reader "MAIL FROM:<$From>"
        $ok = $ok -and (Test-SMTPResult $response "(250)" "MAIL FROM")
    }

    if ($ok)
    {
        $response = Send $writer $reader "RCPT TO:<$To>"
        $ok = $ok -and (Test-SMTPResult $response "(250)" "RCPT TO")
    }

    if ($ok -and $expectSuccess)
    {
        $response = Send $writer $reader "DATA"
        $ok = $ok -and (Test-SMTPResult $response "(354)" "DATA")
    }

    if ($ok -and $expectSuccess)
    {
        $body = @"
From: <$From>
To: <$To>
Subject: RelayNewt Test Mail [$uid]

Hi,

this is a test mail from RelayNewt.

UID  : $uid
Test : $testName
From : $From
To   : $To

-- RelayNewt
"@

        foreach ($line in $body -split "`n")
        {
            Send $writer $reader $line.TrimEnd("`r")
        }

        $response = Send $writer $reader "."
        $ok = $ok -and (Test-SMTPResult $response "(2\d\d)" "End of DATA")
    }

    Send $writer $reader "QUIT"

    $client.Close()

    if ($ok)
    {
        Write-Host "PASS"
        $testsPassed++
    }
    else
    {
        if ($expectSuccess)
        {
            Write-Host "FAIL (expected success)"
            $testsFailed++
        }
        else
        {
            Write-Host "PASS (expected failure)"
            $testsPassed++
        }
    }
}

Write-Host ""
Write-Host "========================================"
Write-Host " TEST SUMMARY"
Write-Host "========================================"
Write-Host ("Total Tests    : {0}" -f $testsTotal)
Write-Host ("Passed         : {0}" -f $testsPassed)
Write-Host ("Failed         : {0}" -f $testsFailed)
Write-Host "========================================"

if ($testsFailed -gt 0)
{
    exit 1
}

exit 0