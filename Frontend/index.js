
let secretManagerCredentials = {
    SECRET_NAME: "production/TwoWeeksTask",
    VALUE: process.env["production/TwoWeeksTask"]
}

const express = require("express");
const app = express();
const PORT = process.env.PORT = 80;
const http = require("http");

let router = express.Router();
let router2 = express.Router();
let router3 = express.Router();
let router4 = express.Router();

router.get('/',async function (req, res) {
    console.log("raz")

    var options = {
        host: JSON.parse(secretManagerCredentials.VALUE).BACKEND_BALANCER_DNS_NAME,
        port: 3000,
        path: '/testBackend'

    };


    var httpreq = http.request(options, function (response) {
        response.setEncoding('utf8');
        response.on('data', function (chunk) {
            res.send(chunk);
        });
    });
    httpreq.end();
});

router2.get('/',async function (req, res) {
    console.log(secretManagerCredentials)
    res.json({'message': "frontend ok", "creds": secretManagerCredentials.VALUE});
});


router3.get('/',async function (req, res) {
    console.log("raz")

    var options = {
        host: JSON.parse(secretManagerCredentials.VALUE).BACKEND_BALANCER_DNS_NAME,
        port: 3000,
        path: '/testRedis'

    };

    var httpreq = http.request(options, function (response) {
        response.setEncoding('utf8');
        response.on('data', function (chunk) {
            res.send(chunk);
        });
    });
    httpreq.end();
});

router4.get('/',async function (req, res) {
    console.log("raz")

    var options = {
        host: JSON.parse(secretManagerCredentials.VALUE).BACKEND_BALANCER_DNS_NAME,
        port: 3000,
        path: '/testDatabase'

    };

    var httpreq = http.request(options, function (response) {
        response.setEncoding('utf8');
        response.on('data', function (chunk) {
            res.send(chunk);
        });
    });
    httpreq.end();
});

app.use('/testBackend', router);
app.use('/testFrontend', router2);
app.use('/testRedis', router3);
app.use('/testDatabase', router4);

app.listen(PORT,function(){
    console.log('Server is running at PORT:',PORT);
    console.log(JSON.parse(secretManagerCredentials.VALUE).BACKEND_BALANCER_DNS_NAME)
});
