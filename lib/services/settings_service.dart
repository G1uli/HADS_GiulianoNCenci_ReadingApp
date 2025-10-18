import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  // Default values
  static const Color _defaultBackgroundColor = Colors.white;
  static const Color _defaultSidebarColor = Colors.white;
  static const double _defaultFontScale = 1.0;

  // Keys for shared preferences
  static const String _backgroundColorKey = 'background_color';
  static const String _sidebarColorKey = 'sidebar_color';
  static const String _fontScaleKey = 'font_scale';
  static const String _customSitesKey =
      'custom_sites'; // New key for custom sites

  // Current settings with default values
  Color _backgroundColor = _defaultBackgroundColor;
  Color _sidebarColor = _defaultSidebarColor;
  double _fontScale = _defaultFontScale;

  // Getters
  Color get backgroundColor => _backgroundColor;
  Color get sidebarColor => _sidebarColor;
  double get fontScale => _fontScale;

  // Initialize settings from storage
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load background color
      final colorValue = prefs.getInt(_backgroundColorKey);
      if (colorValue != null) {
        _backgroundColor = Color(colorValue);
      }

      // Load sidebar color
      final sidebarColorValue = prefs.getInt(_sidebarColorKey);
      if (sidebarColorValue != null) {
        _sidebarColor = Color(sidebarColorValue);
      }

      // Load font scale
      final scaleValue = prefs.getDouble(_fontScaleKey);
      if (scaleValue != null) {
        _fontScale = scaleValue;
      }
    } catch (e) {
      // If any error occurs, use defaults
      _backgroundColor = _defaultBackgroundColor;
      _sidebarColor = _defaultSidebarColor;
      _fontScale = _defaultFontScale;
    }
  }

  // Save background color
  Future<void> saveBackgroundColor(Color color) async {
    _backgroundColor = color;
    try {
      final prefs = await SharedPreferences.getInstance();
      // ignore: deprecated_member_use
      await prefs.setInt(_backgroundColorKey, color.value);
    } catch (e) {
      // Handle error silently
    }
  }

  // Save sidebar color
  Future<void> saveSidebarColor(Color color) async {
    _sidebarColor = color;
    try {
      final prefs = await SharedPreferences.getInstance();
      // ignore: deprecated_member_use
      await prefs.setInt(_sidebarColorKey, color.value);
    } catch (e) {
      // Handle error silently
    }
  }

  // Save font scale
  Future<void> saveFontScale(double scale) async {
    _fontScale = scale;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_fontScaleKey, scale);
    } catch (e) {
      // Handle error silently
    }
  }

  // Reset to defaults
  Future<void> resetToDefaults() async {
    _backgroundColor = _defaultBackgroundColor;
    _sidebarColor = _defaultSidebarColor;
    _fontScale = _defaultFontScale;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_backgroundColorKey);
      await prefs.remove(_sidebarColorKey);
      await prefs.remove(_fontScaleKey);
      await prefs.remove(_customSitesKey); // Also remove custom sites
    } catch (e) {
      // Handle error silently
    }
  }

  // NEW: Save custom websites
  Future<void> saveCustomSites(List<String> sites) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_customSitesKey, sites);
    } catch (e) {
      // ignore: avoid_print
      print('Error saving custom sites: $e');
    }
  }

  // NEW: Get custom websites
  Future<List<String>> getCustomSites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_customSitesKey) ?? [];
    } catch (e) {
      // ignore: avoid_print
      print('Error loading custom sites: $e');
      return [];
    }
  }
}
