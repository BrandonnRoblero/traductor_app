import 'package:traductor_app/utils/flags.dart';

//Idiomas que la app puede traducir
class Language {
  //codigo del idioma (se usara para la traduccion y la voz)
  final String code;
  //nombre que se muestra en pantalla
  final String name;
  //bandera del pais del idioma
  final FlagIcon Function(double width) flag;

  const Language({required this.code, required this.name, required this.flag});
}

//9.1 lista de idiomas en el orden en que aparecen las banderas
final List<Language> languages = [
  Language(
    code: 'en',
    name: 'Inglés',
    flag: (w) => FlagIcon.usa(width: w),
  ),
  Language(
    code: 'es',
    name: 'Español',
    flag: (w) => FlagIcon.mexico(width: w),
  ),
  Language(
    code: 'zh',
    name: 'Chino',
    flag: (w) => FlagIcon.china(width: w),
  ),
  Language(
    code: 'fr',
    name: 'Francés',
    flag: (w) => FlagIcon.france(width: w),
  ),
  Language(
    code: 'ar',
    name: 'Árabe',
    flag: (w) => FlagIcon.egypt(width: w),
  ),
];
