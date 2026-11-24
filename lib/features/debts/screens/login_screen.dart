import 'package:stockly_saas/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // États de l'interface
  bool _isEmailMode = true;
  bool _isOtpSent = false;
  bool _isLoading = false;
  bool _motDePasseVisible = false;
  String? _verificationId;

  // Contrôleurs de texte
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  // ------------------------------------------------------------------
  // 🔤 IDENTIFIANT → E-MAIL INTERNE
  // Si l'utilisateur tape un identifiant (sans @), on ajoute @stockly.app
  // Exemple : "gracenbm.nhgkxz" → "gracenbm.nhgkxz@stockly.app"
  // ------------------------------------------------------------------
  String _convertirEnEmail(String saisie) {
    final texte = saisie.trim().toLowerCase().replaceAll(' ', '');
    if (texte.contains('@')) return texte;
    return '$texte@stockly.app';
  }

  // ------------------------------------------------------------------
  // 💬 MESSAGES D'ERREUR EN FRANÇAIS SIMPLE
  // ------------------------------------------------------------------
  String _messageErreurAuth(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-email':
        return AppLocalizations.of(context).logWrong;
      case 'user-disabled':
        return AppLocalizations.of(context).logDisabled;
      case 'too-many-requests':
        return AppLocalizations.of(context).pwdTooMany;
      case 'network-request-failed':
        return AppLocalizations.of(context).logNoInternet;
      default:
        return e.message ?? AppLocalizations.of(context).logError;
    }
  }

  // ------------------------------------------------------------------
  // 🔄 REDIRECTION DYNAMIQUE SELON LE RÔLE FIRESTORE
  // ------------------------------------------------------------------
  Future<void> _fetchUserProfileAndNavigate(String uid) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        throw Exception(AppLocalizations.of(context).logNoProfile);
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // ⛔ Compte désactivé par le propriétaire
      if (userData['estActif'] == false) {
        await FirebaseAuth.instance.signOut();
        _afficherMessage(
            AppLocalizations.of(context).logDisabled);
        return;
      }

      // Normalisation en minuscules pour éviter les erreurs de casse
      String role = (userData['role'] ?? 'caissier').toString().toLowerCase();

      if (!mounted) return;

      final nom = (userData['nom'] ?? '').toString();
      _afficherMessage(nom.isEmpty ? AppLocalizations.of(context).logOk : AppLocalizations.of(context).logWelcome(nom));

      // 🔀 Propriétaire et Gérant → tableau de bord ; Caissier → caisse
      if (role == 'owner' || role == 'admin' || role == 'gerant') {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/caisse');
      }
    } catch (e) {
      _afficherMessage(AppLocalizations.of(context).logDbError(e.toString()));
    }
  }

  // ------------------------------------------------------------------
  // 📧 1. Connexion par Email OU Identifiant / Mot de passe
  // ------------------------------------------------------------------
  Future<void> _loginWithEmail() async {
    final saisie = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (saisie.isEmpty || password.isEmpty) {
      _afficherMessage(AppLocalizations.of(context).fillAll);
      return;
    }

    final email = _convertirEnEmail(saisie);

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        await _fetchUserProfileAndNavigate(userCredential.user!.uid);
      }
    } on FirebaseAuthException catch (e) {
      _afficherMessage(_messageErreurAuth(e));
    } catch (e) {
      _afficherMessage(AppLocalizations.of(context).errorWith(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ------------------------------------------------------------------
  // 📱 2. Connexion par SMS (Étape A : Envoi du code)
  // ------------------------------------------------------------------
  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      _afficherMessage(AppLocalizations.of(context).logEnterPhone);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          UserCredential userCredential = await FirebaseAuth.instance
              .signInWithCredential(credential);
          if (userCredential.user != null) {
            await _fetchUserProfileAndNavigate(userCredential.user!.uid);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          _afficherMessage(AppLocalizations.of(context).logSmsError('${e.message}'));
          if (mounted) setState(() => _isLoading = false);
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _isOtpSent = true;
              _isLoading = false;
            });
            _afficherMessage(AppLocalizations.of(context).logSmsSent);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      _afficherMessage(AppLocalizations.of(context).errorWith(e.toString()));
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ------------------------------------------------------------------
  // 🔑 3. Connexion par SMS (Étape B : Validation du code)
  // ------------------------------------------------------------------
  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.isEmpty || _verificationId == null) {
      _afficherMessage(AppLocalizations.of(context).logEnterCode);
      return;
    }

    setState(() => _isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      if (userCredential.user != null) {
        await _fetchUserProfileAndNavigate(userCredential.user!.uid);
      }
    } on FirebaseAuthException catch (e) {
      _afficherMessage(e.message ?? AppLocalizations.of(context).logBadCode);
    } catch (e) {
      _afficherMessage(AppLocalizations.of(context).errorWith(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _afficherMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.storefront, size: 80, color: Colors.blue),
              const SizedBox(height: 12),
              const Text(
                'Nguli',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // Sélecteur Mode Email / SMS
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _isEmailMode = !_isEmailMode;
                    _isOtpSent = false;
                  });
                },
                icon: Icon(_isEmailMode ? Icons.phone : Icons.email),
                label: Text(
                  _isEmailMode
                      ? AppLocalizations.of(context).logWithPhone
                      : AppLocalizations.of(context).logWithId,
                ),
              ),
              const SizedBox(height: 24),

              // Formulaire Mode Email / Identifiant
              if (_isEmailMode) ...[
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.text,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.none,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).logIdLabel,
                    hintText: 'ex : grace.nhgkxz',
                    helperText: AppLocalizations.of(context).logIdHelp,
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: !_motDePasseVisible,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).logPassword,
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_motDePasseVisible
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(
                          () => _motDePasseVisible = !_motDePasseVisible),
                    ),
                  ),
                  onSubmitted: (_) {
                    if (!_isLoading) _loginWithEmail();
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _loginWithEmail,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(AppLocalizations.of(context).logSignIn, style: TextStyle(fontSize: 18)),
                  ),
                ),
              ]
              // Formulaire Mode SMS (Étape 1 : Numéro)
              else if (!_isOtpSent) ...[
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).logPhoneLabel,
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendOtp,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(AppLocalizations.of(context).logSendSms, style: TextStyle(fontSize: 18)),
                  ),
                ),
              ]
              // Formulaire Mode SMS (Étape 2 : Code OTP)
              else ...[
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).logCodeLabel,
                    prefixIcon: Icon(Icons.phonelink_ring),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(AppLocalizations.of(context).logValidateCode, style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],

              // ------------------------------------------------------------------
              // 🚀 LIEN VERS LA CRÉATION D'ENTREPRISE
              // ------------------------------------------------------------------
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppLocalizations.of(context).logNew),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: Text(
                      AppLocalizations.of(context).logCreateBusiness,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}