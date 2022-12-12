## Proof-of-Value Setup

This script is used to automate the initial configuration of the Login Enterprise Virtual Appliance. It currently leverages the Login Enterprise Public API v5. 
As of 12/9/2022 it only supports RDP and Storefront connectors.

## Example Usage
```
# RDP Target:
.\POC\Scripts\PovSetup.ps1 -Fqdn <YOUR_FQDN> -Token <YOUR_SECRET_TOKEN> -ConnectorType "RDP" -TargetRDPHost <MY_TARGET_HOST>

# StoreFront target
.\POC\Scripts\PovSetup.ps1 -Fqdn <YOUR_FQDN> -Token <YOUR_SECRET_TOKEN> -ConnectorType "Storefront" -ServerUrl <MY_STOREFRONT_URL> -TargetResource <MY_STORE_RESOURCE>

# Add -Debug "Y" to remove created resources for easier debugging and development
.\POC\Scripts\PovSetup.ps1 -Fqdn <YOUR_FQDN> -Token <YOUR_SECRET_TOKEN> -ConnectorType "RDP" -TargetRDPHost <MY_TARGET_HOST> -Debug "Y"
```


### Algorithm

* Import Active Directory Accounts from .csv file
    * Store Username, Password, Domain
    * Create Account in Login Enterprise
* Create Account Groups
    * Application Testing
    * Load Testing
    * Continuous Testing
* Create All Launchers Group
    * _Note: This will likely be redundant in 4.10, as new installations come pre-canned with All Launchers Launcher Group_
* Create Tests
    * Application Test
        * Assign Application Testing Account Group
        * Assign All Launchers Group
        * Configure Specified Connector
    * Load Test
        * Assign Load Testing Account Group
        * Assign All Launchers Group
        * Configure Specified Connector
    * Continuous Test
        * Assign Continuous Testing Account Group
        * Assign All Launchers Group
        * Configure Specified Connector
* Update Workflows:
    * _Note: This will be updated for 4.10, as new installations come pre-canned with Knowledge Worker workflows_
    * Add Out-of-box applications to Application Test
    * Add Out-of-box applications to Load Test
    * Add Out-of-box applications to Continuous Test
* Add SLA Reports:
    * Add Daily SLA Report 
    * Add Weekly SLA Report
* If in Debug mode:
    * Delete all resources created above

#### Notes

In order to import your Active Directory accounts, your .csv must be in the following format:

| Username    | Password            | Domain           | 
| ----------- | ------------------- |------------------|
| User1       | Ajd342@8o$4#!       | contoso.org      |
| ...         | ...                 | ...              |
| UserN       | Whfj983&0w2%!       | contoso.org      |

