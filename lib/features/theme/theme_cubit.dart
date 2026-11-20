import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum ThemePreference { system, light, dark }

class ThemeCubit extends Cubit<ThemePreference> {
  ThemeCubit() : super(ThemePreference.light);

  void use(ThemePreference preference) => emit(preference);

  void toggle(Brightness current) {
    emit(
      current == Brightness.dark ? ThemePreference.light : ThemePreference.dark,
    );
  }

  Brightness resolve(Brightness platform) {
    return switch (state) {
      ThemePreference.light => Brightness.light,
      ThemePreference.dark => Brightness.dark,
      ThemePreference.system => platform,
    };
  }
}
