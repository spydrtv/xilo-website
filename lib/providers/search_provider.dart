import 'package:flutter/foundation.dart';
import '../models/search_filter.dart';
import '../services/music_service.dart';

class SearchProvider extends ChangeNotifier {
  final MusicService _service;
  SearchProvider({required MusicService service}) : _service = service;

  String _query = '';
  String get query => _query;

  SearchFilter _filter = const SearchFilter();
  SearchFilter get filter => _filter;

  List<dynamic> _results = [];
  List<dynamic> get results => _results;

  bool get hasActiveFilters => _filter.hasActiveFilters;
  int get activeFilterCount => _filter.activeFilterCount;

  void search(String query) {
    _query = query;
    _runSearch();
  }

  void applyFilter(SearchFilter filter) {
    _filter = filter;
    _runSearch();
  }

  void clearFilters() {
    _filter = const SearchFilter();
    _runSearch();
  }

  void clear() {
    _query = '';
    _filter = const SearchFilter();
    _results = [];
    notifyListeners();
  }

  void _runSearch() {
    if (_query.isEmpty && !_filter.hasActiveFilters) {
      _results = [];
    } else {
      _results = _service.filteredSearch(_query, _filter);
    }
    notifyListeners();
  }
}
