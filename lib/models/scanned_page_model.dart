import 'package:uuid/uuid.dart';

import 'text_block_model.dart';

class ScannedPage {
  ScannedPage({
    String? id,
    required this.imagePath,
    this.urduText = '',
    this.romanEnglishText = '',
    this.isApproved = false,
    this.pageNumber = 1,
    List<TextBlock>? textBlocks,
  })  : id = id ?? const Uuid().v4(),
        textBlocks = textBlocks ?? <TextBlock>[];

  final String id;
  String imagePath;
  String urduText;
  String romanEnglishText;
  bool isApproved;
  int pageNumber;
  List<TextBlock> textBlocks;

  Map<String, dynamic> toJson() => {
        'id': id,
        'imagePath': imagePath,
        'urduText': urduText,
        'romanEnglishText': romanEnglishText,
        'isApproved': isApproved,
        'pageNumber': pageNumber,
        'textBlocks': textBlocks.map((b) => b.toJson()).toList(),
      };

  factory ScannedPage.fromJson(Map<String, dynamic> json) => ScannedPage(
        id: json['id'] as String?,
        imagePath: json['imagePath'] as String? ?? '',
        urduText: json['urduText'] as String? ?? '',
        romanEnglishText: json['romanEnglishText'] as String? ?? '',
        isApproved: json['isApproved'] as bool? ?? false,
        pageNumber: json['pageNumber'] as int? ?? 1,
        textBlocks: (json['textBlocks'] as List<dynamic>? ?? [])
            .map((e) => TextBlock.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
