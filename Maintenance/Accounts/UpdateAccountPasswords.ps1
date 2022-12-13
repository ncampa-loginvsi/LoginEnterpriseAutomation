# Parameters:
# fqdn: fully qualified name of the Login Enterprise appliance (example.com not https://example.com/publicApi)
# token: the token generated from the appliance (requires Configuration level access)
# pathToCsv: the path to the csv file containing user information in the format Username, Password
Param(
    [Parameter(Mandatory=$true)]$Fqdn,
    [Parameter(Mandatory=$true)]$Token,
    [Parameter(Mandatory=$true)]$PathToCsv,
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
        [string]$OrderBy = "username",
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
        orderBy   = $OrderBy
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
        [string]$AccountId,
        [string]$Username,
        [string]$Password,
        [string]$Domain
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
        username = $Username
        password = $Password
        domain = $Domain
    } | ConvertTo-Json

    $Parameters = @{
        Uri         = "https://" + $global:fqdn + "/publicApi/v5/accounts" + "/$AccountId"
        Headers     = $Header
        Method      = "PUT"
        body        = $Body
        ContentType = "application/json"
    }

    $Response = Invoke-RestMethod @Parameters
    $Response.items 
}

# Import spreadsheet containing user profile specifications in Username, Password format
$AccountList = (Import-Csv -Path $PathToCsv)
$NumAccounts = $AccountList.Count
Write-Host "Collected $NumAccounts accounts to modify. Starting Account update process now..."

# For every row in the dataset
Foreach ($Row in $AccountList) {

    # Grab their username and password
    $Username = $Row.Username 
    $Password = $Row.Password
    $Domain = $Row.Domain

    # Only return the appliance account that matches the domain/user combination (remove domain check to only match username)
    Write-Host "Beginning Account update process for: $Username@$Domain..."
    $Account = Get-LeAccounts -Count $Count | Where-Object {($_.username -eq $Username) -and ($_.domain -eq $Domain)}
    Write-Host "Got account details for $Username@$Domain..."

    # Grab the user in that rows accountId
    $AccountId = $Account.id
    
    # Reconfigure the account using password from dataset
    Write-Host "Making changes for $Username@$Domain with accountId: $AccountId..."
    Set-LeAccount -AccountId $AccountId -Username $Username -Password $Password -Domain $Domain
    Write-Host "Successfully changed account configuration for $Username@$Domain..."
}