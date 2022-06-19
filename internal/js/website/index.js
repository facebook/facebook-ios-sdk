/**
 * (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.
 */

var port = 8080;

if(!process.argv[2]) {
  console.log('Insufficient number of arguments given for the port! Default 8080 will be used.');
} else {
  port = process.argv[2];
}

const express = require("express")
const path = require("path") 
const multer = require("multer") 
const app = express()

app.set("views",path.join(__dirname,"views")) 
app.set("view engine","ejs")
       
/* Maximum file size 1 MB. */
const maxSize = 1 * 1000 * 1000;
    
var upload = multer({
    dest: "fbsdk_js",
    limits: { fileSize: maxSize }
}).single("file");

var download = multer({
dest: "fbsdk_js",
limits: { fileSize: maxSize }
}).single("file");

app.get("/",function(req,res){ 
    res.render("Signup"); 
})

app.get('/download/:file(*)',(req, res) => {
  var file = req.params.file;
  var fileLocation = path.join('../',file);
  console.log(fileLocation);
  res.download(fileLocation, file);
});

app.post("/upload",function (req, res, next) {
    /* The file will not be uploaded if an error occurs. */
    upload(req,res,function(err) { 
  
      if(err) {

        /* Error. Can be due to a file size that is too great. */
        res.send(err)
        return;
      }
      else {

        /* File successfully uploaded. */
        res.send("Success. File uploaded!")
      }
    });
})

app.listen(port,function(error) {
    if(error) {
      throw error;
    }
    console.log("Server created Successfully on PORT " + port);
})
