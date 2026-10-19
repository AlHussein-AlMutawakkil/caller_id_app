import '../data/contact_model.dart';

abstract class SearchNumberState {
  const SearchNumberState();
}

class SearchNumberInitial extends SearchNumberState {}

class SearchNumberLoading extends SearchNumberState {}

class SearchNumberSuccess extends SearchNumberState {
  final List<ContactModel> results;
  const SearchNumberSuccess(this.results);
}

class SearchNumberError extends SearchNumberState {
  final String message;
  const SearchNumberError(this.message);
}