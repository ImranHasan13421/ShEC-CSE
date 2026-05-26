import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TourService {
  static final TourService instance = TourService._internal();
  TourService._internal();

  final ValueNotifier<bool> isTourActive = ValueNotifier<bool>(false);
  bool _hasCompletedTour = false;

  bool get hasCompletedTour => _hasCompletedTour;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasCompletedTour = prefs.getBool('has_completed_tour') ?? false;
    } catch (e) {
      debugPrint('TourService init error: $e');
    }
  }

  void startTour() {
    isTourActive.value = true;
  }

  Future<void> completeTour() async {
    isTourActive.value = false;
    _hasCompletedTour = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_completed_tour', true);
    } catch (e) {
      debugPrint('TourService save error: $e');
    }
  }

  Future<void> resetTour() async {
    _hasCompletedTour = false;
    isTourActive.value = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('has_completed_tour');
    } catch (e) {
      debugPrint('TourService reset error: $e');
    }
  }

  Future<bool> hasCompletedScreenTour(String screenKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('has_completed_tour_$screenKey') ?? false;
    } catch (e) {
      debugPrint('TourService hasCompletedScreenTour error: $e');
      return false;
    }
  }

  Future<void> completeScreenTour(String screenKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_completed_tour_$screenKey', true);
    } catch (e) {
      debugPrint('TourService completeScreenTour error: $e');
    }
  }

  Future<void> resetAllScreenTours() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('has_completed_tour_')) {
          await prefs.remove(key);
        }
      }
      await resetTour();
    } catch (e) {
      debugPrint('TourService resetAllScreenTours error: $e');
    }
  }
}
