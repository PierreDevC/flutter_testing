import 'package:flutter/material.dart';
import '../core/theme.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text('Account', style: serif(32)),
            const SizedBox(height: 24),
            _buildProfileCard(),
            const SizedBox(height: 24),
            _buildSection('Preferences', [
              _tile(
                icon: Icons.notifications_none_rounded,
                label: 'Notifications',
                color: const Color(0xFF3DAA5C),
                bgColor: const Color(0xFFDCF5DC),
                trailing: Switch.adaptive(
                  value: _notifications,
                  onChanged: (v) => setState(() => _notifications = v),
                  activeTrackColor: kGreen,
                ),
              ),
              _tile(
                icon: Icons.language_outlined,
                label: 'Language',
                color: const Color(0xFF2B82D0),
                bgColor: const Color(0xFFDCEEF9),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('English', style: sans(13, color: Colors.grey[500])),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded,
                        color: Colors.grey[400], size: 18),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 16),
            _buildSection('Support', [
              _tile(
                icon: Icons.help_outline_rounded,
                label: 'Help & FAQ',
                color: const Color(0xFFD07A2B),
                bgColor: const Color(0xFFF9EEDC),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: Colors.grey[400], size: 18),
              ),
              _tile(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy Policy',
                color: Colors.grey,
                bgColor: const Color(0xFFF0F0F0),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: Colors.grey[400], size: 18),
              ),
            ]),
            const SizedBox(height: 24),
            _buildSignOutButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 34,
            backgroundColor: kGreen,
            child: Text('P',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pierre', style: sans(18, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('pierre@email.com',
                    style: sans(13, color: Colors.grey[500])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
                color: kMint, borderRadius: BorderRadius.circular(20)),
            child: Text('Edit',
                style: sans(13, weight: FontWeight.w600, color: kGreen)),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: sans(12, weight: FontWeight.w600, color: Colors.grey[500])
              .copyWith(letterSpacing: 0.8),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                items[i],
                if (i < items.length - 1)
                  const Divider(
                      height: 1, indent: 62, color: Color(0xFFF0F0F0)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _tile({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: bgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: sans(15, weight: FontWeight.w500)),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: const Color(0xFFFFF0F0),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: Text('Sign Out',
            style: sans(15,
                weight: FontWeight.w600,
                color: const Color(0xFFD32F2F))),
      ),
    );
  }
}
