import 'package:supabase_flutter/supabase_flutter.dart';

enum OtpChannel { sms, whatsapp, email }

/// Résultat renvoyé après l'envoi du code, pour savoir comment le vérifier ensuite.
class OtpSendResult {
  final OtpChannel channel;
  final String? contact; // numéro ou email, pour ré-affichage

  OtpSendResult({required this.channel, this.contact});
}

class AuthService {
  GoTrueClient get _auth => Supabase.instance.client.auth;

  String describeAuthError(AuthException error) {
    final message = error.message;
    if (message.toLowerCase().contains('error sending confirmation email')) {
      return 'Supabase n’a pas pu envoyer l’e-mail. L’OTP est désactivé dans l’application ; vérifiez le SMTP dans Supabase ou désactivez « Confirm email » pour créer le compte sans vérification.';
    }
    return message;
  }

  Future<User?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return (await _auth.signInWithPassword(email: email, password: password))
        .user;
  }

  Future<User?> createEmailAccount({
    required String email,
    required String password,
    Map<String, dynamic> data = const {},
  }) async {
    return (await _auth.signUp(email: email, password: password, data: data))
        .user;
  }

  Future<User?> signInWithPhonePassword({
    required String phoneNumber,
    required String password,
  }) async {
    return (await _auth.signInWithPassword(
      phone: phoneNumber,
      password: password,
    ))
        .user;
  }

  Future<User?> createPhoneAccount({
    required String phoneNumber,
    required String password,
    Map<String, dynamic> data = const {},
  }) async {
    return (await _auth.signUp(
      phone: phoneNumber,
      password: password,
      data: data,
    ))
        .user;
  }

  /// Envoie un code SMS pour une connexion sans mot de passe.
  Future<OtpSendResult> sendPhoneOtp({
    required String phoneNumber,
  }) async {
    await _auth.signInWithOtp(phone: phoneNumber);
    return OtpSendResult(
      channel: OtpChannel.sms,
      contact: phoneNumber,
    );
  }

  Future<User?> verifyPhoneOtp({
    required String phoneNumber,
    required String smsCode,
  }) async {
    return (await _auth.verifyOTP(
      type: OtpType.sms,
      phone: phoneNumber,
      token: smsCode,
    ))
        .user;
  }

  Future<OtpSendResult> sendWhatsappOtp(String phoneNumber) => Future.error(
      UnsupportedError('Le fournisseur OTP WhatsApp n’est pas configuré.'));

  Future<User?> verifyCustomOtp({
    required OtpChannel channel,
    required String contact,
    required String code,
  }) =>
      Future.error(UnsupportedError('Seul l’OTP SMS Supabase est configuré.'));

  Stream<User?> get authState =>
      _auth.onAuthStateChange.map((state) => state.session?.user);

  User? get currentUser => _auth.currentUser;

  Future<void> signOut() => _auth.signOut();
}
