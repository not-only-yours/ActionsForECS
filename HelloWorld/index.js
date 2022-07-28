const http = require('http');
const port = 80;

const server = http.createServer((req, res) => {
  let sensetiveData = GetSecrets();
  const msg = sensetiveData === "" ?
      'Hello Node!\n Ur Sensetive Data is ' :
      'Hello Node!\n Ur Sensetive Data is ' + sensetiveData

  res.end(msg);
});
server.listen(port, () => {
  console.log(`Server running on http://localhost:${port}/`);
});




const GetSecrets = () => {
  var AWS = require('aws-sdk'),
      region = "eu-west-2",
      secretName = "production/NikitasSecrets",
      secret = "",
      decodedBinarySecret = "";

  // Create a Secrets Manager client
  var client = new AWS.SecretsManager({
    region: region
  });

  // In this sample we only handle the specific exceptions for the 'GetSecretValue' API.
  // See https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
  // We rethrow the exception by default.

  client.getSecretValue({SecretId: secretName}, function (err, data) {
    if (err) {
      if (err.code === 'DecryptionFailureException')
          // Secrets Manager can't decrypt the protected secret text using the provided KMS key.
          // Deal with the exception here, and/or rethrow at your discretion.
        throw err;
      else if (err.code === 'InternalServiceErrorException')
          // An error occurred on the server side.
          // Deal with the exception here, and/or rethrow at your discretion.
        throw err;
      else if (err.code === 'InvalidParameterException')
          // You provided an invalid value for a parameter.
          // Deal with the exception here, and/or rethrow at your discretion.
        throw err;
      else if (err.code === 'InvalidRequestException')
          // You provided a parameter value that is not valid for the current state of the resource.
          // Deal with the exception here, and/or rethrow at your discretion.
        throw err;
      else if (err.code === 'ResourceNotFoundException')
          // We can't find the resource that you asked for.
          // Deal with the exception here, and/or rethrow at your discretion.
        throw err;
    } else {
      // Decrypts secret using the associated KMS key.
      // Depending on whether the secret is a string or binary, one of these fields will be populated.
      if ('SecretString' in data) {
        secret = data.SecretString;
      } else {
        let buff = new Buffer(data.SecretBinary, 'base64');
        decodedBinarySecret = buff.toString('ascii');
      }
    }

    // Your code goes here.
  });
  console.log(secret, decodedBinarySecret)
  return secret === "" ? decodedBinarySecret : secret
}