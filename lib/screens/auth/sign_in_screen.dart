import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/store.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';

const _africanCountries = <String, String>{
  'DZ': 'Algérie',
  'AO': 'Angola',
  'BJ': 'Bénin',
  'BW': 'Botswana',
  'BF': 'Burkina Faso',
  'BI': 'Burundi',
  'CV': 'Cap-Vert',
  'CM': 'Cameroun',
  'CF': 'République centrafricaine',
  'KM': 'Comores',
  'CG': 'République du Congo',
  'CD': 'République démocratique du Congo',
  'CI': 'Côte d’Ivoire',
  'DJ': 'Djibouti',
  'EG': 'Égypte',
  'GQ': 'Guinée équatoriale',
  'ER': 'Érythrée',
  'SZ': 'Eswatini',
  'ET': 'Éthiopie',
  'GA': 'Gabon',
  'GM': 'Gambie',
  'GH': 'Ghana',
  'GN': 'Guinée',
  'GW': 'Guinée-Bissau',
  'KE': 'Kenya',
  'LS': 'Lesotho',
  'LR': 'Libéria',
  'LY': 'Libye',
  'MG': 'Madagascar',
  'MW': 'Malawi',
  'ML': 'Mali',
  'MR': 'Mauritanie',
  'MU': 'Maurice',
  'MA': 'Maroc',
  'MZ': 'Mozambique',
  'NA': 'Namibie',
  'NE': 'Niger',
  'NG': 'Nigéria',
  'UG': 'Ouganda',
  'RW': 'Rwanda',
  'ST': 'Sao Tomé-et-Principe',
  'SN': 'Sénégal',
  'SC': 'Seychelles',
  'SL': 'Sierra Leone',
  'SO': 'Somalie',
  'ZA': 'Afrique du Sud',
  'SS': 'Soudan du Sud',
  'SD': 'Soudan',
  'TZ': 'Tanzanie',
  'TG': 'Togo',
  'TN': 'Tunisie',
  'ZM': 'Zambie',
  'ZW': 'Zimbabwe',
};

const _africanCities = <String, List<String>>{
  'DZ': ['Alger', 'Oran', 'Constantine', 'Annaba', 'Blida'],
  'AO': ['Luanda', 'Huambo', 'Lobito', 'Benguela', 'Lubango'],
  'BJ': ['Cotonou', 'Porto-Novo', 'Parakou', 'Abomey-Calavi'],
  'BW': ['Gaborone', 'Francistown', 'Maun', 'Molepolole'],
  'BF': ['Ouagadougou', 'Bobo-Dioulasso', 'Koudougou', 'Banfora'],
  'BI': ['Bujumbura', 'Gitega', 'Ngozi', 'Ruyigi'],
  'CV': ['Praia', 'Mindelo', 'Santa Maria', 'Assomada'],
  'CM': ['Yaoundé', 'Douala', 'Garoua', 'Bafoussam', 'Bamenda', 'Maroua'],
  'CF': ['Bangui', 'Bimbo', 'Berbérati', 'Carnot'],
  'KM': ['Moroni', 'Mutsamudu', 'Fomboni'],
  'CG': ['Brazzaville', 'Pointe-Noire', 'Dolisie', 'Nkayi'],
  'CD': ['Kinshasa', 'Lubumbashi', 'Mbuji-Mayi', 'Goma', 'Kisangani'],
  'CI': ['Abidjan', 'Yamoussoukro', 'Bouaké', 'Daloa', 'San-Pédro'],
  'DJ': ['Djibouti', 'Ali Sabieh', 'Tadjourah', 'Obock'],
  'EG': ['Le Caire', 'Alexandrie', 'Gizeh', 'Louxor', 'Assouan'],
  'GQ': ['Malabo', 'Bata', 'Ebebiyín', 'Mongomo'],
  'ER': ['Asmara', 'Keren', 'Massawa', 'Assab'],
  'SZ': ['Mbabane', 'Manzini', 'Lobamba', 'Siteki'],
  'ET': ['Addis-Abeba', 'Dire Dawa', 'Mekele', 'Gondar', 'Hawassa'],
  'GA': ['Libreville', 'Port-Gentil', 'Franceville', 'Oyem'],
  'GM': ['Banjul', 'Serekunda', 'Brikama', 'Bakau'],
  'GH': ['Accra', 'Kumasi', 'Tamale', 'Takoradi', 'Cape Coast'],
  'GN': ['Conakry', 'Nzérékoré', 'Kindia', 'Kankan', 'Labé'],
  'GW': ['Bissau', 'Bafatá', 'Gabú', 'Cacheu'],
  'KE': ['Nairobi', 'Mombasa', 'Kisumu', 'Nakuru', 'Eldoret'],
  'LS': ['Maseru', 'Teyateyaneng', 'Mafeteng', 'Hlotse'],
  'LR': ['Monrovia', 'Gbarnga', 'Buchanan', 'Kakata'],
  'LY': ['Tripoli', 'Benghazi', 'Misrata', 'Sabha', 'Tobrouk'],
  'MG': ['Antananarivo', 'Toamasina', 'Antsirabe', 'Mahajanga'],
  'MW': ['Lilongwe', 'Blantyre', 'Mzuzu', 'Zomba'],
  'ML': ['Bamako', 'Sikasso', 'Ségou', 'Mopti', 'Kayes'],
  'MR': ['Nouakchott', 'Nouadhibou', 'Rosso', 'Atar'],
  'MU': ['Port-Louis', 'Beau-Bassin', 'Curepipe', 'Quatre Bornes'],
  'MA': ['Rabat', 'Casablanca', 'Marrakech', 'Fès', 'Tanger'],
  'MZ': ['Maputo', 'Matola', 'Beira', 'Nampula', 'Quelimane'],
  'NA': ['Windhoek', 'Walvis Bay', 'Swakopmund', 'Oshakati'],
  'NE': ['Niamey', 'Zinder', 'Maradi', 'Agadez'],
  'NG': ['Abuja', 'Lagos', 'Kano', 'Ibadan', 'Port Harcourt'],
  'UG': ['Kampala', 'Entebbe', 'Gulu', 'Jinja', 'Mbarara'],
  'RW': ['Kigali', 'Butare', 'Gisenyi', 'Musanze'],
  'ST': ['São Tomé', 'Santo António', 'Neves'],
  'SN': ['Dakar', 'Thiès', 'Saint-Louis', 'Ziguinchor', 'Touba'],
  'SC': ['Victoria', 'Anse Boileau', 'Beau Vallon'],
  'SL': ['Freetown', 'Bo', 'Kenema', 'Makeni'],
  'SO': ['Mogadiscio', 'Hargeisa', 'Kismayo', 'Bosaso'],
  'ZA': ['Pretoria', 'Johannesbourg', 'Le Cap', 'Durban', 'Gqeberha'],
  'SS': ['Djouba', 'Wau', 'Malakal', 'Yei'],
  'SD': ['Khartoum', 'Omdourman', 'Port-Soudan', 'Kassala'],
  'TZ': ['Dodoma', 'Dar es Salaam', 'Arusha', 'Mwanza', 'Zanzibar'],
  'TG': ['Lomé', 'Sokodé', 'Kara', 'Kpalimé'],
  'TN': ['Tunis', 'Sfax', 'Sousse', 'Kairouan', 'Bizerte'],
  'ZM': ['Lusaka', 'Kitwe', 'Ndola', 'Livingstone'],
  'ZW': ['Harare', 'Bulawayo', 'Mutare', 'Gweru'],
};

class SignInScreen extends StatefulWidget {
  final bool isSignUp;

  const SignInScreen({super.key, this.isSignUp = false});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _villeController = TextEditingController();
  final _regionController = TextEditingController();
  final _lieuController = TextEditingController();
  final _authService = AuthService();
  final _userService = UserService();

  String _statutMarital = 'Célibataire';
  String _phoneDialCode = '+237';
  String _residenceCountryCode = 'CM';
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _error;

  String get _email => _emailController.text.trim();
  String get _phoneE164 =>
      '$_phoneDialCode${_phoneController.text.replaceAll(RegExp(r'\D'), '')}';
  List<String> get _residenceCities =>
      _africanCities[_residenceCountryCode] ?? const [];

  String? _optional(String value) => value.trim().isEmpty ? null : value.trim();

  Map<String, dynamic> _profileData() => {
        'name': _nameController.text.trim(),
        'phone': _optional(_phoneController.text) == null ? null : _phoneE164,
        'email': _email,
        'ville': _optional(_villeController.text),
        'pays': _africanCountries[_residenceCountryCode],
        'region': _optional(_regionController.text),
        'statutMarital': _statutMarital,
        'lieuResidence': _optional(_lieuController.text),
      };

  Future<void> _handleSubmit() async {
    setState(() => _error = null);
    if (!_email.contains('@')) {
      setState(() => _error = 'Saisissez une adresse e-mail valide.');
      return;
    }
    if (widget.isSignUp) {
      if (_passwordController.text.length < 8) {
        setState(() =>
            _error = 'Le mot de passe doit contenir au moins 8 caractères.');
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() => _error = 'Les mots de passe ne correspondent pas.');
        return;
      }
      if (_nameController.text.trim().isEmpty) {
        setState(() => _error = 'Le nom complet est requis.');
        return;
      }
      if (_phoneController.text.replaceAll(RegExp(r'\D'), '').length < 6) {
        setState(() => _error = 'Saisissez un numéro de téléphone valide.');
        return;
      }
    } else if (_passwordController.text.isEmpty) {
      setState(() => _error = 'Saisissez votre mot de passe.');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      if (widget.isSignUp) {
        final profile = _profileData();
        final user = await _authService.createEmailAccount(
          email: _email,
          password: _passwordController.text,
          data: profile,
        );
        if (user == null) {
          throw const AuthException('Supabase n’a pas créé le compte.');
        }
        if (Supabase.instance.client.auth.currentSession == null) {
          throw const AuthException(
            'Supabase exige toujours une confirmation e-mail. Désactivez « Confirm email » dans Authentication > Providers pour permettre l’accès immédiat.',
          );
        }
        await _enterHome(user, profile);
      } else {
        final user = await _authService.signInWithEmailPassword(
          email: _email,
          password: _passwordController.text,
        );
        if (user == null) {
          throw const AuthException('Connexion impossible.');
        }
        await _enterHome(user, user.userMetadata ?? const <String, dynamic>{});
      }
    } on AuthException catch (error) {
      if (mounted) {
        setState(() => _error = _authService.describeAuthError(error));
      }
    } catch (error) {
      if (mounted) setState(() => _error = 'Erreur Supabase : $error');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _enterHome(
      User user, Map<String, dynamic> fallbackProfile) async {
    AppStore.instance.syncSupabaseUser(user, profile: fallbackProfile);
    if (mounted) context.go('/app/home');

    try {
      final storedProfile = await _userService.getUser(user.id);
      final profile = Map<String, dynamic>.from(
        storedProfile ?? fallbackProfile,
      );
      if (storedProfile == null) {
        await _userService.createUser(
          user.id,
          name: profile['name'] as String? ?? 'Utilisateur',
          phone: profile['phone'] as String? ?? user.phone,
          email: profile['email'] as String? ?? user.email,
          ville: profile['ville'] as String?,
          pays: profile['pays'] as String?,
          region: profile['region'] as String?,
          statutMarital: profile['statutMarital'] as String?,
          lieuResidence: profile['lieuResidence'] as String?,
        );
      }
      AppStore.instance.syncSupabaseUser(user, profile: profile);
      await AppStore.instance.loadOrganizations();
    } catch (error) {
      debugPrint(
          'Session ouverte, synchronisation Supabase incomplète: $error');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _villeController.dispose();
    _regionController.dispose();
    _lieuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _Logo(),
                  const SizedBox(height: 16),
                  Text(
                    widget.isSignUp ? 'Créer un compte' : 'Connexion',
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  if (widget.isSignUp) ...[
                    const SizedBox(height: 4),
                    const Text(
                      'Ces informations seront affichées sur votre profil.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (_error != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.errorBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!,
                                style: const TextStyle(
                                    color: AppColors.error, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (widget.isSignUp) ...[
                    const _FieldLabel('Nom complet *'),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration:
                          const InputDecoration(hintText: 'Nom complet'),
                    ),
                    const SizedBox(height: 16),
                    const _FieldLabel('Numéro de téléphone *'),
                    Row(
                      children: [
                        SizedBox(
                          width: 112,
                          child: DropdownButtonFormField<String>(
                            initialValue: _phoneDialCode,
                            isExpanded: true,
                            decoration:
                                const InputDecoration(labelText: 'Indicatif'),
                            items: const [
                              '+213',
                              '+216',
                              '+229',
                              '+267',
                              '+226',
                              '+257',
                              '+237',
                              '+238',
                              '+236',
                              '+235',
                              '+269',
                              '+242',
                              '+243',
                              '+225',
                              '+253',
                              '+20',
                              '+240',
                              '+291',
                              '+251',
                              '+241',
                              '+220',
                              '+233',
                              '+224',
                              '+245',
                              '+254',
                              '+266',
                              '+231',
                              '+218',
                              '+261',
                              '+265',
                              '+223',
                              '+222',
                              '+230',
                              '+212',
                              '+258',
                              '+264',
                              '+227',
                              '+234',
                              '+250',
                              '+239',
                              '+221',
                              '+232',
                              '+252',
                              '+27',
                              '+211',
                              '+249',
                              '+255',
                              '+228',
                              '+256',
                              '+260',
                              '+263',
                            ]
                                .map((code) => DropdownMenuItem(
                                      value: code,
                                      child: Text(code),
                                    ))
                                .toList(),
                            onChanged: (code) {
                              if (code != null) {
                                setState(() => _phoneDialCode = code);
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration:
                                const InputDecoration(hintText: '6XX XXX XXX'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const _FieldLabel('Mot de passe *'),
                    _passwordField(_passwordController, isNewPassword: true),
                    const SizedBox(height: 12),
                    const _FieldLabel('Confirmer le mot de passe *'),
                    _passwordField(_confirmPasswordController,
                        isNewPassword: true, isConfirmation: true),
                    const SizedBox(height: 16),
                  ],
                  const _FieldLabel('Adresse e-mail *'),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'vous@exemple.com',
                    ),
                  ),
                  if (!widget.isSignUp) ...[
                    const SizedBox(height: 16),
                    const _FieldLabel('Mot de passe *'),
                    _passwordField(_passwordController),
                  ],
                  if (widget.isSignUp) ...[
                    const SizedBox(height: 20),
                    const _FieldLabel('Localisation'),
                    DropdownButtonFormField<String>(
                      initialValue: _residenceCountryCode,
                      isExpanded: true,
                      dropdownColor: AppColors.card,
                      decoration:
                          const InputDecoration(labelText: 'Pays de résidence'),
                      items: (_africanCountries.entries.toList()
                            ..sort((a, b) => a.value.compareTo(b.value)))
                          .map((entry) => DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(entry.value),
                              ))
                          .toList(),
                      onChanged: (code) {
                        if (code == null) return;
                        setState(() {
                          _residenceCountryCode = code;
                          _villeController.clear();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey(_residenceCountryCode),
                      initialValue: _residenceCities.contains(
                        _villeController.text,
                      )
                          ? _villeController.text
                          : null,
                      isExpanded: true,
                      dropdownColor: AppColors.card,
                      decoration: const InputDecoration(labelText: 'Ville'),
                      hint: const Text('Choisir une ville'),
                      items: _residenceCities
                          .map((city) => DropdownMenuItem(
                                value: city,
                                child: Text(city),
                              ))
                          .toList(),
                      onChanged: (city) => setState(
                        () => _villeController.text = city ?? '',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _regionController,
                      decoration:
                          const InputDecoration(hintText: 'Région (optionnel)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _lieuController,
                      decoration: const InputDecoration(
                          hintText: 'Lieu de résidence (optionnel)'),
                    ),
                    const SizedBox(height: 16),
                    const _FieldLabel('Statut marital'),
                    DropdownButtonFormField<String>(
                      initialValue: _statutMarital,
                      dropdownColor: AppColors.card,
                      items: const [
                        'Célibataire',
                        'Marié(e)',
                        'Divorcé(e)',
                        'Veuf(ve)',
                      ]
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ))
                          .toList(),
                      onChanged: (value) => setState(
                          () => _statutMarital = value ?? 'Célibataire'),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.isSignUp
                              ? 'Créer le compte'
                              : 'Se connecter'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.isSignUp
                            ? 'Vous avez déjà un compte ? '
                            : 'Pas encore de compte ? ',
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
                          widget.isSignUp ? 'Connexion' : 'Créer un compte',
                          style: const TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordField(
    TextEditingController controller, {
    bool isNewPassword = false,
    bool isConfirmation = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: _obscurePassword,
      autofillHints: [
        isNewPassword ? AutofillHints.newPassword : AutofillHints.password,
      ],
      decoration: InputDecoration(
        hintText: isConfirmation
            ? 'Ressaisissez le mot de passe'
            : isNewPassword
                ? 'Au moins 8 caractères'
                : 'Votre mot de passe',
        suffixIcon: IconButton(
          tooltip: _obscurePassword
              ? 'Afficher le mot de passe'
              : 'Masquer le mot de passe',
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) => Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: const Center(
          child: Icon(Icons.people_alt_rounded,
              color: AppColors.accentColor, size: 38),
        ),
      );
}
