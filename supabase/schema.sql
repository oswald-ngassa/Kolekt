create table if not exists public.users (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null,
  phone text,
  email text,
  ville text,
  pays text,
  region text,
  statut_marital text,
  lieu_residence text,
  created_at timestamptz not null default now()
);

alter table public.users enable row level security;

drop policy if exists "Users can read their own profile" on public.users;
create policy "Users can read their own profile"
  on public.users for select
  using (auth.uid() = id);

drop policy if exists "Users can create their own profile" on public.users;
create policy "Users can create their own profile"
  on public.users for insert
  with check (auth.uid() = id);

drop policy if exists "Users can update their own profile" on public.users;
create policy "Users can update their own profile"
  on public.users for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

drop policy if exists "Users can delete their own profile" on public.users;
create policy "Users can delete their own profile"
  on public.users for delete
  using (auth.uid() = id);

create table if not exists public.organizations (
  id text primary key,
  owner_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  join_code text,
  snapshot jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.organizations
  add column if not exists join_code text;

create or replace function public.generate_organization_join_code()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.join_code is null or btrim(new.join_code) = '' then
    loop
      new.join_code := 'KOL-' || upper(substr(md5(random()::text || clock_timestamp()::text), 1, 8));
      exit when not exists (
        select 1 from public.organizations o where o.join_code = new.join_code
      );
    end loop;
  end if;
  return new;
end;
$$;

drop trigger if exists organizations_generate_join_code on public.organizations;
create trigger organizations_generate_join_code
  before insert or update on public.organizations
  for each row execute function public.generate_organization_join_code();

update public.organizations
set join_code = null
where join_code is null or btrim(join_code) = '';

create unique index if not exists organizations_join_code_unique_idx
  on public.organizations (join_code);

create index if not exists organizations_owner_id_idx
  on public.organizations (owner_id);

alter table public.organizations enable row level security;

create table if not exists public.organization_members (
  organization_id text not null references public.organizations (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null default 'Membre'
    check (role in ('Propriétaire / Administrateur', 'Administrateur', 'Membre')),
  joined_at timestamptz not null default now(),
  primary key (organization_id, user_id)
);

create index if not exists organization_members_user_id_idx
  on public.organization_members (user_id);

create or replace function public.join_organization_by_code(target_join_code text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_org public.organizations%rowtype;
  v_profile public.users%rowtype;
  v_metadata jsonb;
  v_name text;
  v_phone text;
  v_email text;
  v_pays text;
  v_statut_marital text;
  v_ville text;
  v_region text;
  v_lieu_residence text;
  v_member_id text := gen_random_uuid()::text;
  v_member jsonb;
  v_activity jsonb;
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  select * into v_org
  from public.organizations
  where join_code = upper(btrim(target_join_code))
  for update;

  if not found then
    raise exception 'Invalid join code';
  end if;

  if v_org.owner_id = v_user_id or exists (
    select 1 from public.organization_members om
    where om.organization_id = v_org.id and om.user_id = v_user_id
  ) then
    raise exception 'Already a member';
  end if;

  select * into v_profile from public.users where id = v_user_id;
  if not found then
    select raw_user_meta_data into v_metadata
    from auth.users
    where id = v_user_id;
    v_name := coalesce(v_metadata->>'name', 'Membre');
    v_phone := coalesce(v_metadata->>'phone', '');
    v_email := v_metadata->>'email';
    v_pays := v_metadata->>'pays';
    v_statut_marital := v_metadata->>'statutMarital';
    v_ville := v_metadata->>'ville';
    v_region := v_metadata->>'region';
    v_lieu_residence := v_metadata->>'lieuResidence';
  else
    v_name := v_profile.name;
    v_phone := coalesce(v_profile.phone, '');
    v_email := v_profile.email;
    v_pays := v_profile.pays;
    v_statut_marital := v_profile.statut_marital;
    v_ville := v_profile.ville;
    v_region := v_profile.region;
    v_lieu_residence := v_profile.lieu_residence;
  end if;

  v_member := jsonb_build_object(
    'id', v_member_id,
    'name', v_name,
    'phone', v_phone,
    'email', v_email,
    'role', 'Membre',
    'ownerAccountId', v_user_id::text,
    'matricule', null,
    'pays', v_pays,
    'statutMarital', v_statut_marital,
    'ville', v_ville,
    'region', v_region,
    'lieuResidence', v_lieu_residence,
    'joinedAt', now()::text
  );

  insert into public.organization_members (organization_id, user_id, role)
  values (v_org.id, v_user_id, 'Membre');

  insert into public.members (
    id, organization_id, owner_user_id, name, phone, email, role,
    pays, statut_marital, ville, region, lieu_residence
  ) values (
    v_member_id, v_org.id, v_user_id, v_name,
    v_phone, v_email, 'Membre',
    v_pays, v_statut_marital, v_ville,
    v_region, v_lieu_residence
  );

  v_activity := jsonb_build_object(
    'text', v_name || ' a rejoint l’association',
    'date', now()::text,
    'type', 'member',
    'isRead', false
  );

  update public.organizations
  set snapshot = jsonb_set(
        jsonb_set(
          coalesce(snapshot, '{}'::jsonb),
          '{members}',
          coalesce(snapshot->'members', '[]'::jsonb) || jsonb_build_array(v_member),
          true
        ),
        '{activity_log}',
        coalesce(snapshot->'activity_log', '[]'::jsonb) || jsonb_build_array(v_activity),
        true
      ),
      updated_at = now()
  where id = v_org.id;

  return jsonb_build_object('organization_id', v_org.id);
end;
$$;

revoke all on function public.join_organization_by_code(text) from public;
grant execute on function public.join_organization_by_code(text) to authenticated;

create table if not exists public.members (
  id text primary key,
  organization_id text not null references public.organizations (id) on delete cascade,
  owner_user_id uuid references auth.users (id) on delete set null,
  name text not null,
  phone text not null default '',
  email text,
  role text not null default 'Membre',
  matricule text,
  pays text,
  statut_marital text,
  ville text,
  region text,
  lieu_residence text,
  joined_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index if not exists members_organization_id_idx
  on public.members (organization_id);

create table if not exists public.tontines (
  id text primary key,
  organization_id text not null references public.organizations (id) on delete cascade,
  created_by uuid not null references auth.users (id) on delete restrict,
  libelle text not null,
  description text,
  montant_base numeric(14, 2) not null default 0 check (montant_base >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists tontines_organization_id_idx
  on public.tontines (organization_id);

create table if not exists public.tontine_members (
  tontine_id text not null references public.tontines (id) on delete cascade,
  member_id text not null references public.members (id) on delete cascade,
  is_beneficiary boolean not null default false,
  position integer,
  added_at timestamptz not null default now(),
  primary key (tontine_id, member_id)
);

create table if not exists public.cotisations (
  id text primary key,
  organization_id text not null references public.organizations (id) on delete cascade,
  created_by uuid not null references auth.users (id) on delete restrict,
  titre text not null,
  type text not null default 'Volontaire'
    check (type in ('Volontaire', 'Fixe')),
  visibilite text not null default 'Privée'
    check (visibilite in ('Privée', 'Publique')),
  date_fin timestamptz not null,
  description text,
  sanctions_automatiques boolean not null default false,
  payer_avec_frais boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists cotisations_organization_id_idx
  on public.cotisations (organization_id);

create table if not exists public.cotisation_participants (
  cotisation_id text not null references public.cotisations (id) on delete cascade,
  member_id text not null references public.members (id) on delete cascade,
  montant_attendu numeric(14, 2) not null default 0 check (montant_attendu >= 0),
  primary key (cotisation_id, member_id)
);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  cotisation_id text not null references public.cotisations (id) on delete cascade,
  member_id text not null references public.members (id) on delete cascade,
  recorded_by uuid not null references auth.users (id) on delete restrict,
  amount numeric(14, 2) not null check (amount > 0),
  currency text not null default 'XAF',
  payment_method text,
  note text,
  paid_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.campay_transactions (
  id uuid primary key default gen_random_uuid(),
  organization_id text not null references public.organizations (id) on delete cascade,
  organization_name text not null,
  cotisation_id text not null,
  cotisation_title text not null,
  member_id text not null,
  member_name text not null,
  recorded_by uuid not null references auth.users (id) on delete restrict,
  external_reference text not null unique,
  provider_reference text unique,
  amount numeric(14, 2) not null check (amount > 0),
  currency text not null default 'XAF',
  status text not null default 'PENDING'
    check (status in ('PENDING', 'SUCCESSFUL', 'FAILED', 'CANCELLED')),
  reconciled_manually boolean not null default false,
  error_message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  paid_at timestamptz
);

alter table public.campay_transactions
  add column if not exists organization_name text not null default '',
  add column if not exists cotisation_title text not null default '',
  add column if not exists member_name text not null default '',
  add column if not exists reconciled_manually boolean not null default false;

create index if not exists campay_transactions_organization_created_idx
  on public.campay_transactions (organization_id, created_at desc);

create index if not exists payments_cotisation_id_idx
  on public.payments (cotisation_id, paid_at desc);

create or replace function public.is_organization_manager(target_organization_id text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.organizations o
    where o.id = target_organization_id
      and o.owner_id = (select auth.uid())
  ) or exists (
    select 1
    from public.organization_members om
    where om.organization_id = target_organization_id
      and om.user_id = (select auth.uid())
      and om.role in ('Propriétaire / Administrateur', 'Administrateur')
  );
$$;

revoke all on function public.is_organization_manager(text) from public;
grant execute on function public.is_organization_manager(text) to authenticated;

create or replace function public.leave_organization(
  target_organization_id text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_snapshot jsonb;
  v_members jsonb;
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  if exists (
    select 1 from public.organizations
    where id = target_organization_id and owner_id = v_user_id
  ) then
    raise exception 'The organization owner cannot leave the organization';
  end if;

  select snapshot into v_snapshot
  from public.organizations
  where id = target_organization_id
  for update;

  if not found then
    raise exception 'Organization not found';
  end if;

  select coalesce(jsonb_agg(member), '[]'::jsonb) into v_members
  from jsonb_array_elements(coalesce(v_snapshot->'members', '[]'::jsonb)) as member
  where member->>'ownerAccountId' is distinct from v_user_id::text;

  update public.organizations
  set snapshot = jsonb_set(v_snapshot, '{members}', v_members, true),
      updated_at = now()
  where id = target_organization_id;

  delete from public.organization_members
  where organization_id = target_organization_id and user_id = v_user_id;
end;
$$;

revoke all on function public.leave_organization(text) from public;
grant execute on function public.leave_organization(text) to authenticated;

drop policy if exists "Owners can read their organizations" on public.organizations;
drop policy if exists "Authenticated users can create owned organizations" on public.organizations;
drop policy if exists "Owners can update their organizations" on public.organizations;
drop policy if exists "Owners can delete their organizations" on public.organizations;

drop policy if exists "Members can read their organizations" on public.organizations;
create policy "Members can read their organizations"
  on public.organizations for select
  using (
    owner_id = (select auth.uid())
    or exists (
      select 1 from public.organization_members om
      where om.organization_id = id and om.user_id = (select auth.uid())
    )
  );

drop policy if exists "Users can create owned organizations" on public.organizations;
create policy "Users can create owned organizations"
  on public.organizations for insert
  with check (owner_id = (select auth.uid()));

drop policy if exists "Managers can update organizations" on public.organizations;
create policy "Managers can update organizations"
  on public.organizations for update
  using (public.is_organization_manager(id))
  with check (public.is_organization_manager(id));

create or replace function public.protect_organization_settings()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if old.owner_id <> (select auth.uid()) and (
    new.name is distinct from old.name
    or new.snapshot->'acronym' is distinct from old.snapshot->'acronym'
    or new.snapshot->'description' is distinct from old.snapshot->'description'
    or new.snapshot->'currency' is distinct from old.snapshot->'currency'
    or new.snapshot->'fond_de_caisse_actif' is distinct from old.snapshot->'fond_de_caisse_actif'
    or new.snapshot->'fond_de_caisse_montant' is distinct from old.snapshot->'fond_de_caisse_montant'
    or new.snapshot->'paiement_en_ligne' is distinct from old.snapshot->'paiement_en_ligne'
    or new.snapshot->'payer_avec_frais' is distinct from old.snapshot->'payer_avec_frais'
    or new.snapshot->'prets_epargne_actif' is distinct from old.snapshot->'prets_epargne_actif'
    or new.snapshot->'invite_links' is distinct from old.snapshot->'invite_links'
    or new.snapshot->'wallet_managers' is distinct from old.snapshot->'wallet_managers'
    or exists (
      select 1
      from jsonb_array_elements(coalesce(new.snapshot->'members', '[]'::jsonb)) as new_members(new_member)
      left join lateral (
        select old_members.old_member
        from jsonb_array_elements(coalesce(old.snapshot->'members', '[]'::jsonb)) as old_members(old_member)
        where old_member->>'id' = new_member->>'id'
        limit 1
      ) as previous_member on true
      where (previous_member.old_member is null
             and coalesce(new_member->>'role', 'Membre') <> 'Membre')
         or (previous_member.old_member is not null
             and previous_member.old_member->>'role' is distinct from new_member->>'role')
    )
  ) then
    raise exception 'Only the organization owner can change organization settings';
  end if;
  return new;
end;
$$;

drop trigger if exists protect_organization_settings on public.organizations;
create trigger protect_organization_settings
  before update on public.organizations
  for each row execute function public.protect_organization_settings();

drop policy if exists "Owners can delete organizations" on public.organizations;
create policy "Owners can delete organizations"
  on public.organizations for delete
  using (owner_id = (select auth.uid()));

alter table public.organization_members enable row level security;
alter table public.members enable row level security;
alter table public.tontines enable row level security;
alter table public.tontine_members enable row level security;
alter table public.cotisations enable row level security;
alter table public.cotisation_participants enable row level security;
alter table public.payments enable row level security;
alter table public.campay_transactions enable row level security;

drop policy if exists "Members can view their organization memberships" on public.organization_members;
create policy "Members can view their organization memberships"
  on public.organization_members for select
  using (
    user_id = (select auth.uid())
    or public.is_organization_manager(organization_id)
  );

drop policy if exists "Managers can manage organization memberships" on public.organization_members;
drop policy if exists "Managers can add memberships" on public.organization_members;
create policy "Managers can add memberships"
  on public.organization_members for insert
  with check (
    public.is_organization_manager(organization_id)
    and (
      role = 'Membre'
      or exists (
        select 1 from public.organizations o
        where o.id = organization_id and o.owner_id = (select auth.uid())
      )
    )
  );

drop policy if exists "Managers can remove memberships" on public.organization_members;
create policy "Managers can remove memberships"
  on public.organization_members for delete
  using (
    public.is_organization_manager(organization_id)
    and (
      role = 'Membre'
      or exists (
        select 1 from public.organizations o
        where o.id = organization_id and o.owner_id = (select auth.uid())
      )
    )
  );

drop policy if exists "Owners can update membership roles" on public.organization_members;
create policy "Owners can update membership roles"
  on public.organization_members for update
  using (
    exists (
      select 1 from public.organizations o
      where o.id = organization_id and o.owner_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.organizations o
      where o.id = organization_id and o.owner_id = (select auth.uid())
    )
  );

drop policy if exists "Members can read organization people" on public.members;
create policy "Members can read organization people"
  on public.members for select
  using (
    exists (
      select 1 from public.organizations o
      where o.id = organization_id and o.owner_id = (select auth.uid())
    ) or exists (
      select 1 from public.organization_members om
      where om.organization_id = organization_id and om.user_id = (select auth.uid())
    )
  );

drop policy if exists "Managers can manage organization people" on public.members;
create policy "Managers can manage organization people"
  on public.members for all
  using (public.is_organization_manager(organization_id))
  with check (public.is_organization_manager(organization_id));

drop policy if exists "Members can read organization tontines" on public.tontines;
create policy "Members can read organization tontines"
  on public.tontines for select
  using (
    exists (
      select 1 from public.organizations o
      where o.id = organization_id and o.owner_id = (select auth.uid())
    ) or exists (
      select 1 from public.organization_members om
      where om.organization_id = organization_id and om.user_id = (select auth.uid())
    )
  );

drop policy if exists "Managers can manage organization tontines" on public.tontines;
create policy "Managers can manage organization tontines"
  on public.tontines for all
  using (public.is_organization_manager(organization_id))
  with check (public.is_organization_manager(organization_id));

drop policy if exists "Members can read tontine participants" on public.tontine_members;
create policy "Members can read tontine participants"
  on public.tontine_members for select
  using (
    exists (
      select 1 from public.tontines t
      where t.id = tontine_id
        and (
          exists (select 1 from public.organizations o where o.id = t.organization_id and o.owner_id = (select auth.uid()))
          or exists (select 1 from public.organization_members om where om.organization_id = t.organization_id and om.user_id = (select auth.uid()))
        )
    )
  );

drop policy if exists "Managers can manage tontine participants" on public.tontine_members;
create policy "Managers can manage tontine participants"
  on public.tontine_members for all
  using (
    exists (select 1 from public.tontines t where t.id = tontine_id and public.is_organization_manager(t.organization_id))
  )
  with check (
    exists (select 1 from public.tontines t where t.id = tontine_id and public.is_organization_manager(t.organization_id))
  );

drop policy if exists "Members can read organization cotisations" on public.cotisations;
create policy "Members can read organization cotisations"
  on public.cotisations for select
  using (
    exists (
      select 1 from public.organizations o
      where o.id = organization_id and o.owner_id = (select auth.uid())
    ) or exists (
      select 1 from public.organization_members om
      where om.organization_id = organization_id and om.user_id = (select auth.uid())
    )
  );

drop policy if exists "Managers can manage organization cotisations" on public.cotisations;
create policy "Managers can manage organization cotisations"
  on public.cotisations for all
  using (public.is_organization_manager(organization_id))
  with check (public.is_organization_manager(organization_id));

drop policy if exists "Members can read cotisation participants" on public.cotisation_participants;
create policy "Members can read cotisation participants"
  on public.cotisation_participants for select
  using (
    exists (
      select 1 from public.cotisations c
      where c.id = cotisation_id
        and (
          exists (select 1 from public.organizations o where o.id = c.organization_id and o.owner_id = (select auth.uid()))
          or exists (select 1 from public.organization_members om where om.organization_id = c.organization_id and om.user_id = (select auth.uid()))
        )
    )
  );

drop policy if exists "Managers can manage cotisation participants" on public.cotisation_participants;
create policy "Managers can manage cotisation participants"
  on public.cotisation_participants for all
  using (
    exists (select 1 from public.cotisations c where c.id = cotisation_id and public.is_organization_manager(c.organization_id))
  )
  with check (
    exists (select 1 from public.cotisations c where c.id = cotisation_id and public.is_organization_manager(c.organization_id))
  );

drop policy if exists "Members can read organization payments" on public.payments;
create policy "Members can read organization payments"
  on public.payments for select
  using (
    exists (
      select 1 from public.cotisations c
      join public.organizations o on o.id = c.organization_id
      where c.id = cotisation_id and o.owner_id = (select auth.uid())
    ) or exists (
      select 1 from public.cotisations c
      join public.organization_members om on om.organization_id = c.organization_id
      where c.id = cotisation_id and om.user_id = (select auth.uid())
    )
  );

drop policy if exists "Managers can manage organization payments" on public.payments;
create policy "Managers can manage organization payments"
  on public.payments for all
  using (
    exists (select 1 from public.cotisations c where c.id = cotisation_id and public.is_organization_manager(c.organization_id))
  )
  with check (
    recorded_by = (select auth.uid())
    and exists (select 1 from public.cotisations c where c.id = cotisation_id and public.is_organization_manager(c.organization_id))
  );

drop policy if exists "Members can read Campay transactions" on public.campay_transactions;
create policy "Members can read Campay transactions"
  on public.campay_transactions for select
  using (
    exists (
      select 1 from public.organizations o
      where o.id = organization_id and o.owner_id = (select auth.uid())
    ) or exists (
      select 1 from public.organization_members om
      where om.organization_id = organization_id and om.user_id = (select auth.uid())
    )
  );

create or replace function public.finalize_campay_transaction(
  target_reference text,
  target_status text
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_transaction public.campay_transactions%rowtype;
  v_snapshot jsonb;
  v_cotisation jsonb;
  v_participant jsonb;
  v_cotisation_index bigint;
  v_participant_index bigint;
  v_paid numeric;
  v_expected numeric;
  v_period text;
  v_frequency text;
begin
  if target_status not in ('SUCCESSFUL', 'FAILED', 'CANCELLED') then
    raise exception 'Unsupported Campay status';
  end if;

  select * into v_transaction
  from public.campay_transactions
  where provider_reference = target_reference
     or external_reference = target_reference
  for update;

  if not found then
    raise exception 'Campay transaction not found';
  end if;

  if v_transaction.status = 'SUCCESSFUL' then
    return true;
  end if;

  if target_status <> 'SUCCESSFUL' then
    update public.campay_transactions
    set status = target_status, updated_at = now()
    where id = v_transaction.id;
    return true;
  end if;

  select snapshot into v_snapshot
  from public.organizations
  where id = v_transaction.organization_id
  for update;

  select item, ordinality - 1 into v_cotisation, v_cotisation_index
  from jsonb_array_elements(coalesce(v_snapshot->'cotisations', '[]'::jsonb))
       with ordinality as entries(item, ordinality)
  where item->>'id' = v_transaction.cotisation_id
  limit 1;

  if v_cotisation is null then
    raise exception 'Cotisation missing from organization snapshot';
  end if;

  select item, ordinality - 1 into v_participant, v_participant_index
  from jsonb_array_elements(coalesce(v_cotisation->'participants', '[]'::jsonb))
       with ordinality as entries(item, ordinality)
  where item->'member'->>'id' = v_transaction.member_id
  limit 1;

  if v_participant is null then
    raise exception 'Participant missing from organization snapshot';
  end if;

  v_frequency := coalesce(v_cotisation->>'frequence', 'Mensuelle');
  v_period := case v_frequency
    when 'Journalière' then to_char(timezone('UTC', now()), 'YYYY-MM-DD')
    when 'Hebdomadaire' then to_char(date_trunc('week', timezone('UTC', now())), 'YYYY-MM-DD')
    else to_char(timezone('UTC', now()), 'YYYY-MM')
  end;
  v_expected := coalesce(nullif(v_participant->>'montantAttendu', '')::numeric, 0)
    + coalesce(nullif(v_participant->>'penaliteCumulee', '')::numeric, 0);
  v_paid := case
    when v_participant->>'periodePaiement' = v_period
      then coalesce(nullif(v_participant->>'montantPaye', '')::numeric, 0)
    else 0
  end;
  if v_expected > 0 and v_transaction.amount > v_expected - v_paid + 0.001 then
    raise exception 'Amount exceeds the outstanding contribution for this period';
  end if;
  v_participant := jsonb_set(v_participant, '{montantPaye}', to_jsonb(v_paid + v_transaction.amount), true);
  v_participant := jsonb_set(v_participant, '{periodePaiement}', to_jsonb(v_period), true);
  v_snapshot := jsonb_set(
    v_snapshot,
    array['cotisations', v_cotisation_index::text, 'participants',
          v_participant_index::text],
    v_participant,
    true
  );

  v_snapshot := jsonb_set(
    v_snapshot,
    '{activity_log}',
    coalesce(v_snapshot->'activity_log', '[]'::jsonb) || jsonb_build_array(
      jsonb_build_object(
        'text', v_transaction.member_name || ' a payé ' ||
          trim(to_char(v_transaction.amount, 'FM999999999990.00')) || ' ' ||
          v_transaction.currency || ' sur "' || v_transaction.cotisation_title || '"',
        'date', now(),
        'type', 'payment',
        'isRead', false
      )
    ),
    true
  );

  update public.organizations
  set snapshot = v_snapshot, updated_at = now()
  where id = v_transaction.organization_id;

  update public.campay_transactions
  set status = 'SUCCESSFUL', paid_at = now(), updated_at = now()
  where id = v_transaction.id;

  return true;
end;
$$;

revoke all on function public.finalize_campay_transaction(text, text) from public;
grant execute on function public.finalize_campay_transaction(text, text) to service_role;

create or replace function public.reconcile_historical_campay_payment(
  target_organization_id text,
  target_cotisation_id text,
  target_member_id text,
  target_provider_reference text,
  target_amount numeric
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_snapshot jsonb;
  v_cotisation jsonb;
  v_participant jsonb;
  v_cotisation_index bigint;
  v_participant_index bigint;
  v_paid numeric;
  v_expected numeric;
  v_transaction_id uuid;
  v_user_id uuid := auth.uid();
  v_period text;
  v_frequency text;
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;
  if not public.is_organization_manager(target_organization_id) then
    raise exception 'Only organization managers can reconcile payments';
  end if;
  if length(trim(target_provider_reference)) < 3 or target_amount <= 0 then
    raise exception 'Invalid Campay reference or amount';
  end if;
  if exists (
    select 1 from public.campay_transactions
    where provider_reference = trim(target_provider_reference)
  ) then
    raise exception 'This Campay reference has already been recorded';
  end if;

  select snapshot into v_snapshot
  from public.organizations
  where id = target_organization_id
  for update;
  if v_snapshot is null then
    raise exception 'Organization not found';
  end if;

  select item, ordinality - 1 into v_cotisation, v_cotisation_index
  from jsonb_array_elements(coalesce(v_snapshot->'cotisations', '[]'::jsonb))
       with ordinality as entries(item, ordinality)
  where item->>'id' = target_cotisation_id
  limit 1;
  if v_cotisation is null then
    raise exception 'Cotisation not found';
  end if;

  select item, ordinality - 1 into v_participant, v_participant_index
  from jsonb_array_elements(coalesce(v_cotisation->'participants', '[]'::jsonb))
       with ordinality as entries(item, ordinality)
  where item->'member'->>'id' = target_member_id
  limit 1;
  if v_participant is null then
    raise exception 'Participant not found';
  end if;

  v_frequency := coalesce(v_cotisation->>'frequence', 'Mensuelle');
  v_period := case v_frequency
    when 'Journalière' then to_char(timezone('UTC', now()), 'YYYY-MM-DD')
    when 'Hebdomadaire' then to_char(date_trunc('week', timezone('UTC', now())), 'YYYY-MM-DD')
    else to_char(timezone('UTC', now()), 'YYYY-MM')
  end;
  v_paid := case
    when v_participant->>'periodePaiement' = v_period
      then coalesce(nullif(v_participant->>'montantPaye', '')::numeric, 0)
    else 0
  end;
  v_expected := coalesce(nullif(v_participant->>'montantAttendu', '')::numeric, 0)
    + coalesce(nullif(v_participant->>'penaliteCumulee', '')::numeric, 0);
  if v_expected > 0 and target_amount > v_expected - v_paid + 0.001 then
    raise exception 'Amount exceeds the outstanding contribution';
  end if;

  insert into public.campay_transactions (
    organization_id, organization_name, cotisation_id, cotisation_title,
    member_id, member_name, recorded_by, external_reference,
    provider_reference, amount, currency, status, reconciled_manually,
    paid_at, updated_at
  ) values (
    target_organization_id,
    coalesce(v_snapshot->>'name', target_organization_id),
    target_cotisation_id,
    coalesce(v_cotisation->>'titre', 'Cotisation'),
    target_member_id,
    coalesce(v_participant->'member'->>'name', 'Membre'),
    v_user_id,
    'reconciled-' || gen_random_uuid()::text,
    trim(target_provider_reference),
    target_amount,
    coalesce(v_snapshot->>'currency', 'XAF'),
    'SUCCESSFUL',
    true,
    now(),
    now()
  ) returning id into v_transaction_id;

  v_participant := jsonb_set(v_participant, '{montantPaye}', to_jsonb(v_paid + target_amount), true);
  v_participant := jsonb_set(v_participant, '{periodePaiement}', to_jsonb(v_period), true);
  v_snapshot := jsonb_set(
    v_snapshot,
    array['cotisations', v_cotisation_index::text, 'participants',
          v_participant_index::text],
    v_participant,
    true
  );
  update public.organizations
  set snapshot = v_snapshot, updated_at = now()
  where id = target_organization_id;

  return v_transaction_id;
end;
$$;

revoke all on function public.reconcile_historical_campay_payment(text, text, text, text, numeric) from public;
grant execute on function public.reconcile_historical_campay_payment(text, text, text, text, numeric) to authenticated;

create or replace function public.delete_current_user()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  delete from auth.users where id = auth.uid();
end;
$$;

revoke all on function public.delete_current_user() from public;
grant execute on function public.delete_current_user() to authenticated;