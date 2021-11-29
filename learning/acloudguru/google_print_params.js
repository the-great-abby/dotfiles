#!/usr/bin/env node
const prompt = require('prompt')
prompt.start();

// username
// password
// url
prompt.get(['accessKeyId', 'accessSecretKey'], function (err, result) {
    if (err) { return onErr(err); }
    console.log('Command-line input received:');
    console.log('  export AWS_ACCESS_KEY_ID: ' + result.accessKeyId);
    console.log('  export AWS_ACCESS_SECRET_KEY: ' + result.accessSecretKey);
});

function onErr(err) {
    console.log(err);
    return 1;
}


