import '../domain/task.dart';

const double voiceTaskAutoCreateConfidenceThreshold = 0.75;

/// Structured output returned by the voice-task backend proxy.
class VoiceTaskParseResult {
  final String title;
  final String? description;
  final DateTime? dueDate;
  final bool isAllDay;
  final TaskPriority priority;
  final double confidence;
  final String rawTranscript;
  final String? tag;

  const VoiceTaskParseResult({
    required this.title,
    required this.description,
    required this.dueDate,
    this.isAllDay = false,
    required this.priority,
    required this.confidence,
    required this.rawTranscript,
    this.tag,
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
      isAllDay: _readBool(json['is_all_day']),
      priority: _readPriority(json['priority']),
      confidence: confidence.clamp(0, 1).toDouble(),
      rawTranscript: _readString(json['raw_transcript']).trim(),
      tag: _readNullableTag(json['tag']),
    );
  }

  bool get canAutoCreate =>
      title.trim().isNotEmpty &&
      confidence >= voiceTaskAutoCreateConfidenceThreshold;

  VoiceTaskParseResult copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isAllDay,
    TaskPriority? priority,
    double? confidence,
    String? rawTranscript,
    String? tag,
  }) {
    return VoiceTaskParseResult(
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isAllDay: isAllDay ?? this.isAllDay,
      priority: priority ?? this.priority,
      confidence: confidence ?? this.confidence,
      rawTranscript: rawTranscript ?? this.rawTranscript,
      tag: tag ?? this.tag,
    );
  }
}

String? _readNullableTag(Object? value) {
  final text = _readNullableString(value);
  if (text == null) return null;
  final normalized = text.trim().toLowerCase();
  if (normalized == 'work' || normalized == '工作') return 'work';
  if (normalized == 'life' || normalized == '生活') return 'life';
  return null;
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

bool _readBool(Object? value) {
  if (value is bool) return value;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }
  return false;
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
