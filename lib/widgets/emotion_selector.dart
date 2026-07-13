import 'package:flutter/material.dart';

class EmotionSelector extends StatefulWidget {
  const EmotionSelector({super.key});

  @override
  State<EmotionSelector> createState() => _EmotionSelectorState();
}

class _EmotionSelectorState extends State<EmotionSelector> {
  String _selectedEmotion = '';

  final List<Map<String, String>> _emotions = [
    {'icon': '😊', 'label': 'Vui'},
    {'icon': '❤️', 'label': 'Thương'},
    {'icon': '😢', 'label': 'Nhớ'},
    {'icon': '😤', 'label': 'Hờn'},
    {'icon': '🥰', 'label': 'Yêu'},
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: _emotions.map((e) {
        final isSelected = _selectedEmotion == e['label'];
        return GestureDetector(
          onTap: () => setState(() => _selectedEmotion = e['label']!),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.pink[100] : Colors.grey[200],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.pink : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Text(e['icon']!, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(height: 4),
              Text(e['label']!,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.pink : Colors.grey,
                  )),
            ],
          ),
        );
      }).toList(),
    );
  }
}