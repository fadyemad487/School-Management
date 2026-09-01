import '../../../core/network/api_client.dart';

class StudentAiService {
  final _client = ApiClient();

  Future<String> chat({
    required String message,
    List<Map<String, dynamic>> history = const [],
  }) async {
    final response = await _client.client.post(
      '/students/mobile/ai-chat',
      data: {
        'message': message,
        'history': history,
      },
    );
    if (response.statusCode == 200 && response.data['success'] == true) {
      return response.data['reply'] as String? ?? 'حاضر يا بطل!';
    }
    throw Exception(response.data['message'] ?? 'فشل الاتصال بالمساعد');
  }
}
