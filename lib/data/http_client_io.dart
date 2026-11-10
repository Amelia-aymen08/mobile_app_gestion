import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Client HTTP mobile : la connexion au serveur (TCP + TLS) doit s'etablir en
/// 5 secondes. Au-dela, on abandonne cette tentative pour en relancer une
/// (voir `_RetryOnConnectClient`), au lieu d'attendre 20 secondes pour rien.
http.Client createBaseClient() {
  final io = HttpClient()..connectionTimeout = const Duration(seconds: 5);
  return IOClient(io);
}

/// Vrai seulement si la connexion n'a jamais ete etablie : la requete n'a
/// donc pas atteint le serveur et peut etre renvoyee sans risque de doublon,
/// meme pour un POST (creation de ticket, message...).
bool isConnectFailure(Object error) {
  if (error is! SocketException) return false;
  final msg = error.message.toLowerCase();
  final code = error.osError?.errorCode;
  return msg.contains('connection timed out') ||
      msg.contains('connection refused') ||
      msg.contains('network is unreachable') ||
      msg.contains('failed host lookup') ||
      // ETIMEDOUT / ECONNREFUSED / ENETUNREACH (Linux, Android) et equivalents
      // Windows / iOS.
      const {110, 111, 101, 60, 61, 51, 10060, 10061}.contains(code);
}
