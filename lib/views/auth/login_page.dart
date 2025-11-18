import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'signup_page.dart';
import '../home/home_page.dart';
import '../expert_dashboard/expert_main_page.dart';
import '../admin/admin_main_page.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/localization_service.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/modern_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/social_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _forgotPasswordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _forgotPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    
    final success = await authProvider.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      // Get user role from Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        final role = userDoc.data()?['role'] ?? 'user';
        
        if (!mounted) return;
        
        // Navigate based on role - clear entire stack
        Widget destinationPage;
        if (role == 'admin') {
          destinationPage = const AdminMainPage();
        } else if (role == 'expert') {
          destinationPage = const ExpertMainPage();
        } else {
          destinationPage = const HomePage();
        }
        
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => destinationPage),
          (route) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? AppStrings.signInFailed),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showForgotPasswordDialog() {
    final parentContext = context;
    _forgotPasswordController.text = _emailController.text.trim();
    final dialogFormKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> _submitRequest() async {
              if (isSubmitting) return;
              if (!dialogFormKey.currentState!.validate()) return;

              if (!context.mounted) return;
              setState(() => isSubmitting = true);

              final authProvider = parentContext.read<AuthProvider>();
              final success = await authProvider.resetPassword(_forgotPasswordController.text.trim());

              if (!mounted) return;

              if (success) {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: const Text('Nếu email này đã được đăng ký, chúng tôi đã gửi hướng dẫn đặt lại mật khẩu vào hộp thư của bạn.'),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              } else {
                if (!context.mounted) return;
                setState(() => isSubmitting = false);
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: Text(authProvider.errorMessage ?? AppStrings.signInFailed),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            }

            final bottomInset = MediaQuery.of(parentContext).viewInsets.bottom;

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: bottomInset > 0 ? bottomInset : 24,
                top: 24,
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: AlertDialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text(
                      'Đặt lại mật khẩu',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    content: Form(
                      key: dialogFormKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nhập email để nhận liên kết đặt lại mật khẩu.',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          ModernTextField(
                            controller: _forgotPasswordController,
                            label: context.l10n.emailAddress,
                            hint: context.l10n.email,
                            icon: Icons.mail_outline,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return context.l10n.emailAddress;
                              }
                              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegex.hasMatch(value.trim())) {
                                return context.l10n.emailAddress;
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                        ),
                        child: const Text('Hủy'),
                      ),
                      ElevatedButton(
                        onPressed: isSubmitting ? null : _submitRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'Gửi yêu cầu',
                                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    // Back button
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey[100],
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Logo/Brand Area
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Title
                    Text(
                      context.l10n.signInToModiki,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -1.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.signInToContinue,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Email field
                    ModernTextField(
                      controller: _emailController,
                      label: context.l10n.emailAddress,
                      hint: context.l10n.email,
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.l10n.emailAddress;
                        }
                        if (!value.contains('@')) {
                          return context.l10n.emailAddress;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Password field
                    ModernTextField(
                      controller: _passwordController,
                      label: context.l10n.password,
                      hint: context.l10n.password,
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppColors.textSecondary,
                          size: 22,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.l10n.password;
                        }
                        if (value.length < 6) {
                          return context.l10n.password;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        child: Text(
                          context.l10n.forgotPassword,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Login button
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return PrimaryButton(
                          text: context.l10n.signIn,
                          icon: Icons.arrow_forward,
                          isLoading: authProvider.isLoading,
                          onPressed: _login,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Divider
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppColors.borderMedium, thickness: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            context.l10n.orContinueWith,
                            style: TextStyle(
                              color: AppColors.textSecondary.withOpacity(0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(color: AppColors.borderMedium, thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Social login buttons
                    Row(
                      children: [
                        Expanded(
                          child: SocialButton(
                            icon: Icons.g_mobiledata,
                            label: 'Google',
                            onPressed: () {
                              // TODO: Implement Google sign in
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SocialButton(
                            icon: Icons.apple,
                            label: 'Apple',
                            onPressed: () {
                              // TODO: Implement Apple sign in
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Sign up link
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.l10n.dontHaveAccount,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const SignUpPage()),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              context.l10n.signUp,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
