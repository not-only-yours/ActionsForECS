const AWSLambdaRouter = require('aws-lambda-router-wn');
const app = new AWSLambdaRouter();

app.get('/testBackend',async function (req, res) {
     response(null, {'message': "backend ok"});

});
