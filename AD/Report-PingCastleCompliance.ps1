$Script:filePathBase = "<redacted>"
cd $Script:filePathBase

function runProgram {

    Write-Host "Starting PingCastle executable process... this is expected to take a few minutes."
    $fileExecutable = $Script:filePathBase + "PingCastle.exe"
    Start-Process -NoNewWindow -FilePath "$fileExecutable" -ArgumentList "--healthcheck --server <redacted>" -Wait
    $Script:xml = [xml](Get-Content -Path "<redacted>.xml")

}

runProgram

function programUpdateCheck {

    $url = "https://github.com/vletoux/pingcastle/releases/latest"
    $response = Invoke-WebRequest -Uri $url

    $latestReleaseUrl = $response.BaseResponse.ResponseUri.AbsoluteUri
    Write-Output "Latest Release URL: $latestReleaseUrl"
    $latestReleaseName = (Split-Path $latestReleaseUrl -Leaf)
    Write-Output "Latest Release Name: $latestReleaseName"

    if ($latestReleaseName -eq $xml.HealthCheckData.EngineVersion) {
       
        $Script:updateMessage = "Current version match for: $latestReleaseName"
        Write-Host $Script:updateMessage

    } else {

        try {

            $fileExecutable = $Script:filePathBase + "PingCastleAutoUpdater.exe"
            Start-Process -NoNewWindow -FilePath "$fileExecutable" -Wait
            Write-Host "Updating PingCastle using self-updater tool"

        }

        catch {

            $Script:updateMessage = "A newer version of PingCastle is available. Update now!"
            Write-Host $Script:updateMessage

        }
    }
}

programUpdateCheck

function analyticsReport {

    # Establish reportable metrics
    #$riskRuleFindings = @()

    $domain = $Script:xml.HealthCheckData.DomainFQDN
    $globalScore = $Script:xml.HealthCheckData.GlobalScore
    $staleObjectsScore = $Script:xml.HealthCheckData.StaleObjectsScore
    $privilegedGroupScore = $Script:xml.HealthCheckData.PrivilegiedGroupScore
    $trustScore = $xml.HealthCheckData.TrustScore
    $anomalyScore = $xml.HealthCheckData.AnomalyScore

    if ($globalScore -ge 25) { $complianceMessage = "Active Directory Security Health Score is at risk!"}
    else { $complianceMessage = "Active Directory Health Score is within accepted risk tolerances." }

    <#$riskRuleFindings += $Script:xml.HealthcheckData.RiskRules.HealthcheckRiskRule | where Category -eq "StaleObjects"
    $riskRuleFindings += $Script:xml.HealthcheckData.RiskRules.HealthcheckRiskRule | where Category -eq "PrivilegedAccounts"
    $riskRuleFindings += $Script:xml.HealthcheckData.RiskRules.HealthcheckRiskRule | where Category -eq "Trust"
    $riskRuleFindings += $Script:xml.HealthcheckData.RiskRules.HealthcheckRiskRule | where Category -eq "Anomalies"#>

    #Send report via email
    $Attachment = $Script:filePathBase + "<redacted>.html"

    $body = @"
    <html>  
      <body>
          <b><font size="+2">$complianceMessage</font></b></br>
          <b><font size="+1">$Script:updateMessage</font></b></br>
          </br>
          <b><u>High-level Statistics</u></b></br>
          </br>
          Domain:                   $domain</br>
          Global Score:             $globalScore</br>
          </br>
          Stale Object Score:       $staleObjectsScore</br>
          Privileged Group Score:   $privilegedGroupScore</br>
          Trust Score:              $trustScore</br>
          Anomaly Score:            $anomalyScore</br>
          </br>
          <b>Note:</b> See attachment for original html report. Note that there are expandable sections that provide detailed breakdowns of suggested remediation actions.<br>
      </body>  
    </html>  
"@

    $params = @{
        Attachment = $Attachment
        Body = $body 
        BodyAsHtml = $true
        Subject = "PingCastle Active Directory Compliance Report"
        From = '<redacted>' 
        To = '<redacted>'
        #Cc = '<redacted>'
        SmtpServer = '<redacted>'
        Port = 25
    }
 
    Send-MailMessage @params

}

analyticsReport
