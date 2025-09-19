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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Background Color Selection
            const Text(
              'Background Color',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      label: Text(_colorNames[index]),
                      // ignore: deprecated_member_use
                      selected:
                          // ignore: deprecated_member_use
                          _selectedBackgroundColor.value ==
                          // ignore: deprecated_member_use
                          _colorOptions[index].value,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedBackgroundColor = _colorOptions[index];
                          });
                          _settingsService.saveBackgroundColor(
                            _colorOptions[index],
                          );
                        }
                      },
                      selectedColor: _colorOptions[index],
                      backgroundColor: _colorOptions[index],
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
            const Text(
              'Sidebar Color',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      label: Text(_colorNames[index]),
                      // ignore: deprecated_member_use
                      selected:
                          // ignore: deprecated_member_use
                          _selectedSidebarColor.value ==
                          // ignore: deprecated_member_use
                          _colorOptions[index].value,
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
                      backgroundColor: _colorOptions[index],
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
            const Text(
              'Text Size',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Small'),
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
                const Text('Large'),
              ],
            ),
            Text(
              'Preview Text - Current scale: ${_fontScale.toStringAsFixed(1)}',
              style: TextStyle(fontSize: 16 * _fontScale),
            ),
            const SizedBox(height: 20),

            // Reset to Defaults
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedBackgroundColor = Colors.white;
                  _selectedSidebarColor = Colors.white;
                  _fontScale = 1.0;
                });
                _settingsService.resetToDefaults();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings reset to defaults')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black,
              ),
              child: const Text('Reset to Default Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
