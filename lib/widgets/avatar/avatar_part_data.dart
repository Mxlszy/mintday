import 'package:flutter/material.dart';

class AvatarShapeOption {
  const AvatarShapeOption({required this.label, required this.pixels});

  final String label;
  final List<List<int>> pixels;
}

class AvatarPartOption {
  const AvatarPartOption({
    required this.label,
    required this.pixels,
    required this.baseColor,
  });

  final String label;
  final List<List<int>> pixels;
  final Color baseColor;
}

class AvatarPartData {
  AvatarPartData._();

  static const int gridWidth = 16;
  static const int gridHeight = 24;
  static const int _headRows = 16;
  static const int _bodyStartRow = 14;
  static const String _blankRow = '.... .... .... ....';

  static const List<String> skinLabels = <String>[
    '浅肤色',
    '自然肤',
    '小麦色',
    '深肤色',
    '巧克力',
  ];

  static const List<Color> skinColors = <Color>[
    Color(0xFFFFE4CF),
    Color(0xFFF7C9A5),
    Color(0xFFE1AC7B),
    Color(0xFFB7774E),
    Color(0xFF7B4C33),
  ];

  static const List<String> bodyColorLabels = <String>[
    '云白',
    '曜黑',
    '晴蓝',
    '薄荷绿',
    '莓果红',
    '暮紫',
  ];

  static const List<Color> bodyColors = <Color>[
    Color(0xFFF4F1E8),
    Color(0xFF2E3240),
    Color(0xFF5D7FD6),
    Color(0xFF62A978),
    Color(0xFFD96D6A),
    Color(0xFF8C6ED9),
  ];

  static final List<AvatarShapeOption> faceShapes = <AvatarShapeOption>[
    AvatarShapeOption(
      label: '圆脸',
      pixels: _extendHeadMatrix(<String>[
        '.... .... .... ....',
        '.... .333 333. ....',
        '...3 3111 1113 3...',
        '..31 1111 1111 13..',
        '.311 1111 1111 113.',
        '.311 1111 1111 113.',
        '3111 1111 1111 1113',
        '3111 1111 1111 1113',
        '3111 1111 1111 1113',
        '3111 1111 1111 1113',
        '3111 1111 1111 1113',
        '.211 1111 1111 112.',
        '.221 1111 1111 122.',
        '..22 1111 1111 22..',
        '...2 2222 2222 2...',
        '.... .... .... ....',
      ]),
    ),
    AvatarShapeOption(
      label: '方脸',
      pixels: _extendHeadMatrix(<String>[
        '.... .... .... ....',
        '.... 3333 3333 ....',
        '...3 1111 1111 3...',
        '...3 1111 1111 3...',
        '..31 1111 1111 13..',
        '..31 1111 1111 13..',
        '..31 1111 1111 13..',
        '..31 1111 1111 13..',
        '..31 1111 1111 13..',
        '..31 1111 1111 13..',
        '..21 1111 1111 12..',
        '..21 1111 1111 12..',
        '..22 1111 1111 22..',
        '...2 2222 2222 2...',
        '.... 2222 2222 ....',
        '.... .... .... ....',
      ]),
    ),
    AvatarShapeOption(
      label: '瓜子脸',
      pixels: _extendHeadMatrix(<String>[
        '.... .... .... ....',
        '.... ..33 33.. ....',
        '...3 3111 1113 3...',
        '..31 1111 1111 13..',
        '..31 1111 1111 13..',
        '.311 1111 1111 113.',
        '.311 1111 1111 113.',
        '.311 1111 1111 113.',
        '..31 1111 1111 13..',
        '..31 1111 1111 13..',
        '...1 1111 1111 1...',
        '...2 1111 1111 2...',
        '.... 2111 1112 ....',
        '.... .211 112. ....',
        '.... ..22 22.. ....',
        '.... .... .... ....',
      ]),
    ),
  ];

  static final List<AvatarPartOption> hairStyles = <AvatarPartOption>[
    AvatarPartOption(
      label: '短发',
      baseColor: const Color(0xFF2E3240),
      pixels: _extendHeadMatrix(<String>[
        '.... 3333 3333 ....',
        '...3 1111 1111 3...',
        '..31 1111 1111 13..',
        '.311 1111 1111 113.',
        '.311 1111 1111 113.',
        '.... 1... ...1 ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
      ]),
    ),
    AvatarPartOption(
      label: '中分',
      baseColor: const Color(0xFF5A4237),
      pixels: _extendHeadMatrix(<String>[
        '.... 3333 3333 ....',
        '...3 1113 3111 3...',
        '..31 1113 3111 13..',
        '..31 111. .111 13..',
        '.311 11.. ..11 113.',
        '.31. .... .... .13.',
        '..1. .... .... .1..',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
      ]),
    ),
    AvatarPartOption(
      label: '马尾',
      baseColor: const Color(0xFF3E4C77),
      pixels: _extendHeadMatrix(<String>[
        '.... 3333 3333 ....',
        '...3 1111 1111 3...',
        '..31 1111 1111 13..',
        '.311 1111 1111 113.',
        '.311 1111 1111 113.',
        '..31 .... .... 13..',
        '...1 .... .... 113.',
        '.... .... .... 113.',
        '.... .... .... 13..',
        '.... .... .... 3...',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
      ]),
    ),
    AvatarPartOption(
      label: '卷发',
      baseColor: const Color(0xFF7A5946),
      pixels: _extendHeadMatrix(<String>[
        '..33 3333 3333 33..',
        '.311 1111 1111 113.',
        '3311 1111 1111 1133',
        '3111 1111 1111 1113',
        '.311 1111 1111 113.',
        '..31 .... .... 13..',
        '.3.. .... .... ..3.',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
      ]),
    ),
    AvatarPartOption(
      label: '寸头',
      baseColor: const Color(0xFF8A94A6),
      pixels: _extendHeadMatrix(<String>[
        '.... .333 333. ....',
        '...3 3111 1113 3...',
        '..31 1111 1111 13..',
        '..31 1111 1111 13..',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
      ]),
    ),
    AvatarPartOption(
      label: '帽子',
      baseColor: const Color(0xFF72AEBB),
      pixels: _extendHeadMatrix(<String>[
        '.... 3333 3333 ....',
        '...3 1111 1111 3...',
        '..31 1111 1111 13..',
        '..33 3333 3333 33..',
        '...1 1111 1111 1...',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
      ]),
    ),
  ];

  static final List<AvatarPartOption> eyeStyles = <AvatarPartOption>[
    AvatarPartOption(
      label: '圆眼',
      baseColor: const Color(0xFF1C2132),
      pixels: _extendHeadMatrix(<String>[
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .3.. ..3. ....',
        '.... .11. .11. ....',
        '.... .11. .11. ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
      ]),
    ),
    AvatarPartOption(
      label: '细长眼',
      baseColor: const Color(0xFF1C2132),
      pixels: _extendHeadMatrix(<String>[
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .33. .33. ....',
        '.... .11. .11. ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
      ]),
    ),
    AvatarPartOption(
      label: '星星眼',
      baseColor: const Color(0xFFF5C842),
      pixels: _extendHeadMatrix(<String>[
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .3.. ..3. ....',
        '.... .131 131. ....',
        '.... .3.. ..3. ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
      ]),
    ),
    AvatarPartOption(
      label: '墨镜',
      baseColor: const Color(0xFF111111),
      pixels: _extendHeadMatrix(<String>[
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... 3333 3333 ....',
        '.... 1111 1111 ....',
        '.... 2222 2222 ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
      ]),
    ),
  ];

  static final List<AvatarPartOption> mouthStyles = <AvatarPartOption>[
    AvatarPartOption(
      label: '微笑',
      baseColor: const Color(0xFFD47B87),
      pixels: _extendHeadMatrix(<String>[
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... ..3. .3.. ....',
        '.... .211 112. ....',
        '.... ..22 22.. ....',
        '.... .... .... ....',
      ]),
    ),
    AvatarPartOption(
      label: '平嘴',
      baseColor: const Color(0xFFBE6E79),
      pixels: _extendHeadMatrix(<String>[
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .222 222. ....',
        '.... .... .... ....',
        '.... .... .... ....',
      ]),
    ),
    AvatarPartOption(
      label: '惊讶',
      baseColor: const Color(0xFFC76873),
      pixels: _extendHeadMatrix(<String>[
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... ..31 13.. ....',
        '.... ..21 12.. ....',
        '.... .... .... ....',
        '.... .... .... ....',
      ]),
    ),
  ];

  static final List<AvatarPartOption> accessories = <AvatarPartOption>[
    AvatarPartOption(
      label: '无',
      baseColor: Colors.transparent,
      pixels: _emptyMatrix(),
    ),
    AvatarPartOption(
      label: '圆框眼镜',
      baseColor: const Color(0xFF667590),
      pixels: _extendHeadMatrix(<String>[
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .333 333. ....',
        '.... 31.3 3.13 ....',
        '.... .333 333. ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
      ]),
    ),
    AvatarPartOption(
      label: '腮红',
      baseColor: const Color(0xFFDF8E98),
      pixels: _extendHeadMatrix(<String>[
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... 33.. ..33 ....',
        '.... 11.. ..11 ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
      ]),
    ),
    AvatarPartOption(
      label: '耳环',
      baseColor: const Color(0xFFF5C842),
      pixels: _extendHeadMatrix(<String>[
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.... .... .... ....',
        '.3.. .... .... ..3.',
        '.1.. .... .... ..1.',
        '.2.. .... .... ..2.',
        '.... .... .... ....',
        '.... .... .... ....',
      ]),
    ),
  ];

  static final List<AvatarPartOption> bodyStyles = <AvatarPartOption>[
    AvatarPartOption(
      label: '圆领T恤',
      baseColor: bodyColors[0],
      pixels: _bodyMatrix(<String>[
        '.... 33.. ..33 ....',
        '...3 111. .111 3...',
        '..31 1111 1111 13..',
        '..31 1111 1111 13..',
        '..31 1111 1111 13..',
        '..31 1122 2211 13..',
        '..31 1111 1111 13..',
        '...1 1111 1111 1...',
        '...2 2222 2222 2...',
        '.... 2222 2222 ....',
      ]),
    ),
    AvatarPartOption(
      label: '卫衣',
      baseColor: bodyColors[0],
      pixels: _bodyMatrix(<String>[
        '...3 33.. ..33 3...',
        '..31 1133 3311 13..',
        '..31 11.. ..11 13..',
        '..31 1111 1111 13..',
        '..31 1122 2211 13..',
        '..31 1111 1111 13..',
        '..31 11.3 3.11 13..',
        '...1 1111 1111 1...',
        '...2 2111 1112 2...',
        '.... 2222 2222 ....',
      ]),
    ),
    AvatarPartOption(
      label: '衬衫',
      baseColor: bodyColors[0],
      pixels: _bodyMatrix(<String>[
        '.... 33.. ..33 ....',
        '...3 11.. ..11 3...',
        '..31 1133 3311 13..',
        '..31 1112 2111 13..',
        '..31 1113 3111 13..',
        '..31 1112 2111 13..',
        '..31 1113 3111 13..',
        '...1 1112 2111 1...',
        '...2 2222 2222 2...',
        '.... 2222 2222 ....',
      ]),
    ),
    AvatarPartOption(
      label: '夹克',
      baseColor: bodyColors[0],
      pixels: _bodyMatrix(<String>[
        '...3 3333 3333 3...',
        '..31 1111 1111 13..',
        '..31 1112 2111 13..',
        '..31 1113 3111 13..',
        '..31 2223 3222 13..',
        '..31 1113 3111 13..',
        '..31 1112 2111 13..',
        '...1 1113 3111 1...',
        '...2 2222 2222 2...',
        '.... 2222 2222 ....',
      ]),
    ),
    AvatarPartOption(
      label: '和风',
      baseColor: bodyColors[0],
      pixels: _bodyMatrix(<String>[
        '.... 33.. ..33 ....',
        '...3 111. .111 3...',
        '..31 1113 3111 13..',
        '..31 1131 1311 13..',
        '..31 1311 1131 13..',
        '..31 3111 1113 13..',
        '..31 3333 3333 13..',
        '...1 1112 2111 1...',
        '...2 2222 2222 2...',
        '.... 2222 2222 ....',
      ]),
    ),
    AvatarPartOption(
      label: '机甲',
      baseColor: bodyColors[0],
      pixels: _bodyMatrix(<String>[
        '..33 33.. ..33 33..',
        '..31 1133 3311 13..',
        '..31 1311 1131 13..',
        '..31 1112 2111 13..',
        '..31 3333 3333 13..',
        '..31 1211 1121 13..',
        '..31 1113 3111 13..',
        '...1 1222 2221 1...',
        '...2 2211 1122 2...',
        '.... 2222 2222 ....',
      ]),
    ),
  ];

  static List<List<int>> _extendHeadMatrix(List<String> headRows) {
    if (headRows.length != _headRows) {
      throw StateError('Avatar head matrix must have $_headRows rows.');
    }

    return _matrix(<String>[
      ...headRows,
      ...List<String>.filled(gridHeight - headRows.length, _blankRow),
    ]);
  }

  static List<List<int>> _bodyMatrix(List<String> bodyRows) {
    if (bodyRows.length != gridHeight - _bodyStartRow) {
      throw StateError(
        'Avatar body matrix must have ${gridHeight - _bodyStartRow} rows.',
      );
    }

    return _matrix(<String>[
      ...List<String>.filled(_bodyStartRow, _blankRow),
      ...bodyRows,
    ]);
  }

  static List<List<int>> _matrix(List<String> rows) {
    if (rows.length != gridHeight) {
      throw StateError('Avatar matrix must have $gridHeight rows.');
    }

    return List<List<int>>.unmodifiable(
      rows.map((String row) {
        final compact = row.replaceAll(' ', '');
        if (compact.length != gridWidth) {
          throw StateError('Avatar row must have $gridWidth columns: $row');
        }

        return List<int>.unmodifiable(
          compact.split('').map((String value) {
            if (value == '.') {
              return 0;
            }

            final parsed = int.tryParse(value);
            if (parsed == null || parsed < 0 || parsed > 3) {
              throw StateError('Unsupported pixel value: $value');
            }
            return parsed;
          }),
        );
      }),
    );
  }

  static List<List<int>> _emptyMatrix() {
    return List<List<int>>.unmodifiable(
      List<List<int>>.generate(
        gridHeight,
        (_) => List<int>.unmodifiable(List<int>.filled(gridWidth, 0)),
      ),
    );
  }
}
