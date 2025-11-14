import 'package:flutter/material.dart';
import 'expert_dashboard_page.dart';
import 'appointments_page.dart';
import '../profile/profile_page.dart';
import '../chatbot/chatbot_page.dart';
import '../../core/services/localization_service.dart';

/// Main navigation page for experts with bottom navigation bar
/// Shows: Dashboard, Appointments, Schedule (placeholder), Chatbot, Profile
class ExpertMainPage extends StatefulWidget {
  const ExpertMainPage({super.key});

  @override
  State<ExpertMainPage> createState() => _ExpertMainPageState();
}

class _ExpertMainPageState extends State<ExpertMainPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget currentTab;
    
    switch (_selectedIndex) {
      case 0:
        currentTab = const ExpertDashboardPage();
        break;
      case 1:
        currentTab = const AppointmentsPage();
        break;
      case 2:
        // TODO: Schedule Management Page (Phase 2 Task 3)
        currentTab = _buildPlaceholderTab(
          'Schedule Management',
          'Set your availability and working hours',
          Icons.schedule_outlined,
        );
        break;
      case 3:
        currentTab = const ChatbotPage();
        break;
      case 4:
        currentTab = const ProfilePage();
        break;
      default:
        currentTab = const ExpertDashboardPage();
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: currentTab,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  0,
                  Icons.dashboard_outlined,
                  Icons.dashboard,
                  'Dashboard',
                ),
                _buildNavItem(
                  1,
                  Icons.calendar_month_outlined,
                  Icons.calendar_month,
                  'Appointments',
                ),
                _buildNavItem(
                  2,
                  Icons.schedule_outlined,
                  Icons.schedule,
                  'Schedule',
                ),
                _buildNavItem(
                  3,
                  Icons.chat_bubble_outline,
                  Icons.chat_bubble,
                  context.l10n.chatbot,
                ),
                _buildNavItem(
                  4,
                  Icons.person_outline,
                  Icons.person,
                  context.l10n.profile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData outlinedIcon,
    IconData filledIcon,
    String label,
  ) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? filledIcon : outlinedIcon,
            color: isSelected ? const Color(0xFF4CAF50) : Colors.grey,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? const Color(0xFF4CAF50) : Colors.grey,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderTab(String title, String subtitle, IconData icon) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 64,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.construction,
                        size: 20,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Coming Soon in Phase 2',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
