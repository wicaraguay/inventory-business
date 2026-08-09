import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Multi-select state for "print several QR labels at once". While [active] the
/// products table shows a checkbox on each row and [ids] holds the picked
/// product ids. Kept tiny and separate so ProductsScreen stays stateless.
typedef LabelSelection = ({bool active, Set<String> ids});

class LabelSelectionNotifier extends Notifier<LabelSelection> {
  @override
  LabelSelection build() => (active: false, ids: <String>{});

  /// Enter selection mode with an empty pick.
  void start() => state = (active: true, ids: <String>{});

  /// Leave selection mode and forget the pick.
  void cancel() => state = (active: false, ids: <String>{});

  /// Add or remove a product id from the pick.
  void toggle(String id) {
    final next = {...state.ids};
    if (!next.remove(id)) next.add(id);
    state = (active: state.active, ids: next);
  }
}

final labelSelectionProvider =
    NotifierProvider<LabelSelectionNotifier, LabelSelection>(
  LabelSelectionNotifier.new,
);
