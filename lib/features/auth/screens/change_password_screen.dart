import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// Change Password screen – lock illustration, subtitle,
/// three password fields (current, new, confirm) with visibility
/// toggles, and a midBlue "Change Password" button.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // ═══════════════════════════════════
                // Back button + title
                // ═══════════════════════════════════
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const SizedBox(
                          width: 24,
                          height: 24,
                          child: Icon(
                            IconsaxPlusLinear.arrow_left,
                            size: 24,
                            color: Color(0xFF3D3D3D),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Change Password',
                            style: TextStyle(fontFamily: AppFonts.inter, 
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                ),

                // ═══════════════════════════════════
                // Scrollable content
                // ═══════════════════════════════════
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),

                        // ── Lock illustration placeholder ──
                        Container(
                          width: 137,
                          height: 139,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Center(
                            child: Icon(
                              IconsaxPlusLinear.lock_1,
                              size: 56,
                              color: Color(0xFF123A72),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Subtitle ──
                        SizedBox(
                          width: 217,
                          child: Text(
                            'For your security, please choose a strong new password.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: AppFonts.inter, 
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              height: 15 / 12,
                              color: const Color(0xFF3D3D3D),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // ── Current Password ──
                        _buildPasswordField(
                          label: 'Current Password',
                          placeholder: 'Enter current password',
                          controller: _currentController,
                          obscure: _obscureCurrent,
                          onToggle: () => setState(
                              () => _obscureCurrent = !_obscureCurrent),
                        ),
                        const SizedBox(height: 20),

                        // ── New Password ──
                        _buildPasswordField(
                          label: 'New Password',
                          placeholder: 'Enter new password',
                          controller: _newController,
                          obscure: _obscureNew,
                          onToggle: () =>
                              setState(() => _obscureNew = !_obscureNew),
                        ),
                        const SizedBox(height: 20),

                        // ── Confirm New Password ──
                        _buildPasswordField(
                          label: 'Confirm New Password',
                          placeholder: 'Re-enter new password',
                          controller: _confirmController,
                          obscure: _obscureConfirm,
                          onToggle: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),

                // ═══════════════════════════════════
                // Change Password button (pinned bottom)
                // ═══════════════════════════════════
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF123A72),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Center(
                        child: Text(
                          'Change Password',
                          style: TextStyle(fontFamily: AppFonts.inter, 
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Password field with visibility toggle
  // ═══════════════════════════════════════════════
  Widget _buildPasswordField({
    required String label,
    required String placeholder,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontFamily: AppFonts.inter, 
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF4F4F4F),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFC6C6C6)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  style: TextStyle(fontFamily: AppFonts.inter, 
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1F1F1F),
                  ),
                  decoration: InputDecoration(
                    hintText: placeholder,
                    hintStyle: TextStyle(fontFamily: AppFonts.inter, 
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6D6D6D),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Icon(
                    obscure
                        ? IconsaxPlusLinear.eye_slash
                        : IconsaxPlusLinear.eye,
                    size: 20,
                    color: const Color(0xFF6D6D6D),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
