import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../theme.dart';
import '../models/visitor_pass.dart';
import '../services/visitor_store.dart';

class CreateTokenScreen extends StatefulWidget {
  final bool isDark;

  const CreateTokenScreen({super.key, required this.isDark});

  @override
  State<CreateTokenScreen> createState() => _CreateTokenScreenState();
}

class _CreateTokenScreenState extends State<CreateTokenScreen> {
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saveAsFrequent = false;
  String _selectedCategory = 'Friend';
  String _selectedDuration = '24 Hours (Standard)';

  final List<String> _categories = [
    'Friend',
    'Family',
    'Delivery',
    'Service & Repairs',
    'Work'
  ];
  final List<String> _durations = [
    '24 Hours (Standard)',
    '12 Hours (Daytime)',
    '4 Hours (Quick Visit)',
    '2 Hours (Delivery)'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool _generating = false;
  Future<void> _generateToken() async {
    if (!_formKey.currentState!.validate()) return;

    if (_generating) return;
    setState(() => _generating = true);
    try {
      final name = _nameController.text.trim();
      final newPass = await VisitorStore.instance.createVisitorToken(
        visitorName: name,
        saveAsFrequent: _saveAsFrequent,
        relationship: _selectedCategory,
      );

      HapticFeedback.mediumImpact();
      if (mounted) _showSuccessDialog(newPass);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _showSuccessDialog(VisitorPass pass) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final cardBg = TokenTheme.card(isDark);
        final primaryTextColor =
            isDark ? Colors.white : const Color(0xFF111827);
        final secondaryTextColor =
            isDark ? const Color(0xFF8B949E) : const Color(0xFF6B7280);

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TokenTheme.primaryMint.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: TokenTheme.primaryMint, size: 36),
                ),
                const SizedBox(height: 12),
                Text(
                  'Visitor Token Generated!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Share this access pass with ${pass.visitorName}',
                  style: TextStyle(fontSize: 14, color: secondaryTextColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Token Display Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0D1117)
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: TokenTheme.primaryMint.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'ENTRY CODE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: TokenTheme.primaryMintDark,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pass.code.split('').join('  '),
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: primaryTextColor,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.schedule,
                              size: 14, color: secondaryTextColor),
                          const SizedBox(width: 4),
                          Text(
                            'Valid for 24 hours at the security gate',
                            style: TextStyle(
                                fontSize: 12, color: secondaryTextColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final text =
                              'Hi ${pass.visitorName}, here is your Residence gate access code: ${pass.code}. Valid for entry at the security gate.';
                          HapticFeedback.lightImpact();
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                          try {
                            await Share.share(text,
                                subject: 'Residence Access Pass');
                          } catch (e) {
                            Clipboard.setData(ClipboardData(text: text));
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Access pass for ${pass.visitorName} copied to clipboard!'),
                                  backgroundColor: TokenTheme.primaryMintDark,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.share_rounded,
                            size: 18, color: Colors.white),
                        label: const Text('Share Pass',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TokenTheme.primaryMintDark,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF21262D)
                            : const Color(0xFFE2E8F0),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        'Done',
                        style: TextStyle(
                          color: primaryTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = TokenTheme.pageBg(isDark);
    final cardBg = TokenTheme.card(isDark);
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFF8B949E) : const Color(0xFF6B7280);
    final frequentGuests = VisitorStore.instance.frequentGuests;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: primaryTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'New Visitor Token',
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
              horizontal: TokenTheme.pageSidePadding, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Select Frequent Guests
                if (frequentGuests.isNotEmpty) ...[
                  Text(
                    'FREQUENT GUESTS',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: secondaryTextColor,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: frequentGuests.map((guest) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            avatar: CircleAvatar(
                              backgroundColor:
                                  TokenTheme.primaryMint.withValues(alpha: 0.2),
                              child: Text(
                                guest.name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: TokenTheme.primaryMintDark),
                              ),
                            ),
                            label: Text(
                              guest.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: primaryTextColor,
                              ),
                            ),
                            backgroundColor: cardBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isDark
                                    ? const Color(0xFF21262D)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _nameController.text = guest.name;
                                _selectedCategory = guest.relationship;
                              });
                              HapticFeedback.selectionClick();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Guest Details Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: isDark ? 0.35 : 0.09),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Guest Full Name *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _nameController,
                        style: TextStyle(color: primaryTextColor, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'e.g. David Kalu / Amazon Delivery',
                          hintStyle: TextStyle(
                              color: secondaryTextColor, fontSize: 14),
                          prefixIcon: Icon(Icons.person_outline_rounded,
                              color: secondaryTextColor),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF0D1117)
                              : const Color(0xFFF9FAFB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter the visitor’s name';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Category / Relationship Dropdown
                      Text(
                        'Relationship / Purpose',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0D1117)
                              : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            isExpanded: true,
                            dropdownColor: cardBg,
                            icon: Icon(Icons.keyboard_arrow_down_rounded,
                                color: secondaryTextColor),
                            items: _categories.map((cat) {
                              return DropdownMenuItem(
                                value: cat,
                                child: Text(
                                  cat,
                                  style: TextStyle(
                                      color: primaryTextColor, fontSize: 14.5),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() =>
                                _selectedCategory = val ?? _selectedCategory),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Validity Duration
                      Text(
                        'Pass Duration',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0D1117)
                              : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedDuration,
                            isExpanded: true,
                            dropdownColor: cardBg,
                            icon: Icon(Icons.access_time_rounded,
                                color: secondaryTextColor, size: 20),
                            items: _durations.map((dur) {
                              return DropdownMenuItem(
                                value: dur,
                                child: Text(
                                  dur,
                                  style: TextStyle(
                                      color: primaryTextColor, fontSize: 14.5),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() =>
                                _selectedDuration = val ?? _selectedDuration),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Divider(
                          color: isDark
                              ? const Color(0xFF21262D)
                              : const Color(0xFFF1F5F9)),
                      const SizedBox(height: 8),

                      // Save as Frequent Guest Switch
                      Material(
                        color: Colors.transparent,
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Save to Frequent Guests',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: primaryTextColor,
                            ),
                          ),
                          subtitle: Text(
                            'Quick-generate passes for this guest next time',
                            style: TextStyle(
                                fontSize: 12, color: secondaryTextColor),
                          ),
                          activeTrackColor: TokenTheme.primaryMint,
                          value: _saveAsFrequent,
                          onChanged: (val) =>
                              setState(() => _saveAsFrequent = val),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _generating ? null : _generateToken,
                    icon: const Icon(Icons.key_rounded, color: Colors.white),
                    label: const Text(
                      'Generate Access Token',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TokenTheme.primaryMintDark,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
