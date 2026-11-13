import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide OtpChannel;
import '../app/app_router.dart';
import '../data/strings.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared.dart';

enum _Mode { phone, email }

class SignInScreen extends StatefulWidget {
  final bool isSignUp;
  const SignInScreen({super.key, this.isSignUp = false});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> with StoreListening {
  final _authService = AuthService();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  _Mode _mode = _Mode.phone;
  String _countryCode = '+237';
  bool _loading = false;
  String? _errorText; // ex: "Utilisateur non trouvé..."

  Future<void> _handleAuth() async {
    final phoneNumber = '$_countryCode${_phoneController.text.trim()}';
    if (_mode == _Mode.phone &&
        (_phoneController.text.trim().isEmpty ||
            !RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(phoneNumber))) {
      setState(() {
        _errorText = S.t('auth_invalid_phone');
      });
      return;
    }
    if (_mode == _Mode.email && _emailController.text.trim().isEmpty) {
      setState(() => _errorText = S.t('auth_email_required'));
      return;
    }
    if (_passwordController.text.length < 6) {
      setState(() =>
          _errorText = S.t('auth_password_min'));
      return;
    }
    if (widget.isSignUp &&
        _passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorText = S.t('auth_password_mismatch'));
      return;
    }

    setState(() {
      _loading = true;
      _errorText = null;
    });

    try {
      if (_mode == _Mode.phone) {
        if (widget.isSignUp) {
          await _authService.createPhoneAccount(
            phoneNumber: phoneNumber,
            password: _passwordController.text,
          );
        } else {
          await _authService.signInWithPhonePassword(
            phoneNumber: phoneNumber,
            password: _passwordController.text,
          );
        }
      } else {
        if (widget.isSignUp) {
          await _authService.createEmailAccount(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
        } else {
          await _authService.signInWithEmailPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
        }
      }
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          widget.isSignUp ? AppRoutes.authName : AppRoutes.serviceChooser,
          (route) => false,
          arguments: widget.isSignUp ? null : {'name': 'nOVa'},
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _errorText = _authService.describeAuthError(e));
      }
    } catch (e) {
      if (mounted) setState(() => _errorText = 'Erreur : $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Logo(),
                  const SizedBox(height: 12),
                  const Text(
                    'nOVa',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    S.t(widget.isSignUp ? 'auth_create_account' : 'auth_sign_in'),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_errorText != null) _ErrorBanner(text: _errorText!),
                  if (_errorText != null) const SizedBox(height: 16),
                  _ModeToggle(
                    mode: _mode,
                    onChanged: (m) => setState(() => _mode = m),
                  ),
                  const SizedBox(height: 20),
                  if (_mode == _Mode.phone) ...[
                    _PhoneField(
                      controller: _phoneController,
                      onCountryChanged: (code) =>
                          setState(() => _countryCode = code),
                    ),
                  ] else ...[
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: S.t('auth_email_hint'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: S.t('auth_password_hint'),
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                    ),
                  ),
                  if (widget.isSignUp) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: S.t('auth_confirm_password_hint'),
                        prefixIcon: const Icon(Icons.lock_reset_rounded),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _handleAuth,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                            : Text(S.t(widget.isSignUp
                              ? 'auth_create_account'
                              : 'auth_sign_in')),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        S.t(widget.isSignUp
                          ? 'auth_have_account'
                          : 'auth_no_account'),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: () {
                          final target = widget.isSignUp
                              ? const SignInScreen()
                              : const SignInScreen(isSignUp: true);
                          if (GoRouter.maybeOf(context) != null) {
                            context.go(widget.isSignUp
                                ? '/sign-in'
                                : '/create-account');
                          } else {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => target),
                            );
                          }
                        },
                        child: Text(
                            S.t(widget.isSignUp
                              ? 'auth_sign_in'
                              : 'auth_create_account_link'),
                          style: const TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 18),
                    TextButton.icon(
                      onPressed: () =>
                          Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.homeShell,
                        (route) => false,
                        arguments: {'serviceName': 'nOVa Demo'},
                      ),
                      icon: const Icon(Icons.explore_outlined),
                      label: Text(S.t('auth_explore')),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: const Color(0xFF111B2D),
        borderRadius: BorderRadius.circular(28),
        border:
            Border.all(color: AppColors.primaryColor.withValues(alpha: 0.7)),
      ),
      child: const Center(
        child: Text(
          'n',
          style: TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.w900,
            color: AppColors.primaryColor,
            letterSpacing: -2,
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String text;
  const _ErrorBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: AppColors.error, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final _Mode mode;
  final ValueChanged<_Mode> onChanged;
  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget pill(String label, IconData icon, _Mode value) {
      final selected = mode == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 18,
                    color: selected ? Colors.black : AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.black : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        pill(S.t('auth_phone_mode'), Icons.phone, _Mode.phone),
        pill(S.t('auth_email_mode'), Icons.email_outlined, _Mode.email),
      ],
    );
  }
}

class _PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onCountryChanged;
  const _PhoneField({required this.controller, required this.onCountryChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          CountryCodePicker(
            initialSelection: 'CM',
            favorite: const ['+237', 'CM'],
            textStyle: const TextStyle(color: Colors.white),
            onChanged: (c) => onCountryChanged(c.dialCode ?? '+237'),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: S.t('auth_phone_hint'),
                border: InputBorder.none,
                filled: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
