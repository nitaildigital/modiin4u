import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/realestate/providers/neighborhood_providers.dart';
import '../theme/app_fonts.dart';
import 'push_service.dart';
import 'push_settings.dart';

/// The master switch in Settings. Turning it on also asks for permission
/// when the device has not given it — on the website, the only place a
/// browser may be asked, because it is a tap.
Future<void> setPushEnabled(WidgetRef ref, bool on) async {
  final settings = ref.read(pushSettingsProvider);
  await ref.read(pushSettingsProvider.notifier).update(settings.copyWith(enabled: on));
  if (!on) return;
  final push = ref.read(pushServiceProvider);
  if (!push.isAvailable || push.allowed.value == true) return;
  await push.requestPermission(openSettingsIfRefused: true);
}

/// The neighbourhood this device hears about, from the admin's list.
/// Returns the chosen id, or null if the sheet was closed.
Future<String?> pickPushNeighborhood(BuildContext context, {String? current}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => Consumer(
      builder: (context, ref, _) {
        final hoods = ref.watch(activeNeighborhoodsProvider);
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
            child: hoods.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const SizedBox(height: 80),
              data: (list) => ListView(
                shrinkWrap: true,
                children: [
                  for (final n in list)
                    ListTile(
                      title: Text(n.name, style: const TextStyle(fontFamily: AppFonts.rubik)),
                      trailing: n.id == current ? const Icon(Icons.check) : null,
                      onTap: () => Navigator.pop(context, n.id),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

/// The chosen neighbourhood's name, for the row that opens the picker.
final pushNeighborhoodNameProvider = FutureProvider.autoDispose<String?>((ref) async {
  final id = ref.watch(pushSettingsProvider.select((s) => s.neighborhoodId));
  if (id == null) return null;
  final hood = await ref.watch(neighborhoodByIdProvider(id).future);
  return hood?.name;
});
