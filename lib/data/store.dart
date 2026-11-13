import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';
import '../services/organization_service.dart';

enum AppLanguage { fr, en }

/// Simule l'état applicatif normalement géré par le backend.
/// Aucune persistance réelle : tout est perdu au rechargement de la page,
/// mais PENDANT la session, tous les comptes créés restent en mémoire dans
/// [accounts] — se déconnecter ne les efface plus (seul "Delete my account" le fait).
class AppStore extends ChangeNotifier {
  AppStore._();
  static final AppStore instance = AppStore._();

  final List<Account> accounts = [];
  Account? currentAccount;

  final List<Organization> organizations = [];
  Organization? activeOrg;
  final _organizationService = OrganizationService();

  // Préférences d'affichage : globales, appliquées immédiatement à toute l'app.
  ThemeMode themeMode = ThemeMode.dark;
  AppLanguage language = AppLanguage.fr;

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    notifyListeners();
  }

  void setLanguage(AppLanguage lang) {
    language = lang;
    notifyListeners();
  }

  int _idCounter = 0;
  String nextId() =>
      'id_${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';

  // --- Raccourcis de lecture vers le compte actuellement connecté ---
  String? get userName => currentAccount?.name;
  String? get userPhone => currentAccount?.phone;
  String? get userEmail => currentAccount?.email;
  String? get userVille => currentAccount?.ville;
  String? get userPays => currentAccount?.pays;
  String? get userRegion => currentAccount?.region;
  String? get userStatutMarital => currentAccount?.statutMarital;
  String? get userLieuResidence => currentAccount?.lieuResidence;
  String? get userMatricule => currentAccount?.matricule;
  DateTime? get memberSince => currentAccount?.memberSince;
  Member? get me => currentAccount?.me;
  bool get isLoggedIn => currentAccount != null;

  bool isOrganizationOwner(Organization org) {
    final userId = currentAccount?.id;
    if (userId != null && org.ownerId == userId) return true;
    return org.currentUserRole.toLowerCase().contains('propriétaire');
  }

  bool canManageOrganization(Organization org) {
    final role = org.currentUserRole.toLowerCase();
    return isOrganizationOwner(org) || role.contains('administrateur');
  }

  void requireOrganizationManager(Organization org) {
    if (!canManageOrganization(org)) {
      throw StateError(
          'Seuls le propriétaire et les administrateurs peuvent effectuer cette action.');
    }
  }

  void requireOrganizationOwner(Organization org) {
    if (!isOrganizationOwner(org)) {
      throw StateError(
          'Seul le propriétaire de l’association peut modifier ses paramètres.');
    }
  }

  Future<void> loadOrganizations() async {
    _organizationService.watchOrganizations(loadOrganizations);
    final activeOrgId = activeOrg?.id;
    final loaded = await _organizationService.loadMine();
    organizations
      ..clear()
      ..addAll(loaded);
    activeOrg = loaded.where((org) => org.id == activeOrgId).firstOrNull ??
        (loaded.isEmpty ? null : loaded.first);
    notifyListeners();
    for (final org in loaded) {
      for (final cotisation in org.cotisations) {
        await applyCotisationPenalties(org, cotisation, DateTime.now());
      }
    }
  }

  Future<void> _persistOrganization(Organization organization) async {
    try {
      await _organizationService.save(organization);
    } on AssertionError catch (error) {
      debugPrint(
          'Persistance organisation ignorée (Supabase non initialisé): $error');
    } on AuthException catch (error) {
      debugPrint(
          'Persistance organisation ignorée (auth non disponible): $error');
    } on Exception catch (error) {
      debugPrint('Persistance organisation impossible: $error');
    }
  }

  Future<void> persistOrganization(Organization organization) =>
      _persistOrganization(organization);

  Future<void> deleteOrganization(Organization organization) async {
    await _organizationService.deleteOrganization(organization.id);
    organizations.removeWhere((item) => item.id == organization.id);
    if (activeOrg?.id == organization.id) {
      activeOrg = organizations.firstOrNull;
    }
    notifyListeners();
  }

  Future<void> leaveOrganization(Organization organization) async {
    await _organizationService.leaveOrganization(organization.id);
    organizations.removeWhere((item) => item.id == organization.id);
    if (activeOrg?.id == organization.id) {
      activeOrg = organizations.firstOrNull;
    }
    notifyListeners();
  }

  Future<void> joinOrganizationByCode(String code) async {
    final organizationId = await _organizationService.joinByCode(code);
    await loadOrganizations();
    activeOrg = organizations
        .where((organization) => organization.id == organizationId)
        .firstOrNull;
    notifyListeners();
  }

  void syncSupabaseUser(User user, {Map<String, dynamic>? profile}) {
    final data = profile ?? user.userMetadata ?? const <String, dynamic>{};
    final existing =
        accounts.where((account) => account.id == user.id).firstOrNull;
    final account = existing ??
        Account(
          id: user.id,
          name: (data['name'] as String?) ?? 'Utilisateur',
          phone: (data['phone'] as String?) ?? user.phone,
          email: (data['email'] as String?) ?? user.email,
          password: '',
          matricule:
              'NV-${DateTime.now().year}-${user.id.substring(0, user.id.length > 4 ? 4 : user.id.length)}',
        );
    account.name = (data['name'] as String?) ?? account.name;
    account.phone = (data['phone'] as String?) ?? account.phone;
    account.email = (data['email'] as String?) ?? account.email;
    account.ville = data['ville'] as String?;
    account.pays = data['pays'] as String?;
    account.region = data['region'] as String?;
    account.statutMarital = data['statutMarital'] as String?;
    account.lieuResidence = data['lieuResidence'] as String?;
    if (existing == null) accounts.add(account);
    currentAccount = account;
    notifyListeners();
  }

  /// Retrouve "moi" au sein d'une organisation précise (contrairement à [me],
  /// qui ne pointait que vers la dernière organisation créée).
  Member? myMemberIn(Organization org) {
    final accId = currentAccount?.id;
    if (accId == null) return null;
    for (final m in org.membres) {
      if (m.ownerAccountId == accId) return m;
    }
    if (org.ownerId == accId) {
      for (final member in org.membres) {
        if (member.role.toLowerCase() == 'propriétaire') return member;
      }
    }
    return null;
  }

  /// Inscription : vérifie que le téléphone/email n'est pas déjà utilisé par
  /// un autre compte de la session. Retourne un message d'erreur si ça
  /// échoue, ou null si le compte a bien été créé (et connecté).
  String? signUp({
    required String name,
    String? phone,
    String? email,
    required String password,
    String? ville,
    String? pays,
    String? region,
    String? statutMarital,
    String? lieuResidence,
  }) {
    final contact = (phone?.isNotEmpty == true ? phone : email) ?? '';
    if (contact.isEmpty) return 'Un numéro ou un email est requis.';

    final exists = accounts.any((a) => a.matchesContact(contact));
    if (exists) {
      return 'Ce ${phone?.isNotEmpty == true ? 'numéro' : 'email'} est déjà utilisé par un autre compte.';
    }

    final account = Account(
      id: nextId(),
      name: name,
      phone: (phone?.isNotEmpty ?? false) ? phone : null,
      email: (email?.isNotEmpty ?? false) ? email : null,
      password: password,
      ville: (ville?.isNotEmpty ?? false) ? ville : null,
      pays: (pays?.isNotEmpty ?? false) ? pays : null,
      region: (region?.isNotEmpty ?? false) ? region : null,
      statutMarital: statutMarital,
      lieuResidence:
          (lieuResidence?.isNotEmpty ?? false) ? lieuResidence : null,
      matricule:
          'NV-${DateTime.now().year}-${nextId().replaceAll('id_', '').padLeft(4, '0')}',
    );
    accounts.add(account);
    currentAccount = account;
    notifyListeners();
    return null;
  }

  /// Connexion : cherche un compte correspondant au contact + mot de passe.
  /// Retourne un message d'erreur si échec, ou null si connecté avec succès.
  String? login({required String contact, required String password}) {
    if (accounts.isEmpty) {
      return "Aucun compte trouvé. Créez d'abord un compte.";
    }
    Account? account;
    for (final a in accounts) {
      if (a.matchesContact(contact)) {
        account = a;
        break;
      }
    }
    if (account == null) {
      return "Aucun compte trouvé pour ce contact.";
    }
    if (account.password != password) {
      return 'Mot de passe incorrect.';
    }
    currentAccount = account;
    notifyListeners();
    return null;
  }

  /// Déconnexion : ferme juste la session en cours, garde le compte en mémoire.
  void logout() {
    _organizationService.stopWatchingOrganizations();
    currentAccount = null;
    activeOrg = null;
    organizations.clear();
    accounts.clear();
    notifyListeners();
  }

  /// Supprime définitivement le compte connecté (contrairement à logout()).
  void deleteCurrentAccount() {
    if (currentAccount != null) accounts.remove(currentAccount);
    currentAccount = null;
    activeOrg = null;
    notifyListeners();
  }

  Future<void> deleteSupabaseAccount() async {
    await _organizationService.deleteCurrentAccount();
    deleteCurrentAccount();
  }

  /// Mise à jour du profil du compte déjà connecté (écran "Modifier le profil",
  /// "Ajouter un email"...). Ne fait rien si personne n'est connecté.
  void updateProfile({
    String? name,
    String? phone,
    String? email,
    String? ville,
    String? pays,
    String? region,
    String? statutMarital,
    String? lieuResidence,
  }) {
    final acc = currentAccount;
    if (acc == null) return;
    if (name != null && name.isNotEmpty) acc.name = name;
    if (phone != null && phone.isNotEmpty) acc.phone = phone;
    if (email != null && email.isNotEmpty) acc.email = email;
    if (ville != null) acc.ville = ville.isEmpty ? null : ville;
    if (pays != null) acc.pays = pays.isEmpty ? null : pays;
    if (region != null) acc.region = region.isEmpty ? null : region;
    if (statutMarital != null) acc.statutMarital = statutMarital;
    if (lieuResidence != null) {
      acc.lieuResidence = lieuResidence.isEmpty ? null : lieuResidence;
    }
    // Garde "moi" synchronisé dans TOUTES les organisations (avant, un seul
    // pointeur "me" ne suivait que la dernière organisation créée).
    for (final org in organizations) {
      final idx = org.membres.indexWhere((m) => m.ownerAccountId == acc.id);
      if (idx != -1) {
        org.membres[idx].name = acc.name;
        org.membres[idx].phone = acc.phone ?? org.membres[idx].phone;
        org.membres[idx].email = acc.email;
        org.membres[idx].ville = acc.ville;
        org.membres[idx].pays = acc.pays;
        org.membres[idx].region = acc.region;
        org.membres[idx].statutMarital = acc.statutMarital;
        org.membres[idx].lieuResidence = acc.lieuResidence;
      }
    }
    notifyListeners();
  }

  Future<Organization> createOrganization({
    required String name,
    String? acronym,
    String? referralCode,
    String? description,
    String currency = 'XAF',
  }) async {
    final org = Organization(
      id: nextId(),
      ownerId: currentAccount?.id,
      currentUserRole: 'Propriétaire / Administrateur',
      name: name,
      acronym: acronym,
      referralCode: referralCode,
      description: description,
      currency: currency,
    );
    final acc = currentAccount;
    final meMember = Member(
      id: nextId(),
      name: acc?.name ?? 'Moi',
      phone: acc?.phone ?? '',
      email: acc?.email,
      role: 'Propriétaire',
      matricule: acc?.matricule,
      pays: acc?.pays,
      region: acc?.region,
      ville: acc?.ville,
      statutMarital: acc?.statutMarital,
      lieuResidence: acc?.lieuResidence,
      joinedAt: acc?.memberSince,
      ownerAccountId: acc?.id,
    );
    acc?.me = meMember;
    org.membres.add(meMember);
    organizations.add(org);
    activeOrg = org;
    notifyListeners();
    await _persistOrganization(org);
    return org;
  }

  Future<void> setActiveOrg(Organization org) async {
    activeOrg = org;
    notifyListeners();
    await _persistOrganization(org);
  }

  Future<void> addCotisation(Organization org, Cotisation c) async {
    requireOrganizationManager(org);
    org.cotisations.add(c);
    _logActivity(org, 'Cotisation "${c.titre}" créée');
    notifyListeners();
    try {
      await _persistOrganization(org);
    } catch (_) {
      org.cotisations.remove(c);
      org.activityLog.removeWhere(
          (entry) => entry.text == 'Cotisation "${c.titre}" créée');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> syncCotisationPeriods(
      Organization org, Cotisation cotisation) async {
    final currentPeriod = cotisation.currentPeriodKey();
    var changed = false;
    for (final participant in cotisation.participants) {
      final previousPeriod = participant.periodePaiement;
      final previousPaid = participant.montantPaye;
      participant.appliquerPeriode(currentPeriod);
      changed = changed ||
          previousPeriod != participant.periodePaiement ||
          previousPaid != participant.montantPaye;
    }
    if (changed) await _persistOrganization(org);
  }

  Future<void> addCotisationParticipant(
      Organization org, Cotisation cotisation, Member member) async {
    requireOrganizationManager(org);
    if (cotisation.participants.any((item) => item.member.id == member.id)) {
      return;
    }
    cotisation.participants.add(CotisationParticipant(
      member: member,
      montantAttendu: cotisation.participants.isEmpty
          ? 0
          : cotisation.participants.first.montantAttendu,
      ordrePassage: cotisation.participants.length + 1,
    ));
    _logActivity(org, '${member.name} a été ajouté(e) à "${cotisation.titre}"',
        type: 'member');
    notifyListeners();
    await _persistOrganization(org);
  }

  Future<void> reorderCotisationParticipants(Organization org,
      Cotisation cotisation, int oldIndex, int newIndex) async {
    requireOrganizationManager(org);
    if (newIndex > oldIndex) newIndex--;
    final participant = cotisation.participants.removeAt(oldIndex);
    cotisation.participants.insert(newIndex, participant);
    for (var index = 0; index < cotisation.participants.length; index++) {
      cotisation.participants[index].ordrePassage = index + 1;
    }
    notifyListeners();
    await _persistOrganization(org);
  }

  Future<void> configureCotisationPenalty(
      Organization org, Cotisation cotisation, double dailyAmount) async {
    requireOrganizationManager(org);
    cotisation.penaliteJournaliere = dailyAmount;
    cotisation.sanctionsAutomatiques = dailyAmount > 0;
    notifyListeners();
    await _persistOrganization(org);
  }

  Future<void> applyCotisationPenalties(
      Organization org, Cotisation cotisation, DateTime now) async {
    if (!cotisation.sanctionsAutomatiques ||
        cotisation.penaliteJournaliere <= 0) {
      return;
    }
    var changed = false;
    for (final participant in cotisation.participants) {
      if (participant.montantAttendu <= 0 || !now.isAfter(cotisation.dateFin)) {
        continue;
      }
      while (participant.montantPaye <
              participant.montantAttendu + participant.penaliteCumulee &&
          now.isAfter(_deadlineFor(
              cotisation, participant.joursPenaliteAppliques + 1))) {
        participant.joursPenaliteAppliques++;
        final penalty = cotisation.penaliteJournaliere;
        participant.penaliteCumulee += penalty;
        _logActivity(
          org,
          'Pénalité de ${penalty.toStringAsFixed(0)} ${org.currency} pour ${participant.member.name} (jour ${participant.joursPenaliteAppliques} de retard sur "${cotisation.titre}")',
          type: 'sanction',
        );
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
      await _persistOrganization(org);
    }
  }

  DateTime _deadlineFor(Cotisation cotisation, int lateDay) {
    return cotisation.dateFin.add(Duration(days: lateDay - 1));
  }

  Future<void> addTontine(Organization org, Tontine t) async {
    requireOrganizationManager(org);
    org.tontines.add(t);
    _logActivity(org, 'Tontine "${t.libelle}" créée');
    notifyListeners();
    try {
      await _persistOrganization(org);
    } catch (_) {
      org.tontines.remove(t);
      org.activityLog
          .removeWhere((entry) => entry.text == 'Tontine "${t.libelle}" créée');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addTontineMember(
      Organization org, Tontine tontine, Member member) async {
    requireOrganizationManager(org);
    if (tontine.membres.any((item) => item.id == member.id)) return;
    tontine.membres.add(member);
    notifyListeners();
    await _persistOrganization(org);
  }

  Future<void> removeTontineMember(
      Organization org, Tontine tontine, Member member) async {
    requireOrganizationManager(org);
    tontine.membres.removeWhere((item) => item.id == member.id);
    tontine.beneficiaires.removeWhere((item) => item.id == member.id);
    notifyListeners();
    await _persistOrganization(org);
  }

  Future<void> addMember(Organization org, Member m) async {
    requireOrganizationManager(org);
    if (!isOrganizationOwner(org) && m.role != 'Membre') {
      throw StateError(
          'Seul le propriétaire peut attribuer un rôle administrateur.');
    }
    org.membres.add(m);
    _logActivity(org, '${m.name} a rejoint le groupe', type: 'member');
    notifyListeners();
    await _persistOrganization(org);
  }

  Future<void> addSanction(
      Organization org, String memberName, String details) async {
    requireOrganizationManager(org);
    _logActivity(org, 'Sanction pour $memberName : $details', type: 'sanction');
    notifyListeners();
    await _persistOrganization(org);
  }

  Future<void> addInviteLink(Organization org, InviteLink l) async {
    requireOrganizationOwner(org);
    org.inviteLinks.add(l);
    notifyListeners();
    await _persistOrganization(org);
  }

  Future<void> addWalletManager(Organization org, WalletManager w) async {
    requireOrganizationOwner(org);
    org.walletManagers.add(w);
    notifyListeners();
    await _persistOrganization(org);
  }

  Future<void> recordPayment(
    Organization org,
    String memberName,
    double amount,
    String cotisationTitre, {
    String status = 'paid',
  }) async {
    final normalizedStatus = status.toLowerCase();
    final message = normalizedStatus == 'pending'
        ? '$memberName a un paiement en attente de ${amount.toStringAsFixed(0)} ${org.currency} sur "$cotisationTitre"'
        : '$memberName a payé ${amount.toStringAsFixed(0)} ${org.currency} sur "$cotisationTitre"';

    _logActivity(org, message, type: 'payment');
    notifyListeners();
    await _persistOrganization(org);
  }

  int unreadNotificationCount(Organization org) => org.activityLog
      .where((entry) => entry.type != 'general' && !entry.isRead)
      .length;

  Future<void> markNotificationsRead(Organization org) async {
    for (final entry
        in org.activityLog.where((entry) => entry.type != 'general')) {
      entry.isRead = true;
    }
    notifyListeners();
    await _persistOrganization(org);
  }

  void _logActivity(Organization org, String text, {String type = 'general'}) {
    org.activityLog.insert(
      0,
      ActivityEntry(text: text, date: DateTime.now(), type: type),
    );
    if (org.activityLog.length > 20) org.activityLog.removeLast();
  }
}
