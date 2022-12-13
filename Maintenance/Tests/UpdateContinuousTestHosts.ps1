Param(
    $Fqdn = "YOUR_FQDN",
    $Token = "YOUR_CONFIGURATION_LEVEL_TOKEN",
    $TestId = "YOUR_TEST_ID_TO_CHANGE",
    $PathToCsv = "YOUR_PATH_TO_HOSTLIST_CSV"
)

$global:Fqdn = $Fqdn
$global:Token = $Token 

$code = @"
public class SSLHandler
{public static System.Net.Security.RemoteCertificateValidationCallback GetSSLHandler()
    {return new System.Net.Security.RemoteCertificateValidationCallback((sender, certificate, chain, policyErrors) => { return true; });}
}
"@
Add-Type -TypeDefinition $code

# Query for existing accounts
function Get-LeTest {
    Param (
        [string]$TestId,
        [string]$Include = "environment"
    )

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:Token"
    }

    $Body = @{
        testId    = $TestId
        include   = $Include 
    } 

    $Parameters = @{
        Uri         = 'https://' + $global:Fqdn + '/publicApi/v5/tests' + "/$TestId"
        Headers     = $Header
        Method      = 'GET'
        body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response
}

function Update-LeTest {
    Param (
        [string]$TestId,
        [string]$body
    )

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:Token"
    }

    $Parameters = @{
        Uri         = 'https://' + $global:Fqdn + '/publicApi/v5/tests' + "/$TestId"
        Headers     = $Header
        Method      = 'PUT'
        body        = $body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response
}

# Get current state json configuration of test to modify
Write-Host "Attempting to collect current configuration for test with TestId: $TestId..."
$ResponseBody = Get-LeTest -TestId $TestId
Write-Host "Collected test configuration for test..."
# $ResponseBody.environment.connector.hostList

# Create Request Body by pulling all of the unchanged properties directly from the response body
Write-Host "Building request body..."
$RequestBody = New-Object -TypeName PSObject
$RequestBody | Add-Member -MemberType NoteProperty -Name "type" -Value $ResponseBody.type
$RequestBody | Add-Member -MemberType NoteProperty -Name "scheduleType" -Value $ResponseBody.scheduleType
$RequestBody | Add-Member -MemberType NoteProperty -Name "intervalInMinutes" -Value $ResponseBody.scheduleIntervalInMinutes
$RequestBody | Add-Member -MemberType NoteProperty -Name "numberOfSessions" -Value $ResponseBody.numberOfSessions
$RequestBody | Add-Member -MemberType NoteProperty -Name "enableCustomScreenshots" -Value $ResponseBody.enableCustomScreenshots
$RequestBody | Add-Member -MemberType NoteProperty -Name "repeatCount" -Value $ResponseBody.repeatCount
$RequestBody | Add-Member -MemberType NoteProperty -Name "isRepeatEnabled" -Value $ResponseBody.isRepeatEnabled
$RequestBody | Add-Member -MemberType NoteProperty -Name "isEnabled" -Value $ResponseBody.isEnabled
$RequestBody | Add-Member -MemberType NoteProperty -Name "restartOnComplete" -Value $ResponseBody.restartOnComplete
$RequestBody | Add-Member -MemberType NoteProperty -Name "name" -Value $ResponseBody.name
$RequestBody | Add-Member -MemberType NoteProperty -Name "description" -Value $ResponseBody.description
$RequestBody | Add-Member -MemberType NoteProperty -Name "environmentUpdate" -Value $ResponseBody.environment

# For each RDP host to add to environment, create a new object and append to the original list
Write-Host "Adding hosts to request body..."
$HostList = (Import-Csv -Path $PathToCsv)

Foreach ($Row in $HostList) {
    $Target = $Row.Target
    $NewRow = New-Object -TypeName PSObject
    $NewRow | Add-Member -MemberType NoteProperty -Name "enabled" -Value "True"
    $NewRow | Add-Member -MemberType NoteProperty -Name "endpoint" -Value $Target
    $RequestBody.environmentUpdate.connector.hostList += $NewRow
    Write-Host "Target $Target added to request body hostList ..." 
}

# Remove unchanged properties from request object
Write-Host "Removing unchanged test configuration elements..."
$RequestBody.environmentUpdate.PSObject.properties.remove('launcherGroups')
$RequestBody.environmentUpdate.PSObject.properties.remove('accountGroups')

# Convert object to json for PUT request
$RequestBody = $RequestBody | ConvertTo-Json -Depth 8
Write-Host "Request body built..."
 
# Update test to modify with updated request body
Update-LeTest -TestId $TestId -Body $RequestBody | Out-Null
Write-Host "Test with ID $TestId has been successfully updated with your provided list of hosts."
