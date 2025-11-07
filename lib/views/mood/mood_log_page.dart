import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/mood_entry.dart';
import '../../services/firestore_service.dart';
import '../../core/services/localization_service.dart';

class MoodLogPage extends StatefulWidget {
  const MoodLogPage({super.key});

  @override
  State<MoodLogPage> createState() => _MoodLogPageState();
}

class _MoodLogPageState extends State<MoodLogPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _noteController = TextEditingController();
  
  int _selectedMoodLevel = 3; // Default: Okay
  final Set<String> _selectedFactors = {};
  bool _isSaving = false;

  // Mood levels with emojis - Will be localized in build method
  List<Map<String, dynamic>> get _moodLevels => [
    {'level': 1, 'emoji': '😞', 'labelKey': 'veryPoor'},
    {'level': 2, 'emoji': '😕', 'labelKey': 'poor'},
    {'level': 3, 'emoji': '😐', 'labelKey': 'okay'},
    {'level': 4, 'emoji': '🙂', 'labelKey': 'good'},
    {'level': 5, 'emoji': '😄', 'labelKey': 'excellent'},
  ];

  // Emotion factors - Will be localized in build method
  List<String> get _emotionFactorKeys => [
    'work',
    'family',
    'health',
    'relationships',
    'sleep',
    'exercise',
    'social',
    'money',
    'weather',
    'food',
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveMoodEntry() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final moodEntry = MoodEntry(
        entryId: '', // Firestore will generate
        userId: user.uid,
        moodLevel: _selectedMoodLevel,
        note: _noteController.text.trim(),
        emotionFactors: _selectedFactors.toList(),
        tags: [], // Can add tags later
        timestamp: DateTime.now(),
      );

      await _firestoreService.createMoodEntry(moodEntry);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.moodLoggedSuccess),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate back after short delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.errorSavingMood(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.l10n.moodLog,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Color(0xFF4CAF50),
                  strokeWidth: 2.5,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveMoodEntry,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Text(
                context.l10n.save,
                style: const TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question
              Text(
                context.l10n.howAreYouFeelingToday,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 32),

              // Mood selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _moodLevels.map((mood) {
                  final isSelected = _selectedMoodLevel == mood['level'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMoodLevel = mood['level']),
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? const Color(0xFF81C784).withOpacity(0.2)
                                : Colors.orange.shade50,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected 
                                  ? const Color(0xFF4CAF50)
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              mood['emoji'],
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getMoodLabel(context, mood['labelKey']),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected 
                                ? const Color(0xFF4CAF50)
                                : Colors.grey.shade700,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),

              // Notes section
              Text(
                context.l10n.notes,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _noteController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: context.l10n.notesHint,
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: const TextStyle(fontSize: 15),
                ),
              ),
              const SizedBox(height: 32),

              // What's influencing your mood
              Text(
                context.l10n.emotionFactors,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _emotionFactorKeys.map((factorKey) {
                  final factor = _getEmotionFactorLabel(context, factorKey);
                  final isSelected = _selectedFactors.contains(factorKey);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedFactors.remove(factorKey);
                        } else {
                          _selectedFactors.add(factorKey);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? const Color(0xFF81C784).withOpacity(0.3)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: isSelected 
                              ? const Color(0xFF4CAF50)
                              : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        factor,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected 
                              ? const Color(0xFF2E7D32)
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 80), // Space for FAB
            ],
          ),
        ),
      ),
    );
  }

  String _getMoodLabel(BuildContext context, String labelKey) {
    switch (labelKey) {
      case 'veryPoor':
        return context.l10n.veryPoor;
      case 'poor':
        return context.l10n.poor;
      case 'okay':
        return context.l10n.okay;
      case 'good':
        return context.l10n.good;
      case 'excellent':
        return context.l10n.excellent;
      default:
        return '';
    }
  }

  String _getEmotionFactorLabel(BuildContext context, String factorKey) {
    switch (factorKey) {
      case 'work':
        return context.l10n.work;
      case 'family':
        return context.l10n.family;
      case 'health':
        return context.l10n.health;
      case 'relationships':
        return context.l10n.relationships;
      case 'sleep':
        return context.l10n.sleep;
      case 'exercise':
        return context.l10n.exercise;
      case 'social':
        return context.l10n.social;
      case 'money':
        return context.l10n.money;
      case 'weather':
        return context.l10n.weather;
      case 'food':
        return context.l10n.food;
      default:
        return factorKey;
    }
  }
}
