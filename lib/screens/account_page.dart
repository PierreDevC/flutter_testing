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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;
        
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isWide ? 40 : 20, vertical: isWide ? 40 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Account', style: serif(isWide ? 44 : 32, weight: FontWeight.w700)),
                const SizedBox(height: 32),
                
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildProfileCard(isWide: true)),
                      const SizedBox(width: 40),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
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
                                    Text('English', style: sans(14, color: Colors.grey[500])),
                                    const SizedBox(width: 4),
                                    Icon(Icons.chevron_right_rounded,
                                        color: Colors.grey[400], size: 20),
                                  ],
                                ),
                              ),
                            ]),
                            const SizedBox(height: 32),
                            _buildSection('Support', [
                              _tile(
                                icon: Icons.help_outline_rounded,
                                label: 'Help & FAQ',
                                color: const Color(0xFFD07A2B),
                                bgColor: const Color(0xFFF9EEDC),
                                trailing: Icon(Icons.chevron_right_rounded,
                                    color: Colors.grey[400], size: 20),
                                onTap: () {},
                              ),
                              _tile(
                                icon: Icons.privacy_tip_outlined,
                                label: 'Privacy Policy',
                                color: Colors.grey,
                                bgColor: const Color(0xFFF0F0F0),
                                trailing: Icon(Icons.chevron_right_rounded,
                                    color: Colors.grey[400], size: 20),
                                onTap: () {},
                              ),
                            ]),
                            const SizedBox(height: 40),
                            _buildSignOutButton(),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildProfileCard(isWide: false),
                      const SizedBox(height: 32),
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
                      const SizedBox(height: 24),
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
                      const SizedBox(height: 40),
                      _buildSignOutButton(),
                    ],
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildProfileCard({required bool isWide}) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: EdgeInsets.all(isWide ? 32 : 24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 44,
              backgroundColor: kGreen,
              child: Text('P',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 20),
            Text('Pierre', style: sans(22, weight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('pierre@email.com',
                style: sans(15, color: Colors.grey[500])),
            const SizedBox(height: 24),
            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                    color: kMint, borderRadius: BorderRadius.circular(20)),
                child: Text('Edit Profile',
                    style: sans(14, weight: FontWeight.w600, color: kGreen)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: sans(13, weight: FontWeight.w700, color: Colors.grey[500])
                .copyWith(letterSpacing: 1.2),
          ),
        ),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                items[i],
                if (i < items.length - 1)
                  const Divider(
                      height: 1, indent: 70, color: Color(0xFFF0F0F0)),
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
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: bgColor, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(label, style: sans(16, weight: FontWeight.w600)),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: const Color(0xFFFFF0F0),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        child: Text('Sign Out',
            style: sans(16,
                weight: FontWeight.w700,
                color: const Color(0xFFD32F2F))),
      ),
    );
  }
}
