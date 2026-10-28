import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../data/api_service.dart';
import '../../services/gi_haptics.dart';
import '../../theme/design_tokens.dart';
import '../../theme/gi_colors.dart';
import '../../theme/ticket_status.dart';
import '../../widgets/gi_pressable.dart';
import '../../widgets/gi_primary_button.dart';
import '../admin/admin_sheet.dart';
import '../admin/admin_ui.dart';
import 'intervenant_store.dart';

/// Les deux gestes de l'intervenant, communs a la liste et a la fiche.
///
/// Commencer se fait d'un appui : la mission passe « En cours » et
/// l'administration le voit aussitot. Terminer ouvre une feuille courte —
/// un compte rendu facultatif et les photos du travail fait — puis cloture.

/// Limites du serveur : quatre pieces jointes par ticket, dix megaoctets
/// en tout, photos du resident comprises.
const kMaxTicketFiles = 4;
const kMaxTicketBytes = 10 * 1024 * 1024;

Future<void> startMission(
    BuildContext context, IntervenantStore store, Map ticket) async {
  GiHaptics.select();
  try {
    await store.start(TicketFields.id(ticket));
    if (context.mounted) {
      showAdminToast(context, 'Mission commencée · bon courage !');
    }
  } catch (e) {
    if (context.mounted) {
      showAdminToast(context, e.toString().replaceFirst('Exception: ', ''),
          error: true);
    }
  }
}

/// Rend vrai si la mission a ete terminee.
Future<bool> finishMission(
    BuildContext context, IntervenantStore store, Map ticket) async {
  final existing =
      (ticket['attachments'] is List) ? (ticket['attachments'] as List) : [];
  final done = await showAdminSheet<bool>(
    context,
    title: 'Terminer la mission',
    subtitle: TicketFields.title(ticket),
    builder: (sheet) => _FinishForm(
      store: store,
      ticketId: TicketFields.id(ticket),
      freeSlots: (kMaxTicketFiles - existing.length).clamp(0, kMaxTicketFiles),
      usedBytes: existing.whereType<Map>().fold<int>(
          0, (sum, a) => sum + ((a['size'] as num?)?.toInt() ?? 0)),
    ),
  );
  if (done == true && context.mounted) {
    showAdminToast(context, "Mission terminée · l'administration est prévenue");
  }
  return done == true;
}

/// Photos choisies sur l'appareil, pretes a l'envoi.
Future<List<UploadFile>> pickPhotos(BuildContext context,
    {required int freeSlots, required int usedBytes}) async {
  if (freeSlots <= 0) {
    showAdminToast(context, '$kMaxTicketFiles photos maximum par mission',
        error: true);
    return const [];
  }
  final result = await FilePicker.platform
      .pickFiles(type: FileType.image, allowMultiple: true, withData: true);
  if (result == null) return const [];
  final files = [
    for (final f in result.files)
      if (f.bytes != null)
        UploadFile(
            bytes: f.bytes!, filename: f.name, mimeType: _mimeOf(f.name)),
  ];
  if (!context.mounted) return const [];
  if (files.length > freeSlots) {
    showAdminToast(
        context,
        freeSlots == 1
            ? 'Encore une seule photo possible'
            : 'Encore $freeSlots photos possibles',
        error: true);
    return const [];
  }
  final bytes = files.fold<int>(usedBytes, (s, f) => s + f.bytes.length);
  if (bytes > kMaxTicketBytes) {
    showAdminToast(context, 'Photos trop lourdes : 10 Mo au total',
        error: true);
    return const [];
  }
  return files;
}

String _mimeOf(String name) {
  final ext = name.split('.').last.toLowerCase();
  return switch (ext) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'heic' => 'image/heic',
    _ => 'image/jpeg',
  };
}

class _FinishForm extends StatefulWidget {
  final IntervenantStore store;
  final String ticketId;
  final int freeSlots;
  final int usedBytes;

  const _FinishForm({
    required this.store,
    required this.ticketId,
    required this.freeSlots,
    required this.usedBytes,
  });

  @override
  State<_FinishForm> createState() => _FinishFormState();
}

class _FinishFormState extends State<_FinishForm> {
  final _note = TextEditingController();
  final List<UploadFile> _photos = [];
  bool _sending = false;

  /// Les comptes rendus les plus frequents, en un appui.
  static const _quick = [
    'Réparation effectuée',
    'Pièce remplacée',
    'Nettoyage effectué',
    'Contrôle fait, tout fonctionne',
  ];

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _addQuick(String text) {
    GiHaptics.select();
    final current = _note.text.trim();
    if (current.contains(text)) return;
    _note.text = current.isEmpty ? text : '$current. $text';
    _note.selection = TextSelection.collapsed(offset: _note.text.length);
    setState(() {});
  }

  Future<void> _pick() async {
    final picked = await pickPhotos(context,
        freeSlots: widget.freeSlots - _photos.length,
        usedBytes: widget.usedBytes +
            _photos.fold<int>(0, (s, f) => s + f.bytes.length));
    if (picked.isNotEmpty && mounted) setState(() => _photos.addAll(picked));
  }

  Future<void> _submit() async {
    setState(() => _sending = true);
    try {
      await widget.store
          .finish(widget.ticketId, note: _note.text, photos: _photos);
      GiHaptics.success();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      showAdminToast(context, e.toString().replaceFirst('Exception: ', ''),
          error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: FigSpace.md,
          runSpacing: FigSpace.md,
          children: [
            for (final q in _quick)
              GiPressable(
                pressedScale: 0.95,
                onTap: _sending ? null : () => _addQuick(q),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _note.text.contains(q)
                        ? FigAlert.success.withValues(alpha: 0.12)
                        : c.card,
                    border: Border.all(
                        color: _note.text.contains(q)
                            ? FigAlert.success.withValues(alpha: 0.5)
                            : c.cardBorder),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(q,
                      style: FigText.label.copyWith(color: c.textBody)),
                ),
              ),
          ],
        ),
        const SizedBox(height: FigSpace.xl),
        AdminField(
          controller: _note,
          label: 'Compte rendu (facultatif)',
          hint: "Ce que vous avez fait, ce qu'il reste à prévoir…",
          lines: 3,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: FigSpace.xl),
        Text('Photos du travail fait',
            style: FigText.label.copyWith(color: c.textMuted)),
        const SizedBox(height: 6),
        SizedBox(
          height: 76,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (var i = 0; i < _photos.length; i++) ...[
                _thumb(c, i),
                const SizedBox(width: FigSpace.md),
              ],
              if (_photos.length < widget.freeSlots)
                GiPressable(
                  pressedScale: 0.94,
                  onTap: _sending ? null : _pick,
                  child: Container(
                    width: 76,
                    decoration: BoxDecoration(
                      color: c.fieldBg,
                      border: Border.all(color: c.fieldBorder),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined,
                            size: 22, color: c.textBody),
                        const SizedBox(height: 4),
                        Text('Ajouter',
                            style: FigText.caption
                                .copyWith(fontSize: 11, color: c.textMuted)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (widget.freeSlots == 0) ...[
          const SizedBox(height: FigSpace.sm),
          Text('Ce ticket a déjà ses $kMaxTicketFiles pièces jointes.',
              style: FigText.label.copyWith(color: c.textFaint)),
        ],
        const SizedBox(height: FigSpace.xxl),
        GiPrimaryButton(
          label: 'Valider la fin de la mission',
          isLoading: _sending,
          onPressed: _submit,
        ),
        const SizedBox(height: FigSpace.md),
        AdminGhostButton(
            label: 'Pas encore',
            onTap: _sending ? null : () => Navigator.pop(context, false)),
      ],
    );
  }

  Widget _thumb(GiColors c, int i) => Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(_photos[i].bytes,
                width: 76, height: 76, fit: BoxFit.cover, cacheWidth: 200),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GiPressable(
              pressedScale: 0.85,
              onTap: _sending ? null : () => setState(() => _photos.removeAt(i)),
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded,
                    size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      );
}
