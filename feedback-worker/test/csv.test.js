import assert from 'node:assert/strict';
import { test } from 'node:test';
import { csvOf, totalsOf } from '../tools/csv.js';

const row = (o) => ({ id: 1, at: 'now', lang: 'es', kind: '', easy: '', helped: '', again: '', message: '', email: '', details: '', ...o });

test('a formula from a stranger never runs', () => {
  for (const evil of ['=HYPERLINK("http://x","ok")', '+1+1', '-2', '@SUM(A1)', '  =1']) {
    const out = csvOf([row({ message: evil })]).split('\r\n')[1];
    assert.ok(out.includes(`'${evil.replaceAll('"', '""')}`), out);
  }
});

test('commas, quotes and new lines stay in one cell', () => {
  const out = csvOf([row({ message: 'uno, "dos"\ntres' })]);
  assert.ok(out.includes('"uno, ""dos""\ntres"'));
});

test('totals count each answer', () => {
  const t = totalsOf([row({ easy: 'yes' }), row({ easy: 'yes' }), row({ easy: 'no', kind: 'idea' })]);
  assert.ok(t.includes('yes: 2') && t.includes('no: 1') && t.includes('idea: 1'));
});
