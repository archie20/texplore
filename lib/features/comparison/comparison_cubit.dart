import 'package:flutter_bloc/flutter_bloc.dart';

class ComparisonCubit extends Cubit<List<String>> {
  ComparisonCubit([List<String>? ids])
    : super(List.unmodifiable(ids ?? const []));

  void toggle(String id) {
    if (state.contains(id)) {
      emit([
        for (final existing in state)
          if (existing != id) existing,
      ]);
    } else {
      emit([...state, id]);
    }
  }

  void setIds(List<String> ids) {
    final unique = <String>[];
    for (final id in ids) {
      if (id.isEmpty || unique.contains(id)) continue;
      unique.add(id);
    }
    emit(unique);
  }

  void remove(String id) => emit([
    for (final existing in state)
      if (existing != id) existing,
  ]);
}
