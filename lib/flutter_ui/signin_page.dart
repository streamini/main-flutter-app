import 'package:broadcast_gemini/flutter_ui/main_page.dart';
import 'package:flutter/material.dart';
import "package:http/http.dart" as http;
import 'dart:io';
import 'dart:async';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthManager {
  static const String redirectUrl = 'http://localhost:';
  static const String googleAuthApi =
      "https://accounts.google.com/o/oauth2/v2/auth";
  static const String googleTokenApi = "https://oauth2.googleapis.com/token";
  static const String googleClientId =
      '289130469948-jq5f58ujvatf5ic2l1npkbmo37b68cd8.apps.googleusercontent.com';
  static const String authClientSecret = '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';
  static const String emailScope = 'email';

  HttpServer? redirectServer;

  Future<oauth2.Client> login() async {
    await redirectServer?.close();
    redirectServer = await HttpServer.bind('localhost', 0);
    final fullRedirectUrl = redirectUrl + redirectServer!.port.toString();

    var grant = oauth2.AuthorizationCodeGrant(
      googleClientId,
      Uri.parse(googleAuthApi),
      Uri.parse(googleTokenApi),
      secret: authClientSecret,
      httpClient: JsonAcceptingHttpClient(),
    );

    var authorizationUrl = grant
        .getAuthorizationUrl(Uri.parse(fullRedirectUrl), scopes: [emailScope]);

    await _redirect(authorizationUrl);
    var responseQueryParameters = await _listen();
    var client =
        await grant.handleAuthorizationResponse(responseQueryParameters);
    await _saveLoginState(client);
    return client;
  }

  Future<void> _saveLoginState(oauth2.Client client) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', client.credentials.accessToken);
    await prefs.setString(
        'refreshToken', client.credentials.refreshToken ?? '');
    await prefs.setString('scopes', client.credentials.scopes?.join(',') ?? '');
    await prefs.setString(
        'tokenEndpoint', client.credentials.tokenEndpoint.toString());
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('accessToken');
  }

  Future<oauth2.Client?> getSavedClient() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('accessToken')) return null;

    final accessToken = prefs.getString('accessToken')!;
    final refreshToken = prefs.getString('refreshToken') ?? '';
    final scopes = prefs.getString('scopes')?.split(',') ?? [];
    final tokenEndpoint = Uri.parse(prefs.getString('tokenEndpoint')!);

    final credentials = oauth2.Credentials(
      accessToken,
      refreshToken: refreshToken,
      tokenEndpoint: tokenEndpoint,
      scopes: scopes,
    );

    return oauth2.Client(credentials,
        identifier: googleClientId, secret: authClientSecret);
  }

  Future<void> _redirect(Uri authorizationUri) async {
    if (await canLaunchUrl(authorizationUri)) {
      await launchUrl(authorizationUri);
    } else {
      throw Exception('Cannot launch $authorizationUri');
    }
  }

  Future<Map<String, String>> _listen() async {
    var request = await redirectServer!.first;
    var params = request.uri.queryParameters;
    request.response
      ..statusCode = 200
      ..headers.set('content-type', 'text/plain')
      ..writeln(
          'Sign in completed! You can close this tab now and return to StreaMini!');
    await request.response.close();
    await redirectServer!.close();
    redirectServer = null;
    return params;
  }
}

class JsonAcceptingHttpClient extends http.BaseClient {
  final _httpClient = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Accept'] = 'application/json';
    return _httpClient.send(request);
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLoggingIn = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkLoginState();
  }

  Future<void> _checkLoginState() async {
    final authManager = AuthManager();
    if (await authManager.isLoggedIn()) {
      final client = await authManager.getSavedClient();
      if (client != null) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => MainPage()));
      }
    }
  }

  void startLogin() async {
    setState(() {
      isLoggingIn = true;
      errorMessage = '';
    });
    try {
      final client = await AuthManager().login();
      // Assuming you have a method to handle successful login
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => MainPage()));
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to login: ${e.toString()}';
        isLoggingIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Color.fromARGB(255, 105, 79, 142),
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: isLoggingIn
              ? Container(
                  height: 300,
                  width: 300,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    // Red border with 2 pixels width
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        // Shadow color with opacity
                        spreadRadius: 20,
                        // Spread radius
                        blurRadius: 100,
                        // Blur radius
                        offset: Offset(0, 0), // Changes position of shadow
                      ),
                    ],
                    color: Color.fromARGB(255, 182, 146, 194),
                    // Transparent background
                    borderRadius: BorderRadius.circular(10), // Rounded corners
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                              strokeWidth: 14, color: Colors.blueGrey)),
                      SizedBox(height: 20),
                      Text('Signing in...',
                          style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w400,
                              color: Color.fromARGB(255, 254, 243, 226))),
                    ],
                  ),
                )
              : Container(
                  height: 300,
                  width: 700,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    // Red border with 2 pixels width

                    color: Color.fromARGB(255, 182, 146, 194),
                    // Transparent background
                    borderRadius: BorderRadius.circular(10), // Rounded corners
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(errorMessage,
                              style: TextStyle(color: Colors.red)),
                        ),
                      Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                'Welcome to StreaMini! \nPlease Sign in to continue.',
                                style: TextStyle(
                                    fontSize: 42,
                                    color: Color.fromARGB(255, 254, 243, 226))),
                            SizedBox(height: 100),
                            ElevatedButton(
                              onPressed: startLogin,
                              child: Text('Sign in with Google'),
                            )
                          ]),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
