import 'package:flutter/material.dart';

const Color navy = Color(0xFF04142A);
const Color navy2 = Color(0xFF071C38);
const Color gold = Color(0xFFFFBC12);
const Color purple = Color(0xFF7A2CE8);
const Color borderBlue = Color(0xFF164879);

class NeonPanel extends StatelessWidget {
  const NeonPanel({
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.color = navy,
    this.borderColor = borderBlue,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.97),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: borderColor.withOpacity(0.12),
            blurRadius: 16,
          ),
        ],
      ),
      child: child,
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 72, color: gold),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          SizedBox(
            width: 520,
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Color(0xFFB9C8DB)),
            ),
          ),
          if (action != null) ...<Widget>[
            const SizedBox(height: 24),
            action!,
          ],
        ],
      ),
    );
  }
}

ButtonStyle goldButtonStyle() {
  return FilledButton.styleFrom(
    backgroundColor: gold,
    foregroundColor: Colors.black,
    padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 20),
    textStyle: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );
}

ButtonStyle purpleButtonStyle() {
  return FilledButton.styleFrom(
    backgroundColor: purple,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );
}
