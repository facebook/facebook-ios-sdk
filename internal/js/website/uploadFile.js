/**
 * (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.
 */

var http = require('http');
var fs = require('fs');
var path = require('path');
var mime = require('mime');
var GUID = require('GUID');
var formidable = require('formidable');
var util = require('util');

var port = 8080;

if(!process.argv[2]) {
  console.log('Insufficient number of arguments given for the port! Default 8080 will be used.');
} else {
  port = process.argv[2];
}

http.createServer(function (req, res) {
  if (req.url === '/upload') {
    var form = new formidable.IncomingForm();
    form.parse(req, function (err, fields, files) {
      if(err) {
        throw err;
      }
      res.write('The file was successfully uploaded to the local node server!');
      res.end();
    });
  }
  else if(req.url === '/download/AppEvents.js') {
    var file = "AppEvents.js";
    fs.readFile('./' + file, function (err, content) {
        if (err) {
            res.writeHead(400, {'Content-type':'text/html'})
            console.log(err);
            res.end("No such file");
            return;
        } else {
            /* Assure that the content will be downloaded as an attachment. */
            res.setHeader('Content-disposition', 'attachment; filename='+file);
            res.end(content);
        }
    });
  }
  else {
    res.writeHead(200, {'Content-Type': 'text/html'});
    res.write('<form action="upload" method="post" enctype="multipart/form-data">');
    res.write('<input type="file" name="filetoupload"><br>');
    res.write('<input type="submit">');
    res.write('</form>');
    return res.end();
  }
}).listen(port);
