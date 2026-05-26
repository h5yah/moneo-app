import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fintech/services/miro_knowledge_service.dart';

class AiAssistantService {
  AiAssistantService._();

  static final AiAssistantService instance = AiAssistantService._();

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  Future<String> sendMessage(String message) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('You must be signed in to use the assistant.');
    }

    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Message is empty.');
    }

    final knowledgeContext =
        await MiroKnowledgeService.instance.buildKnowledgeContext(trimmed);

    final callable = _functions.httpsCallable('miroChat');
    final payload = <String, dynamic>{
      'message': trimmed,
      if (knowledgeContext.isNotEmpty) 'knowledgeContext': knowledgeContext,
    };

    final response = await callable.call(payload);

    final raw = response.data;
    if (raw is! Map) {
      throw StateError('Empty response from assistant.');
    }

    final data = Map<String, dynamic>.from(raw);
    final reply = data['reply'];
    if (reply is String && reply.trim().isNotEmpty) {
      return reply.trim();
    }

    throw StateError('Invalid response from assistant.');
  }
}
