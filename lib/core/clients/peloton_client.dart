import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/peloton_models.dart';

class PelotonClient {
  static const String _baseUrl = 'https://api.onepeloton.com';
  // Note: api-3p.onepeloton.com is also used in old_app, but api.onepeloton.com is the standard public one.
  // old_app uses api-3p for some things. We'll start with standard.
  // old_app peloton.cpp uses 'https://api-3p.onepeloton.com/api/v1/ride/'
  
  static const String _authUrl = 'https://auth.onepeloton.com/auth/login';

  final http.Client _client = http.Client();
  Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'User-Agent': 'Peloton/1.0.0 (Android; 10)',
  };

  String? _userId;
  String? _sessionId;
  
  bool get isLoggedIn => _sessionId != null;

  PelotonClient();

  Future<void> init() async {
     final prefs = await SharedPreferences.getInstance();
     final sessionCookie = prefs.getString('peloton_session_id');
     final userId = prefs.getString('peloton_user_id');
     
     if (sessionCookie != null && userId != null) {
       _sessionId = sessionCookie;
       _userId = userId;
       _headers['Cookie'] = 'peloton_session_id=$_sessionId';
     }
  }

  Future<bool> login(String usernameOrEmail, String password) async {
    try {
      final response = await _client.post(
        Uri.parse(_authUrl),
        body: jsonEncode({
          'username_or_email': usernameOrEmail,
          'password': password,
        }),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        _userId = body['user_id'];
        _sessionId = body['session_id']; // This might be in cookies, checking body first
        
        // If session_id is not in body, check cookies
         if (_sessionId == null) {
            final rawCookie = response.headers['set-cookie'];
            if (rawCookie != null) {
              final cookies = rawCookie.split(';');
              for (final cookie in cookies) {
                if (cookie.trim().startsWith('peloton_session_id=')) {
                  _sessionId = cookie.split('=')[1];
                  break;
                }
              }
            }
         }

        if (_sessionId != null && _userId != null) {
           _headers['Cookie'] = 'peloton_session_id=$_sessionId';
           
           // Persist
           final prefs = await SharedPreferences.getInstance();
           await prefs.setString('peloton_session_id', _sessionId!);
           await prefs.setString('peloton_user_id', _userId!);
           
           return true;
        }
      }
      print('Login Failed: ${response.statusCode} ${response.body}');
      return false;
    } catch (e) {
      print('Login Error: $e');
      return false;
    }
  }
  
  Future<void> logout() async {
    _userId = null;
    _sessionId = null;
    _headers.remove('Cookie');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('peloton_session_id');
    await prefs.remove('peloton_user_id');
  }

  Future<List<PelotonRide>> getRecentWorkouts({int limit = 20, int page = 0}) async {
    if (!isLoggedIn) return [];

    try {
      // https://api.onepeloton.com/api/v2/ride/archived?limit=20&page=0&sort_by=-original_air_time
      // Or user specific: /api/user/{userId}/workouts
      // Let's use the ride discovery endpoint as it gives us classes we can take.
      
      final uri = Uri.parse('$_baseUrl/api/v2/ride/archived').replace(queryParameters: {
        'limit': limit.toString(),
        'page': page.toString(),
        'sort_by': '-original_air_time',
        'browse_category': 'cycling', 
        'content_format': 'audio,video',
      });

      final response = await _client.get(uri, headers: _headers);
      
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] as List;
        return data.map((json) => PelotonRide.fromJson(json)).toList();
      }
      print('Fetch Workouts Failed: ${response.statusCode} ${response.body}');
    } catch (e) {
      print('Fetch Workouts Error: $e');
    }
    return [];
  }
  
  Future<PelotonRide?> getRideDetails(String rideId) async {
      if (!isLoggedIn) return null;
      try {
        final response = await _client.get(
           Uri.parse('$_baseUrl/api/v1/ride/$rideId'),
           headers: _headers
        );
         if (response.statusCode == 200) {
            return PelotonRide.fromJson(jsonDecode(response.body));
         }
      } catch (e) {
        print('Get Ride Details Error: $e');
      }
      return null;
  }

  Future<List<PelotonInstructorCue>> getInstructorCues(String rideId) async {
     if (!isLoggedIn) return [];
     
     try {
       final response = await _client.get(
         Uri.parse('$_baseUrl/api/v1/ride/$rideId/details?stream_source=multichannel'),
         headers: _headers,
       );
       
       if (response.statusCode == 200) {
         final body = jsonDecode(response.body);
         final cuesJson = body['instructor_cues'] as List?;
         if (cuesJson != null) {
           return cuesJson.map((json) => PelotonInstructorCue.fromJson(json)).toList();
         }
       }
        print('Fetch Cues Failed: ${response.statusCode}');
     } catch (e) {
       print('Fetch Cues Error: $e');
     }
     return [];
  }
}
