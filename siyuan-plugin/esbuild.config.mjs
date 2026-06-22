import esbuild from 'esbuild';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(__dirname, '..');
const envPath = path.join(rootDir, '.env');

function loadEnvFile(filePath) {
  if (!fs.existsSync(filePath)) return {};
  const env = {};
  for (const line of fs.readFileSync(filePath, 'utf8').split('\n')) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const idx = trimmed.indexOf('=');
    if (idx === -1) continue;
    const key = trimmed.slice(0, idx).trim();
    const value = trimmed.slice(idx + 1).trim();
    env[key] = value;
  }
  return env;
}

const fileEnv = loadEnvFile(envPath);
const env = { ...fileEnv, ...process.env };

const supabaseUrl =
  env.SUPABASE_URL || 'http://127.0.0.1:54321';
const supabaseAnonKey =
  env.SUPABASE_ANON_KEY ||
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';
const pairingEndpoint =
  env.TEMPO_SIYUAN_PAIRING_ENDPOINT ||
  `${supabaseUrl}/functions/v1/siyuan-pairing`;

const pluginJson = JSON.parse(
  fs.readFileSync(path.join(__dirname, 'plugin.json'), 'utf8')
);

await esbuild.build({
  entryPoints: [path.join(__dirname, 'src/index.ts')],
  bundle: true,
  outfile: path.join(__dirname, 'dist/index.js'),
  format: 'cjs',
  platform: 'browser',
  target: ['es2020'],
  minify: true,
  legalComments: 'none',
  external: ['siyuan'],
  loader: {
    '.css': 'text',
  },
  define: {
    __SUPABASE_URL__: JSON.stringify(supabaseUrl),
    __SUPABASE_ANON_KEY__: JSON.stringify(supabaseAnonKey),
    __PAIRING_ENDPOINT__: JSON.stringify(pairingEndpoint),
    __PLUGIN_VERSION__: JSON.stringify(pluginJson.version),
  },
  logLevel: 'info',
});

console.log('Built dist/index.js with Supabase URL:', supabaseUrl);
