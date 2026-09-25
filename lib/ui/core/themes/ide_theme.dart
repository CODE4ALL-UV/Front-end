import 'package:flutter/material.dart';

class CodeConsoleTheme extends ThemeExtension<CodeConsoleTheme> {
  final Color background;
  final Color border;
  final Color text;
  final Color prompt;
  final Color keyword;
  final Color string;
  final Color comment;
  final Color error;

  const CodeConsoleTheme({
    required this.background,
    required this.border,
    required this.text,
    required this.prompt,
    required this.keyword,
    required this.string,
    required this.comment,
    required this.error,
  });

  @override
  CodeConsoleTheme copyWith({Color? background}) => CodeConsoleTheme(
    background: background ?? this.background,
    border: border,
    text: text,
    prompt: prompt,
    keyword: keyword,
    string: string,
    comment: comment,
    error: error,
  );

  @override
  CodeConsoleTheme lerp(covariant CodeConsoleTheme? other, double t) {
    if (other is! CodeConsoleTheme) return this;
    return CodeConsoleTheme(
      background: Color.lerp(background, other.background, t)!,
      border: Color.lerp(border, other.border, t)!,
      text: Color.lerp(text, other.text, t)!,
      prompt: Color.lerp(prompt, other.prompt, t)!,
      keyword: Color.lerp(keyword, other.keyword, t)!,
      string: Color.lerp(string, other.string, t)!,
      comment: Color.lerp(comment, other.comment, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }
}
