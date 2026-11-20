import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/services/search_index.dart';

class SearchState extends Equatable {
  const SearchState({
    this.query = '',
    this.hits = const [],
    this.includeSuperseded = false,
  });

  final String query;
  final List<SearchHit> hits;
  final bool includeSuperseded;

  SearchState copyWith({
    String? query,
    List<SearchHit>? hits,
    bool? includeSuperseded,
  }) {
    return SearchState(
      query: query ?? this.query,
      hits: hits ?? this.hits,
      includeSuperseded: includeSuperseded ?? this.includeSuperseded,
    );
  }

  @override
  List<Object?> get props => [query, hits, includeSuperseded];
}

class SearchCubit extends Cubit<SearchState> {
  SearchCubit(this._index, {this.debounce = const Duration(milliseconds: 150)})
    : super(const SearchState());

  final SearchIndex _index;
  final Duration debounce;
  Timer? _timer;

  void queryChanged(String value) {
    emit(
      state.copyWith(
        query: value,
        hits: value.trim().isEmpty ? const [] : state.hits,
      ),
    );
    _timer?.cancel();
    if (value.trim().isEmpty) return;
    _timer = Timer(debounce, () {
      emit(
        state.copyWith(
          hits: _index.search(
            value,
            includeSuperseded: state.includeSuperseded,
          ),
        ),
      );
    });
  }

  void setIncludeSuperseded(bool value) {
    emit(
      state.copyWith(
        includeSuperseded: value,
        hits: state.query.trim().isEmpty
            ? const []
            : _index.search(state.query, includeSuperseded: value),
      ),
    );
  }

  void clear() {
    _timer?.cancel();
    emit(const SearchState());
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
