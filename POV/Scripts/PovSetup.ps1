Param(
    [string]$Fqdn,
    [string]$Token,
    [string]$FilePath = ".\POV\Resources\Accounts.csv",
    [string]$ConnectorType,
    [string]$TargetRDPHost,
    [string]$ServerUrl,
    [string]$TargetResource,
    [string]$Debug
)

$global:Fqdn = $Fqdn
$global:Token = $Token

function Main {
    param (
        $FilePath,
        $ConnectorType,
        $TargetRDPHost,
        $ServerUrl,
        $TargetResource,
        $Debug
    )

    Write-Host `n
    Write-Host "Welcome to the Login Enterprise Proof-Of-Value Setup tool. This tool will assist with getting you off the ground, and straight to finding the value..." -ForegroundColor "Cyan"
    Write-Host "Developed in December 2022 by Nick Campa for Login VSI..." -ForegroundColor "Cyan"
    Write-Host `n

    # Import functions from wd
    Write-Host "Start: Beginning function import process..." -ForegroundColor "White"
    . .\POV\Scripts\API.ps1
    Write-Host "[DEBUG] API Endpoint commands successfully imported..." -ForegroundColor "Green"
    . .\POV\Scripts\Helpers.ps1
    Write-Host "[DEBUG] API Helper functions successfully imported..." -ForegroundColor "Green"

    # Confirm connection parameters
    Greet-User -ConnectorType $ConnectorType -TargetRDPHost $TargetRDPHost -ServerUrl $ServerUrl -TargetResource $TargetResource
  
    # Import .csv file of accounts into the appliance
    "-" * 100
    Write-Host "[ACCOUNTS] Start: Beginning account import process..." -ForegroundColor "White"
    $AccountIds = Import-LeAccounts -FilePath $FilePath
    Write-Host "[ACCOUNTS] End: Account import process completed..." -ForegroundColor "White"
    "-" * 100

    # Create empty account groups to add users to
    Write-Host "[GROUPS] Start: Beginning account groups creation process..." -ForegroundColor "White"
    $AccountGroupIds = Import-AccountGroups
    Write-Host "[GROUPS] End: Account group creation process completed..." -ForegroundColor "White"
    "-" * 100

    Write-Host "[GROUPS] Start: Beginning account group population process..." -ForegroundColor "White"
    Add-LeAccountGroupMembers -AccountIds $AccountIds
    Write-Host "[GROUPS] End: Account Group population process completed..." -ForegroundColor "White"
    "-" * 100

    # Create empty launcher group to add launchers to
    # In 4.10 this will no longer be needed, should be a default group for new installations
    Write-Host "[GROUPS] Start: Beginning launcher group creation process..." -ForegroundColor "White"
    $LauncherGroupId = Import-LeLauncherGroup -LauncherGroupName "All Launchers" -Description "This is a group containing all launchers."
    Write-Host "[GROUPS] End: Launcher groups creation process completed..." -ForegroundColor "White"
    "-" * 100

    # AppId, LoadId, ContId
    Write-Host "[TESTS] Start: Beginning Test Creation process..." -ForegroundColor "White"
    $TestIds = Import-Tests -AccountGroupId $AccountGroupIds -LauncherGroupId $LauncherGroupId -ConnectorType $ConnectorType -TargetRDPHost $TargetRDPHost -ServerUrl $ServerUrl -TargetResource $TargetResource
    Write-Host "[TESTS] End: Tests Creation process completed..." -ForegroundColor "White"
    "-" * 100

    # Add sample applications to created tests (Will be replaced to add knowledge worker by default in 4.10)
    Write-Host "[WORKFLOW] Start: Beginnning workflow update process..." -ForegroundColor "White"
    Import-LeWorkflowUpdates -TestIds $TestIds
    Write-Host "[WORKFLOW] End: Workflow update process completed..." -ForegroundColor "White"
    "-" * 100

    # Add SLA Reports
    Write-Host "[WORKFLOW] Start: Beginnning workflow update process..." -ForegroundColor "White"
    Add-LeSLAReports -TestIds $TestIds
    Write-Host "[WORKFLOW] End: Workflow update process completed..." -ForegroundColor "White"
    "-" * 100
    


    if ($Debug -eq "Y") {
        Write-Host "[CLEANUP] Start: Beginning cleanup process..." -ForegroundColor "White"
        Debug-Cleanup -AccountIds $AccountIds -AccountGroupIds $AccountGroupIds -LauncherGroupId $LauncherGroupId -TestIds $TestIds
        Write-Host "[CLEANUP] End: Cleanup process has been completed..." -ForegroundColor "White"
        "-" * 100
    } 
    
    Write-Host "[DEBUG] Script has completed. Enjoy your proof of concept..." -ForegroundColor "Green"
    
}

# Pass non-sensitive arguments here, and call it from the command line: ".\ProofOfValue.ps1 -Fqdn <YOUR_FQDN> -Token <YOUR_SECRET_TOKEN>"
Main -FilePath $FilePath -ConnectorType $ConnectorType -TargetRDPHost $TargetRDPHost -ServerUrl $ServerUrl -TargetResource $TargetResource -Debug $Debug


#[string]$Fqdn,
#[string]$Token,
#[string]$FilePath,
#[string]$ConnectorType,
#[string]$Target # For now this will be either RDP host or Storefront URL

# CreateTest("Application Test", type="appTest")
# CreateTest("Capacity Baseline", type="loadTest")
# CreateTest("Hunting for Failure", type="contTest")

# Create Three tests:
# Create an Application Test (PowerPoint, Word, Excel, Notepad, Paint)
# Create a Load Test (PowerPoint, Word, Excel, Notepad, Paint)
# Create a Continuous Test (PowerPoint, Word, Excel, Notepad, Paint)

# Add three locations:
# Create new location 1
# Create new location 2
# Create new location 3


# READD THESE
#chrisMoltisanti,Password2,newark.nj
#paulieWalnuts,Password3,newark.nj