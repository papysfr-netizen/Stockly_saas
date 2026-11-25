// 👩🏾 Le visage de « Demandez à Nguli » : une commerçante congolaise, foulard en pagne.
// Dessin source : docs/outils/nguli_avatar.svg (image 256 px, environ 36 Ko).
import 'package:flutter/material.dart';

class AvatarNguli extends StatelessWidget {
  final double taille;
  const AvatarNguli({super.key, this.taille = 32});

  @override
  Widget build(BuildContext context) => ClipOval(
        child: Image.asset(
          'assets/images/nguli_avatar.png',
          width: taille,
          height: taille,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        ),
      );
}
