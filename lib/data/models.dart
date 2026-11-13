class Account {
  final String id;
  String name;
  String? phone;
  String? email;
  String password;
  String? ville;
  String? pays;
  String? region;
  String? statutMarital;
  String? lieuResidence;
  final String matricule;
  final DateTime memberSince;
  Member? me; // représentation "moi" en tant que membre dans une organisation

  Account({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    required this.password,
    this.ville,
    this.pays,
    this.region,
    this.statutMarital,
    this.lieuResidence,
    required this.matricule,
    DateTime? memberSince,
  }) : memberSince = memberSince ?? DateTime.now();

  /// Un contact (téléphone ou email) correspond-il à ce compte ?
  bool matchesContact(String contact) {
    final c = contact.trim().toLowerCase();
    return (phone != null && phone!.trim().toLowerCase() == c) ||
        (email != null && email!.trim().toLowerCase() == c);
  }
}

class Member {
  final String id;
  String name;
  String phone;
  String? email;
  String role; // Propriétaire, Administrateur, Membre
  String? matricule;
  String? pays;
  String? statutMarital;
  String? ville;
  String? region;
  String? lieuResidence;
  final DateTime joinedAt;
  final String?
      ownerAccountId; // relie ce membre au compte connecté qui l'a créé ("moi")

  Member({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.role = 'Membre',
    this.matricule,
    this.pays,
    this.statutMarital,
    this.ville,
    this.region,
    this.lieuResidence,
    this.ownerAccountId,
    DateTime? joinedAt,
  }) : joinedAt = joinedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'role': role,
        'matricule': matricule,
        'pays': pays,
        'statutMarital': statutMarital,
        'ville': ville,
        'region': region,
        'lieuResidence': lieuResidence,
        'ownerAccountId': ownerAccountId,
        'joinedAt': joinedAt.toIso8601String(),
      };

  factory Member.fromJson(Map<String, dynamic> json) => Member(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Membre',
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String?,
        role: json['role'] as String? ?? 'Membre',
        matricule: json['matricule'] as String?,
        pays: json['pays'] as String?,
        statutMarital: json['statutMarital'] as String?,
        ville: json['ville'] as String?,
        region: json['region'] as String?,
        lieuResidence: json['lieuResidence'] as String?,
        ownerAccountId: json['ownerAccountId'] as String?,
        joinedAt: DateTime.tryParse(json['joinedAt'] as String? ?? ''),
      );
}

class CotisationParticipant {
  final Member member;
  double montantPaye;
  double montantAttendu;
  String? periodePaiement;
  int ordrePassage;
  int joursPenaliteAppliques;
  double penaliteCumulee;
  CotisationParticipant(
      {required this.member,
      this.montantPaye = 0,
      this.montantAttendu = 0,
      this.periodePaiement,
      this.ordrePassage = 0,
      this.joursPenaliteAppliques = 0,
      this.penaliteCumulee = 0});

  void appliquerPeriode(String periode) {
    if (periodePaiement == null) {
      periodePaiement = periode;
    } else if (periodePaiement != periode) {
      montantPaye = 0;
      periodePaiement = periode;
    }
  }

  String get statut {
    if (montantPaye <= 0) return 'Non payé';
    if (montantTotalAttendu > 0 && montantPaye < montantTotalAttendu) {
      return 'Partiel';
    }
    return 'Payé';
  }

  double get montantTotalAttendu => montantAttendu + penaliteCumulee;
}

class Cotisation {
  final String id;
  String titre;
  String type; // Volontaire / Fixe
  String frequence;
  String visibilite; // Privée / Publique
  DateTime dateFin;
  String? description;
  bool sanctionsAutomatiques;
  double penaliteJournaliere;
  bool payerAvecFrais;
  final List<CotisationParticipant> participants;

  Cotisation({
    required this.id,
    required this.titre,
    this.type = 'Volontaire',
    this.frequence = 'Mensuelle',
    this.visibilite = 'Privée',
    required this.dateFin,
    this.description,
    this.sanctionsAutomatiques = false,
    this.penaliteJournaliere = 0,
    this.payerAvecFrais = false,
    List<CotisationParticipant>? participants,
  }) : participants = participants ?? [];

  static String periodKeyForFrequency(String frequency, [DateTime? at]) {
    final date = (at ?? DateTime.now()).toUtc();
    final day = DateTime.utc(date.year, date.month, date.day);
    switch (frequency) {
      case 'Journalière':
        return '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      case 'Hebdomadaire':
        final monday = day.subtract(Duration(days: day.weekday - 1));
        return '${monday.year.toString().padLeft(4, '0')}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
      default:
        return '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}';
    }
  }

  String currentPeriodKey([DateTime? at]) =>
      periodKeyForFrequency(frequence, at);

  DateTime nextDueDate([DateTime? at]) {
    final now = at ?? DateTime.now();
    var due = dateFin;
    while (!due.isAfter(now)) {
      if (frequence == 'Journalière') {
        due = due.add(const Duration(days: 1));
      } else if (frequence == 'Hebdomadaire') {
        due = due.add(const Duration(days: 7));
      } else {
        final nextMonth = DateTime(due.year, due.month + 1, 1);
        final lastDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
        due = DateTime(
            nextMonth.year, nextMonth.month, due.day.clamp(1, lastDay));
      }
    }
    return due;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'titre': titre,
        'type': type,
        'frequence': frequence,
        'visibilite': visibilite,
        'dateFin': dateFin.toIso8601String(),
        'description': description,
        'sanctionsAutomatiques': sanctionsAutomatiques,
        'penaliteJournaliere': penaliteJournaliere,
        'payerAvecFrais': payerAvecFrais,
        'participants': participants
            .map((participant) => {
                  'member': participant.member.toJson(),
                  'montantPaye': participant.montantPaye,
                  'montantAttendu': participant.montantAttendu,
                  'periodePaiement': participant.periodePaiement,
                  'ordrePassage': participant.ordrePassage,
                  'joursPenaliteAppliques': participant.joursPenaliteAppliques,
                  'penaliteCumulee': participant.penaliteCumulee,
                })
            .toList(),
      };

  factory Cotisation.fromJson(Map<String, dynamic> json) => Cotisation(
        id: json['id'] as String,
        titre: json['titre'] as String? ?? '',
        type: json['type'] as String? ?? 'Volontaire',
        frequence: json['frequence'] as String? ?? 'Mensuelle',
        visibilite: json['visibilite'] as String? ?? 'Privée',
        dateFin: DateTime.tryParse(json['dateFin'] as String? ?? '') ??
            DateTime.now(),
        description: json['description'] as String?,
        sanctionsAutomatiques: json['sanctionsAutomatiques'] as bool? ?? false,
        penaliteJournaliere:
            (json['penaliteJournaliere'] as num?)?.toDouble() ?? 0,
        payerAvecFrais: json['payerAvecFrais'] as bool? ?? false,
        participants:
            (json['participants'] as List<dynamic>? ?? []).map((entry) {
          final data = Map<String, dynamic>.from(entry as Map);
          return CotisationParticipant(
            member: Member.fromJson(
                Map<String, dynamic>.from(data['member'] as Map)),
            montantPaye: (data['montantPaye'] as num?)?.toDouble() ?? 0,
            montantAttendu: (data['montantAttendu'] as num?)?.toDouble() ?? 0,
            periodePaiement: data['periodePaiement'] as String?,
            ordrePassage: data['ordrePassage'] as int? ?? 0,
            joursPenaliteAppliques: data['joursPenaliteAppliques'] as int? ?? 0,
            penaliteCumulee: (data['penaliteCumulee'] as num?)?.toDouble() ?? 0,
          );
        }).toList(),
      );

  /// Total réellement collecté = somme de ce que chaque participant a payé.
  double get collecte {
    final currentPeriod = currentPeriodKey();
    return participants.fold(0.0, (sum, participant) {
      if (participant.periodePaiement != null &&
          participant.periodePaiement != currentPeriod) {
        return sum;
      }
      return sum + participant.montantPaye;
    });
  }
}

class Tontine {
  final String id;
  String libelle;
  String? description;
  double montantBase;
  final List<Member> membres;
  final List<Member> beneficiaires;

  Tontine({
    required this.id,
    required this.libelle,
    this.description,
    this.montantBase = 0,
    List<Member>? membres,
    List<Member>? beneficiaires,
  })  : membres = membres ?? [],
        beneficiaires = beneficiaires ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'libelle': libelle,
        'description': description,
        'montantBase': montantBase,
        'membres': membres.map((member) => member.toJson()).toList(),
        'beneficiaires':
            beneficiaires.map((member) => member.toJson()).toList(),
      };

  factory Tontine.fromJson(Map<String, dynamic> json) => Tontine(
        id: json['id'] as String,
        libelle: json['libelle'] as String? ?? '',
        description: json['description'] as String?,
        montantBase: (json['montantBase'] as num?)?.toDouble() ?? 0,
        membres: (json['membres'] as List<dynamic>? ?? [])
            .map((member) =>
                Member.fromJson(Map<String, dynamic>.from(member as Map)))
            .toList(),
        beneficiaires: (json['beneficiaires'] as List<dynamic>? ?? [])
            .map((member) =>
                Member.fromJson(Map<String, dynamic>.from(member as Map)))
            .toList(),
      );
}

class InviteLink {
  final String id;
  final String url;
  int expirationJours;
  int? maxAdhesions;
  String role;
  String? message;
  bool actif;
  final DateTime createdAt;

  InviteLink({
    required this.id,
    required this.url,
    this.expirationJours = 30,
    this.maxAdhesions,
    this.role = 'Membre',
    this.message,
    this.actif = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class WalletManager {
  final Member member;
  String role; // Administrateur / Propriétaire légal
  WalletManager({required this.member, this.role = 'Administrateur'});
}

class Compte {
  final String nom; // Courant, Fond de caisse, Projet, Sanction, Épargnes
  double solde;
  Compte({required this.nom, this.solde = 0});
}

class ActivityEntry {
  final String text;
  final DateTime date;
  final String type;
  bool isRead;

  ActivityEntry({
    required this.text,
    required this.date,
    this.type = 'general',
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'date': date.toIso8601String(),
        'type': type,
        'isRead': isRead,
      };

  factory ActivityEntry.fromJson(Map<String, dynamic> json) => ActivityEntry(
        text: json['text'] as String? ?? '',
        date:
            DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        type: json['type'] as String? ?? 'general',
        isRead: json['isRead'] as bool? ?? false,
      );
}

class Organization {
  final String id;
  String? joinCode;
  String? ownerId;
  String currentUserRole;
  String name;
  String? acronym;
  String? referralCode;
  String? description;
  String currency;
  bool fondDeCaisseActif;
  double? fondDeCaisseMontant;
  bool paiementEnLigne;
  bool payerAvecFrais;
  bool pretsEpargneActif;
  final List<Member> membres;
  final List<Cotisation> cotisations;
  final List<Tontine> tontines;
  final List<InviteLink> inviteLinks;
  final List<WalletManager> walletManagers;
  final List<Compte> comptes;
  final List<ActivityEntry> activityLog = [];

  Organization({
    required this.id,
    required this.name,
    this.joinCode,
    this.ownerId,
    this.currentUserRole = 'Propriétaire',
    this.acronym,
    this.referralCode,
    this.description,
    this.currency = 'XAF',
    this.fondDeCaisseActif = false,
    this.fondDeCaisseMontant,
    this.paiementEnLigne = false,
    this.payerAvecFrais = false,
    this.pretsEpargneActif = false,
    List<Member>? membres,
    List<Cotisation>? cotisations,
    List<Tontine>? tontines,
    List<InviteLink>? inviteLinks,
    List<WalletManager>? walletManagers,
    List<Compte>? comptes,
  })  : membres = membres ?? [],
        cotisations = cotisations ?? [],
        tontines = tontines ?? [],
        inviteLinks = inviteLinks ?? [],
        walletManagers = walletManagers ?? [],
        comptes = comptes ??
            [
              Compte(nom: 'Courant'),
              Compte(nom: 'Fond de caisse'),
              Compte(nom: 'Projet'),
              Compte(nom: 'Sanction'),
              Compte(nom: 'Épargnes'),
            ];

  Map<String, dynamic> toJson() => {
        'id': id,
        'join_code': joinCode,
        'owner_id': ownerId,
        'name': name,
        'acronym': acronym,
        'referral_code': referralCode,
        'description': description,
        'currency': currency,
        'fond_de_caisse_actif': fondDeCaisseActif,
        'fond_de_caisse_montant': fondDeCaisseMontant,
        'paiement_en_ligne': paiementEnLigne,
        'payer_avec_frais': payerAvecFrais,
        'prets_epargne_actif': pretsEpargneActif,
        'current_user_role': currentUserRole,
        'members': membres.map((member) => member.toJson()).toList(),
        'cotisations': cotisations.map((item) => item.toJson()).toList(),
        'tontines': tontines.map((item) => item.toJson()).toList(),
        'invite_links': inviteLinks
            .map((item) => {
                  'id': item.id,
                  'url': item.url,
                  'expirationJours': item.expirationJours,
                  'maxAdhesions': item.maxAdhesions,
                  'role': item.role,
                  'message': item.message,
                  'actif': item.actif,
                  'createdAt': item.createdAt.toIso8601String(),
                })
            .toList(),
        'wallet_managers': walletManagers
            .map((manager) => {
                  'member': manager.member.toJson(),
                  'role': manager.role,
                })
            .toList(),
        'comptes': comptes
            .map((compte) => {'nom': compte.nom, 'solde': compte.solde})
            .toList(),
        'activity_log': activityLog.map((entry) => entry.toJson()).toList(),
      };

  factory Organization.fromJson(Map<String, dynamic> json) {
    final organization = Organization(
      id: json['id'] as String,
      joinCode: json['join_code'] as String?,
      ownerId: json['owner_id'] as String?,
      currentUserRole: json['current_user_role'] as String? ?? 'Membre',
      name: json['name'] as String? ?? '',
      acronym: json['acronym'] as String?,
      referralCode: json['referral_code'] as String?,
      description: json['description'] as String?,
      currency: json['currency'] as String? ?? 'XAF',
      fondDeCaisseActif: json['fond_de_caisse_actif'] as bool? ?? false,
      fondDeCaisseMontant: (json['fond_de_caisse_montant'] as num?)?.toDouble(),
      paiementEnLigne: json['paiement_en_ligne'] as bool? ?? false,
      payerAvecFrais: json['payer_avec_frais'] as bool? ?? false,
      pretsEpargneActif: json['prets_epargne_actif'] as bool? ?? false,
      membres: (json['members'] as List<dynamic>? ?? [])
          .map((member) =>
              Member.fromJson(Map<String, dynamic>.from(member as Map)))
          .toList(),
      cotisations: (json['cotisations'] as List<dynamic>? ?? [])
          .map((item) =>
              Cotisation.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      tontines: (json['tontines'] as List<dynamic>? ?? [])
          .map((item) =>
              Tontine.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      comptes: (json['comptes'] as List<dynamic>? ?? []).map((item) {
        final data = Map<String, dynamic>.from(item as Map);
        return Compte(
          nom: data['nom'] as String? ?? '',
          solde: (data['solde'] as num?)?.toDouble() ?? 0,
        );
      }).toList(),
    );
    organization.inviteLinks.addAll(
      (json['invite_links'] as List<dynamic>? ?? []).map((item) {
        final data = Map<String, dynamic>.from(item as Map);
        return InviteLink(
          id: data['id'] as String,
          url: data['url'] as String? ?? '',
          expirationJours: data['expirationJours'] as int? ?? 30,
          maxAdhesions: data['maxAdhesions'] as int?,
          role: data['role'] as String? ?? 'Membre',
          message: data['message'] as String?,
          actif: data['actif'] as bool? ?? true,
          createdAt: DateTime.tryParse(data['createdAt'] as String? ?? ''),
        );
      }),
    );
    organization.walletManagers.addAll(
      (json['wallet_managers'] as List<dynamic>? ?? []).map((item) {
        final data = Map<String, dynamic>.from(item as Map);
        return WalletManager(
          member:
              Member.fromJson(Map<String, dynamic>.from(data['member'] as Map)),
          role: data['role'] as String? ?? 'Administrateur',
        );
      }),
    );
    organization.activityLog.addAll(
      (json['activity_log'] as List<dynamic>? ?? []).map(
        (entry) => ActivityEntry.fromJson(
          Map<String, dynamic>.from(entry as Map),
        ),
      ),
    );
    return organization;
  }

  String get inviteUrl =>
      'https://nova.app/join/${id.length > 8 ? id.substring(0, 8) : id}';

  // --- Statistiques dérivées (calculées à la volée, jamais stockées) ---
  double get totalCollecte =>
      cotisations.fold(0.0, (sum, c) => sum + c.collecte);
  int get obligationsCount => cotisations.length + tontines.length;
  double get soldeTotalComptes => comptes.fold(0.0, (sum, c) => sum + c.solde);
}
