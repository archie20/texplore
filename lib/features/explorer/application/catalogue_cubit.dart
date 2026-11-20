import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/catalogue_repository.dart';
import '../../../domain/models/catalogue.dart';

sealed class CatalogueState extends Equatable {
  const CatalogueState();

  @override
  List<Object?> get props => [];
}

class CatalogueLoading extends CatalogueState {
  const CatalogueLoading();
}

class CatalogueLoaded extends CatalogueState {
  const CatalogueLoaded(this.catalogue);

  final Catalogue catalogue;

  @override
  List<Object?> get props => [catalogue];
}

class CatalogueFailed extends CatalogueState {
  const CatalogueFailed(this.message, this.issues);

  final String message;
  final List<ValidationIssue> issues;

  @override
  List<Object?> get props => [message, issues];
}

class CatalogueCubit extends Cubit<CatalogueState> {
  CatalogueCubit(this._repository) : super(const CatalogueLoading());

  final CatalogueRepository _repository;

  Future<void> load() async {
    emit(const CatalogueLoading());
    try {
      final result = await _repository.load();
      if (result.fatal) {
        emit(
          CatalogueFailed(
            result.fatalMessage ?? 'The catalogue could not be read.',
            result.catalogue.issues,
          ),
        );
        return;
      }
      emit(CatalogueLoaded(result.catalogue));
    } catch (error) {
      emit(
        CatalogueFailed('The catalogue could not be read. $error', const []),
      );
    }
  }
}
