# World of Workflows Business Edition Installation Instructions

Welcome to the World of Workflows Business Edition Installation Instructions. You can use these instructions to create the configuration file for World of Workflows and then deploy the edition to Azure, AWS, GCP or On-Premises.

## Requirements

- Entra ID (Azure AD) - World of Workflows Business Edition requires Entra Id
- Microsoft Powershell
- Microsoft Graph PowerShell
  - Install using the script below:
    ```Powershell
    Install-Module Microsoft.Graph -Scope CurrentUser
    ```
## Instructions

1. Open a browser and browse to [Microsoft Entra Id (Microsoft Azure ID)](https://portal.azure.com/#view/Microsoft_AAD_IAM/)
2. Open a PowerShell Window
3. Run the Script from this repo ```WOWFBEConfiguration.ps1```
4. Enter the Client Application Name or press Enter for Defaults
5. Enter the Server Application Name or press Enter for Defaults
6. Enter the Base URL of your Installation or press Enter for defaults
7. The Script will create the appropriate settings
8. Go back to the browser in Item 1
9. Choose **App registrations** from the left menu, or search for **App Registrations** from within **All Services**
10. Click **All applications** and click World of Workflows Server (or whatever you entered in step 5)
11. Click **API Permissions** from the left menu
12. Click **+ Add a permission**
13. Click **Microsoft Graph**
14. Click **Delegated permissions**, search for **profile**, click the checkbox to the left of **profile** and click the **Add Permissions Button**
15. Navigate back to [Microsoft Entra Id (Microsoft Azure ID)](https://portal.azure.com/#view/Microsoft_AAD_IAM/)
16. Click **Enterprise Applications** from the left menu.
17. Unselect **Application type == Enterprise Applications** by clicking the **x**
18. In the search box, type World of Workflows Server or whatever you typed for step 5
19. Select the Application (World of Workflows Server)
20. Click **Users and Groups** from the left menu
21. Click **+ Add user/group**
22. Click **None Selected** under Users and Groups
23. Find and add your user account and select it using the checkbox to the left
24. Click **Select**
25. Click **Assign**

Congratulations.

Now rename the file created by the Powershell from appsettings1.json to appsettings.json and copy it to the root folder of your Business Edition Installation.

Deploy your Business Edition Installation.

