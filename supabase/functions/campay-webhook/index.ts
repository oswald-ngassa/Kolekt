import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const jsonResponse = (body: Record<string, unknown>, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });

Deno.serve(async (request) => {
  if (request.method !== 'POST') return jsonResponse({ error: 'Method not allowed.' }, 405);

  const webhookSecret = Deno.env.get('CAMPAY_WEBHOOK_SECRET');
  const suppliedSecret = new URL(request.url).searchParams.get('token');
  if (!webhookSecret || suppliedSecret !== webhookSecret) {
    return jsonResponse({ error: 'Unauthorized.' }, 401);
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!supabaseUrl || !serviceRoleKey) {
    console.error('Supabase service configuration is missing.');
    return jsonResponse({ error: 'Server configuration is incomplete.' }, 503);
  }

  try {
    const body = await request.json();
    const reference = String(body.reference ?? body.transaction_reference ?? body.external_reference ?? '');
    const providerStatus = String(body.status ?? '').toUpperCase();
    const status = providerStatus === 'SUCCESS' ? 'SUCCESSFUL' : providerStatus;
    if (!reference || !['SUCCESSFUL', 'FAILED', 'CANCELLED'].includes(status)) {
      return jsonResponse({ error: 'Invalid Campay notification.' }, 400);
    }

    const admin = createClient(supabaseUrl, serviceRoleKey);
    const { error } = await admin.rpc('finalize_campay_transaction', {
      target_reference: reference,
      target_status: status,
    });
    if (error) {
      console.error('Campay notification processing failed:', error.message);
      return jsonResponse({ error: 'Unable to update transaction.' }, 500);
    }

    return jsonResponse({ received: true });
  } catch (error) {
    console.error('Campay webhook error:', error);
    return jsonResponse({ error: 'Invalid notification body.' }, 400);
  }
});
