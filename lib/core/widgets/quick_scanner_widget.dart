// lib/core/widgets/quick_scanner_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Scanner de code-barres avec CONFIRMATION :
/// un code n'est accepté que s'il est lu plusieurs fois de suite à l'identique.
/// Cela évite les lectures partielles (étiquette abîmée, reflet, plastique).
/// Solution de secours : saisie manuelle du numéro imprimé.
class QuickScannerWidget extends StatefulWidget {
  final Function(String code)? onCodeScanned;

  const QuickScannerWidget({
    super.key,
    this.onCodeScanned,
  });

  @override
  State<QuickScannerWidget> createState() => _QuickScannerWidgetState();
}

class _QuickScannerWidgetState extends State<QuickScannerWidget> {
  /// Nombre de lectures identiques consécutives exigées.
  static const int _lecturesRequises = 3;

  /// Au-delà de ce délai sans lecture, on recommence le comptage.
  static const Duration _delaiRemiseAZero = Duration(milliseconds: 1500);

  /// Cadre rectangulaire, adapté aux codes-barres longs.
  static const double _largeurCadre = 320.0;
  static const double _hauteurCadre = 160.0;

  late final MobileScannerController _controller;
  bool _hasScanned = false;

  String? _codeEnCours;
  int _compteur = 0;
  DateTime _derniereLecture = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      // "normal" : les lectures identiques successives arrivent bien
      // (indispensable pour la confirmation).
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
      formats: [
        BarcodeFormat.aztec,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.code93,
        BarcodeFormat.codabar,
        BarcodeFormat.dataMatrix,
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.itf,
        BarcodeFormat.pdf417,
        BarcodeFormat.qrCode,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Termine le scan avec ce code (scanné et confirmé, ou saisi à la main).
  void _terminer(String code) {
    if (_hasScanned) return;
    setState(() => _hasScanned = true);
    HapticFeedback.mediumImpact();
    widget.onCodeScanned?.call(code);
    if (mounted) {
      Navigator.of(context).pop(code);
    }
  }

  void _handleBarcodeDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    // Premier code non vide de l'image
    String? lu;
    for (final barcode in capture.barcodes) {
      final valeur = barcode.rawValue?.trim();
      if (valeur != null && valeur.isNotEmpty) {
        lu = valeur;
        break;
      }
    }
    if (lu == null) return;

    final maintenant = DateTime.now();
    final tropAncien = maintenant.difference(_derniereLecture) > _delaiRemiseAZero;
    _derniereLecture = maintenant;

    setState(() {
      if (tropAncien || lu != _codeEnCours) {
        // Nouveau code (ou lecture différente) : on recommence à 1.
        _codeEnCours = lu;
        _compteur = 1;
      } else {
        _compteur++;
      }
    });

    if (_compteur >= _lecturesRequises) {
      _terminer(_codeEnCours!);
    }
  }

  /// Solution de secours : taper le numéro imprimé sous les barres.
  Future<void> _saisirALaMain() async {
    final controleur = TextEditingController();

    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Saisir le code à la main'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tapez le numéro imprimé sous les barres.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controleur,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Code-barres',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (valeur) => Navigator.pop(ctx, valeur.trim()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controleur.text.trim()),
            child: const Text('Valider'),
          ),
        ],
      ),
    );

    // CORRECTIF PLANTAGE : la petite fenêtre est encore en train de se fermer
    // (animation). On ne détruit le champ qu'une seconde plus tard,
    // et on attend la fin de l'animation avant de quitter le scanner.
    Future.delayed(const Duration(seconds: 1), controleur.dispose);

    if (code != null && code.isNotEmpty && mounted) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted) _terminer(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Scanner le Code-barres',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, child) {
              final isTorchOn = state.torchState == TorchState.on;
              return IconButton(
                icon: Icon(
                  isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  color: isTorchOn ? Colors.amber : Colors.white,
                ),
                tooltip: 'Flash',
                onPressed: () => _controller.toggleTorch(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white),
            tooltip: 'Changer de caméra',
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcodeDetect,
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.camera_enhance_rounded,
                        color: Colors.redAccent,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Accès à la caméra requis',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Veuillez autoriser l\'accès à la caméra dans les paramètres pour scanner les codes-barres.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _controller.start(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Masque sombre découpé au centre (rectangle large)
          Positioned.fill(
            child: CustomPaint(
              painter: ScannerOverlayPainter(
                overlayColor: Colors.black.withValues(alpha: 0.6),
                largeurCadre: _largeurCadre,
                hauteurCadre: _hauteurCadre,
                borderRadius: 20.0,
                borderColor: theme.colorScheme.primary,
              ),
            ),
          ),

          // Progression de la vérification (en haut)
          if (_codeEnCours != null && !_hasScanned)
            Positioned(
              top: 40,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Vérification… $_compteur/$_lecturesRequises',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _codeEnCours!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _compteur / _lecturesRequises,
                        minHeight: 5,
                        backgroundColor: Colors.white24,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Instruction + bouton de secours (en bas)
          Positioned(
            bottom: 40,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Reculez un peu : tout le code-barres doit tenir dans le cadre',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _hasScanned ? null : _saisirALaMain,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.keyboard_rounded),
                  label: const Text(
                    'Saisir le code à la main',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Color overlayColor;
  final double largeurCadre;
  final double hauteurCadre;
  final double borderRadius;
  final Color borderColor;

  ScannerOverlayPainter({
    required this.overlayColor,
    required this.largeurCadre,
    required this.hauteurCadre,
    required this.borderRadius,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = overlayColor;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    // Le cadre ne dépasse jamais l'écran (petits téléphones).
    final largeur = largeurCadre > size.width - 32 ? size.width - 32 : largeurCadre;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final cadre = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: largeur,
      height: hauteurCadre,
    );
    final cadreArrondi = RRect.fromRectAndRadius(
      cadre,
      Radius.circular(borderRadius),
    );

    final backgroundPath = Path()
      ..addRect(rect)
      ..addRRect(cadreArrondi);
    backgroundPath.fillType = PathFillType.evenOdd;

    canvas.drawPath(backgroundPath, backgroundPaint);
    canvas.drawRRect(cadreArrondi, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}