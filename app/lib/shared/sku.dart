/// Builds a SHORT, readable base code from a product name, so the user doesn't
/// have to type long SKUs. Removes accents and connector words, then:
///   - one word            -> first 5 letters      ("Sandalia"        -> "SANDA")
///   - two or more words    -> 3 letters of the first + initial of the next few
///     ("Bota de cuero alto" -> "BOTCA", "Zapatilla running" -> "ZAPR")
///
/// The result is only a SUGGESTION: every form keeps the field editable, and in
/// bulk the talle is appended (e.g. "BOTCA-34"). Kept intentionally simple.
String shortSku(String name) {
  const accents = 'áàäâãéèëêíìïîóòöôõúùüûñ';
  const plain = 'aaaaaeeeeiiiiooooouuuun';
  var s = name.toLowerCase().trim();
  for (var i = 0; i < accents.length; i++) {
    s = s.replaceAll(accents[i], plain[i]);
  }

  const stop = {
    'de', 'del', 'la', 'el', 'los', 'las', 'y', 'con', 'para', 'a', 'un', 'una',
  };
  final words = s
      .split(RegExp('[^a-z0-9]+'))
      .where((w) => w.isNotEmpty && !stop.contains(w))
      .toList();
  if (words.isEmpty) return '';

  String code;
  if (words.length == 1) {
    final w = words.first;
    code = w.length <= 5 ? w : w.substring(0, 5);
  } else {
    final first = words.first;
    code = first.length <= 3 ? first : first.substring(0, 3);
    for (final w in words.skip(1).take(2)) {
      code += w[0];
    }
  }
  return code.toUpperCase();
}
