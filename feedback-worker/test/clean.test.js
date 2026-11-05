import assert from 'node:assert/strict';
import { test } from 'node:test';
import { countLinks, defang, looksLikeSpam, plain, readFields, rowOf } from '../src/clean.js';

const good = { kind: 'idea', message: 'Hola', email: '', details: '', lang: 'es', token: 'x'.repeat(20) };

test('accepts what the page sends', () => assert.equal(readFields(good).message, 'Hola'));
test('a picture alone is enough', () => assert.equal(readFields({ ...good, message: '' }).message, ''));
test('so is one tapped answer', () => assert.equal(readFields({ ...good, kind: '', message: '', easy: 'some' }).easy, 'some'));
test('saying nothing at all is refused', () => assert.equal(readFields({ ...good, kind: '', message: '' }), null));

test('refuses what the page never sends', () => {
  for (const bad of [null, 7, [], { ...good, kind: 'x' }, { ...good, kind: 'constructor' }, { ...good, kind: '__proto__' }, { ...good, easy: 'maybe' }, { ...good, again: 1 }, { ...good, message: 5 },
    { ...good, token: 'short' }, { ...good, token: undefined }, { ...good, lang: 'fr' }, { ...good, message: 'x'.repeat(3001) },
    { ...good, email: 'nope' }, { ...good, email: 'a@b.mx\nBcc: x@y.com' }, { ...good, email: 'a b@c.mx' }, { ...good, details: 'x'.repeat(401) }]) {
    assert.equal(readFields(bad), null, JSON.stringify(bad)?.slice(0, 60));
  }
});

test('hidden characters go', () => {
  assert.equal(plain('pa​ypal‮.com\u0000'), 'paypal.com');
  assert.equal(plain('línea\nsegunda'), 'línea\nsegunda');
});

test('no address stays clickable', () => {
  for (const s of ['https://evil.com/login', 'HTTP://evil.com', 'www.evil.com', 'evil.com', 'go to evil.co.uk/x now', 'mi correo a@b.com']) {
    assert.ok(!/https?:\/\/|www\.|\w\.[a-z]{2}/i.test(defang(s)), defang(s));
  }
  assert.equal(defang('Hola, 3.5 pesos. Bien'), 'Hola, 3.5 pesos. Bien');
});

test('links are counted', () => {
  assert.equal(countLinks('nada aquí'), 0);
  assert.equal(countLinks('https://a.com y www.b.org y c.mx/d'), 3);
  assert.ok(looksLikeSpam({ message: 'a.com b.com c.com' }));
  assert.ok(!looksLikeSpam({ message: 'mira penkosoftware.org' }));
});

test('what is stored has nothing clickable in it', () => {
  const row = rowOf(readFields({ ...good, message: 'URGENTE: tu cuenta https://evil.com', email: 'a@b.mx', easy: 'yes' }), 'now');
  assert.ok(!row.join(' ').includes('https://'));
  assert.equal(row[3], 'yes');
  assert.equal(row[7], 'a@b.mx');
});
