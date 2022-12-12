$SSLHandler = @"
public class SSLHandler
{public static System.Net.Security.RemoteCertificateValidationCallback GetSSLHandler()
    {return new System.Net.Security.RemoteCertificateValidationCallback((sender, certificate, chain, policyErrors) => { return true; });}
}
"@
Add-Type -TypeDefinition $SSLHandler

# ========================================================================================================================
# Get Applications
# ========================================================================================================================
function Get-LeApplications {
    Param (
        [string]$orderBy = "name",
        [string]$Direction = "asc",
        [string]$Count = "100",
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
        Uri         = 'https://' + $global:fqdn + '/publicApi/v5/applications'
        Headers     = $Header
        Method      = 'GET'
        body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response.items 
}

# ========================================================================================================================
# Get Application
# ========================================================================================================================
function Get-LeApplication {
    Param (
        [string]$ApplicationId
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
        Uri         = 'https://' + $global:fqdn + '/publicApi/v5/applications'
        Headers     = $Header
        Method      = 'GET'
        body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response.items 
}

# ========================================================================================================================
# Create Account
# ========================================================================================================================
function New-LeAccount {
    Param (
        [string]$username,
        [string]$password,
        [string]$domain
    )

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $token"
    }

    $Body = @{
        username = $username
        domain = $domain
        password = $password
    } | ConvertTo-Json

    $Parameters = @{
        Uri         = "https://" + $global:fqdn + "/publicApi/v5/accounts"
        Headers     = $Header
        Method      = "POST"
        body        = $Body
        ContentType = "application/json"
    }
    
    #Invoke-RestMethod @Parameters
    $Response = Invoke-RestMethod @Parameters
    $Response
}

# ========================================================================================================================
# Create Account Group
# ========================================================================================================================
function New-LeAccountGroup {
    Param (
        [string]$GroupName,
        [string]$Description
    )

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $token"
    }

    $Body = @"
{
    "type": "Selection",
    "name": "$GroupName",
    "description": "$Description"
    }
"@

    $Parameters = @{
        Uri         = "https://" + $global:fqdn + "/publicApi/v5/account-groups"
        Headers     = $Header
        Method      = "POST"
        body        = $Body
        ContentType = "application/json"
    }
    
    Invoke-RestMethod @Parameters
    $Response.items 
}

function Add-LeAccountGroupMember {
    Param (
        [string]$GroupId,
        [string]$AccountId
    )

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }

    $Body = @"
[
    "$AccountId"
]
"@

    $Parameters = @{
        Uri         = "https://" + $global:fqdn + "/publicApi/v5/account-groups" + "/$GroupId" + "/members"
        Headers     = $Header
        Method      = "POST"
        body        = $Body
        ContentType = "application/json"
    }
    
    #$Parameters.body
    $Response = Invoke-RestMethod @Parameters
    $Response.items 
        
    }



# ========================================================================================================================
# Create Launcher Group
# ========================================================================================================================
function New-LeLauncherGroup {
    Param (
        [string]$GroupName,
        [string]$Description
    )

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $token"
    }

    $Body = @"
{
    "type": "Selection",
    "name": "$GroupName",
    "description": "$Description"
    }
"@

    $Parameters = @{
        Uri         = "https://" + $global:fqdn + "/publicApi/v5/launcher-groups"
        Headers     = $Header
        Method      = "POST"
        body        = $Body
        ContentType = "application/json"
    }
    
    $Response = Invoke-RestMethod @Parameters
    $Response."id"
}

# ========================================================================================================================
# Create Application Test
# ========================================================================================================================
function New-LeApplicationTest {
    Param (
        [string]$TestName,
        [string]$Description,
        [string]$AccountGroupId,
        [string]$LauncherGroupId,
        [string]$ConnectorType,
        [string]$TargetRDPHost, # This is either RDP Host or Storefront URL
        [string]$ServerUrl,
        [string]$TargetResource
    )

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $token"
    }

    if ($ConnectorType -eq "RDP"){
        $Body = @"
{
    "type": "ApplicationTest",
    "name": "$TestName",
    "description": "$Description",
    "connector": {
        "type": "Rdp",
        "hostList": [{
            "endpoint": "$TargetRDPHost",
            "enabled": true
        }]
    },
    "accountGroups": [
        "$AccountGroupId"
    ],
    "launcherGroups": [
        "$LauncherGroupId"
    ]
}
"@
    } elseif ($ConnectorType -eq "StoreFront") {
        $Body = @"
{
    "type": "ApplicationTest",
    "name": "$TestName",
    "description": "$Description",
    "connector": {
        "type": "Storefront",
        "serverUrl": "$ServerUrl",
        "resource": "$TargetResource"
    },
    "accountGroups": [
        "$AccountGroupId"
    ],
    "launcherGroups": [
        "$LauncherGroupId"
    ]
}
"@
    }

    $Parameters = @{
        Uri         = "https://" + $global:fqdn + "/publicApi/v5/tests"
        Headers     = $Header
        Method      = "POST"
        body        = $Body
        ContentType = "application/json"
    }
    
    
    #Write-Host $Parameters.body
    $Response = Invoke-RestMethod @Parameters
    $Response
}

# ========================================================================================================================
# Create Load Test
# ========================================================================================================================
function New-LeLoadTest {
    Param (
        [string]$TestName,
        [string]$Description,
        [string]$AccountGroupId,
        [string]$LauncherGroupId,
        [string]$ConnectorType,
        [string]$TargetRDPHost, # This is either RDP Host or Storefront URL
        [string]$ServerUrl,
        [string]$TargetResource
    )

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $token"
    }

    if ($ConnectorType -eq "RDP"){
        $Body = @"
{
    "type": "LoadTest",
    "name": "$TestName",
    "description": "$Description",
    "connector": {
        "type": "Rdp",
        "hostList": [{
            "endpoint": "$TargetRDPHost",
            "enabled": true
        }]
    },
    "accountGroups": [
        "$AccountGroupId"
    ],
    "launcherGroups": [
        "$LauncherGroupId"
    ]
}
"@
    } elseif ($ConnectorType -eq "StoreFront") {
        $Body = @"
{
    "type": "LoadTest",
    "name": "$TestName",
    "description": "$Description",
    "connector": {
        "type": "Storefront",
        "serverUrl": "$ServerUrl",
        "resource": "$TargetResource"
    },
    "accountGroups": [
        "$AccountGroupId"
    ],
    "launcherGroups": [
        "$LauncherGroupId"
    ]
}
"@
    }
    

    $Parameters = @{
        Uri         = "https://" + $global:fqdn + "/publicApi/v5/tests"
        Headers     = $Header
        Method      = "POST"
        body        = $Body
        ContentType = "application/json"
    }
    
    #Write-Host $Parameters.body
    $Response = Invoke-RestMethod @Parameters
    $Response
}


# ========================================================================================================================
# Create Continuous Test
# ========================================================================================================================
function New-LeContinuousTest {
    Param (
        [string]$TestName,
        [string]$Description,
        [string]$AccountGroupId,
        [string]$LauncherGroupId,
        [string]$ConnectorType,
        [string]$TargetRDPHost, # This is either RDP Host or Storefront URL
        [string]$ServerUrl,
        [string]$TargetResource
    )

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $token"
    }

# Endpoint is set to false because the account group is empty
    if ($ConnectorType -eq "RDP"){
        $Body = @"
{
"type": "ContinuousTest",
"name": "$TestName",
"description": "$Description",
"isEnabled": "false",
"connector": {
    "type": "Rdp",
    "hostList": [{
        "endpoint": "$TargetRDPHost",
        "enabled": true
    }]
},
"accountGroups": [
    "$AccountGroupId"
],
"launcherGroups": [
    "$LauncherGroupId"
]
}
"@
    } elseif ($ConnectorType -eq "StoreFront") {
        $Body = @"
{
    "type": "ContinuousTest",
    "name": "$TestName",
    "description": "$Description",
    "connector": {
        "type": "Storefront",
        "serverUrl": "$ServerUrl",
        "resource": "$TargetResource"
    },
    "accountGroups": [
        "$AccountGroupId"
    ],
    "launcherGroups": [
        "$LauncherGroupId"
    ]
}
"@
    }

    $Parameters = @{
        Uri         = "https://" + $global:fqdn + "/publicApi/v5/tests"
        Headers     = $Header
        Method      = "POST"
        body        = $Body
        ContentType = "application/json"
    }
    
    #Write-Host $Parameters.body
    $Response = Invoke-RestMethod @Parameters
    $Response
}

# ========================================================================================================================
# Update Workflow
# ========================================================================================================================
function Update-LeWorkflow {
    Param (
        [string]$TestId,
        [string]$ApplicationIds
    )

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $token"
    }

    $ExcelId = $ApplicationIds.Substring(0, 36)
    $PowerpointId = $ApplicationIds.Substring(37, 36)
    $WordId = $ApplicationIds.Substring(74, 36)
    
    $Body = @"
[        
    {
        "type": "AppInvocation",
        "applicationId": "$ExcelId",
        "isEnabled": true
    },
    {
        "type": "Delay",
        "delayInSeconds": 5,
        "isEnabled": true
    },
    {
        "type": "AppInvocation",
        "applicationId": "$PowerpointId",
        "isEnabled": true
    },
    {
        "type": "Delay",
        "delayInSeconds": 5,
        "isEnabled": true
    },
    {
        "type": "AppInvocation",
        "applicationId": "$WordId",
        "isEnabled": true
    }
]
"@

    $Parameters = @{
        Uri         = "https://" + $global:fqdn + "/publicApi/v5/tests" + "/$TestId" + "/workload"
        Headers     = $Header
        Method      = "POST"
        body        = $Body
        ContentType = "application/json"
    }
    
    
    $Parameters.body
    $Response = Invoke-RestMethod @Parameters
    $Response
}

# ========================================================================================================================
# Add Start time Thresholds
# ========================================================================================================================


# ========================================================================================================================
# Create SLA Reports
# ========================================================================================================================
function New-LeSLAReport {
    Param (
        [string]$TestId,
        [string]$Frequency
    )

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $token"
    }
    
    $Body = @"
{
    "frequency": "$Frequency",
    "name" : "$Frequency SLA Report",
    "description": "Get a report from your canaries in the coalmine.",
    "latencyThreshold": {
        "isEnabled": true,
        "value": 5
    },
    "loginTimeThreshold": {
        "isEnabled": true,
        "value": 40
    },
    "notification": {
        isEnabled: false
    }
}
"@

    $Parameters = @{
        Uri         = "https://" + $global:fqdn + "/publicApi/v5/tests" + "/$TestId" + "/report-configurations"
        Headers     = $Header
        Method      = "POST"
        body        = $Body
        ContentType = "application/json"
    }
    
    $Parameters.Uri
    $Parameters.body
    $Response = Invoke-RestMethod @Parameters
    $Response
}





# ========================================================================================================================
# Remove Account
# ========================================================================================================================
function Remove-LeAccount {
    Param (
        [string]$AccountId
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
        accountId = $AccountId
    } 

    $Parameters = @{
        Uri         = "https://" + $global:fqdn + "/publicApi/v5/accounts" + "/$AccountId"
        Headers     = $Header
        Method      = "DELETE"
        body        = $Body
        ContentType = "application/json"
    }
    
    
    $Response = Invoke-RestMethod @Parameters
    $Response.items 
}
# ========================================================================================================================
# Remove Account Group
# ========================================================================================================================
function Remove-LeAccountGroup {
    Param (
        [string]$AccountGroupId
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
        accountId = $AccountId
    } 

    $Parameters = @{
        Uri         = "https://" + $global:fqdn + "/publicApi/v5/account-groups" + "/$AccountGroupId"
        Headers     = $Header
        Method      = "DELETE"
        body        = $Body
        ContentType = "application/json"
    }
    
    $Response = Invoke-RestMethod @Parameters
    $Response.items 
}

# ========================================================================================================================
# Remove Launcher Group
# ========================================================================================================================
function Remove-LeLauncherGroup {
    Param (
        [string]$LauncherGroupId
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
        accountId = $LauncherGroupId
    } 

    $Parameters = @{
        Uri         = "https://" + $global:fqdn + "/publicApi/v5/launcher-groups" + "/$LauncherGroupId"
        Headers     = $Header
        Method      = "DELETE"
        body        = $Body
        ContentType = "application/json"
    }
    
    $Response = Invoke-RestMethod @Parameters
    $Response 
}


# ========================================================================================================================
# Remove Test
# ========================================================================================================================
function Remove-LeTest {
    Param (
        [string]$TestId
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
        accountId = $TestId
    } 

    $Parameters = @{
        Uri         = "https://" + $global:fqdn + "/publicApi/v5/tests" + "/$TestId"
        Headers     = $Header
        Method      = "DELETE"
        body        = $Body
        ContentType = "application/json"
    }
    
    
    #$Parameters.body.accountId
    $Response = Invoke-RestMethod @Parameters
    $Response
}

