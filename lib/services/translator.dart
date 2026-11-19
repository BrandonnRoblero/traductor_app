import 'dart:convert';

import 'package:http/http.dart' as http;

//Error de traduccion con un mensaje listo para mostrar
class TranslationException implements Exception {
  final String message;
  const TranslationException(this.message);

  @override
  String toString() => message;
}

//Traduce texto usando el servicio gratuito de MyMemory (no necesita llave).
//Funciona igual en el telefono y en el navegador, pero necesita internet.
class Translator {
  static const String _host = 'api.mymemory.translated.net';
  //1. MyMemory acepta hasta 500 caracteres por consulta
  static const int _maxLength = 500;

  //2. traduce [text] del idioma [from] al idioma [to] (codigos 'ja', 'es'...)
  static Future<String> translate(
    String text, {
    required String from,
    required String to,
  }) async {
    final clean = text.replaceAll('\n', ' ').trim();
    if (clean.isEmpty) return '';
    if (from == to) return clean;

    final uri = Uri.https(_host, '/get', {
      'q': clean.length > _maxLength ? clean.substring(0, _maxLength) : clean,
      'langpair': '$from|$to',
    });
    final http.Response response;
    try {
      response = await http.get(uri).timeout(const Duration(seconds: 12));
    } catch (_) {
      throw const TranslationException('Sin conexión: no se pudo traducir');
    }
    if (response.statusCode != 200) {
      throw const TranslationException(
        'El traductor no respondió, intenta de nuevo',
      );
    }
    //2.1 la respuesta trae la traduccion en responseData.translatedText
    final body =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final data = body['responseData'] as Map<String, dynamic>?;
    final translated = (data?['translatedText'] as String?)?.trim() ?? '';
    final status = '${body['responseStatus']}';
    if (status != '200' || translated.isEmpty) {
      throw const TranslationException('No se pudo traducir este texto');
    }
    return translated;
  }
}
