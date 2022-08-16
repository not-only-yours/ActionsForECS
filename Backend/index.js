let secretManagerCredentials = {
    SECRET_NAME: "production/TwoWeeksTask",
    VALUE: process.env["production/TwoWeeksTask"]
}

let secretManagerRDS = {
    SECRET_NAME: "production/MySQL_Database_Secrets",
    VALUE: process.env["production/MySQL_Database_Secrets"]
}

let secretManagerRedis = {
    SECRET_NAME: "production/Elasticache",
    VALUE: process.env["production/Elasticache"]
}

const express = require("express");
const app = express();
const PORT = process.env.PORT = 3000;
const AWS = require('aws-sdk')
const {response} = require("express");

let router = express.Router();
let router2 = express.Router();
let router3 = express.Router();

router.get('/',async function (req, res) {
    console.log("raz")


    res.json({'message': "backend ok"});
});

router2.get('/',async function (req, res) {
    console.log("testRedis")

var RedisCluster = require('elasticache');
 var RedisClient = require('redis');
 console.log(JSON.parse(secretManagerElasticache.VALUE))

 var redis = new RedisCluster({
     servers: [
         {
             host: aws-ecs-cluster.mdngce.0001.euw2.cache.amazonaws.com,
             port: 6739
         }
     ],
     createClient: function (port, host) {
         // this is the default behaviour
         return RedisClient.createClient(port, host);
     }
 });
 //connect to redis
 redis.on("connect", function () {
   console.log("connected");
 });


router3.get('/',async function (req, res) {
    console.log("testDatabase")

    var mysql = require('mysql');
    console.log(JSON.parse(secretManagerRDS.VALUE))

    var connection = mysql.createConnection(JSON.parse(secretManagerRDS.VALUE));

    connection.connect(function(err) {
        console.log("connection")
      if (err) {
        console.error('Database connection failed: ' + err.stack);
        return;
      }
      res.json({'message': "Connected to database."});
    });

    connection.end();
});

app.use('/testBackend', router);
app.use('/testRedis', router2);
app.use('/testDatabase', router3);

app.listen(PORT,function(){
    console.log('Server is running at PORT:',PORT);
});



