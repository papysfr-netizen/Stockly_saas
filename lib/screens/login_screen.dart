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
  String? _verificationId;

  // Contrôleurs de texte
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

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
        throw Exception("Aucun profil trouvé dans la collection 'users'.");
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Normalisation en minuscules pour éviter les erreurs de casse
      String role = (userData['role'] ?? 'vendeur').toString().toLowerCase();

      if (!mounted) return;

      _afficherMessage("Connexion réussie ! Rôle : $role");

      // 🔀 Redirection RBAC selon les permissions
      if (role == 'owner' || role == 'admin') {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        // Redirection directe vers l'interface de caisse pour les vendeurs / caissiers
        Navigator.pushReplacementNamed(context, '/caisse');
      }
    } catch (e) {
      _afficherMessage("Erreur d'accès à la base de données : ${e.toString()}");
    }
  }

  // ------------------------------------------------------------------
  // 📧 1. Connexion par Email / Mot de passe
  // ------------------------------------------------------------------
  Future<void> _loginWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _afficherMessage("Veuillez remplir tous les champs.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        await _fetchUserProfileAndNavigate(userCredential.user!.uid);
      }
    } on FirebaseAuthException catch (e) {
      _afficherMessage(e.message ?? "Erreur de connexion e-mail.");
    } catch (e) {
      _afficherMessage("Erreur : ${e.toString()}");
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
      _afficherMessage("Veuillez entrer un numéro de téléphone.");
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
          _afficherMessage("Erreur SMS : ${e.message}");
          if (mounted) setState(() => _isLoading = false);
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _isOtpSent = true;
              _isLoading = false;
            });
            _afficherMessage("Code SMS envoyé !");
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      _afficherMessage("Erreur : ${e.toString()}");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ------------------------------------------------------------------
  // 🔑 3. Connexion par SMS (Étape B : Validation du code)
  // ------------------------------------------------------------------
  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.isEmpty || _verificationId == null) {
      _afficherMessage("Veuillez saisir le code reçu.");
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
      _afficherMessage(e.message ?? "Code SMS invalide.");
    } catch (e) {
      _afficherMessage("Erreur : ${e.toString()}");
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
                'Stockly SaaS',
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
                      ? 'Se connecter avec un numéro'
                      : 'Se connecter par E-mail',
                ),
              ),
              const SizedBox(height: 24),

              // Formulaire Mode Email
              if (_isEmailMode) ...[
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Adresse E-mail',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _loginWithEmail,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Se connecter', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ]
              // Formulaire Mode SMS (Étape 1 : Numéro)
              else if (!_isOtpSent) ...[
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone (ex: +33612345678)',
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
                        : const Text('Envoyer le code SMS', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ]
              // Formulaire Mode SMS (Étape 2 : Code OTP)
              else ...[
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Code à 6 chiffres reçu par SMS',
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
                        : const Text('Valider le code', style: TextStyle(fontSize: 18)),
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
                  const Text("Nouveau sur Stockly ?"),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Créer une entreprise',
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