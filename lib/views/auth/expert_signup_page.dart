import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/expert_user.dart';
import '../../services/expert_user_service.dart';
import '../../shared/widgets/modern_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import 'expert_pending_approval_page.dart';

class ExpertSignupPage extends StatefulWidget {
  const ExpertSignupPage({super.key});

  @override
  State<ExpertSignupPage> createState() => _ExpertSignupPageState();
}

class _ExpertSignupPageState extends State<ExpertSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _expertUserService = ExpertUserService();
  
  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _educationController = TextEditingController();
  final _universityController = TextEditingController();
  final _specializationController = TextEditingController();
  final _bioController = TextEditingController();
  
  int? _graduationYear;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentStep = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _licenseNumberController.dispose();
    _educationController.dispose();
    _universityController.dispose();
    _specializationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final credentials = ExpertCredentials(
        licenseNumber: _licenseNumberController.text.trim(),
        education: _educationController.text.trim(),
        university: _universityController.text.trim(),
        graduationYear: _graduationYear,
        specialization: _specializationController.text.trim(),
        bio: _bioController.text.trim(),
      );

      final uid = await _expertUserService.createExpertUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
        credentials: credentials,
      );

      if (uid != null && mounted) {
        // Navigate to pending approval page
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const ExpertPendingApprovalPage(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      if (e.code == 'weak-password') {
        message = 'Password is too weak';
      } else if (e.code == 'email-already-in-use') {
        message = 'Email is already registered';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Expert Registration',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Stepper(
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep < 2) {
                if (_validateCurrentStep()) {
                  setState(() => _currentStep++);
                }
              } else {
                _handleSignup();
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() => _currentStep--);
              }
            },
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _currentStep == 2 ? 'Submit' : 'Continue',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    if (_currentStep > 0) ...[
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: _isLoading ? null : details.onStepCancel,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 24,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Back'),
                      ),
                    ],
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: const Text('Account Info'),
                isActive: _currentStep >= 0,
                state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                content: _buildAccountInfoStep(),
              ),
              Step(
                title: const Text('Credentials'),
                isActive: _currentStep >= 1,
                state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                content: _buildCredentialsStep(),
              ),
              Step(
                title: const Text('Specialization'),
                isActive: _currentStep >= 2,
                state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                content: _buildSpecializationStep(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      return _nameController.text.isNotEmpty &&
          _emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty &&
          _passwordController.text == _confirmPasswordController.text;
    } else if (_currentStep == 1) {
      return _licenseNumberController.text.isNotEmpty &&
          _educationController.text.isNotEmpty;
    }
    return true;
  }

  Widget _buildAccountInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Create your expert account',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 24),
        
        ModernTextField(
          controller: _nameController,
          label: 'Full Name',
          hint: 'Dr. John Doe',
          icon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        ModernTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'expert@example.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!value.contains('@')) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        ModernTextField(
          controller: _passwordController,
          label: 'Password',
          hint: '••••••••',
          icon: Icons.lock_outline,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        ModernTextField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          hint: '••••••••',
          icon: Icons.lock_outline,
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
            },
          ),
          validator: (value) {
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCredentialsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Professional Credentials',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 24),
        
        ModernTextField(
          controller: _licenseNumberController,
          label: 'License Number',
          hint: 'PSY-12345',
          icon: Icons.badge_outlined,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your license number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        ModernTextField(
          controller: _educationController,
          label: 'Education',
          hint: 'PhD in Clinical Psychology',
          icon: Icons.school_outlined,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your education';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        ModernTextField(
          controller: _universityController,
          label: 'University',
          hint: 'Harvard University',
          icon: Icons.account_balance_outlined,
        ),
        const SizedBox(height: 16),
        
        DropdownButtonFormField<int>(
          value: _graduationYear,
          decoration: InputDecoration(
            labelText: 'Graduation Year',
            prefixIcon: const Icon(Icons.calendar_today_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          items: List.generate(
            50,
            (index) => DropdownMenuItem(
              value: DateTime.now().year - index,
              child: Text('${DateTime.now().year - index}'),
            ),
          ),
          onChanged: (value) {
            setState(() => _graduationYear = value);
          },
        ),
      ],
    );
  }

  Widget _buildSpecializationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Specialization',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 24),
        
        DropdownButtonFormField<String>(
          value: _specializationController.text.isEmpty 
              ? null 
              : _specializationController.text,
          decoration: InputDecoration(
            labelText: 'Specialization',
            prefixIcon: const Icon(Icons.psychology_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          items: const [
            DropdownMenuItem(value: 'Anxiety', child: Text('Anxiety')),
            DropdownMenuItem(value: 'Depression', child: Text('Depression')),
            DropdownMenuItem(value: 'Stress', child: Text('Stress')),
            DropdownMenuItem(value: 'Sleep', child: Text('Sleep Disorders')),
            DropdownMenuItem(value: 'Relationships', child: Text('Relationships')),
            DropdownMenuItem(value: 'General', child: Text('General Mental Health')),
          ],
          onChanged: (value) {
            setState(() {
              _specializationController.text = value ?? '';
            });
          },
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _bioController,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: 'Professional Bio',
            hintText: 'Tell us about your experience and approach...',
            alignLabelWithHint: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your bio';
            }
            if (value.length < 50) {
              return 'Bio must be at least 50 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your application will be reviewed by our team. You will be notified via email once approved.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
