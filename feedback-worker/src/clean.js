// clean.js — what a stranger's message goes through before it reaches our inbox. Plain functions, tested in test/.

/** The picture chosen on the form (or none) */
export const KINDS = ['good', 'confused', 'broken', 'idea', 'complaint'];

/** The tap-only questions, and their only answers */
export const QUESTIONS = ['easy', 'helped', 'again'];
const ANSWERS = ['', 'yes', 'some', 'no'];

export const MAX_BODY = 8192;
const MAX_MESSAGE = 3000;
const EMAIL = /^[^\s@<>"',;:()\\]{1,64}@[a-z0-9-]+(\.[a-z0-9-]+)*\.[a-z]{2,}$/i;

/** Control characters, and the invisible and direction-changing ones that can disguise a word or a link */
const HIDDEN = /[\u0000-\u0008\u000B-\u001F\u007F-\u009F\u00AD\u200B-\u200F\u2028-\u202E\u2060-\u206F\uFEFF]/g;

export const plain = (s) => s.normalize('NFC').replace(HIDDEN, '').trim();

/** How many web addresses a text carries */
const ADDRESS = /\b(?:(?:https?|ftp):\/\/|www\.)\S+|\b[\w-]+(?:\.[\w-]+)*\.[a-z]{2,}(?:\/\S*)?/gi;
export const countLinks = (s) => (s.match(ADDRESS) ?? []).length;

/** Stops anything in the text being a link an email app would make clickable */
export const defang = (s) =>
  s.replace(ADDRESS, (a) => a.replace(/^(https?|ftp):\/\//i, (_, p) => `${p.replace(/t/gi, 'x')}[:]//`).replace(/\./g, '[.]').replace(/@/g, '[at]'));

/** The form's fields, checked and tidied; null when they aren't what the page sends, or say nothing at all */
export function readFields(body) {
  if (typeof body !== 'object' || body === null) return null;
  const { kind = '', message = '', email = '', details = '', lang = 'es', token, easy = '', helped = '', again = '' } = body;
  if (![kind, message, email, details, lang, token, easy, helped, again].every((v) => typeof v === 'string')) return null;
  if (kind !== '' && !KINDS.includes(kind)) return null;
  if (![easy, helped, again].every((a) => ANSWERS.includes(a))) return null;
  if (token.length < 10 || token.length > 2048) return null;
  if (lang !== 'es' && lang !== 'en') return null;
  const text = plain(message), address = plain(email);
  if (text.length > MAX_MESSAGE || details.length > 400) return null;
  if (address !== '' && (address.length > 120 || !EMAIL.test(address))) return null;
  if (!kind && !easy && !helped && !again && !text) return null;
  return { kind, easy, helped, again, message: text, email: address, details: plain(details), lang, token };
}

/** One row of the answers table: whatever was written is stored with nothing clickable in it */
export const rowOf = ({ kind, easy, helped, again, message, email, details, lang }, at) =>
  [at, lang, kind, easy, helped, again, defang(message), email, defang(details)];

/** Messages that are dropped while the sender is told they arrived, so a spammer learns nothing */
export const looksLikeSpam = ({ message }) => countLinks(message) >= 3;
