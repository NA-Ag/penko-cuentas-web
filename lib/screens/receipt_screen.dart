// receipt_screen.dart — "Leer un ticket": a photo of a receipt, read by the tutor model, checked by the engine
// (money/receipt.dart: each line's quantity × price, and the items adding up to the TOTAL), sorted into budget groups
// the person can change, then handed to "Mi presupuesto". The photo is deleted after reading; nothing is saved.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../ai/tutor.dart';
import '../art/palette.dart';
import '../art/penko.dart';
import '../i18n/lang.dart';
import '../money/money.dart';
import '../money/receipt.dart';
import '../ui/pixel_ui.dart';
import '../ui/thinking.dart';

class ReceiptScreen extends StatefulWidget {
  final String? imagePath; // a picture to read straight away (tests)
  const ReceiptScreen({super.key, this.imagePath});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  File? _photo;
  Receipt? _receipt;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (widget.imagePath != null) _read(File(widget.imagePath!), delete: false);
  }

  Future<void> _pick(ImageSource from) async {
    final picked = await ImagePicker().pickImage(source: from, maxWidth: 1600, imageQuality: 85);
    if (picked != null) _read(File(picked.path), delete: true);
  }

  Future<void> _read(File photo, {required bool delete}) async {
    setState(() {
      _photo = photo;
      _receipt = null;
      _failed = false;
    });
    final text = await Tutor.instance.look(photo.path, receiptInstruction);
    if (delete) {
      try {
        photo.deleteSync(); // the picture isn't kept
      } catch (_) {}
    }
    if (!mounted) return;
    final r = text == null ? null : parseReceipt(text);
    setState(() {
      _receipt = r != null && r.items.isNotEmpty ? r : null;
      _failed = _receipt == null;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(tr('Leer un ticket', 'Read a receipt'))),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: _receipt != null
            ? _result(_receipt!)
            : _photo != null && !_failed
            ? _reading()
            : _start(),
      ),
    ),
  );

  Widget _start() => ListView(
    children: [
      const Center(child: Penko(pose: PenkoPose.talk, size: 96)),
      const SizedBox(height: 16),
      Text(
        _failed
            ? tr('No pude leer bien ese ticket. Prueba con otra foto: derecha, con buena luz y que se vea entero.',
                "I couldn't read that receipt well. Try another photo: straight, in good light and with the whole receipt in it.")
            : tr('Tómale una foto a un ticket. Yo leo los productos, reviso que sumen el total y te ayudo a ponerlos en tu '
                  'presupuesto.', 'Take a photo of a receipt. I read the items, check that they add up to the total and help '
                  'you put them in your budget.'),
        style: const TextStyle(fontSize: 18, height: 1.4, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      Text(tr('La foto no se guarda: la borro en cuanto termino de leerla.', "The photo isn't kept: I delete it as soon as I finish reading it."),
          style: const TextStyle(color: Pk.textSoft, fontSize: 15)),
      const SizedBox(height: 24),
      PkButton(tr('Tomar foto', 'Take a photo'), leading: const Icon(Icons.photo_camera_outlined, color: Pk.onGold),
          onPressed: () => _pick(ImageSource.camera)),
      const SizedBox(height: 12),
      PkButton(tr('Elegir de mis fotos', 'Choose from my photos'), color: Pk.note, textColor: Pk.gold,
          leading: const Icon(Icons.photo_library_outlined, color: Pk.gold), onPressed: () => _pick(ImageSource.gallery)),
    ],
  );

  Widget _reading() => Column(
    children: [
      Expanded(child: ScanningImage(image: FileImage(_photo!))),
      const SizedBox(height: 20),
      PenkoWorking(label: tr('Leyendo tu ticket', 'Reading your receipt'), usual: const Duration(seconds: 50)),
    ],
  );

  Widget _result(Receipt r) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // The engine's verdict first
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: r.addsUp ? Pk.rightSoft : Pk.wrongSoft, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Icon(r.addsUp ? Icons.check_circle_outline : Icons.info_outline, color: r.addsUp ? Pk.rightText : Pk.wrongText),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                r.addsUp
                    ? tr('Cuadra: los productos suman ${pesos(r.sum)}, igual que el total del ticket.',
                        'It adds up: the items come to ${pesos(r.sum)}, the same as the receipt\'s total.')
                    : r.total == null
                    ? tr('No encontré el total del ticket. Revisa los productos.', "I couldn't find the receipt's total. Check the items.")
                    : tr('Casi: los productos suman ${pesos(r.sum)} y el ticket dice ${pesos(r.total!)}. Revisa si leí '
                          'algo mal; toca la basura para quitar una línea.', 'Almost: the items come to ${pesos(r.sum)} and the '
                          'receipt says ${pesos(r.total!)}. Check whether I misread something; tap the trash can to remove a line.'),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: r.addsUp ? Pk.rightText : Pk.wrongText),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Text(tr('Toca el grupo para cambiarlo.', 'Tap the group to change it.'), style: const TextStyle(color: Pk.textSoft, fontSize: 14)),
      const SizedBox(height: 8),
      Expanded(
        child: ListView(
          children: [
            for (final item in r.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PkPanel(
                  padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            ActionChip(
                              label: Text(spendNames[item.group]!),
                              onPressed: () => setState(() => item.group = Spend.values[(item.group.index + 1) % Spend.values.length]),
                            ),
                            if (!item.lineChecks)
                              Text(tr('La cantidad por el precio no da este importe.', "The quantity times the price doesn't give this amount."),
                                  style: const TextStyle(color: Pk.wrongText, fontSize: 13)),
                          ],
                        ),
                      ),
                      Text(pesos(item.amount), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      IconButton(
                        tooltip: tr('Quitar ${item.name}', 'Remove ${item.name}'),
                        icon: const Icon(Icons.delete_outline, color: Pk.textSoft),
                        onPressed: () => setState(() => r.items.remove(item)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      PkButton(tr('Pasar a mi presupuesto', 'Add to my budget'), leading: const Icon(Icons.pie_chart_outline, color: Pk.onGold),
          onPressed: () => Navigator.of(context).pop(r.byGroup)),
    ],
  );
}
