let secretManagerCredentials = {
    SECRET_NAME: "production/TwoWeeksTask",
    VALUE: process.env["production/TwoWeeksTask"]
}

let secretManagerRDS = {
    SECRET_NAME: "production/MySQL_Database_Secrets",
    VALUE: process.env["production/MySQL_Database_Secrets"]
}

const express = require("express");
const app = express();
const PORT = process.env.PORT = 3000;
const AWS = require('aws-sdk')
const {response} = require("express");
const redis = require("redis");

let router = express.Router();
let router2 = express.Router();
let router3 = express.Router();

router.get('/',async function (req, res) {
    console.log("raz")


    res.json({'message': "backend ok"});
});

router2.get('/',async function (req, res) {
    console.log("testRedis")


try {
  // This will error as this user is not allowed to run this command...
    const redis = require('redis')

    redis.createClient(JSON.parse(secretManagerCredentials.VALUE))
    res.json({'message': "Connected to the redis."});

} catch (e) {
    console.log(`GET command failed: ${e.message}`);

}
});

router3.get('/',async function (req, res) {
    console.log("testDatabase")

    var mysql = require('mysql');
    console.log(JSON.parse(secretManagerRDS.VALUE))
    try {
    var connection = mysql.createConnection({
        host: secretManagerCredentials.VALUE.host,
        port: secretManagerCredentials.VALUE.port,
        user: secretManagerCredentials.VALUE.username,
        password: secretManagerCredentials.VALUE.password,
        database: secretManagerCredentials.VALUE.dbname
    });

    connection.connect(function(err) {
        console.log("connection")
      if (err) {
        console.error('Database connection failed: ' + err.stack);
        return;
      }
      res.json({'message': "Connected to database."});
    });

    connection.end();
    } catch (e) {
              console.log(`GET command failed: ${e.message}`);
        }
});

app.use('/testBackend', router);
app.use('/testRedis', router2);
app.use('/testDatabase', router3);

app.listen(PORT,function(){
    console.log('Server is running at PORT:',PORT);
});



