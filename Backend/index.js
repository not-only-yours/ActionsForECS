//import {AWS} from "aws-sdk";

let secretManagerCredentials = {
    SECRET_NAME: "production/TwoWeeksTask",
    VALUE: process.env["production/TwoWeeksTask"]
}

let DNS_TYPES = {
    REDIS: "REDIS_DNS_NAME",
    DATABASE:"DATABASE_DNS_NAME",
    BACKEND_BALANCER: "BACKEND_BALANCER_DNS_NAME"
}


let variable = {
    region: "eu-west-2",
    // accessKeyId: "",
    // secretAccessKey: ""
};

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


    res.json({'message': JSON.parse(secretManagerCredentials.VALUE).REDIS_DNS_NAME});
});

router3.get('/',async function (req, res) {
    console.log("testDatabase")


    res.json({'message': JSON.parse(secretManagerCredentials.VALUE).DATABASE_DNS_NAME});
});

// router.get('/testDatabase',async function (req, res) {
//     res.json({'message': await GetSecrets(secretManagerCredentials.SECRET_NAME, DNS_TYPES.DATABASE)});
// });
app.use('/testBackend', router);
app.use('/testRedis', router2);
app.use('/testDatabase', router3);

app.listen(PORT,function(){
    console.log('Server is running at PORT:',PORT);
});




// const GetSecrets = (secretName, typeOfDNS) => {
//     var secret,
//         decodedBinarySecret,
//         client = new AWS.SecretsManager(variable)
//
//     return new Promise((resolve, reject) => {
//         client.getSecretValue({SecretId: secretName}, function (err, data) {
//             if ('SecretString' in data) {
//                 secret = JSON.parse(data.SecretString);
//             } else {
//                 let buff = new Buffer(data.SecretBinary, 'base64');
//                 decodedBinarySecret = JSON.parse(buff.toString('ascii'));
//             }
//             //console.log(toString(typeof decodedBinarySecret) === "undefined" ? decodedBinarySecret.SecretName: secret.SecretName)
//
//             resolve(  toString(typeof decodedBinarySecret) === "undefined" ? decodedBinarySecret[typeOfDNS] : secret[typeOfDNS])
//         });
//     })
//
//
//
// }

