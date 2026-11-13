import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const jsonResponse = (body: Record<string, unknown>, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (request.method !== 'POST') return jsonResponse({ error: 'Méthode non autorisée.' }, 405);

  const authorization = request.headers.get('Authorization');
  if (!authorization) return jsonResponse({ error: 'Connexion requise.' }, 401);

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    const campayUsername = Deno.env.get('CAMPAY_USERNAME');
    const campayPassword = Deno.env.get('CAMPAY_PASSWORD');
    const campayBaseUrl = (Deno.env.get('CAMPAY_BASE_URL') ?? 'https://demo.campay.net').replace(/\/$/, '');
    if (!supabaseUrl || !supabaseAnonKey || !serviceRoleKey || !campayUsername || !campayPassword) {
      return jsonResponse({ error: 'La configuration serveur Campay est incomplète.' }, 503);
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authorization } },
    });
    const admin = createClient(supabaseUrl, serviceRoleKey);
    const { data: authData, error: authError } = await supabase.auth.getUser();
    if (authError || !authData.user) return jsonResponse({ error: 'Session invalide.' }, 401);

    const body = await request.json();
    const organizationId = String(body.organizationId ?? '');
    const cotisationId = String(body.cotisationId ?? '');
    const memberId = String(body.memberId ?? '');
    const phone = String(body.phone ?? '').replace(/\D/g, '');
    const amount = Number(body.amount);
    if (!organizationId || !cotisationId || !memberId || phone.length < 9 || phone.length > 15 || !Number.isFinite(amount) || amount <= 0) {
      return jsonResponse({ error: 'Organisation, cotisation, numéro ou montant invalide.' }, 400);
    }

    const { data: organization, error: organizationError } = await supabase
      .from('organizations')
      .select('id, owner_id, snapshot')
      .eq('id', organizationId)
      .maybeSingle();
    if (organizationError || !organization) return jsonResponse({ error: 'Organisation introuvable ou accès refusé.' }, 404);

    const snapshot = organization.snapshot as Record<string, unknown>;
    const cotisations = Array.isArray(snapshot.cotisations) ? snapshot.cotisations as Record<string, unknown>[] : [];
    const cotisation = cotisations.find((item) => item.id === cotisationId);
    const participants = Array.isArray(cotisation?.participants)
      ? cotisation.participants as Record<string, unknown>[]
      : [];
    const participant = participants.find((item) => {
      const member = item.member as Record<string, unknown> | undefined;
      return member?.id === memberId;
    });
    if (!participant) return jsonResponse({ error: 'Ce membre ne participe pas à cette cotisation.' }, 403);

    const participantMember = participant.member as Record<string, unknown>;
    const isOrganizationOwner = organization.owner_id === authData.user.id;
    const isMemberOwner = participantMember.ownerAccountId === authData.user.id;
    if (!isOrganizationOwner && !isMemberOwner) {
      return jsonResponse({ error: 'Cette cotisation ne vous est pas attribuée.' }, 403);
    }

    const expected = Number(participant.montantAttendu ?? 0);
    const paid = Number(participant.montantPaye ?? 0);
    if (expected > 0 && amount > expected - paid + 0.001) {
      return jsonResponse({ error: 'Le montant dépasse le reste à cotiser.' }, 400);
    }

    const tokenResponse = await fetch(`${campayBaseUrl}/api/token/`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username: campayUsername, password: campayPassword }),
    });
    const tokenData = await tokenResponse.json();
    if (!tokenResponse.ok || typeof tokenData.token !== 'string') {
      console.error('Campay token request failed:', tokenResponse.status);
      return jsonResponse({ error: 'Impossible de contacter Campay pour le moment.' }, 502);
    }

    const externalReference = `${organizationId}-${cotisationId}-${crypto.randomUUID()}`;
    const amountToCharge = Number(amount.toFixed(0));
    const { data: transaction, error: transactionError } = await admin
      .from('campay_transactions')
      .insert({
        organization_id: organizationId,
        organization_name: String(snapshot.name ?? organization.name),
        cotisation_id: cotisationId,
        cotisation_title: String(cotisation.titre ?? 'Cotisation'),
        member_id: memberId,
        member_name: String(participantMember.name ?? 'Membre'),
        recorded_by: authData.user.id,
        external_reference: externalReference,
        amount: amountToCharge,
        currency: String(snapshot.currency ?? 'XAF'),
      })
      .select('id')
      .single();
    if (transactionError || !transaction) {
      console.error('Campay transaction insert failed:', transactionError?.message);
      return jsonResponse({ error: 'Impossible d’enregistrer la demande de paiement.' }, 500);
    }

    const collectResponse = await fetch(`${campayBaseUrl}/api/collect/`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Token ${tokenData.token}`,
      },
      body: JSON.stringify({
        amount: amountToCharge.toFixed(0),
        currency: String(snapshot.currency ?? 'XAF'),
        from: phone,
        description: `${String(cotisation?.titre ?? 'Cotisation')} - Kolekt`,
        external_reference: externalReference,
      }),
    });
    const collectBody = await collectResponse.text();
    let collectData: Record<string, unknown> = {};
    try {
      const parsed = JSON.parse(collectBody);
      if (parsed && typeof parsed === 'object') collectData = parsed;
    } catch {
      collectData = {};
    }
    if (!collectResponse.ok) {
      const providerMessage = [collectData.detail, collectData.message, collectData.error]
        .find((value) => typeof value === 'string' && value.trim().length > 0);
      const safeMessage = typeof providerMessage === 'string'
        ? providerMessage.slice(0, 300)
        : `Réponse Campay HTTP ${collectResponse.status}`;
      console.error('Campay collect rejected:', collectResponse.status, safeMessage);
      await admin.from('campay_transactions').update({
        status: 'FAILED',
        error_message: safeMessage,
        updated_at: new Date().toISOString(),
      }).eq('id', transaction.id);
      return jsonResponse({
        error: `Campay a refusé la demande : ${safeMessage}`,
        providerStatus: collectResponse.status,
      }, 502);
    }

    const providerReference = typeof collectData.reference === 'string'
      ? collectData.reference
      : null;
    await admin.from('campay_transactions').update({
      provider_reference: providerReference,
      updated_at: new Date().toISOString(),
    }).eq('id', transaction.id);

    const initialStatus = String(collectData.status ?? 'PENDING').toUpperCase();
    if (initialStatus === 'SUCCESSFUL') {
      const { error: finalizeError } = await admin.rpc('finalize_campay_transaction', {
        target_reference: providerReference ?? externalReference,
        target_status: 'SUCCESSFUL',
      });
      if (finalizeError) console.error('Campay immediate finalization failed:', finalizeError.message);
    }

    return jsonResponse({
      transactionId: transaction.id,
      reference: collectData.reference ?? null,
      ussdCode: collectData.ussd_code ?? null,
      operator: collectData.operator ?? null,
      status: initialStatus,
      message: collectData.message ?? 'Confirmez la demande sur votre téléphone.',
    });
  } catch (error) {
    console.error('Campay collect error:', error);
    return jsonResponse({ error: 'Une erreur est survenue lors de la demande Campay.' }, 500);
  }
});