import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/auth_controller.dart';

class PinLockScreen extends ConsumerStatefulWidget {
  /// Le PIN stocké dans Firestore pour l'utilisateur actuel
  final String expectedPin; 
  final String userRole;

  const PinLockScreen({
    super.key,
    required this.expectedPin,
    required this.userRole,
  });

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen> {
  String _enteredPin = '';
  static const int _pinLength = 4;
  bool _hasError = false;

  void _onKeyPress(String value) {
    if (_enteredPin.length < _pinLength) {
      setState(() {
        _enteredPin += value;
        _hasError = false;
      });

      if (_enteredPin.length == _pinLength) {
        _verifyPin();
      }
    }
  }

  void _onDelete() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _hasError = false;
      });
    }
  }

  Future<void> _verifyPin() async {
    final authController = ref.read(authControllerProvider.notifier);
    
    final success = await authController.unlockWithPin(
      _enteredPin,
      widget.expectedPin,
      widget.userRole,
    );

    if (!success) {
      setState(() {
        _hasError = true;
        _enteredPin = '';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code PIN incorrect', textAlign: TextAlign.center),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Colors.blueGrey),
                const SizedBox(height: 16),
                const Text(
                  'Caisse Verrouillée',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Entrez votre code PIN pour reprendre',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Correction du débordement : FittedBox réduit les puces si l'espace horizontal est restreint
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pinLength, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6.0),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index < _enteredPin.length
                              ? (_hasError ? Colors.red : Colors.blueGrey)
                              : Colors.transparent,
                          border: Border.all(
                            color: _hasError ? Colors.red : Colors.blueGrey,
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Pavé numérique
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (var i = 1; i <= 9; i++) _buildNumButton(i.toString()),
                    const SizedBox.shrink(),
                    _buildNumButton('0'),
                    _buildDeleteButton(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumButton(String number) {
    return InkWell(
      onTap: () => _onKeyPress(number),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          number,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return InkWell(
      onTap: _onDelete,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.backspace_outlined, size: 28),
      ),
    );
  }
}