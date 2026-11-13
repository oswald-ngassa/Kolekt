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