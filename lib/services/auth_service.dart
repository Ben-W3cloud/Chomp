import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import '../core/env.dart';
import '../core/constants.dart';
import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  final _api = ApiClient.instance;

  /// Opens GitHub's consent screen in the system browser, captures the
  /// redirect, and exchanges the code with OUR backend — which holds
  /// the GitHub client secret — for a Chomp session token. The phone
  /// never sees the raw GitHub access token.
  Future<ChompUser> signInWithGitHub() async {
    final authUrl = Uri.https('github.com', '/login/oauth/authorize', {
      'client_id': Env.githubClientId,
      'scope': 'repo read:user',
      'redirect_uri': '${Env.githubCallbackScheme}://callback',
    });

    final result = await FlutterWebAuth2.authenticate(
      url: authUrl.toString(),
      callbackUrlScheme: Env.githubCallbackScheme,
    );

    final code = Uri.parse(result).queryParameters['code'];
    if (code == null) {
      throw StateError('GitHub did not return an authorization code.');
    }

    final response =
        await _api.post(ApiEndpoints.githubOAuthExchange, {'code': code})
            as Map<String, dynamic>;
    final sessionToken = response['session_token'] as String;
    await _api.setSessionToken(sessionToken);
    return ChompUser.fromJson(response['user'] as Map<String, dynamic>);
  }

  Future<bool> isSignedIn() async => (await _api.sessionToken) != null;

  Future<void> signOut() => _api.clearSession();
}
