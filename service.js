var express = require('express'),
    app = express(),
    fs = require('fs'),
    https = require("https"),
    qlikAuth = require('qlik-auth'),
    o365 = require('./o365.js');

var settings = require('./settings.json');

app.get('/', function ( req, res ) {
    //Init sense auth module
    qlikAuth.init(req, res);
    //Redirect to Office 365 Auth url
    res.redirect( o365.getAuthUrl() );
});


app.get('/oauth2callback', function ( req, res ) {

    if ( req.query.code !== undefined && req.query.state !== undefined ) {
        o365.getTokenFromCode( req.query.code, req.query.state, function ( e, accessToken, refreshToken ) {
            if ( e ) {
                res.send( { "error": e } );
                return;
            }


            o365.getUserId( accessToken, function( err, userId ) {
                if ( !err && userId ) {
                    //Make call for ticket request
                    qlikAuth.requestTicket(req, res, {
                        'UserDirectory': settings.directory,
                        'UserId': userId,
                        'Attributes': []
                    });
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
