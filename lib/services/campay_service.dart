import 'package:supabase_flutter/supabase_flutter.dart';

class CampayService {
  final SupabaseClient _client;

  CampayService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  /// Lance la collecte de paiement via l'Edge Function 'campay-collect'
  Future<Map<String, dynamic>> startCollection({
    required String organizationId,
    required String cotisationId,
    required String memberId,
    required String phone,
    required double amount,
  }) async {
    late final FunctionResponse response;
    try {
      response = await _client.functions.invoke(
        'campay-collect',
        body: {
          'organizationId': organizationId,
          'cotisationId': cotisationId,
          'memberId': memberId,
          'phone': phone,
          'amount': amount,
        },
      );
    } on FunctionException catch (error) {
      final details = error.details;
      final message = details is Map ? details['error'] : null;
      throw Exception(message ?? 'Erreur Edge Function (${error.status}).');
    }

    final data = response.data;

    if (response.status < 200 || response.status >= 300 || data is! Map) {
      final message = data is Map ? data['error'] : null;
      throw Exception(message ?? 'La demande Campay a échoué.');
    }

    return Map<String, dynamic>.from(data);
  }

  Future<String> getTransactionStatus(String transactionId) async {
    final row = await _client
        .from('campay_transactions')
        .select('status')
        .eq('id', transactionId)
        .maybeSingle();
    if (row == null) throw Exception('Transaction Campay introuvable.');
    return row['status'] as String;
  }

  Future<List<Map<String, dynamic>>> getRecentTransactions() async {
    final rows = await _client
        .from('campay_transactions')
        .select(
          'id, organization_name, cotisation_title, member_name, amount, currency, status, created_at, paid_at, error_message',
        )
        .order('created_at', ascending: false)
        .limit(100);
    return rows
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  Future<void> reconcileHistoricalPayment({
    required String organizationId,
    required String cotisationId,
    required String memberId,
    required String providerReference,
    required double amount,
  }) async {
    await _client.rpc('reconcile_historical_campay_payment', params: {
      'target_organization_id': organizationId,
      'target_cotisation_id': cotisationId,
      'target_member_id': memberId,
      'target_provider_reference': providerReference,
      'target_amount': amount,
    });
  }
}