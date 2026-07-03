const { spawn } = require('child_process');
const path = require('path');

// Change working directory to frontend/
const frontendDir = path.resolve(__dirname, '../frontend');
process.chdir(frontendDir);

console.log('Spawning Vite dev server in non-interactive mode (ignoring stdin)...');

const vite = spawn('npx', ['vite', 'editor', '--mode', 'proprietary', '--port', '5173'], {
  stdio: ['ignore', 'inherit', 'inherit'],
  shell: true
});

vite.on('exit', (code) => {
  console.log(`Vite exited with code ${code}`);
  process.exit(code || 0);
});
