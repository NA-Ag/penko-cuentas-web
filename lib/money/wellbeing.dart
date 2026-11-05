// wellbeing.dart — the CFPB Financial Well-Being Scale, abbreviated version, in its official Spanish wording (from
// files.consumerfinance.gov/f/documents/bcfp_fin-well-being_short-Scorecard_es.pdf; a US federal work, public domain).
// The questions, answers and scoring must stay exactly as published, or the score stops meaning anything. It's for
// adults (18+). The score runs from 0 to 100: higher means more financial well-being.
// English: the CFPB's official English wording of the same five items (questions 3, 5, 6, 8 and 10 of the standard
// scale), the same answer options and Part 3, exactly as printed in the CFPB's questionnaire
// (files.consumerfinance.gov/f/documents/cfpb_financial-well-being_toolkit.pdf, p. 6, and the user guide
// files.consumerfinance.gov/f/201512_cfpb_financial-well-being-user-guide-scale.pdf, Table 1). The scoring is the same.

import '../i18n/tr.dart';

/// The five questions, each with its answers from the first to the last column of the official form, and what each
/// answer is worth
class WellbeingItem {
  final String question;
  final List<String> answers;
  final List<int> values;
  const WellbeingItem(this.question, this.answers, this.values);
}

const _describesEs = ['Totalmente', 'Muy bien', 'En cierta medida', 'Muy poco', 'No me describe en lo absoluto'];
const _oftenEs = ['Siempre', 'A menudo', 'A veces', 'Casi nunca', 'Nunca'];
const _describesEn = ['Completely', 'Very well', 'Somewhat', 'Very little', 'Not at all'];
const _oftenEn = ['Always', 'Often', 'Sometimes', 'Rarely', 'Never'];
List<String> get _describes => trOf(_describesEs, _describesEn);
List<String> get _often => trOf(_oftenEs, _oftenEn);

/// The two parts' headings, as on the form
String get describesHeading =>
    tr('¿Cuán bien lo describe a usted o su situación lo siguiente?', 'How well does this statement describe you or your situation?');
String get oftenHeading => tr('¿Con qué frecuencia le ocurre lo siguiente?', 'How often does this statement apply to you?');

/// Part 3's heading, as on the form
String get aboutYouHeading => tr('Más información sobre usted', 'Tell us about yourself.');

List<WellbeingItem> get wellbeingItems => [
  WellbeingItem(
      tr('Debido a mi situación financiera, creo que nunca tendré las cosas que quiero en la vida',
          'Because of my money situation, I feel like I will never have the things I want in life'),
      _describes,
      const [0, 1, 2, 3, 4]),
  WellbeingItem(tr('Apenas estoy subsistiendo financieramente', 'I am just getting by financially'), _describes,
      const [0, 1, 2, 3, 4]),
  WellbeingItem(
      tr('Me preocupa que el dinero que tengo o que ahorre no me dure',
          'I am concerned that the money I have or will save won’t last'),
      _describes,
      const [0, 1, 2, 3, 4]),
  WellbeingItem(tr('Me sobra dinero al final del mes', 'I have money left over at the end of the month'), _often,
      const [4, 3, 2, 1, 0]),
  WellbeingItem(tr('Mis finanzas controlan mi vida', 'My finances control my life'), _often, const [0, 1, 2, 3, 4]),
];

/// Part 3 of the form: these choose the column of the score table
String get ageQuestion => tr('¿Cuál es su edad?', 'How old are you?');
List<String> get ageAnswers => trOf(const ['18-61', '62 años o más'], const ['18-61', '62+']);
String get modeQuestion => tr('¿Cómo contestó el cuestionario?', 'How did you take the questionnaire?');
List<String> get modeAnswers =>
    trOf(const ['Yo leí las preguntas', 'Alguien me leyó las preguntas'], const ['I read the questions', 'Someone read the questions to me']);

/// The official table: for each total (0–20), the score when self-administered (18–61, 62+) and when administered
/// by someone else (18–61, 62+)
const _table = [
  [19, 20, 22, 24], [25, 26, 30, 30], [29, 31, 33, 33], [32, 34, 36, 37], [36, 37, 39, 39], [38, 40, 42, 42],
  [41, 43, 44, 44], [43, 46, 47, 46], [46, 48, 49, 49], [48, 51, 51, 51], [50, 53, 54, 53], [53, 55, 56, 55],
  [55, 58, 58, 57], [57, 61, 60, 59], [60, 63, 63, 62], [63, 66, 66, 64], [65, 69, 68, 67], [68, 73, 72, 70],
  [72, 76, 75, 73], [76, 81, 80, 77], [82, 90, 87, 84],
];

/// The score from the five chosen answers (each 0–4, the column chosen on the form), the age answer (0: 18–61,
/// 1: 62+) and how it was answered (0: read by the person, 1: read to them)
int wellbeingScore(List<int> answers, {required int age, required int mode}) {
  if (answers.length != wellbeingItems.length) throw ArgumentError('five answers');
  var total = 0;
  for (var i = 0; i < answers.length; i++) {
    total += wellbeingItems[i].values[answers[i]];
  }
  return _table[total][mode * 2 + age];
}
