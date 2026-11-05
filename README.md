# Penko Cuentas Claras

*"Cuentas claras, amistades largas."*

Free, open-source maths and everyday money with Penko, a pixel penguin who teaches step by step, the way it's taught
in Mexican schools. In Spanish and English.

**Try it in your browser:** https://cuentas.penkosoftware.org/ (phones, iPhone included, tablets and computers;
nothing to install, no account).

Part of [Penko Software](https://penkosoftware.org/)'s volunteer testing: something broken, confusing or missing?
Open **Ajustes / Settings → Escríbenos / Write to us** in the app.

## What's inside

- **Ábaco**: a voice-first abacus for people who can't read numbers yet
- **Sumas y restas · Multiplicar · Dividir**: column methods with carrying and borrowing, times tables, "la casita"
- **Dinero de todos los días**: discounts, interest, instalments, tandas, budgets, credit cards, saving, the CAT
- **Simuladores**: loans, credit cards, getting out of debt, saving, a budget, the month's calendar, a list of debts,
  and the CFPB Financial Well-Being Scale
- **Recursos**: official sites for help, and **Palabras / Words**: every money and maths term explained with a picture,
  one plain sentence and Penko's voice

Made to be usable by people who read little: every place in the app has its own picture and colour (like the Mexico
City Metro), holding a picture makes Penko say what it is, and every screen can be read aloud. Recorded voice packs in
more languages can be added without code changes (see `docs/VOICE_PACKS.md`).

## The Android app

This repository is the web version. The Android app has the same lessons plus Penko's AI tutor, which runs entirely on
the phone, with no internet: it explains "Why?" in a lesson and reads photos of receipts. The app works on a test
phone, but it isn't publicly available yet: there's no download, and its Android project and AI model aren't in this
repository. Publishing it on Google Play comes next.

## Privacy

No accounts, no ads, no tracking. Progress stays in your own browser. The only thing ever sent is a message you choose
to write with "Write to us".

## Build

```bash
flutter pub get
flutter test
flutter build web --release
```

Pushes to `main` are published automatically (`.github/workflows/deploy-web.yml`).

## Licence

GPL-3.0. See `LICENSE`.
