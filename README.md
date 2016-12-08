# Qlik Sense Authentication module with Office 365

Qlik Sense NodeJs module to authenticate with Office 365 in Qlik Sense.

# Qlik-Auth-Office365

Qlik Sense NodeJs module to authenticate with Office 365 in Qlik Sense.
## Setup step by step
---
### Microsoft Office 365 Application
1. Go to Microsoft Application Registration Portal, Login and Create a new Application https://apps.dev.microsoft.com/ You'll be given an Application Id. This will be your **client_id**. Copy it somewhere for later.
![](https://github.com/mjromper/qlik-auth-office365/raw/master/docs/images/createapp.png)
2. Generate a new password for this application. This will be the **client_secret**. Copy it somewhere when presented as you won't be able to see it again.
![](https://github.com/mjromper/qlik-auth-office365/raw/master/docs/images/generatepassword.png)
3. Add "Web" as the Platform and set the redirect url https://host_sense_server:5555/oauth2callback
![](https://github.com/mjromper/qlik-auth-office365/raw/master/docs/images/webapplicationredirect.png)
4. Save your changes.
![](https://github.com/mjromper/qlik-auth-office365/raw/master/docs/images/saveconfig.png)

### Qlik Sense Virtual Proxy
1. Create a new Virtual Proxy in QMC
2. For Authentication module redirect URI enter the same servername and port you used for Authorized redirect URI in the Application Registration Portal.
![](https://github.com/mjromper/qlik-auth-office365/raw/master/docs/images/virtual-proxy.png)
3. Finish the Virtual Proxy configuration.

### Installation of this module

You need Gulp installed globally:
1. Download the module from here
2. Edit **settings.json** and set the Miscrosft app and Qlik Server information
```
{
	"client_id": "YOUR APPPLICATION ID",
	"client_secret": "YOUR APPPLICATION PASSWORD",
	"redirect_uri": "https://your_sense_server_host:5555/oauth2callback",
	"directory": "Office365",
	"port": 5555
}
```

### Todos

 - Write Tests

License
----

MIT
