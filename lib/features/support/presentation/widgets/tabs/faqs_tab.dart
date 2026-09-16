import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class FaqsTab extends StatelessWidget {
  const FaqsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Map<String, String>> faqs = [
      {'q': 'faq_q1', 'a': 'faq_a1'},
      {'q': 'faq_q2', 'a': 'faq_a2'},
      {'q': 'faq_q3', 'a': 'faq_a3'},
      {'q': 'faq_q4', 'a': 'faq_a4'},
      {'q': 'faq_q5', 'a': 'faq_a5'},
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121621) : theme
          .scaffoldBackgroundColor,
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: faqs.length,
        itemBuilder: (context, index) =>
            _FaqTile(question: faqs[index]['q']!, answer: faqs[index]['a']!),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: ExpansionTile(
            iconColor: theme.hintColor,
            collapsedIconColor: theme.hintColor,
            tilePadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 4),
            title: Text(
              question.tr(),
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  answer.tr(),
                  style: TextStyle(
                    color: theme.hintColor,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}