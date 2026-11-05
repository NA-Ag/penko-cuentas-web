// The form's gateway, between the website and our answers table (https://developers.cloudflare.com/workers/). An answer
// only gets in if it comes from our page, passes Turnstile on the server, and is within the limits in Gate. Nobody can
// read the table from the internet: only tools/export.mjs, logged in as us. Secrets live here, never in the page, so
// there is nothing to copy. No IP address is stored: only a salted hash that stops meaning anything the next day,
// deleted after two days. Nothing is logged.
import { DurableObject } from 'cloudflare:workers';
import { MAX_BODY, looksLikeSpam, readFields, rowOf } from './clean.js';

const HOUR = 3600e3, DAY = 24 * HOUR;
// Kept high enough for a classroom sharing one connection
const PER_IP_HOUR = 6, PER_IP_DAY = 20, ALL_DAY = 80;

/** One counter for the whole world, so the limits are exact (a rate-limit binding counts per location) */
export class Gate extends DurableObject {
  constructor(ctx, env) {
    super(ctx, env);
    this.sql = ctx.storage.sql;
    this.sql.exec('CREATE TABLE IF NOT EXISTS hits (who TEXT, what TEXT, at INTEGER)');
    this.sql.exec('CREATE INDEX IF NOT EXISTS hits_at ON hits (at)');
  }

  /** 'ok', 'limit' (too many), or 'repeat' (the same text again) */
  admit(who, what, now) {
    this.sql.exec('DELETE FROM hits WHERE at < ?', now - 2 * DAY);
    const count = (filter, ...args) => this.sql.exec(`SELECT COUNT(*) AS n FROM hits WHERE ${filter}`, ...args).one().n;
    if (count('at > ?', now - DAY) >= ALL_DAY) return 'limit';
    if (count('who = ? AND at > ?', who, now - HOUR) >= PER_IP_HOUR) return 'limit';
    if (count('who = ? AND at > ?', who, now - DAY) >= PER_IP_DAY) return 'limit';
    const repeat = what !== '' && count('what = ? AND at > ?', what, now - DAY) > 0;
    this.sql.exec('INSERT INTO hits VALUES (?, ?, ?)', who, what, now);
    return repeat ? 'repeat' : 'ok';
  }
}

const sha256 = async (s) =>
  [...new Uint8Array(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(s)))].map((b) => b.toString(16).padStart(2, '0')).join('');

const list = (s) => s.split(',').map((x) => x.trim());

async function human(token, action, ip, env) {
  const res = await fetch('https://challenges.cloudflare.com/turnstile/v0/siteverify', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ secret: env.TURNSTILE_SECRET, response: token, remoteip: ip }),
  });
  const r = await res.json();
  return r.success === true && list(env.ALLOWED_HOSTS).includes(r.hostname) && (r.action === action || env.TEST_MODE === '1');
}

const TABLE = `CREATE TABLE IF NOT EXISTS answers (
  id INTEGER PRIMARY KEY AUTOINCREMENT, at TEXT NOT NULL, lang TEXT, kind TEXT, easy TEXT, helped TEXT, again TEXT,
  message TEXT, email TEXT, details TEXT)`;

async function save(fields, at, env) {
  await env.DB.batch([
    env.DB.prepare(TABLE),
    env.DB.prepare('INSERT INTO answers (at, lang, kind, easy, helped, again, message, email, details) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)').bind(...rowOf(fields, at)),
  ]);
}

export default {
  async fetch(request, env) {
    const origin = request.headers.get('Origin') ?? '';
    const allowed = list(env.ALLOWED_ORIGINS).includes(origin);
    const answer = (status, body) =>
      new Response(body === undefined ? null : JSON.stringify(body), {
        status,
        headers: {
          'Content-Type': 'application/json',
          'Vary': 'Origin',
          ...(allowed && { 'Access-Control-Allow-Origin': origin, 'Access-Control-Allow-Methods': 'POST', 'Access-Control-Allow-Headers': 'Content-Type', 'Access-Control-Max-Age': '86400' }),
        },
      });

    if (!allowed) return answer(403, { ok: false, why: 'origin' });
    if (request.method === 'OPTIONS') return answer(204);
    if (request.method !== 'POST') return answer(405, { ok: false, why: 'method' });
    if (!(request.headers.get('Content-Type') ?? '').startsWith('application/json')) return answer(415, { ok: false, why: 'type' });

    const raw = await request.text();
    if (raw.length > MAX_BODY) return answer(413, { ok: false, why: 'size' });
    let fields;
    try {
      fields = readFields(JSON.parse(raw));
    } catch {
      fields = null;
    }
    if (!fields) return answer(400, { ok: false, why: 'fields' });

    const ip = request.headers.get('CF-Connecting-IP') ?? 'local';
    let passed = false;
    try {
      passed = await human(fields.token, 'feedback', ip, env);
    } catch {
      return answer(503, { ok: false, why: 'check' }); // Closed, not open: the page offers the email route instead
    }
    if (!passed) return answer(403, { ok: false, why: 'human' });

    const now = Date.now();
    const day = new Date(now).toISOString().slice(0, 10);
    const who = await sha256(`${env.SALT}|${day}|${ip}`);
    const what = fields.message ? await sha256(`${env.SALT}|${fields.message.toLowerCase()}`) : '';
    const verdict = await env.GATE.getByName('all').admit(who, what, now);
    if (verdict === 'limit') return answer(429, { ok: false, why: 'limit' });
    if (verdict === 'repeat' || looksLikeSpam(fields)) return answer(200, { ok: true });

    try {
      await save(fields, new Date(now).toISOString(), env);
      return answer(200, { ok: true });
    } catch {
      return answer(502, { ok: false, why: 'save' });
    }
  },
};
