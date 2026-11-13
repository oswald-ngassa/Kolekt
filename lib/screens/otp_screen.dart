import 'package:supabase_flutter/supabase_flutter.dart' hide OtpChannel;
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../app/app_router.dart';
import '../data/store.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';

class OtpScreen extends StatefulWidget {
  final OtpSendResult sendResult;
  final AuthService authService;
  final Map<String, dynamic> profile;

  const OtpScreen({
    super.key,
    required this.sendResult,
    required this.authService,
    this.profile = const {},
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String _code = '';
  bool _loading = false;
  String? _errorText;

  String get _maskedContact {
    final c = widget.sendResult.contact ?? '';
    if (c.contains('@')) {
      final parts = c.split('@');
      return '${parts[0].substring(0, 2)}****@${parts[1]}';
    }
    // masque les 4 derniers chiffres, garde l'indicatif + début
    if (c.length > 4) {
      return '${c.substring(0, c.length - 4)}****';
    }
    return c;
  }

  Future<void> _handleVerify() async {
    if (_code.length < 6) return;
    setState(() {
      _loading = true;
      _errorText = null;
    });

    try {
      final user = widget.sendResult.channel == OtpChannel.sms
          ? await widget.authService.verifyPhoneOtp(
              phoneNumber: widget.sendResult.contact!,
              smsCode: _code,
            )
          : await widget.authService.verifyCustomOtp(
              channel: widget.sendResult.channel,
              contact: widget.sendResult.contact!,
              code: _code,
            );
      if (user == null) throw const AuthException('OTP invalide ou expiré.');
      if (mounted) {
        final exists = await UserService().userExists(user.id);

        if (!mounted) return;
        if (exists) {
          final name = await UserService().getName(user.id) ?? '';
          if (!mounted) return;
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.serviceChooser,
            (route) => false,
            arguments: {'name': name},
          );
        } else {
          await UserService().createUser(
            user.id,
            name: widget.profile['name'] as String? ??
                user.userMetadata?['name'] as String? ??
                'Utilisateur',
            phone: widget.sendResult.contact,
            email: widget.profile['email'] as String?,
          );
          AppStore.instance.syncSupabaseUser(user, profile: widget.profile);
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.authName,
            (route) => false,
          );
        }
      }
    } catch (e) {
      setState(() => _errorText = 'Code invalide ou expiré');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios,
                    color: AppColors.primaryColor, size: 16),
                label: const Text('Back',
                    style: TextStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.people_alt_rounded,
                              color: AppColors.accentColor, size: 40),
                        ),
                        const SizedBox(height: 20),
                        const Text('Verification',
                            style: TextStyle(
                                fontSize: 26, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 14),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                                color: AppColors.primaryColor, fontSize: 14),
                            children: [
                              const TextSpan(text: 'Enter the code sent to '),
                              TextSpan(
                                text: _maskedContact,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        PinCodeTextField(
                          appContext: context,
                          length: 6,
                          autoFocus: true,
                          keyboardType: TextInputType.number,
                          animationType: AnimationType.fade,
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.box,
                            borderRadius: BorderRadius.circular(12),
                            fieldHeight: 56,
                            fieldWidth: 48,
                            activeColor: AppColors.primaryColor,
                            selectedColor: AppColors.primaryColor,
                            inactiveColor: AppColors.inputBorder,
                            activeFillColor: AppColors.inputBg,
                            selectedFillColor: AppColors.inputBg,
                            inactiveFillColor: AppColors.inputBg,
                          ),
                          onChanged: (v) => setState(() => _code = v),
                          onCompleted: (v) {
                            _code = v;
                            _handleVerify();
                          },
                        ),
                        if (_errorText != null) ...[
                          const SizedBox(height: 12),
                          Text(_errorText!,
                              style: const TextStyle(color: AppColors.error)),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _handleVerify,
                            child: _loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.black),
                                  )
                                : const Text('Verify'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
