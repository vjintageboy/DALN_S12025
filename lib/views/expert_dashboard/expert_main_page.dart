import 'package:flutter/material.dart';
import 'expert_dashboard_page.dart';
import 'appointments_page.dart';
import 'schedule_page.dart';
import '../profile/profile_page.dart';
import '../chatbot/chatbot_page.dart';
import '../news/news_feed_page.dart';
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
        currentTab = const NewsFeedPage();
        break;
      case 3:
        currentTab = const SchedulePage();
        break;
      case 4:
        currentTab = const ChatbotPage();
        break;
      case 5:
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
              children: [
                Expanded(
                  child: _buildNavItem(
                    0,
                    Icons.dashboard_outlined,
                    Icons.dashboard,
                    'Dashboard',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    1,
                    Icons.calendar_month_outlined,
                    Icons.calendar_month,
                    'Appointments',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    2,
                    Icons.article_outlined,
                    Icons.article,
                    'News',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    3,
                    Icons.schedule_outlined,
                    Icons.schedule,
                    'Schedule',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    4,
                    Icons.chat_bubble_outline,
                    Icons.chat_bubble,
                    context.l10n.chatbot,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    5,
                    Icons.person_outline,
                    Icons.person,
                    context.l10n.profile,
                  ),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            isSelected ? filledIcon : outlinedIcon,
            color: isSelected ? const Color(0xFF4CAF50) : Colors.grey,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            softWrap: false,
            overflow: TextOverflow.fade,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? const Color(0xFF4CAF50) : Colors.grey,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
