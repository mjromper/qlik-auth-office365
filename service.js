var express = require('express'),
    app = express(),
    fs = require('fs'),
    https = require("https"),
    qlikAuth = require('qlik-auth'),
    o365 = require('./o365.js');

var settings = {};
var arg = process.argv.slice(2);

arg.forEach( function(a) {
    var key = a.split("=");
    switch( key[0] ) {
      case "user_directory":
        settings.directory = key[1];
        break;
      case "client_id":
        settings.client_id = key[1];
        break;
      case "client_secret":
        settings.client_secret = key[1];
        break;
      case "auth_port":
        settings.port = key[1];
        break;
  }
} );

app.get('/', function ( req, res ) {
    //Init sense auth module
    qlikAuth.init(req, res);
    //Redirect to Office 365 Auth url

    var hostUrl = req.protocol+"://"+req.get('host');
    res.redirect( o365.getAuthUrl(hostUrl, settings) );
});


app.get('/oauth2callback', function ( req, res ) {

    if ( req.query.code !== undefined && req.query.state !== undefined ) {
        var hostUrl = req.protocol+"://"+req.get('host');
        o365.getTokenFromCode( req.query.code, req.query.state, hostUrl, settings, function ( e, accessToken, refreshToken ) {
            if ( e ) {
                res.send( { "error": e } );
                return;
            }


            o365.getUserId( accessToken, function( err, userId ) {
                if ( !err && userId ) {

                    o365.getUserGroups( accessToken, function( err, groups ) {

                        if (err) {
                           res.send( { "error": err } );
                           return;
                        }

                        var attributes = groups.value.map( function(g) {
                            return {"Group": g.displayName};
                        } );

                        qlikAuth.requestTicket(req, res, {
                            'UserDirectory': settings.directory,
                            'UserId': userId,
                            'Attributes': attributes
                        });
                    } );

                    //Make call for ticket request
                    /*
                    qlikAuth.requestTicket(req, res, {
                        'UserDirectory': settings.directory,
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
    key: fs.readFileSync( "C:\\ProgramData\\Qlik\\Sense\\Repository\\Exported Certificates\\.Local Certificates\\client_key.pem" ),
    cert: fs.readFileSync( "C:\\ProgramData\\Qlik\\Sense\\Repository\\Exported Certificates\\.Local Certificates\\client.pem" ),
};

//Server application
var server = https.createServer( options, app );
server.listen( settings.port );
