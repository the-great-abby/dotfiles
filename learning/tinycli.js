// don't forget to "npm install prompt"
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
// --- below doesn't work so well
const readline = require('readline');
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  prompt: 'OHAI> '
});

rl.prompt();

rl.on('line', (line) => {
  switch (line.trim()) {
    case 'hello':
      console.log('world!');
      break;
    default:
      console.log(`Say what? I might have heard '${line.trim()}'`);
      break;
  }
  rl.prompt();
}).on('close', () => {
  console.log('Have a great day!');
  process.exit(0);
});
