var express = require('express'),
    app = express(),
    fs = require('fs'),
    https = require("https"),
    qlikAuth = require('qlik-auth'),
    o365 = require('./o365.js'),
    config = require("./config.js");

var arg = process.argv.slice(2);

arg.forEach( function(a) {
    var key = a.split("=");
    switch( key[0] ) {
      case "user_directory":
        config.prefix = key[1];
        break;
      case "certificates_path":
        config.certPath = key[1];
        break;
      case "client_id":
        config.office365.client_id = key[1];
        break;
      case "client_secret":
        config.office365.client_secret = key[1];
        break;
      case "auth_port":
        config.port = key[1];
        break;
  }
} );

app.get('/', function ( req, res ) {
    //Init sense auth module
    qlikAuth.init(req, res);
    //Redirect to Office 365 Auth url

    var hostUrl = req.protocol+"://"+req.get('host');
    res.redirect( o365.getAuthUrl(hostUrl, config) );
});


app.get('/oauth2callback', function ( req, res ) {

    if ( req.query.code !== undefined && req.query.state !== undefined ) {
        var hostUrl = req.protocol+"://"+req.get('host');
        o365.getTokenFromCode( req.query.code, req.query.state, hostUrl, config, function ( e, accessToken, refreshToken ) {
            if ( e ) {
                res.send( { "error": e } );
                return;
            }


            o365.getUserId( accessToken, function( err, user ) {
                if ( !err && userId ) {

                    o365.getUserGroups( accessToken, function( err, groups ) {

                        if (err) {
                           res.send( { "error": err } );
                           return;
                        }

                        var attributes = groups.value.map( function(g) {
                            return {"Group": g.displayName};
                        } );

                        attributes.push( { "name": user.displayName } );

                        qlikAuth.requestTicket(req, res, {
                            'UserDirectory': config.prefix,
                            'UserId': user.userPrincipalName,
                            'Attributes': attributes
                        });
                    } );

                    //Make call for ticket request
                    /*
                    qlikAuth.requestTicket(req, res, {
                        'UserDirectory': config.prefix,
                        'UserId': userId,
                        'Attributes': []
                    });*/
                } else {
                    res.send( { "error": err } );
                }
            });
        });
    } else {
        res.send( {"error": "missing code"} );
    }
});

var options = {
    key: fs.readFileSync( config.certificates().client_key ),
    cert: fs.readFileSync( config.certificates().client ),
};

//Server application
var server = https.createServer( options, app );
server.listen( config.port );
