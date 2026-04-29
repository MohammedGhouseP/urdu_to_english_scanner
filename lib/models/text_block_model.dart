import 'package:uuid/uuid.dart';

enum TextBlockType { paragraph, heading, verse }

TextBlockType _typeFromString(String? s) {
  switch (s) {
    case 'heading':
      return TextBlockType.heading;
    case 'verse':
      return TextBlockType.verse;
    default:
      return TextBlockType.paragraph;
  }
}

String _typeToString(TextBlockType t) => t.name;

class TextBlock {
  TextBlock({
    String? id,
    this.urduContent = '',
    this.romanContent = '',
    this.confidence = 1.0,
    this.isEdited = false,
    this.type = TextBlockType.paragraph,
  }) : id = id ?? const Uuid().v4();

  final String id;
  String urduContent;
  String romanContent;
  double confidence;
  bool isEdited;
  TextBlockType type;

  TextBlock copyWith({
    String? urduContent,
    String? romanContent,
    double? confidence,
    bool? isEdited,
    TextBlockType? type,
  }) {
    return TextBlock(
      id: id,
      urduContent: urduContent ?? this.urduContent,
      romanContent: romanContent ?? this.romanContent,
      confidence: confidence ?? this.confidence,
      isEdited: isEdited ?? this.isEdited,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'urduContent': urduContent,
        'romanContent': romanContent,
        'confidence': confidence,
        'isEdited': isEdited,
        'type': _typeToString(type),
      };

  factory TextBlock.fromJson(Map<String, dynamic> json) => TextBlock(
        id: json['id'] as String?,
        urduContent: json['urduContent'] as String? ?? '',
        romanContent: json['romanContent'] as String? ?? '',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
        isEdited: json['isEdited'] as bool? ?? false,
        type: _typeFromString(json['type'] as String?),
      );
}
