import '../domain/task.dart';

const double voiceTaskAutoCreateConfidenceThreshold = 0.75;

/// Structured output returned by the voice-task backend proxy.
class VoiceTaskParseResult {
  final String title;
  final String? description;
  final DateTime? dueDate;
  final TaskPriority priority;
  final double confidence;
  final String rawTranscript;

  const VoiceTaskParseResult({
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    required this.confidence,
    required this.rawTranscript,
  });

  factory VoiceTaskParseResult.fromJson(Map<String, Object?> json) {
    final confidence = _readDouble(json['confidence']);
    if (confidence == null) {
      throw const FormatException('Voice parse response missing confidence');
    }

    return VoiceTaskParseResult(
      title: _readString(json['title']).trim(),
      description: _readNullableString(json['description'])?.trim(),
      dueDate: _readDateTime(json['due_date']),
      priority: _readPriority(json['priority']),
      confidence: confidence.clamp(0, 1).toDouble(),
      rawTranscript: _readString(json['raw_transcript']).trim(),
    );
  }

  bool get canAutoCreate =>
      title.trim().isNotEmpty &&
      confidence >= voiceTaskAutoCreateConfidenceThreshold;

  VoiceTaskParseResult copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    double? confidence,
    String? rawTranscript,
  }) {
    return VoiceTaskParseResult(
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      confidence: confidence ?? this.confidence,
      rawTranscript: rawTranscript ?? this.rawTranscript,
    );
  }
}

String _readString(Object? value) {
  if (value is String) {
    return value;
  }
  return '';
}

String? _readNullableString(Object? value) {
  if (value == null) {
    return null;
  }
  final text = _readString(value);
  return text.isEmpty ? null : text;
}

double? _readDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

DateTime? _readDateTime(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}

TaskPriority _readPriority(Object? value) {
  if (value is int) {
    return TaskPriority.fromValue(value);
  }
  if (value is num) {
    return TaskPriority.fromValue(value.toInt());
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    final intValue = int.tryParse(normalized);
    if (intValue != null) {
      return TaskPriority.fromValue(intValue);
    }
    return switch (normalized) {
      'p0' || 'urgent' => TaskPriority.p0,
      'p1' || 'high' => TaskPriority.p1,
      'p2' || 'medium' => TaskPriority.p2,
      'p3' || 'low' => TaskPriority.p3,
      _ => TaskPriority.none,
    };
  }
  return TaskPriority.none;
}
