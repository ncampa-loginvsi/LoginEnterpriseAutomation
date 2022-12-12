# ========================================================================================================================
# Write Welcome Dialogue
# ========================================================================================================================
function Greet-User {
    param (
        $ConnectorType,
        $TargetRDPHost,
        $ServerUrl,
        $TargetResource
    )
    
    Write-Host "[DEBUG] Tests using the $ConnectorType connector will be created..." -ForegroundColor "Cyan"
    if ($ConnectorType -eq "RDP") {
        Write-Host "[DEBUG] Tests will be aimed at $TargetRDPHost..." -ForegroundColor "Cyan"
    }
    elseif ($ConnectorType -eq "Storefront") {
        Write-Host "[DEBUG] Tests will be aimed at $TargetResource from the server located at $ServerUrl..." -ForegroundColor "Cyan"
    }

    
}

# ========================================================================================================================
# Create Accounts
# ========================================================================================================================
function Import-LeAccounts {
    param (
        $FilePath
    )
    # Import the csv
    Write-Host "[FILE] Attempting to import file..." -ForegroundColor "Yellow"
    $AccountData = (Import-Csv -Path $FilePath)
    Write-Host "[FILE] File import completed successfully." -ForegroundColor "Green"
    $NumAccounts = $AccountData.Count
    Write-Host "[ACCOUNTS] Found $NumAccounts accounts to import..." -ForegroundColor "White"
    $ids = @()
    # Grab the value from each column for each row and use it to create an account
    Foreach ($user in $accountData) {
        $username = $user.Username
        $password = $user.Password
        $domain = $user.Domain
        Write-Host "[ACCOUNTS] Attempting to add user $username..." -ForegroundColor "Yellow"
        $AccountId =  New-LeAccount -Username $username -Password $password -Domain $domain
        Write-Host "[ACCOUNTS] User $username created successfully..." -ForegroundColor "Green"
        $Id = $AccountId."id"
        Write-Host "[ACCOUNTS] User $username accountID: $Id..." -ForegroundColor "Blue"
        # Add new account id to list to return. This is used when adding users to account groups
        $ids += $Id
    }
    $ids
}

# ========================================================================================================================
# Create Account Group
# ========================================================================================================================
function New-AccountGroup {
    param (
        $GroupName,
        $Description
    )

    Write-Host "[GROUPS] Attempting to create $GroupName Group..." -ForegroundColor "Yellow"
    $AccountGroupId = New-LeAccountGroup -GroupName $GroupName -Description $Description
    Write-Host "[GROUPS] $GroupName name created successfully..." -ForegroundColor "Green"
    $Id = $AccountGroupId."id"
    Write-Host "[DEBUG] $GroupName Group id: $Id..." -ForegroundColor "Blue"
    $AccountGroupId
}

# ========================================================================================================================
# Create All Account Groups
# ========================================================================================================================
function Import-AccountGroups {

    # Cmon... DRY
    $ids = @()
    #Write-Host "[GROUPS] Creating Application Testing Group..."
    #$AppGroupId = New-AccountGroup -GroupName "Application Testing" -Description "These users will be dedicated to application testing."
    $AppGroupId = New-AccountGroup -GroupName "Application Testing" -Description "These users will be dedicated to validating applications post-change."
    $Id = $AppGroupId."id"
    $ids += $Id
    
    $ContGroupId = New-AccountGroup -GroupName "Load Testing" -Description "These users will be dedicated to hunting for failure."
    $Id = $ContGroupId."id"
    $ids += $Id

    $LoadGroupId = New-AccountGroup -GroupName "Continuous Testing" -Description "These users will be dedicated to baseline testing."
    $Id = $LoadGroupId."id"
    $ids += $Id

    $ids
}

# ========================================================================================================================
# Add Account Group Members
# ========================================================================================================================
function Add-LeAccountGroupMembers {
    param (
        $AccountIds
    )

    $AppTestGroupAccountId = $AccountIds[0]
    Write-Host "[GROUPS] Attempting to add user to Application Testing group..." -ForegroundColor "Yellow"
    Add-LeAccountGroupMember -GroupId $AccountGroupIds[0] -AccountId $AppTestGroupAccountId
    Write-Host "[DEBUG] User with id: $AppTestGroupAccountId has been added to the Application Testing Accounts Group..." -ForegroundColor "Blue"
    Write-Host "[GROUPS] Application Testing Account Group populated successfully..." -ForegroundColor "Green"

    $LoadTestGroupAccountIds = $AccountIds[1..25]
    Write-Host "[GROUPS] Attempting to add user to Application Testing group..." -ForegroundColor "Yellow"
    foreach ($Id in $LoadTestGroupAccountIds.Split(" ")) {
        Add-LeAccountGroupMember -GroupId $AccountGroupIds[1] -AccountId $Id
        Write-Host "[DEBUG] User with id: $Id has been added to the Load Testing Accounts Group..." -ForegroundColor "Blue"
    }
    Write-Host "[GROUPS] Load Testing Account Group populated successfully..." -ForegroundColor "Green"
        
    $ContinuousTestGroupAccountId = $AccountIds[26]
    Write-Host "[GROUPS] Attempting to add user to Continuous Testing group..." -ForegroundColor "Yellow"
    Add-LeAccountGroupMember -GroupId $AccountGroupIds[2] -AccountId $ContinuousTestGroupAccountId
    Write-Host "[DEBUG] User with id: $ContinuousTestGroupAccountId has been added to the Continuous Testing Accounts Group..." -ForegroundColor "Blue"
    Write-Host "[GROUPS] Continuous Testing Account Group populated successfully..." -ForegroundColor "Green"
    
}


# ========================================================================================================================
# Create Launcher Group
# ========================================================================================================================
function Import-LeLauncherGroup {
    param(
        $LauncherGroupName,
        $Description
    )
    Write-Host "[GROUPS] Attempting to create $LauncherGroupName..." -ForegroundColor "Yellow"
    $Id = New-LeLauncherGroup -GroupName "$LauncherGroupName" -Description "$Description."
    Write-Host "[GROUPS] $LauncherGroupName created successfully..." -ForegroundColor "Green"
    Write-Host "[DEBUG] $LauncherGroupName id: $Id" -ForegroundColor "Blue"
    $Id
}

# ========================================================================================================================
# Zip Test, TestId
# ========================================================================================================================
function Zip-Arrays {
    [CmdletBinding()]
    Param(
        $First,
        $Second,
        $ResultSelector = { ,$args }
    )

    [System.Linq.Enumerable]::Zip($First, $Second, [Func[Object, Object, Object[]]]$ResultSelector)
}

# ========================================================================================================================
# Create all Tests
# ========================================================================================================================
function Import-Tests {
    param (
        [string]$AccountGroupIds,
        [string]$LauncherGroupId,
        [string]$ConnectorType,
        [string]$TargetRDPHost, # This is either RDP Host or Store Resource
        [string]$ServerUrl,
        [string]$TargetResource # This is Storefront URL
    )

    #Write-Host $AccountGroupIds
    
    $AppTestGroupId = $AccountGroupIds.Substring(0, 36)
    $LoadTestGroupId = $AccountGroupIds.Substring(37, 36)
    $ContinuousTestGroupId = $AccountGroupIds.Substring(74, 36)
    
    $ids = @()
    if ($ConnectorType -eq "RDP") {
        Write-Host "[TESTS] Starting RDP Test Creation process..." -ForegroundColor "Yellow"
        $TestName = "RDP Application Test" 
        Write-Host "[TESTS] Attempting to create $TestName..." -ForegroundColor "Yellow"
        $RDPAppTestId = New-LeApplicationTest -TestName $TestName -Description "This test will validate the performance and functionality of the workflow." -AccountGroupId $AppTestGroupId -LauncherGroupId $LauncherGroupId -ConnectorType "RDP" -TargetRDPHost $TargetRDPHost
        Write-Host "[TESTS] $TestName test created successfully..." -ForegroundColor "Green"
        $Id = $RDPAppTestId."id"
        $ids += $Id
        Write-Host "[DEBUG] $TestName id: $Id..." -ForegroundColor "Blue"

        $TestName = "RDP Load Test"
        Write-Host "[TESTS] Attempting to create $TestName..." -ForegroundColor "Yellow"
        $RDPLoadTestId = New-LeLoadTest -TestName $TestName -Description "Baseline your virtual desktop host's performance and capacity." -AccountGroupId $LoadTestGroupId -LauncherGroupId $LauncherGroupId -ConnectorType "RDP" -TargetRDPHost $TargetRDPHost
        Write-Host "[TESTS] $TestName test created successfully..." -ForegroundColor "Green"
        $Id = $RDPLoadTestId."id"
        $ids += $Id
        Write-Host "[DEBUG] $TestName id: $Id..." -ForegroundColor "Blue"

        $TestName = "RDP Continuous Test"
        Write-Host "[TESTS] Start: Attempting to create $TestName..." -ForegroundColor "Yellow"
        $RDPContinuousTestId = New-LeContinuousTest -TestName $TestName -Description "Have a canary in the coalmine hunting for failure." -AccountGroupId $ContinuousTestGroupId -LauncherGroupId $LauncherGroupId -ConnectorType "RDP" -TargetRDPHost $TargetRDPHost
        Write-Host "[TESTS] $TestName test created successfully..." -ForegroundColor "Green"
        $Id = $RDPContinuousTestId."id"
        $ids += $Id
        Write-Host "[DEBUG] $TestName id: $Id..." -ForegroundColor "Blue"
        Write-Host "[TESTS] RDP Test Creation process completed successfully..." -ForegroundColor "Yellow"
    } elseif ($ConnectorType -eq "Storefront") {

        $TestName = "StoreFront Application Test"
        Write-Host "[TESTS] Attempting to create $TestName..." -ForegroundColor "Yellow"
        $StoreFrontAppTestId = New-LeApplicationTest -TestName $TestName -Description "This test will validate the performance and functionality of the workflow." -AccountGroupId $AppTestGroupId -LauncherGroupId $LauncherGroupId -ConnectorType "Storefront" -ServerUrl $ServerUrl -TargetResource $TargetResource
        Write-Host "[TESTS] $TestName test created successfully..." -ForegroundColor "Green"
        $Id = $StoreFrontAppTestId."id"
        $ids += $Id
        Write-Host "[DEBUG] $TestName id: $Id..." -ForegroundColor "Blue"

        $TestName = "StoreFront Load Test"
        Write-Host "[TESTS] Attempting to create $TestName..." -ForegroundColor "Yellow"
        $StoreFrontLoadTestId = New-LeLoadTest -TestName $TestName -Description "Baseline your virtual desktop host's performance and capacity." -AccountGroupId $AppTestGroupId -LauncherGroupId $LauncherGroupId -ConnectorType "Storefront" -ServerUrl $ServerUrl -TargetResource $TargetResource
        Write-Host "[TESTS] $TestName test created successfully..." -ForegroundColor "Green"
        $Id = $StoreFrontLoadTestId."id"
        $ids += $Id
        Write-Host "[DEBUG] $TestName id: $Id..." -ForegroundColor "Blue"  

        $TestName = "StoreFront Continuous Test"
        Write-Host "[TESTS] Start: Attempting to create $TestName..." -ForegroundColor "Yellow"
        $StoreFrontContinuousTestId = New-LeContinuousTest -TestName $TestName -Description "Have a canary in the coalmine hunting for failure." -AccountGroupId $ContinuousTestGroupId -LauncherGroupId $LauncherGroupId -ConnectorType "Storefront" -ServerUrl $ServerUrl -TargetResource $TargetResource
        Write-Host "[TESTS] $TestName test created successfully..." -ForegroundColor "Green"
        $Id = $StoreFrontContinuousTestId."id"
        $ids += $Id
        Write-Host "[DEBUG] $TestName id: $Id..." -ForegroundColor "Blue"
    } else {
        Write-Host "[ERROR] Connector Type: $ConnectorType is not recognized..." -ForegroundColor "Red"
    }

 
    $ids
}

# ========================================================================================================================
# Get the Ids of Sample Apps to Add to Tests
# ========================================================================================================================
function Get-LeApplicationsForTest {
    $Apps = Get-LeApplications
    [System.Collections.ArrayList]$AppsData = Zip-Arrays -First $Apps.name -Second $Apps.id
    $SampleAppNames = @(
        "Microsoft Excel (interaction)",
        "Microsoft PowerPoint (interaction)",
        "Microsoft Word"
    )
    $AppsData = $AppsData | Where-Object {$SampleAppNames -ccontains $_[0]}
    $SampleAppIds = @()
    Foreach ($AppId in $AppsData) {
        $Id = $AppId[1]
        $SampleAppIds += $Id
    }
    $SampleAppIds
}

function Update-LeTestWorkflows {
    param (
        [string]$TestIds,
        [string]$ApplicationIds
    )

    $ApplicationTestId = $TestIds.Substring(0, 36)
    Write-Host "[WORKFLOW] Attempting to update the Application Test workflow..." -ForegroundColor "Yellow"
    Update-LeWorkflow -TestId $ApplicationTestId -ApplicationIds $SampleAppIds | Out-Null
    Write-Host "[WORKFLOW] Application Test workflow updated..." -ForegroundColor "Green"

    $LoadTestId = $TestIds.Substring(37, 36)
    Write-Host "[WORKFLOW] Attempting to update the Load Test workflow..." -ForegroundColor "Yellow"
    Update-LeWorkflow -TestId $LoadTestId -ApplicationIds $SampleAppIds | Out-Null
    Write-Host "[WORKFLOW] Load Test workflow updated..." -ForegroundColor "Green"

    $ContinuousTestId = $TestIds.Substring(74, 36)
    Write-Host "[WORKFLOW] Attempting to update the Continuous Test workflow..." -ForegroundColor "Yellow"
    Update-LeWorkflow -TestId $ContinuousTestId -ApplicationIds $SampleAppIds | Out-Null
    Write-Host "[WORKFLOW] Continuous Test workflow updated..." -ForegroundColor "Green"
}

function Import-LeWorkflowUpdates {
    param (
        $TestIds
    )
    # Collect Ids for sample out-of-box Applications
    Write-Host "[WORKFLOW] Attempting to collect sample application Ids..." -ForegroundColor "Yellow"
    $SampleAppIds = Get-LeApplicationsForTest
    Write-Host "[WORKFLOW] Sample application Ids collected successfully..." -ForegroundColor "Green"

    # Add workflow to tests
    Write-Host "[WORKFLOW] Attempting to update Test Workflows..." -ForegroundColor "Yellow"
    Update-LeTestWorkflows -TestIds $TestIds -ApplicationIds $SampleAppIds
    Write-Host "[WORKFLOW] Test Workflows updated successfully..." -ForegroundColor "Green"
}

function Add-LeSLAReports {
    param (
        $TestIds
    )

    $ContinuousTestId = $TestIds[2]
    Write-Host "[REPORTS] Attempting to add Daily SLA Report..." -ForegroundColor "Yellow"
    New-LeSLAReport -TestId $ContinuousTestId -Frequency "daily" | Out-Null
    Write-Host "[REPORTS] Daily SLA Report has been added successfully..." -ForegroundColor "Green"

    Write-Host "[REPORTS] Attempting to add Weekly SLA Report..." -ForegroundColor "Yellow"
    New-LeSLAReport -TestId $ContinuousTestId -Frequency "weekly" | Out-Null
    Write-Host "[REPORTS] Weekly SLA Report has been added successfully..." -ForegroundColor "Green"
    
}



# ========================================================================================================================
# Cleanup all Created Resources
# ========================================================================================================================
function Debug-Cleanup {
    param(
        $AccountIds,
        $AccountGroupIds,
        $LauncherGroupId,
        $TestIds
    )

    Write-Host "[CLEANUP] Starting Account removal process..." -ForegroundColor "Red"
    Foreach ($Id in $AccountIds) {
        Start-Sleep 0.125
        Remove-LeAccount $Id
        Write-Host "[CLEANUP] Account removed..." -ForegroundColor "Red"
    }
    Write-Host "[CLEANUP] Account removal process complete..." -ForegroundColor "Red"

    Write-Host "[CLEANUP] Starting Account Group removal process..." -ForegroundColor "Red"
    Foreach ($Id in $AccountGroupIds) {
        Start-Sleep 0.125
        Remove-LeAccountGroup $Id
        Write-Host "[CLEANUP] Account Group removal process complete..." -ForegroundColor "Red"
    }
    Write-Host "[CLEANUP] Account Groups removed..." -ForegroundColor "Red"

    Write-Host "[CLEANUP] Starting Launcher Group removal process..." -ForegroundColor "Red"
    Remove-LeLauncherGroup -LauncherGroupId $LauncherGroupId | Out-Null
    Write-Host "[CLEANUP] Launcher Group removal process complete..." -ForegroundColor "Red"

    Write-Host "[CLEANUP] Starting Test removal process..." -ForegroundColor "Red"
    $TestTypes = @("Application Test", "Load Test", "Continuous Test")
    $Index = 0
    Foreach ($Test in $TestTypes) {
        $Id = $TestIds[$Index]
        $Type = $TestTypes[$Index]
        Write-Host "[DEBUG] Attempting to remove $Type id: $Id" -ForegroundColor "Blue"
        Remove-LeTest -TestId $Id | Out-Null
        $Index++
    }
    Write-Host "[CLEANUP] Test removal process complete......" -ForegroundColor "Red"
    
}

. .\POV\Scripts\API.ps1
Write-Debug "The module was imported"

#Add-LeSLAReports -TestIds "b4c4b07d-789b-49ad-acc3-f10b007f7725"

