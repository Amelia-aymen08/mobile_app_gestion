import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';
import '../../theme/gi_colors.dart';
import '../../theme/residence_images.dart';
import '../../widgets/gi_appear.dart';
import '../../widgets/gi_card.dart';
import '../resident_create_ticket_screen.dart';
import 'admin_store.dart';
import 'admin_ui.dart';

/// Ouvre le formulaire de signalement pour une residence. C'est le meme que
/// celui des residents : memes categories, memes pieces jointes.
Future<bool> openAdminTicketForm(
    BuildContext context, Map<String, dynamic> residence) async {
  final id = (residence['id'] ?? '').toString();
  final created = await adminPush<bool>(
    context,
    ResidentCreateTicketScreen(property: {
      'residenceId': id,
      'Residence': {'id': id, 'name': residence['name']},
    }),
  );
  return created == true;
}

/// Nouveau ticket, premiere etape : la residence concernee.
///
/// Remplace le formulaire en boite de dialogue de l'ancienne
/// administration. Une fois la residence choisie, on passe au formulaire de
/// signalement des residents.
class AdminNewTicketScreen extends StatelessWidget {
  final AdminStore store;

  /// Residence deja choisie — depuis sa fiche ou le filtre de la liste.
  final String residenceId;
  const AdminNewTicketScreen(
      {super.key, required this.store, this.residenceId = ''});

  Future<void> _pick(BuildContext context, Map<String, dynamic> r) async {
    final ok = await openAdminTicketForm(context, r);
    if (ok && context.mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final top = MediaQuery.paddingOf(context).top > 0 ? 14.0 : 24.0;
    final residences = [...store.residences]..sort((a, b) {
        // La residence deja filtree passe en tete.
        final ai = (a['id'] ?? '').toString() == residenceId ? 0 : 1;
        final bi = (b['id'] ?? '').toString() == residenceId ? 0 : 1;
        return ai.compareTo(bi);
      });

    return Scaffold(
      backgroundColor: c.scaffold,
      body: SafeArea(
        bottom: false,
        child: AdminContent(
          maxWidth: 820,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
                FigSpace.pagePadding,
                top,
                FigSpace.pagePadding,
                MediaQuery.paddingOf(context).bottom + 32),
            children: [
              const AdminPageHeader(
                back: true,
                title: 'Nouveau ticket',
                subtitle: 'Pour quelle résidence ?',
              ),
              const SizedBox(height: FigSpace.xl),
              if (residences.isEmpty)
                const AdminEmpty(
                  icon: Icons.apartment_rounded,
                  title: 'Aucune résidence',
                  message: 'Aucune résidence n\'est rattachée à votre compte.',
                ),
              AdminGrid(
                minTileWidth: 340,
                children: [
                  for (var i = 0; i < residences.length; i++)
                    GiAppear(
                      index: i.clamp(0, 8),
                      child: _tile(context, c, residences[i]),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, GiColors c, Map<String, dynamic> r) {
    final id = (r['id'] ?? '').toString();
    final name = (r['name'] ?? '').toString();
    final address = (r['address'] ?? '').toString();
    final asset = residenceImageAsset(id: id, name: name);
    final selected = id == residenceId;
    return GiCard(
      padding: const EdgeInsets.all(10),
      borderColor: selected ? FigBrand.amber : null,
      onTap: () => _pick(context, r),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 64,
              height: 64,
              child: asset != null
                  ? Image.asset(asset, fit: BoxFit.cover)
                  : ColoredBox(
                      color: FigBrand.amber.withValues(alpha: 0.12),
                      child: const Icon(Icons.apartment_rounded,
                          color: FigBrand.amber),
                    ),
            ),
          ),
          const SizedBox(width: FigSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FigText.titleMd.copyWith(color: c.textBody)),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FigText.label.copyWith(color: c.textMuted)),
                ],
              ],
            ),
          ),
          const SizedBox(width: FigSpace.md),
          GiChevron(color: selected ? FigBrand.amber : c.textFaint),
          const SizedBox(width: FigSpace.sm),
        ],
      ),
    );
  }
}
