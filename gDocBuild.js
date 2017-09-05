#!/usr/bin/env node
var fs      = require('fs');
var async   = require('async');
var google  = require('googleapis');
var GoogleSpreadsheet = require("google-spreadsheets");

var params = process.argv;

var spreadsheet = 0;
if (params[2] == "en")
{
    spreadsheet = require('./config/table.json');
}
else if (params[2] == "de")
{
    spreadsheet = require('./config/table_de.json');
}
else if (params[2] == "tool")
{
    spreadsheet = require('./config/table_tool.json')
}
var OAuth2Config = require('./config/oauth2.json');

var tableDirection = "./tables";


if (!fs.existsSync(tableDirection)){
    fs.mkdirSync(tableDirection);
}

if (!OAuth2Config) {
    console.error("need to gen oauth2.json.");
    return;
}

var oauth2Client = new google.auth.OAuth2(OAuth2Config.CLIENT_ID, OAuth2Config.CLIENT_SECRET, OAuth2Config.REDIRECT_URL);

oauth2Client.setCredentials({
    access_token: 'DUMMY',
    expiry_date: 1,
    refresh_token: OAuth2Config.refresh_token,
    token_type: 'Bearer'
});

oauth2Client.getAccessToken(function (err, token) {
    if (err) {
        throw err;
    } else {
        GoogleSpreadsheet({
            key: spreadsheet.csv,
            auth: oauth2Client
        },
        function(error, spreadsheet){
            if (error) {
                console.log(err);
            } else {
                for (var worksheetId in spreadsheet.worksheets) {
                    worksheet = spreadsheet.worksheets[worksheetId]
                    writeCsv(worksheet.title, worksheet)
                }
            }
        });
    }
});

function writeCsv(title, worksheet) {
    worksheet.cells(null, function (err, cells) {
        if (err) {
            return;
        }
        var rows = [];
        var datas = cells['cells'];
        var wstream = fs.createWriteStream("./tables/" + title + ".csv");
        var width = 0;
        for (var key in datas) {
            var rowdata = datas[key];
            for (var cKey in rowdata) {
                index = rowdata[cKey].col - 1;
                if (rows[rowdata[cKey].row - 1] == null) {
                    rows[rowdata[cKey].row - 1] = [];
                }
                rows[rowdata[cKey].row - 1][index] = rowdata[cKey].value;
                width = Math.max(width, index);
            }
        }
        for (var i = 0; i < rows.length; i++) {
            var row = rows[i];
            for (var col = 0; col <= width; col++) {
                var value = row[col];
                if (value == null) {
                    value = "";
                }
                value = value.replace(/(\r\n|\n|\r)/gm,"");
                wstream.write(value + ",");
            }
            wstream.write("\n");
        }
        wstream.end();
        console.log("Finish download table: " + title)
    });
}

