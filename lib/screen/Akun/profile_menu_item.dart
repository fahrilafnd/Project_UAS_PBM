import 'package:flutter/material.dart';

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green,
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(label, style: const TextStyle(fontSize: 18)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
