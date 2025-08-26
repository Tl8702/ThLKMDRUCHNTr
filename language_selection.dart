import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';

/// A page allowing the user to select their preferred language. The choice
/// is persisted using SharedPreferences so that this page is only shown on
/// first launch. The design of this page loosely follows the provided
/// wireframe, with a colourful background and cards for each language.
class LanguageSelectionPage extends StatelessWidget {
  const LanguageSelectionPage({super.key});

  /// List of supported languages with their display names and locale codes.
  static const List<Map<String, String>> languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'es', 'name': 'Español'},
    {'code': 'ar', 'name': 'العربية'},
    {'code': 'fr', 'name': 'Français'},
    {'code': 'pt', 'name': 'Português'},
    {'code': 'de', 'name': 'Deutsch'},
    {'code': 'ru', 'name': 'Русский'},
    {'code': 'ja', 'name': '日本語'},
    {'code': 'hi', 'name': 'हिंदी'},
  ];

  /// Persist the selected language and navigate to the home page.
  Future<void> _onLanguageSelected(
      BuildContext context, Map<String, String> language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', language['code'] ?? 'en');
    // Navigate to the home page and remove the language selection page from the stack.
    // Using pushReplacement ensures the user cannot return to this page with the back button.
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF5733).withOpacity(0.1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                'Choose your language:',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              // Grid of language cards
              Expanded(
                child: GridView.builder(
                  itemCount: languages.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemBuilder: (context, index) {
                    final language = languages[index];
                    return GestureDetector(
                      onTap: () => _onLanguageSelected(context, language),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              language['name']!,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Start button to proceed without selecting language again (optional)
              ElevatedButton(
                onPressed: () {
                  // If the user taps start without explicitly selecting a language,
                  // default to English.
                  _onLanguageSelected(
                    context,
                    {'code': 'en', 'name': 'English'},
                  );
                },
                style: ElevatedButton.styleFrom(
                  shape: const StadiumBorder(),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14.0),
                  child: Text('Start'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
