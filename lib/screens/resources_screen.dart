// resources_screen.dart — "Recursos": where to check things for real. Official public sites, named in plain words
// (no logos), opened in the phone's browser. The app itself stays offline. Also the few things that are important to
// say plainly: this is education, not financial advice, and Penko isn't backed by any institution.
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../art/palette.dart';
import '../glossary/glossary_screen.dart';
import '../glossary/term_card.dart';
import '../glossary/term_text.dart';
import '../glossary/terms.dart';
import '../i18n/lang.dart';
import '../ui/pixel_ui.dart';
import '../wayfinding/wayfinding.dart';

class _Link {
  final String name;
  final String what;
  final String url;
  final IconData icon;
  const _Link(this.name, this.what, this.url, this.icon);
}

/// Mexican official sites (in Spanish), then, in English, a few well-known sites for people elsewhere
/// (the group's sign in places.dart, by id; its links)
List<(String, List<_Link>)> get _groups => [
  ('before_loan', [
    _Link(tr('Calculadora de CAT · Banco de México', "CAT calculator · Banco de México (Banxico, Mexico's central bank)"),
        tr('Calcula el costo anual total de un crédito con la fórmula oficial.',
            "Work out a loan's CAT (total annual cost, Mexico's version of APR) with the official formula."),
        'https://www.banxico.org.mx/CAT/', Icons.calculate_outlined),
    _Link('SIPRES · CONDUSEF',
        tr('Revisa si quien te ofrece un préstamo está registrado y en operación.',
            "Check whether whoever offers you a loan is registered and operating. CONDUSEF is Mexico's financial consumer "
            'protection agency.'),
        'https://sipres.condusef.gob.mx/', Icons.verified_user_outlined),
    _Link(tr('Buró de Entidades Financieras', 'Buró de Entidades Financieras (bureau of financial institutions)'),
        tr('Compara bancos y financieras: quejas, comisiones y sanciones.', 'Compare banks and lenders: complaints, fees and penalties.'),
        'https://www.buro.gob.mx/', Icons.compare_arrows),
  ]),
  ('history', [
    _Link(tr('Buró de Crédito', 'Buró de Crédito (credit bureau)'),
        tr('Puedes pedir tu reporte gratis una vez al año. Cuidado con páginas falsas que te cobran.',
            'You can ask for your report for free once a year. Watch out for fake sites that charge you.'),
        'https://www.burodecredito.com.mx/', Icons.assignment_outlined),
    _Link('Círculo de Crédito', tr('La otra sociedad de información crediticia de México.', "Mexico's other credit bureau."),
        'https://www.circulodecredito.com.mx/', Icons.assignment_ind_outlined),
  ]),
  ('saving', [
    _Link('CETES Directo',
        tr('Ahorro con el gobierno de México, desde montos pequeños.',
            'Saving with the Mexican government (CETES are Mexican government bonds), from small amounts.'),
        'https://www.cetesdirecto.com/', Icons.savings_outlined),
    _Link('CONSAR', tr('Tu Afore y tu ahorro para el retiro.', 'Your Afore (Mexican retirement account) and your retirement savings.'),
        'https://www.gob.mx/consar', Icons.elderly_outlined),
  ]),
  ('help', [
    _Link('CONDUSEF',
        tr('Quejas y orientación sobre bancos, tarjetas, seguros y créditos.',
            'Complaints and guidance about banks, cards, insurance and loans.'),
        'https://www.gob.mx/condusef', Icons.support_agent_outlined),
    _Link('PROFECO',
        tr('Quejas sobre compras en tiendas, incluidos los meses sin intereses de la tienda.',
            "Complaints about store purchases, including a store's interest-free monthly payments. PROFECO is Mexico's "
            'consumer protection agency.'),
        'https://www.gob.mx/profeco', Icons.storefront_outlined),
  ]),
  // Only in English: well-known public sites for people outside Mexico
  if (Lang.en)
    ('elsewhere', [
      _Link('Consumer Financial Protection Bureau', "The US government's consumer finance agency: guides, tools and complaints.",
          'https://www.consumerfinance.gov/', Icons.account_balance_outlined),
      _Link('MyMoney.gov', 'The US government\'s site on money basics: earning, saving, spending, borrowing and protecting.',
          'https://www.mymoney.gov/', Icons.school_outlined),
      _Link('OECD International Network on Financial Education',
          'An international network of public financial education bodies, to find the ones in your country.',
          'https://www.oecd.org/en/networks/infe.html', Icons.public),
    ]),
];

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key});

  /// What the "read this screen" button reads on this tab: the words, then each group and its sites
  static List<String> readLines() => [
    tabPlaces[2].name,
    ...resourcePlaces['words']!.lines,
    for (final (id, links) in _groups) ...[
      ...resourcePlaces[id]!.lines,
      for (final l in links) l.name,
    ],
  ];

  Future<void> _open(BuildContext context, String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('No se pudo abrir. La dirección es $url', "Couldn't open it. The address is $url"))));
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
    children: [
      PlaceHeading(tabPlaces[2], colour: placeColour('tab.resources')),
      const SizedBox(height: 12),
      const _WordsTile(),
      const SizedBox(height: 16),
      TermText(
          tr('Páginas oficiales para revisar las cosas de verdad. Se abren en tu navegador y necesitan internet.',
              'Official sites to check things for real. They open in your browser and need the internet. The lessons '
              'use Mexican pesos and Mexican rules, so most links are official Mexican sites, in Spanish, for people in '
              'Mexico. For other countries, see "Elsewhere" at the end.'),
          style: const TextStyle(color: Pk.textSoft, fontSize: 15)),
      for (final (id, links) in _groups) ...[
        // Each group's picture and colour, like a Metro station's sign
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 10),
          child: PlaceHeading(resourcePlaces[id]!, colour: placeColour(resourcePlaces[id]!.id), size: 18, textColour: Pk.gold),
        ),
        for (final l in links)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Hear(
              lines: [l.name, l.what],
              child: Semantics(
              link: true,
              label: '${l.name}. ${l.what}',
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () => _open(context, l.url),
                child: PkPanel(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(l.icon, color: Pk.gold, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            TermText(l.what, style: const TextStyle(color: Pk.textSoft, fontSize: 14, height: 1.3)),
                          ],
                        ),
                      ),
                      const Icon(Icons.open_in_new, color: Pk.textSoft, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            ),
          ),
      ],
      const SizedBox(height: 16),
      PkPanel(
        color: Pk.note,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('Importante', 'Important'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Pk.gold)),
            const SizedBox(height: 8),
            TermText(
              tr(
                '• Penko es contenido educativo; no es asesoría financiera ni de inversión.\n'
                '• Las tasas y los montos de las lecciones y simuladores son ejemplos.\n'
                '• Penko no está afiliada ni respaldada por Banco de México, CONDUSEF ni ninguna institución financiera.\n'
                '• Antes de contratar un crédito, revisa a la institución en SIPRES.',
                '• Penko is educational content; it is not financial or investment advice.\n'
                '• The rates and amounts in the lessons and simulators are examples.\n'
                '• Penko is not affiliated with or endorsed by Banco de México, CONDUSEF, the CFPB, MyMoney.gov, the OECD or '
                'any financial institution.\n'
                '• In Mexico, before taking out a loan, check the lender in SIPRES.',
              ),
              style: const TextStyle(fontSize: 15, height: 1.45),
            ),
          ],
        ),
      ),
    ],
  );
}

/// The way into the glossary: a few of its pictures and what it's for
class _WordsTile extends StatelessWidget {
  const _WordsTile();

  @override
  Widget build(BuildContext context) {
    final sample = [for (final id in const ['iva', 'interest', 'tanda']) termById(id)!];
    return Hear.place(
      resourcePlaces['words']!,
      child: Semantics(
      button: true,
      label: tr('Palabras: qué quiere decir cada palabra, con dibujo y voz.', 'Words: what each word means, with a picture and a voice.'),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => openGlossary(context),
        child: PkPanel(
          color: Pk.cardHi,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              for (final t in sample) Padding(padding: const EdgeInsets.only(right: 6), child: TermPicture(t, size: 40)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('Palabras', 'Words'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Pk.gold)),
                    Text(tr('Qué quiere decir cada palabra, con dibujo y voz.', 'What each word means, with a picture and a voice.'),
                        style: const TextStyle(color: Pk.textSoft, fontSize: 14, height: 1.3)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Pk.textSoft),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
