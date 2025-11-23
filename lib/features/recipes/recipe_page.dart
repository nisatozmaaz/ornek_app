// lib/features/recipes/recipe_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RecipePage extends StatefulWidget {
  const RecipePage({
    super.key,
    required this.productName,
    required this.expiry,
  });
  final String productName;
  final DateTime? expiry;

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  // API key'ini buraya koyma, sadece sabitte tut
  static const _apiKey = 'AIzaSyAA0Od5wjHe0Ak26nt1FyF6qX1Wy_9wBIA';

  // URL'in içinde key OLMAYACAK
  static const _geminiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  int? _lastStatus;
  String? _lastBody;

  Future<List<Map<String, dynamic>>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchRecipes();
  }

  Future<List<Map<String, dynamic>>> _fetchRecipes() async {
    final prompt =
        """
Sen profesyonel bir şefsin.
Bu ürün bozulmak üzere: ${widget.productName}
Son kullanma tarihi: ${widget.expiry}

Bu ürünle yapılabilecek 1 adet kolay ve kısa yemek tarifi üret.
Cevabını SADECE JSON formatında dön, hiçbir açıklama veya markdown ekleme.

{
  "title": "Tarif başlığı",
  "time_minutes": 15,
  "ingredients": ["malzeme1", "malzeme2"],
  "steps": ["adım1", "adım2"]
}
""";

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt},
          ],
        },
      ],
    });

    final resp = await http.post(
      Uri.parse(_geminiUrl),
      headers: {'Content-Type': 'application/json', 'x-goog-api-key': _apiKey},
      body: body,
    );

    _lastStatus = resp.statusCode;
    _lastBody = resp.body;

    if (resp.statusCode != 200) {
      throw Exception('Gemini API error: ${resp.body}');
    }

    final decoded = jsonDecode(resp.body);
    final text =
        decoded['candidates'][0]['content']['parts'][0]['text'] as String;

    // Markdown code block'larını temizle (```json ... ``` veya ``` ... ```)
    String cleanedText = text.trim();
    cleanedText = cleanedText.replaceAll(RegExp(r'^```json\s*'), '');
    cleanedText = cleanedText.replaceAll(RegExp(r'^```\s*'), '');
    cleanedText = cleanedText.replaceAll(RegExp(r'\s*```$'), '');
    cleanedText = cleanedText.trim();

    // Modelin text alanında JSON var → parse edelim
    final Map<String, dynamic> recipe = jsonDecode(cleanedText);

    return [recipe];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.productName} tarifleri')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Text(
                    'Tarif alınamadı.\n'
                    'Status: ${_lastStatus ?? '-'}\n'
                    'Body:\n${_lastBody ?? snap.error}',
                    textAlign: TextAlign.start,
                  ),
                ),
              ),
            );
          }
          final recipes = snap.data ?? const [];
          if (recipes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Text(
                    'Tarif bulunamadı.\n'
                    'Status: ${_lastStatus ?? '-'}\n'
                    'Body:\n${_lastBody ?? '(boş)'}',
                    textAlign: TextAlign.start,
                  ),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: recipes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final r = recipes[i];
              final title = (r['title'] ?? '').toString();
              final List ingredients = (r['ingredients'] ?? []) as List;
              final List steps = (r['steps'] ?? []) as List;
              final time = r['time_minutes'];

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (time != null) Text('Süre: ${time.toString()} dk'),
                      const SizedBox(height: 8),
                      const Text(
                        'Malzemeler:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: ingredients
                            .map(
                              (e) => Chip(
                                label: Text(
                                  e.toString(),
                                  style: const TextStyle(fontSize: 13),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Adımlar:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      ...steps.asMap().entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('${e.key + 1}. ${e.value}'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
