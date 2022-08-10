//import {AWS} from "aws-sdk";

let secretManagerCredentials = {
    SECRET_NAME: "production/TwoWeeksTask",
    VALUE: process.env.SECRET_NAME
}

let DNS_TYPES = {
    REDIS: "REDIS_DNS_NAME",
    DATABASE:"DATABASE_DNS_NAME",
    BACKEND_BALANCER: "BACKEND_BALANCER_DNS_NAME"
}


let variable = {
    region: "eu-west-2",
    //accessKeyId: "",
    //secretAccessKey: ""
};

const express = require("express");
const app = express();
const PORT = process.env.PORT = 80;
const AWS = require('aws-sdk')
const {response} = require("express");
const querystring = require("querystring");
const http = require("http");

let router = express.Router();
let router2 = express.Router();
let router3 = express.Router();
let router4 = express.Router();

router.get('/',async function (req, res) {
    console.log("raz")

    // var data = querystring.stringify({
    //     requestTo: "DATABASE"
    // });

    var options = {
        host: secretManagerCredentials.VALUE[DNS_TYPES.BACKEND_BALANCER],
        port: 3000,
        path: '/testBackend'

    };


    var httpreq = http.request(options, function (response) {
        response.setEncoding('utf8');
        response.on('data', function (chunk) {
            res.send(chunk);
        });
    });
    //httpreq.write(data);
    httpreq.end();
    //console.log(typeof req, req)
    //res.json(req);


});

router2.get('/',async function (req, res) {
    console.log(secretManagerCredentials)


    res.json({'message': "frontend ok", "creds": secretManagerCredentials.VALUE});
});


router3.get('/',async function (req, res) {
    console.log("raz")

    // var data = querystring.stringify({
    //     requestTo: "DATABASE"
    // });

    var options = {
        host: secretManagerCredentials.VALUE[DNS_TYPES.BACKEND_BALANCER],
        port: 3000,
        path: '/testRedis'

    };


    var httpreq = http.request(options, function (response) {
        response.setEncoding('utf8');
        response.on('data', function (chunk) {
            res.send(chunk);
        });
    });
    //httpreq.write(data);
    httpreq.end();
    //console.log(typeof req, req)
    //res.json(req);


});

router4.get('/',async function (req, res) {
    console.log("raz")

    // var data = querystring.stringify({
    //     requestTo: "DATABASE"
    // });

    var options = {
        host: secretManagerCredentials.VALUE[DNS_TYPES.BACKEND_BALANCER],
        port: 3000,
        path: '/testDatabase'

    };


    var httpreq = http.request(options, function (response) {
        response.setEncoding('utf8');
        response.on('data', function (chunk) {
            res.send(chunk);
        });
    });
    //httpreq.write(data);
    httpreq.end();
    //console.log(typeof req, req)
    //res.json(req);


});

app.use('/testBackend', router);
app.use('/testFrontend', router2);
app.use('/testRedis', router3);
app.use('/testDatabase', router4);

app.listen(PORT,function(){
    console.log('Server is running at PORT:',PORT);
});




const GetSecrets = (secretName, typeOfDNS) => {
    var secret,
        decodedBinarySecret,
        client = new AWS.SecretsManager(variable)

    return new Promise((resolve, reject) => {
        client.getSecretValue({SecretId: secretName}, function (err, data) {
            if ('SecretString' in data) {
                secret = JSON.parse(data.SecretString);
            } else {
                let buff = new Buffer(data.SecretBinary, 'base64');
                decodedBinarySecret = JSON.parse(buff.toString('ascii'));
            }
            //console.log(toString(typeof decodedBinarySecret) === "undefined" ? decodedBinarySecret.SecretName: secret.SecretName)

            resolve(  toString(typeof decodedBinarySecret) === "undefined" ? decodedBinarySecret[typeOfDNS] : secret[typeOfDNS])
        });
    })



}

