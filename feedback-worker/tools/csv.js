// csv.js — turns the answers into a spreadsheet file. Strangers wrote this text, and a spreadsheet would run a cell that
// starts with =, +, - or @ as a formula, so those cells are made harmless.
const COLUMNS = ['id', 'at', 'lang', 'kind', 'easy', 'helped', 'again', 'message', 'email', 'details'];

const cell = (value) => {
  const s = String(value ?? '');
  const safe = /^[\s]*[=+\-@\t\r]/.test(s) ? `'${s}` : s;
  return /[",\n\r]/.test(safe) ? `"${safe.replaceAll('"', '""')}"` : safe;
};

/** With a mark at the start so spreadsheets read ñ and accents properly */
export const csvOf = (rows) => `﻿${[COLUMNS, ...rows.map((r) => COLUMNS.map((c) => r[c]))].map((r) => r.map(cell).join(',')).join('\r\n')}\r\n`;

/** How many gave each answer, for reports */
export function totalsOf(rows) {
  const lines = [];
  for (const column of ['kind', 'easy', 'helped', 'again', 'lang']) {
    const counts = {};
    for (const r of rows) if (r[column]) counts[r[column]] = (counts[r[column]] ?? 0) + 1;
    lines.push(`${column.padEnd(7)} ${Object.entries(counts).map(([k, n]) => `${k}: ${n}`).join('   ') || '-'}`);
  }
  return lines.join('\n');
}
