import 'package:http/http.dart' as http;

/// Web : le navigateur gere lui-meme la connexion, pas de nouvelle tentative.
http.Client createBaseClient() => http.Client();

bool isConnectFailure(Object error) => false;
