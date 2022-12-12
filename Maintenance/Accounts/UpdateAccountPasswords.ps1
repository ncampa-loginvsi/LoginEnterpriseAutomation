# Parameters:
# fqdn: fully qualified name of the Login Enterprise appliance (example.com not https://example.com/publicApi)
# token: the token generated from the appliance (requires Configuration level access)
# pathToCsv: the path to the csv file containing user information in the format Username, Password
Param(
    [Parameter(Mandatory=$true)]$fqdn,
    [Parameter(Mandatory=$true)]$token,
    [Parameter(Mandatory=$true)]$pathToCsv,
    $Count = "1000"
)

$global:fqdn = $fqdn
$global:token = $token 

$code = @"
public class SSLHandler
{public static System.Net.Security.RemoteCertificateValidationCallback GetSSLHandler()
    {return new System.Net.Security.RemoteCertificateValidationCallback((sender, certificate, chain, policyErrors) => { return true; });}
}
"@
Add-Type -TypeDefinition $code

# Query for existing accounts
function Get-LeAccounts {
    Param (
        [string]$orderBy = "username",
        [string]$Direction = "asc",
        [string]$Count = $Count,
        [string]$Include = "none"
    )

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }

    $Body = @{
        orderBy   = $orderBy
        direction = $Direction
        count     = $Count
        include   = $Include 
    } 

    $Parameters = @{
        Uri         = "https://" + $global:fqdn + "/publicApi/v5/accounts"
        Headers     = $Header
        Method      = "GET"
        body        = $Body
        ContentType = "application/json"
    }

    $Response = Invoke-RestMethod @Parameters
    $Response.items 
}

# Set configuration of account by account Id
function Set-LeAccount {
    Param (
        [string]$accountId,
        [string]$password,
        [string]$username,
        [string]$domain
    )

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }

    $Body = @{
        password = $password
        username = $username
        domain = $domain
    } | ConvertTo-Json

    $Parameters = @{
        Uri         = "https://" + $global:fqdn + "/publicApi/v5/accounts" + "/$accountId"
        Headers     = $Header
        Method      = "PUT"
        body        = $Body
        ContentType = "application/json"
    }

    $Response = Invoke-RestMethod @Parameters
    $Response.items 
}

# Import spreadsheet containing user profile specifications in Username, Password format
$AccountList = (Import-Csv -Path $pathToCsv)
$NumAccounts = $accountlist.Count
Write-Host "Collected $NumAccounts accounts to modify. Starting Account update process now..."

# For every row in the dataset
Foreach ($row in $accountlist) {
    # Grab their username and password
    $Username = $row.Username 
    $Password = $row.Password
    $Domain = $row.Domain
    Write-Host "Beginning Account update process for: $Username@$Domain..."
    # Only return the appliance account that matches the domain/user combination (remove domain check to only match username)
    $Account = Get-LeAccounts -Count $Count | Where-Object {($_.username -eq $Username) -and ($_.domain -eq $Domain)}
    Write-Host "Got account details for $Username@$Domain..."
    # Grab the row"s accountId
    $AccountId = $Account.id
    # Reconfigure the account using password from dataset
    Write-Host "Making changes for $Username@$Domain with accountId: $AccountId..."
    Set-LeAccount -accountId $AccountId -username $Username -password $Password -domain $Domain
    Write-Host "Successfully changed account configuration for $Username@$Domain..."
}