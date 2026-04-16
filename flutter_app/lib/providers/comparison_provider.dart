import 'package:flutter/foundation.dart';
import '../models/models.dart';

/// Provider for managing listing comparison (max 3 listings)
class ComparisonProvider extends ChangeNotifier {
  static const int maxComparisons = 3;
  
  final List<Listing> _listings = [];
  
  /// Get all listings in comparison
  List<Listing> get listings => List.unmodifiable(_listings);
  
  /// Get count of compared listings
  int get count => _listings.length;
  
  /// Check if comparison is full
  bool get isFull => _listings.length >= maxComparisons;
  
  /// Check if comparison is empty
  bool get isEmpty => _listings.isEmpty;
  
  /// Check if a listing is in comparison
  bool isInComparison(String listingId) {
    return _listings.any((l) => l.id == listingId);
  }
  
  /// Add a listing to comparison (max 3)
  bool addToComparison(Listing listing) {
    if (_listings.length >= maxComparisons) {
      return false;
    }
    
    if (isInComparison(listing.id)) {
      return false; // Already in comparison
    }
    
    _listings.add(listing);
    notifyListeners();
    return true;
  }
  
  /// Remove a listing from comparison
  void removeFromComparison(String listingId) {
    _listings.removeWhere((l) => l.id == listingId);
    notifyListeners();
  }
  
  /// Toggle a listing in comparison
  bool toggleComparison(Listing listing) {
    if (isInComparison(listing.id)) {
      removeFromComparison(listing.id);
      return false;
    } else {
      return addToComparison(listing);
    }
  }
  
  /// Clear all comparisons
  void clearAll() {
    _listings.clear();
    notifyListeners();
  }
}
