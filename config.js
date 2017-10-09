var path = require('path');
var certPath = 'C:/ProgramData/Qlik/Sense/Repository/Exported Certificates/.Local Certificates';

var config = {

    certPath: certPath,

    certificates: {
        client: path.resolve(certPath, 'client.pem'),
        server: path.resolve(certPath, 'server.pem'),
        root: path.resolve(certPath, 'root.pem'),
        client_key: path.resolve(certPath, 'client_key.pem'),
        server_key: path.resolve(certPath, 'server_key.pem')
    },

    port: 5555,

    /**
     * Sense Server config
     */
    prefix: 'office365',
    cookieName: 'X-Qlik-Session-o365' // Cookie name assigned for virtual proxy

    office365: {
        client_id: "XXXXXXXXXXX",
        client_secret: "XXXXXXXXXXXXXX"
    }
};

module.exports = config;