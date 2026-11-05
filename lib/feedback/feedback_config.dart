// feedback_config.dart — where "Escríbenos / Write to us" messages go: the website posts them to our own gateway
// (feedback-worker/), which checks them and keeps them in a table we download. The page holds no secret: both values
// below are public. The phone app has no internet of its own: it opens this same form in the phone's browser.
// While [feedbackUrl] is empty, the website falls back to the email app.

/// The gateway's address (the build can set it with --dart-define, which the local tests do)
const feedbackUrl = String.fromEnvironment('FEEDBACK_URL');

/// Cloudflare Turnstile's public site key for this form
const turnstileSiteKey = String.fromEnvironment('TURNSTILE_KEY');

const contactEmail = 'contact@penkosoftware.org';
const siteUrl = 'https://cuentas.penkosoftware.org';
const appVersion = '1.0.0';
