import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/number_search_repository.dart';
import 'search_number_state.dart';

class SearchNumberCubit extends Cubit<SearchNumberState> {
  final NumberSearchRepository _repository;

  SearchNumberCubit(this._repository) : super(SearchNumberInitial());

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      emit(SearchNumberInitial());
      return;
    }

    emit(SearchNumberLoading());

    try {
      final results = await _repository.searchByNumber(trimmed);
      emit(SearchNumberSuccess(results));
    } catch (e) {
      emit(SearchNumberError('حدث خطأ أثناء البحث: $e'));
    }
  }
}