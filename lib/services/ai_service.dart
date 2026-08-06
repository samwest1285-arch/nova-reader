import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// The mode of the AI Butler service.
enum AiButlerMode {
  /// Answers questions about the app's features.
  techSupport,

  /// Provides book recommendations and merges book summaries.
  bookButler,
}

/// A cached response entry.
class _CachedResponse {
  final String query;
  final String response;
  final DateTime timestamp;

  const _CachedResponse({
    required this.query,
    required this.response,
    required this.timestamp,
  });

  bool get isExpired {
    return DateTime.now().difference(timestamp).inHours > 24;
  }
}

/// Configuration for the AI Butler service.
class AiServiceConfig {
  /// The OpenRouter API key.
  final String apiKey;

  /// The model to use for completions.
  final String model;

  /// The base URL for the OpenRouter API.
  final String baseUrl;

  /// Maximum tokens for the response.
  final int maxTokens;

  /// Temperature for response generation.
  final double temperature;

  /// Whether to cache responses.
  final bool enableCaching;

  /// Maximum number of cached responses.
  final int maxCacheSize;

  const AiServiceConfig({
    this.apiKey = '',
    this.model = 'deepseek/deepseek-v4-flash-0731',
    this.baseUrl = 'https://openrouter.ai/api/v1',
    this.maxTokens = 1024,
    this.temperature = 0.7,
    this.enableCaching = true,
    this.maxCacheSize = 50,
  });
}

/// The AI Butler service for the Nova Reader app.
///
/// Connects to OpenRouter API to provide tech support (answering questions
/// about the app) and book butler (book recommendations and summary merging).
class AiButlerService {
  AiServiceConfig _config;
  final List<_CachedResponse> _cache = [];
  final math.Random _random = math.Random();

  // Fallback responses for when the API is unavailable.
  static const _fallbackTechResponses = [
    "I'm sorry, I'm having trouble connecting to my knowledge base right now. Please try again later.",
    "My apologies, but I seem to be experiencing a temporary connection issue. Could you ask again in a moment?",
    "I'm afraid I can't access my full knowledge at the moment. Here's what I know: Nova Reader supports EPUB and PDF formats, has a cozy fireplace theme, and includes text-to-speech features.",
    "Pardon me, but my connection seems to be disrupted. Please check your internet connection and try again.",
  ];

  static const _fallbackBookResponses = [
    "I'd love to help with book recommendations, but I'm having trouble reaching my library. Please try again shortly.",
    "My book database is temporarily unavailable. In the meantime, I recommend classics like 'Pride and Prejudice' or 'The Hobbit'!",
    "I apologize, but I can't access my recommendation engine right now. Please check your connection and try again.",
  ];

  AiButlerService({AiServiceConfig? config})
      : _config = config ?? const AiServiceConfig();

  /// Updates the service configuration.
  void updateConfig(AiServiceConfig config) {
    _config = config;
  }

  /// Returns the current configuration.
  AiServiceConfig get config => _config;

  /// Returns the current mode label.
  String get modeLabel => _config.apiKey.isEmpty
      ? 'Offline Mode'
      : 'Connected';

  /// Sends a query to the AI Butler in the specified mode.
  ///
  /// [mode] determines the system prompt and behavior.
  /// [query] is the user's question or request.
  /// [context] is optional additional context (e.g., current book info).
  Future<String> query({
    required AiButlerMode mode,
    required String query,
    String? context,
  }) async {
    // Check cache first
    if (_config.enableCaching) {
      final cached = _getCachedResponse(query);
      if (cached != null) {
        return cached;
      }
    }

    // If no API key, return fallback
    if (_config.apiKey.isEmpty) {
      return _getFallbackResponse(mode);
    }

    try {
      final systemPrompt = _buildSystemPrompt(mode);
      final userMessage = context != null
          ? 'Context: $context\n\nQuery: $query'
          : query;

      final response = await _callOpenRouter(systemPrompt, userMessage);

      // Cache the response
      if (_config.enableCaching) {
        _cacheResponse(query, response);
      }

      return response;
    } catch (e) {
      return _getFallbackResponse(mode);
    }
  }

  /// Merges two book descriptions/summaries into a combined summary.
  ///
  /// This is a specialized function for the Book Butler mode.
  Future<String> mergeBooks({
    required String book1Title,
    required String book1Description,
    required String book2Title,
    required String book2Description,
  }) async {
    final prompt = '''
Please merge the following two books into a combined summary that captures the essence of both:

Book 1: "$book1Title"
Description: $book1Description

Book 2: "$book2Title"
Description: $book2Description

Create a creative, engaging combined summary that:
1. Blends the themes and settings of both books
2. Suggests what a merged story might be like
3. Recommends which readers would enjoy this combination
4. Is written in a warm, inviting tone suitable for a cozy book app
''';

    return query(
      mode: AiButlerMode.bookButler,
      query: prompt,
    );
  }

  /// Answers a tech support question about the app.
  Future<String> askTechSupport(String question) async {
    return query(
      mode: AiButlerMode.techSupport,
      query: question,
    );
  }

  /// Gets a book recommendation based on user preferences.
  Future<String> getRecommendation({
    String? favoriteGenre,
    String? favoriteBook,
    String? mood,
  }) async {
    final prompt = StringBuffer('Please recommend a book for me.');
    if (favoriteGenre != null) {
      prompt.write(' I enjoy $favoriteGenre books.');
    }
    if (favoriteBook != null) {
      prompt.write(' I loved reading "$favoriteBook".');
    }
    if (mood != null) {
      prompt.write(" I'm in the mood for something $mood.");
    }
    prompt.write(
      ' Please provide a warm, personalized recommendation with a brief description.',
    );

    return query(
      mode: AiButlerMode.bookButler,
      query: prompt.toString(),
    );
  }

  /// Builds the system prompt based on the mode.
  String _buildSystemPrompt(AiButlerMode mode) {
    switch (mode) {
      case AiButlerMode.techSupport:
        return '''You are Jeeves, the helpful butler of the Nova Reader app. You are warm, polite, and knowledgeable. You assist users with questions about the app's features.

Nova Reader is a cozy book reading app with the following features:
- EPUB and PDF book reading
- Text-to-speech with multiple voice profiles
- AI-powered book recommendations
- OCR text recognition from camera
- EPUB generation from text, OCR, and PDF
- Cozy fireplace animation
- Tree border decorations
- Ambient sounds (fire, rain, wind, birds)
- Auto theme based on time of day
- Book library management
- Bookmarks and highlights

Answer questions concisely but warmly. If you don't know something, say so politely. Keep responses under 200 words.''';

      case AiButlerMode.bookButler:
        return '''You are Jeeves, the literary butler of the Nova Reader app. You are warm, sophisticated, and passionate about books. You provide book recommendations and merge book summaries.

Your tone is cozy, inviting, and slightly formal — like a well-read butler in a grand library. You reference classic and contemporary literature knowledgeably.

When merging books, create imaginative combinations that blend themes, characters, and settings. When recommending books, consider the user's stated preferences and suggest both popular and hidden gem titles.

Keep responses warm and engaging, under 250 words unless merging books (which can be longer).''';
    }
  }

  /// Calls the OpenRouter API.
  Future<String> _callOpenRouter(String systemPrompt, String userMessage) async {
    final uri = Uri.parse('${_config.baseUrl}/chat/completions');

    final headers = {
      'Authorization': 'Bearer ${_config.apiKey}',
      'Content-Type': 'application/json',
      'HTTP-Referer': 'https://novareader.app',
      'X-Title': 'Nova Reader',
    };

    final body = jsonEncode({
      'model': _config.model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userMessage},
      ],
      'max_tokens': _config.maxTokens,
      'temperature': _config.temperature,
    });

    final response = await http
        .post(uri, headers: headers, body: body)
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>;
      if (choices.isNotEmpty) {
        final message = choices[0]['message'] as Map<String, dynamic>;
        return (message['content'] as String).trim();
      }
      return _getFallbackResponse(AiButlerMode.bookButler);
    } else if (response.statusCode == 401) {
      return 'I apologize, but my API key seems to be invalid. Please check your settings and try again.';
    } else if (response.statusCode == 429) {
      return 'I apologize, but I\'ve reached my rate limit. Please wait a moment and try again.';
    } else {
      return 'I apologize, but I received an unexpected error (${response.statusCode}). Please try again later.';
    }
  }

  /// Returns a fallback response when the API is unavailable.
  String _getFallbackResponse(AiButlerMode mode) {
    switch (mode) {
      case AiButlerMode.techSupport:
        return _fallbackTechResponses[
            _random.nextInt(_fallbackTechResponses.length)];
      case AiButlerMode.bookButler:
        return _fallbackBookResponses[
            _random.nextInt(_fallbackBookResponses.length)];
    }
  }

  // --- Caching ---

  /// Gets a cached response for the given query, or null if not found/expired.
  String? _getCachedResponse(String query) {
    final normalizedQuery = query.toLowerCase().trim();
    for (final cached in _cache) {
      if (cached.query == normalizedQuery && !cached.isExpired) {
        return cached.response;
      }
    }
    return null;
  }

  /// Caches a response for the given query.
  void _cacheResponse(String query, String response) {
    if (_cache.length >= _config.maxCacheSize) {
      _cache.removeAt(0);
    }
    _cache.add(_CachedResponse(
      query: query.toLowerCase().trim(),
      response: response,
      timestamp: DateTime.now(),
    ));
  }

  /// Clears the response cache.
  void clearCache() {
    _cache.clear();
  }

  /// Saves the API key to shared preferences.
  Future<void> saveApiKey(String apiKey) async {
    _config = AiServiceConfig(
      apiKey: apiKey,
      model: _config.model,
      baseUrl: _config.baseUrl,
      maxTokens: _config.maxTokens,
      temperature: _config.temperature,
      enableCaching: _config.enableCaching,
      maxCacheSize: _config.maxCacheSize,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nova_ai_api_key', apiKey);
  }

  /// Loads the API key from shared preferences.
  Future<String> loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('nova_ai_api_key') ?? '';
    if (apiKey.isNotEmpty) {
      _config = AiServiceConfig(
        apiKey: apiKey,
        model: _config.model,
        baseUrl: _config.baseUrl,
        maxTokens: _config.maxTokens,
        temperature: _config.temperature,
        enableCaching: _config.enableCaching,
        maxCacheSize: _config.maxCacheSize,
      );
    }
    return apiKey;
  }
}
