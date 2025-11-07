import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/localization_service.dart';

/// Language Switcher Widget
/// Add this to any screen to allow users to switch languages
class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final isEnglish = localeProvider.locale.languageCode == 'en';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => localeProvider.toggleLocale(),
        borderRadius: BorderRadius.circular(20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language,
              size: 18,
              color: Colors.white.withOpacity(0.9),
            ),
            const SizedBox(width: 6),
            Text(
              isEnglish ? 'EN' : 'VI',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.swap_horiz,
              size: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }
}

/// Language Dropdown Widget
/// More detailed language selector
class LanguageDropdown extends StatelessWidget {
  const LanguageDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButton<Locale>(
        value: localeProvider.locale,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down),
        isExpanded: true,
        items: const [
          DropdownMenuItem(
            value: Locale('en'),
            child: Row(
              children: [
                Text('🇬🇧', style: TextStyle(fontSize: 20)),
                SizedBox(width: 12),
                Text(
                  'English',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          DropdownMenuItem(
            value: Locale('vi'),
            child: Row(
              children: [
                Text('🇻🇳', style: TextStyle(fontSize: 20)),
                SizedBox(width: 12),
                Text(
                  'Tiếng Việt',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
        onChanged: (locale) {
          if (locale != null) {
            localeProvider.setLocale(locale);
          }
        },
      ),
    );
  }
}

/// Settings-style Language Selector
/// Use in settings/profile page
class LanguageSettingsTile extends StatelessWidget {
  const LanguageSettingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final isEnglish = localeProvider.locale.languageCode == 'en';

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF7B2BB0).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.language,
          color: Color(0xFF7B2BB0),
          size: 24,
        ),
      ),
      title: const Text(
        'Language / Ngôn ngữ',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        isEnglish ? 'English' : 'Tiếng Việt',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF7B2BB0).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          isEnglish ? 'EN' : 'VI',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF7B2BB0),
          ),
        ),
      ),
      onTap: () => localeProvider.toggleLocale(),
    );
  }
}
