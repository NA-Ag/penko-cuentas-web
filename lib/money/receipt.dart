// receipt.dart — the engine's side of reading a receipt. The tutor model reads the photo into lines
// ("producto | cantidad | precio unitario | importe"); this code turns them into items, checks them (quantity ×
// price = amount on each line, and the items add up to the receipt's TOTAL) and sorts each item into a budget group by
// its name. The model reads; code decides whether the reading can be trusted, and the person always confirms.

import '../i18n/tr.dart';

/// The budget groups receipts are sorted into (the same as "Mi presupuesto")
enum Spend { food, home, transport, bills, other }

Map<Spend, String> get spendNames => {
  Spend.food: tr('Comida', 'Food'),
  Spend.home: tr('Limpieza y hogar', 'Cleaning and home'),
  Spend.transport: tr('Transporte', 'Transportation'),
  Spend.bills: tr('Luz, agua y teléfono', 'Power, water and phone'),
  Spend.other: tr('Otros gastos', 'Other expenses'),
};

/// Words on Mexican receipts that point to a group (checked as parts of the item's name, without accents)
const _groupWords = {
  Spend.food: [
    'leche', 'tortilla', 'huevo', 'pan', 'arroz', 'frijol', 'aceite', 'azucar', 'cafe', 'refresco', 'agua', 'jugo',
    'pollo', 'carne', 'res', 'cerdo', 'pescado', 'atun', 'queso', 'jamon', 'yogur', 'cereal', 'galleta', 'pasta',
    'sopa', 'jitomate', 'tomate', 'cebolla', 'papa', 'chile', 'aguacate', 'platano', 'manzana', 'naranja', 'limon',
    'fruta', 'verdura', 'maiz', 'harina', 'sal', 'mantequilla', 'crema', 'botana', 'dulce', 'chocolate', 'salchicha',
  ],
  Spend.home: [
    'jabon', 'detergente', 'cloro', 'suavizante', 'papel', 'servilleta', 'escoba', 'trapeador', 'esponja', 'shampoo',
    'champu', 'pasta dental', 'cepillo', 'desodorante', 'panal', 'toalla', 'limpiador', 'fabuloso', 'bolsa basura',
  ],
  Spend.transport: ['gasolina', 'magna', 'premium', 'diesel', 'pasaje', 'metro', 'camion', 'taxi', 'estacionamiento'],
  Spend.bills: ['recarga', 'telcel', 'tiempo aire', 'luz', 'cfe', 'gas', 'internet', 'telefono'],
};

/// Lines that aren't things bought
final _notItems = RegExp(r'^\s*(sub\s*total|total|iva|efectivo|cambio|pago|tarjeta|descuento|fecha|ticket|folio)',
    caseSensitive: false);

class ReceiptItem {
  final String name;
  final double amount; // what this line costs in total
  final bool lineChecks; // false if quantity × price doesn't give the amount
  Spend group;
  ReceiptItem(this.name, this.amount, this.group, {this.lineChecks = true});
}

class Receipt {
  final List<ReceiptItem> items;
  final double? total; // what the receipt says, if it was read
  const Receipt(this.items, this.total);

  double get sum => items.fold(0.0, (t, i) => t + i.amount);

  /// The engine's check: the items add up to the receipt's total (to the cent, give or take rounding)
  bool get addsUp => total != null && (sum - total!).abs() < 0.015;

  Map<Spend, double> get byGroup {
    final out = <Spend, double>{};
    for (final i in items) {
      out[i.group] = (out[i.group] ?? 0) + i.amount;
    }
    return out;
  }
}

String _plain(String s) => s
    .toLowerCase()
    .replaceAll(RegExp('[áà]'), 'a')
    .replaceAll(RegExp('[éè]'), 'e')
    .replaceAll(RegExp('[íì]'), 'i')
    .replaceAll(RegExp('[óò]'), 'o')
    .replaceAll(RegExp('[úùü]'), 'u')
    .replaceAll('ñ', 'n');

/// The group an item's name suggests (the person can change it)
Spend groupOf(String name) {
  final n = _plain(name);
  for (final e in _groupWords.entries) {
    if (e.value.any((w) => RegExp('\\b$w').hasMatch(n))) return e.key;
  }
  return Spend.other;
}

double? _money(String s) {
  final m = RegExp(r'\d{1,3}(?:,\d{3})+(?:\.\d+)?|\d+(?:\.\d+)?').firstMatch(s.replaceAll(r'$', ''));
  return m == null ? null : double.tryParse(m[0]!.replaceAll(',', ''));
}

/// The model's reading ("producto | cantidad | precio | importe" per line, then "TOTAL | importe") as items. A line
/// whose last field isn't an amount (the shop's name, the date) is left out.
Receipt parseReceipt(String text) {
  final items = <ReceiptItem>[];
  double? total;
  for (final raw in text.split('\n')) {
    final fields = raw.split('|').map((f) => f.trim()).where((f) => f.isNotEmpty).toList();
    if (fields.length < 2) continue;
    final amount = _money(fields.last);
    if (amount == null || !fields.last.contains(RegExp(r'\d+[.,]\d{2}|^\$'))) continue; // not money: a date, a time
    final name = fields.first;
    if (RegExp(r'^\s*total', caseSensitive: false).hasMatch(name)) {
      total = amount;
      continue;
    }
    if (_notItems.hasMatch(name)) continue;
    // With a quantity and a unit price, they must give the amount
    var ok = true;
    if (fields.length >= 4) {
      final qty = _money(fields[fields.length - 3]), price = _money(fields[fields.length - 2]);
      if (qty != null && price != null) ok = (qty * price - amount).abs() < 0.015;
    }
    items.add(ReceiptItem(name, amount, groupOf(name), lineChecks: ok));
  }
  return Receipt(items, total);
}

/// What Penko asks the model, with a picture of a receipt
const receiptInstruction = 'Lee este ticket de compra. Escribe una línea por producto: producto | cantidad | precio '
    'unitario | importe. Al final: TOTAL | importe. Solo eso.';
