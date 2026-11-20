import 'package:flutter/widgets.dart';

/// Which publication the inspector should open, if a search result asked for one.
class DetailFocus extends ChangeNotifier {
  String? nodeId;
  String? publicationId;

  void open({required String? nodeId, String? publicationId}) {
    this.nodeId = nodeId;
    this.publicationId = publicationId;
    notifyListeners();
  }

  void clearPublication() {
    if (publicationId == null) return;
    publicationId = null;
    notifyListeners();
  }
}

class DetailScope extends InheritedNotifier<DetailFocus> {
  const DetailScope({
    required DetailFocus focus,
    required super.child,
    super.key,
  }) : super(notifier: focus);

  static DetailFocus of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<DetailScope>();
    assert(scope != null, 'DetailScope is missing');
    return scope!.notifier!;
  }
}
