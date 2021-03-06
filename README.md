# Qlik Sense Authentication module with Office 365

Qlik Sense NodeJs module to authenticate with Office 365 in Qlik Sense. Based on the Ticketing authentication mechanism for Qlik Sense.

## Setup step by step
---
### Microsoft Office 365 Application
1. Go to Microsoft Application Registration Portal, Login and Create a new Application https://apps.dev.microsoft.com/. You'll be given an Application Id. This will be your **client_id**. Copy it somewhere for later.

![](https://github.com/mjromper/qlik-auth-office365/raw/master/docs/images/createapp.png)
2. Generate a new password for this application. This will be the **client_secret**. Copy it somewhere when presented as you won't be able to see it again.

![](https://github.com/mjromper/qlik-auth-office365/raw/master/docs/images/generatepassword.png)
3. Add "Web" as the Platform and set the redirect URI. Select a port number at your choice (different from the ones already in used by Qlik Sense). **https://your_sense_server_host:5555/oauth2callback**

![](https://github.com/mjromper/qlik-auth-office365/raw/master/docs/images/webapplicationredirect.png)
4. Save your changes.
![](https://github.com/mjromper/qlik-auth-office365/raw/master/docs/images/saveconfig.png)

### Installation of this module

* Launch PowerShell in Administrator mode (right-click and select Run As Administrator)
* Create and change directory to an empty directory, i.e. C:\TempO365

```powershell
    mkdir \TempO365; cd \TempO365
```

* Enter the below command exactly as it is (including parentheses):

```powershell
    (Invoke-WebRequest "https://raw.githubusercontent.com/mjromper/qlik-auth-office365/master/setup.ps1" -OutFile setup.ps1) | .\setup.ps1
```

This will download and execute the setup script.

When the downloading and installation of the modules including their dependencies are finished you will be prompted for some configuration options.

```
Enter name of user directory (prefix) [office365]:
<any single word is valid, default: 'office365'>

Enter QS hostname []:
<enter Qlik Sense hostname, ie: yourqliksenseserver.domain.com. Just hostname, not complete url>

Enter certificates folder path: [C:/ProgramData/Qlik/Sense/Repository/Exported Certificates/.Local Certificates]:
<certificates location, so that this module uses https, default: same self sign certificates of Qlik Sense>

Enter port [5555]:
<enter port this module will run on, default: 5555>

Application ID []:
<enter Office 365 application id>

Client Secret []:
<enter Office 365 client secret>
```

- ***port***: *the same used for the redirect URI at the Microsoft Application Registration Portal*
- ***certificates folder***: certificates folder should contain ***client.pem***, ***client_key.pem*** and ***root.pem*** files.


The script also creates a Virtual Proxy in Qlik Sense. Please verify configuration is as follows:


### Qlik Sense Virtual Proxy
1. Virtual Proxy in QMC
2. For Authentication module redirect URI enter the same ***servername*** and ***port*** you used for Authorized redirect URI in the Application Registration Portal.

![](https://github.com/mjromper/qlik-auth-office365/raw/master/docs/images/virtual-proxy.png)

Open the url https://(your_sense_server_host_name)/(directory)/hub

### Todos
 - Write Tests

License
----

MIT
