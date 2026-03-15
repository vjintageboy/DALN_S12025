import 'package:flutter/material.dart';
import '../../models/expert.dart';
import 'widgets/expert_card.dart';
import 'expert_detail_page.dart';
import '../appointment/my_appointments_page.dart';
import '../../core/services/localization_service.dart';

class ExpertListPage extends StatefulWidget {
  const ExpertListPage({super.key});

  @override
  State<ExpertListPage> createState() => _ExpertListPageState();
}

class _ExpertListPageState extends State<ExpertListPage> {
  List<Expert> _filteredExperts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExperts();
  }

  Future<void> _loadExperts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final experts = await Expert.getAllExperts();

      if (!mounted) return;
      setState(() {
        _filteredExperts = experts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.l10n.errorLoadingExperts}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          context.l10n.findAnExpert,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false, // Remove back button
        actions: [
          // My Appointments button
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.calendar_month_outlined,
                  color: Color(0xFF4CAF50),
                  size: 28,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyAppointmentsPage(),
                    ),
                  );
                },
                tooltip: 'My Appointments',
              ),
              // Optional: Badge for pending appointments count
              // Positioned(
              //   right: 8,
              //   top: 8,
              //   child: Container(
              //     padding: const EdgeInsets.all(4),
              //     decoration: const BoxDecoration(
              //       color: Colors.red,
              //       shape: BoxShape.circle,
              //     ),
              //     constraints: const BoxConstraints(
              //       minWidth: 16,
              //       minHeight: 16,
              //     ),
              //     child: const Text(
              //       '2',
              //       style: TextStyle(
              //         color: Colors.white,
              //         fontSize: 10,
              //         fontWeight: FontWeight.w700,
              //       ),
              //       textAlign: TextAlign.center,
              //     ),
              //   ),
              // ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Expert Count
          if (!_isLoading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.grey.shade50,
              child: Text(
                '${_filteredExperts.length} ${_filteredExperts.length == 1 ? context.l10n.expert : context.l10n.experts} ${context.l10n.available}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ),

          // Expert List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
                  )
                : _filteredExperts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          context.l10n.noExpertsFound,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please check back later for more experts.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadExperts,
                    color: const Color(0xFF4CAF50),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredExperts.length,
                      itemBuilder: (context, index) {
                        final expert = _filteredExperts[index];
                        return ExpertCard(
                          expert: expert,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ExpertDetailPage(expert: expert),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
