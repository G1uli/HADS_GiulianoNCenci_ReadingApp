// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:reading_app/services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  late Color _selectedBackgroundColor;
  late Color _selectedSidebarColor;
  late double _fontScale;

  // Predefined color options
  final List<Color> _colorOptions = [
    Colors.white,
    Colors.black,
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
    Colors.brown,
  ];

  final List<String> _colorNames = [
    'White',
    'Black',
    'Blue',
    'Red',
    'Green',
    'Orange',
    'Purple',
    'Teal',
    'Indigo',
    'Brown',
  ];

  @override
  void initState() {
    super.initState();
    _selectedBackgroundColor = _settingsService.backgroundColor;
    _selectedSidebarColor = _settingsService.sidebarColor;
    _fontScale = _settingsService.fontScale;
  }

  // Helper method to determine text color based on background brightness
  Color _getTextColorForBackground(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
  }

  // Helper method to compare colors without using deprecated .value
  bool _colorsAreEqual(Color color1, Color color2) {
    return color1.red == color2.red &&
        color1.green == color2.green &&
        color1.blue == color2.blue &&
        color1.alpha == color2.alpha;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'App Settings',
          style: TextStyle(
            color: _getTextColorForBackground(_settingsService.backgroundColor),
          ),
        ),
        backgroundColor: _settingsService.backgroundColor,
        iconTheme: IconThemeData(
          color: _getTextColorForBackground(_settingsService.backgroundColor),
        ),
      ),
      backgroundColor: _settingsService.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Background Color Selection
            Text(
              'Background Color',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getTextColorForBackground(
                  _settingsService.backgroundColor,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _colorOptions.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(
                        _colorNames[index],
                        style: TextStyle(
                          color: _colorOptions[index].computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                        ),
                      ),
                      selected: _colorsAreEqual(
                        _selectedBackgroundColor,
                        _colorOptions[index],
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedBackgroundColor = _colorOptions[index];
                          });
                          _settingsService.saveBackgroundColor(
                            _colorOptions[index],
                          );
                          // Refresh the screen to update colors immediately
                          if (mounted) {
                            setState(() {});
                          }
                        }
                      },
                      selectedColor: _colorOptions[index],
                      backgroundColor: _colorOptions[index].withOpacity(0.3),
                      labelStyle: TextStyle(
                        color: _colorOptions[index].computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Sidebar Color Selection
            Text(
              'Sidebar Color',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getTextColorForBackground(
                  _settingsService.backgroundColor,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _colorOptions.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(
                        _colorNames[index],
                        style: TextStyle(
                          color: _colorOptions[index].computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                        ),
                      ),
                      selected: _colorsAreEqual(
                        _selectedSidebarColor,
                        _colorOptions[index],
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedSidebarColor = _colorOptions[index];
                          });
                          _settingsService.saveSidebarColor(
                            _colorOptions[index],
                          );
                        }
                      },
                      selectedColor: _colorOptions[index],
                      backgroundColor: _colorOptions[index].withOpacity(0.3),
                      labelStyle: TextStyle(
                        color: _colorOptions[index].computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Font Size Scaling
            Text(
              'Text Size',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getTextColorForBackground(
                  _settingsService.backgroundColor,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'Small',
                  style: TextStyle(
                    color: _getTextColorForBackground(
                      _settingsService.backgroundColor,
                    ),
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: _fontScale,
                    min: 0.8,
                    max: 1.5,
                    divisions: 7,
                    label: _fontScale.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        _fontScale = value;
                      });
                      _settingsService.saveFontScale(value);
                    },
                  ),
                ),
                Text(
                  'Large',
                  style: TextStyle(
                    color: _getTextColorForBackground(
                      _settingsService.backgroundColor,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'Preview Text - Current scale: ${_fontScale.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 16 * _fontScale,
                color: _getTextColorForBackground(
                  _settingsService.backgroundColor,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Reset to Defaults
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedBackgroundColor = Colors.white;
                  _selectedSidebarColor = Colors.blue;
                  _fontScale = 1.0;
                });
                _settingsService.resetToDefaults();
                // Refresh to show changes immediately
                if (mounted) {
                  setState(() {});
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Settings reset to defaults'),
                    backgroundColor: _settingsService.sidebarColor,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _getTextColorForBackground(
                  _settingsService.backgroundColor,
                ).withOpacity(0.1),
                foregroundColor: _getTextColorForBackground(
                  _settingsService.backgroundColor,
                ),
              ),
              child: const Text('Reset to Default Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
