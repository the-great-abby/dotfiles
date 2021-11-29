#!/usr/bin/env node
const prompt = require('prompt')
prompt.start();

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
//var readline = require('readline');
//import * as readline from 'readline/promises';
//import { stdin as input, stdout as output } from 'process';

//const rl = readline.createInterface({ input, output });

// Username
//const username = await rl.question('What Username? ');
// Password
//const password = await rl.question('What Password? ');
// URL
//const url = await rl.question('What URL? ');
// Access Key ID
//const accessKeyId = await rl.question('What Access Key ID? ');
// Access Secret Key
//const accessSecretKey = await rl.question('What Access Secret Key? ');

//console.log("username?");
//rl.prompt();
//rl.prompt();
//rl.prompt();
//rl.prompt();
//rl.prompt();
//console.log(`Thank you for your valuable feedback: ${answer}`);



// const readline = require('readline');
//console.log("Press enter to start");
//const rl = readline.createInterface({
   //input: process.stdin,
   //output: process.stdout,
   //prompt: 'OHAI> '
//});

let accessKeyId = "";
let username = "";
let password = "";
let url = "";
let accessSecretKey= "";
//rl.on('line', (line) => {
  //switch (line.trim()) {
    //case 'accessKey':
      //console.log(`${line.trim()}`);
      //rl.on('line', (line2) => {
        //accessKeyId = line2.trim()
      //});
      //break;
    //case 'hello':
      //console.log('world!');
      //break;
    //default:
      //console.log(`Say what? I might have heard '${line.trim()}'`);
      //console.log('Options are:');
      //console.log('       username');
      //console.log('       password');
      //console.log('       url');
      //console.log('       secretKey');
      //console.log('       accessKey');
      //console.log(' CTRL+D to exit');
      //break;
  //}
  //rl.prompt();
//}).on('close', () => {
  //console.log('Have a great day!');
  //console.log("export ACLOUD_AWS_USERNAME=" + username);
  //console.log("export ACLOUD_AWS_PASSWORD=" + password );
  //console.log("export ACLOUD_AWS_URL=" + url );
  //console.log("export AWS_ACCESS_KEY=" + accessKeyId );
  //console.log("export AWS_SECRET_KEY=" + accessSecretKey );
  //rl.close();
  //process.exit(0);
//});
