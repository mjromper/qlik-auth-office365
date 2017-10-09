var path = require('path');

var config = {
    certPath: "C:/ProgramData/Qlik/Sense/Repository/Exported Certificates/.Local Certificates",
    certificates: function() {
        return {
        	client: path.resolve(this.certPath, 'client.pem'),
       	    client_key: path.resolve(this.certPath, 'client_key.pem'),
        	root: path.resolve(this.certPath, 'root.pem')
        }
    },

    port: 5555,

    /**
     * Sense Server config
     */
    senseHost: 'qmi-qs-latch',
    prefix: 'office365',
    cookieName: 'X-Qlik-Session-o365', // Cookie name assigned for virtual proxy

    /**
    * Office365 App details
    */
    office365: {
        client_id: "XXXXXXXXXXX",
        client_secret: "XXXXXXXXXXXXXX"
    }
};

module.exports = config;