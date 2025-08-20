import 'package:http/http.dart' as http;
import 'dart:convert';

class TrustedDomain {
  final String name;
  final String domain;

  TrustedDomain({required this.name, required this.domain});

  factory TrustedDomain.fromJson(Map<String, dynamic> json) {
    return TrustedDomain(
      name: json['name'],
      domain: json['domain'],
    );
  }
}

Future<List<TrustedDomain>> fetchTrustedDomains() async {
  final response =
      await http.get(Uri.parse('http://YOUR_API_URL/trusted-domains'));

  if (response.statusCode == 200) {
    final List data = json.decode(response.body);
    return data.map((json) => TrustedDomain.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load trusted domains');
  }
}
