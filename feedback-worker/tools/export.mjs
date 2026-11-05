#!/usr/bin/env node
// export.mjs — downloads every answer to a spreadsheet file, and prints the totals. Run it each week: `npm run export`.
// It only reads: nothing is deleted. `--local` reads the test database instead of the real one.
import { execFileSync } from 'node:child_process';
import { mkdirSync, writeFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';
import { csvOf, totalsOf } from './csv.js';

const where = process.argv.includes('--local') ? '--local' : '--remote';
const out = execFileSync(
  'npx',
  ['wrangler', 'd1', 'execute', 'penko-feedback', where, '--json', '--command', 'SELECT * FROM answers ORDER BY id'],
  { encoding: 'utf8', stdio: ['ignore', 'pipe', 'inherit'], maxBuffer: 1 << 28 },
);
const rows = JSON.parse(out)[0].results;
const folder = join(homedir(), 'Documents', 'penko-respuestas');
mkdirSync(folder, { recursive: true });
const file = join(folder, `respuestas-${new Date().toISOString().slice(0, 10)}.csv`);
writeFileSync(file, csvOf(rows));
console.log(`${rows.length} answers saved to ${file}\n`);
console.log(totalsOf(rows));
