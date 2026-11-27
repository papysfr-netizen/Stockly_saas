# Copie modifiée de fake_cloud_firestore 3.1.0

Source : https://pub.dev/packages/fake_cloud_firestore (licence BSD, voir LICENSE).

Seule modification : `lib/src/mock_field_value_factory_platform.dart` — la classe
`MockFieldValueFactoryPlatform` étend `FieldValueFactoryPlatform` au lieu d'utiliser
`MockPlatformInterfaceMixin`, refusé hors du mode debug. Cela permet à la démonstration
web (`lib/main_demo.dart`, base en mémoire) de fonctionner en version compilée.
