import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:reading_app/services/auth_service.dart';
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
      await prefs.remove(_customSitesKey);
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> saveCustomSites(List<dynamic> sites) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = await AuthService().getCurrentUserEmail();
      final userSitesKey = '${userEmail}_custom_sites';

      developer.log('Saving sites for user: $userEmail');
      developer.log('Number of sites: ${sites.length}');

      // Convert sites to JSON strings for storage
      final sitesData = sites.map((site) {
        if (site is Map) {
          return jsonEncode(site);
        } else {
          return site.toString();
        }
      }).toList();

      developer.log('Sites data to save: $sitesData');
      await prefs.setStringList(userSitesKey, sitesData);
      developer.log('Successfully saved sites for user: $userEmail');
    } catch (e) {
      developer.log('Error saving custom sites: $e');
      debugPrint('Error saving custom sites: $e');
    }
  }

  // Replace your existing getCustomSites method with this:
  Future<List<dynamic>> getCustomSites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = await AuthService().getCurrentUserEmail();
      final userSitesKey = '${userEmail}_custom_sites';

      developer.log('Loading sites for user: $userEmail');
      final sitesData = prefs.getStringList(userSitesKey) ?? [];
      developer.log('Raw sites data loaded: $sitesData');

      // Parse the stored data back to proper format
      List<dynamic> parsedSites = [];
      for (var siteData in sitesData) {
        try {
          // Try to parse as JSON
          final decoded = jsonDecode(siteData);
          parsedSites.add(decoded);
          developer.log('Successfully parsed site: $decoded');
        } catch (e) {
          // If not JSON, treat as simple string (backward compatibility)
          parsedSites.add(siteData);
          developer.log('Using raw string for site: $siteData');
        }
      }

      developer.log('Final parsed sites count: ${parsedSites.length}');
      return parsedSites;
    } catch (e) {
      developer.log('Error loading custom sites: $e');
      debugPrint('Error loading custom sites: $e');
      return [];
    }
  }
}
