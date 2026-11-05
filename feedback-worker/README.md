# The form's gateway

A small Cloudflare Worker between the website's "Escríbenos" survey and a private answers table. It's what makes the
form hard to abuse while it's open to anyone. The page holds no secret, so there's nothing to copy, and nobody can read
the table from the internet. It all runs on Cloudflare's free plans; if a free limit were ever reached, it stops rather
than bills.

| Check | Stops |
| --- | --- |
| Only our site's address may call it | Other sites and simple scripts |
| Turnstile checked on the server, for this hostname and action; each pass works once | Bots posting directly |
| At most 6 messages an hour and 20 a day per connection, 80 a day in total | Floods |
| Fields, sizes and kinds must match what the page sends | Junk and oversized requests |
| The same text twice in a day, or 3 or more links, is dropped while the sender is told it arrived | Spam runs, without teaching spammers the rule |
| Invisible characters removed, every link made unclickable, formulas neutralised in the download | Phishing aimed at us, spreadsheet attacks |

If Turnstile can't be reached it refuses the message, and the page offers the email route instead. No IP address is
stored: only a salted daily hash, deleted after two days.

## Setting it up

1. **Turnstile:** in the Cloudflare dashboard, add a widget (mode *Managed*) for `cuentas.penkosoftware.org`. Copy the
   site key and the secret key.
2. **Deploy,** from this folder:
   ```sh
   npm install
   npx wrangler login
   npx wrangler d1 create penko-feedback     # put the id it prints into wrangler.jsonc
   npx wrangler secret put TURNSTILE_SECRET
   openssl rand -hex 32 | npx wrangler secret put SALT
   npx wrangler deploy
   ```
3. In `lib/feedback/feedback_config.dart`, set the Worker's address and the site key as the `defaultValue`s, and replace
   `https://*.workers.dev` in `web/index.html` with the Worker's exact address.

## Each week

`npm run export` saves every answer to `~/Documents/penko-respuestas/respuestas-<date>.csv` and prints the totals. It
deletes nothing.

## Testing

`npm test` checks the cleaning and spreadsheet rules. `npm run dev`, with a `.dev.vars` holding Cloudflare's
[test keys](https://developers.cloudflare.com/turnstile/troubleshooting/testing/), runs the whole gateway locally.
