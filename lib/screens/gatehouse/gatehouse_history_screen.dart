import '../../theme.dart';
import 'package:flutter/material.dart';
import '../../services/gatehouse_store.dart';
import '../../models/gate_log_model.dart';

class GatehouseHistoryScreen extends StatefulWidget {
  final bool isDark;

  const GatehouseHistoryScreen({super.key, required this.isDark});

  @override
  State<GatehouseHistoryScreen> createState() => _GatehouseHistoryScreenState();
}

class _GatehouseHistoryScreenState extends State<GatehouseHistoryScreen> {
  @override
  void initState() {
    super.initState();
    GatehouseStore.instance.refreshHistory();
  }

  int _selectedFilter = 0; // 0: All, 1: Entries, 2: Exits, 3: Denied
  String _searchQuery = '';

  void _showLogDetail(BuildContext context, GateLogEntry log, bool isDark) {
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF161E2E) : Colors.white;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (log.isEntry
                                ? const Color(0xFF10B981)
                                : (log.isExit
                                    ? const Color(0xFF0284C7)
                                    : const Color(0xFFEF4444)))
                            .withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        log.isEntry
                            ? Icons.login_rounded
                            : (log.isExit
                                ? Icons.logout_rounded
                                : Icons.block_rounded),
                        color: log.isEntry
                            ? const Color(0xFF10B981)
                            : (log.isExit
                                ? const Color(0xFF0284C7)
                                : const Color(0xFFEF4444)),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.actionLabel,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: log.isEntry
                                ? const Color(0xFF10B981)
                                : (log.isExit
                                    ? const Color(0xFF0284C7)
                                    : const Color(0xFFEF4444)),
                          ),
                        ),
                        Text(
                          'Log ID: ${log.id}',
                          style: TextStyle(
                              fontSize: 12, color: secondaryTextColor),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildRow('Visitor Name', log.visitorName, primaryTextColor,
                    secondaryTextColor),
                _buildRow('Pass / OTP Code', '#${log.code}',
                    const Color(0xFF0D9488), secondaryTextColor),
                _buildRow('Host Resident', log.hostResident, primaryTextColor,
                    secondaryTextColor),
                _buildRow('Host Unit', log.hostUnit, primaryTextColor,
                    secondaryTextColor),
                _buildRow('Gate Location', log.gateLocation, primaryTextColor,
                    secondaryTextColor),
                _buildRow('Duty Officer', log.officerName, primaryTextColor,
                    secondaryTextColor),
                _buildRow('Verification Method', log.verificationMethod,
                    primaryTextColor, secondaryTextColor),
                _buildRow(
                  'Timestamp',
                  '${log.timestamp.day}/${log.timestamp.month}/${log.timestamp.year} • ${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                  primaryTextColor,
                  secondaryTextColor,
                ),
                if (log.denialReason != null)
                  _buildRow('Denial Reason', log.denialReason!,
                      const Color(0xFFEF4444), secondaryTextColor),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Done',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRow(
      String label, String value, Color valueColor, Color labelColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: labelColor,
                  fontWeight: FontWeight.w500)),
          Text(value,
              style: TextStyle(
                  fontSize: 13.5,
                  color: valueColor,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0B0F17) : const Color(0xFFF4F6F9);
    final cardBg = isDark ? const Color(0xFF161E2E) : Colors.white;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor =
        isDark ? const Color(0xFF26334D) : const Color(0xFFE2E8F0);

    return AnimatedBuilder(
      animation: GatehouseStore.instance,
      builder: (context, _) {
        final allLogs = GatehouseStore.instance.logs;

        final filteredLogs = allLogs.where((log) {
          if (_selectedFilter == 1 && !log.isEntry) return false;
          if (_selectedFilter == 2 && !log.isExit) return false;
          if (_selectedFilter == 3 && !log.isDenied) return false;

          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            return log.visitorName.toLowerCase().contains(q) ||
                log.hostResident.toLowerCase().contains(q) ||
                log.hostUnit.toLowerCase().contains(q) ||
                log.code.toLowerCase().contains(q);
          }
          return true;
        }).toList();

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
            elevation: 0,
            title: Text(
              '24-Hour Gate Logs',
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: borderColor, height: 1),
            ),
          ),
          body: SafeArea(
              child: RefreshIndicator(
            onRefresh: GatehouseStore.instance.refreshHistory,
            child: ListView(
              padding: const EdgeInsets.symmetric(
                  horizontal: TokenTheme.pageSidePadding, vertical: 14),
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              children: [
                if (GatehouseStore.instance.historyError != null)
                  Text(GatehouseStore.instance.historyError!,
                      style: const TextStyle(color: Colors.red)),
                // Search Bar
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search logs by visitor, unit, or code...',
                    hintStyle:
                        TextStyle(fontSize: 13, color: secondaryTextColor),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: secondaryTextColor, size: 20),
                    filled: true,
                    fillColor: cardBg,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderColor),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                          'All Logs (${allLogs.length})', 0, isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                          'Entries (${GatehouseStore.instance.todayEntriesCount})',
                          1,
                          isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                          'Exits (${GatehouseStore.instance.todayExitsCount})',
                          2,
                          isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                          'Denied (${GatehouseStore.instance.todayDeniedCount})',
                          3,
                          isDark),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Audit Trail Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'LOG AUDIT TRAIL (${filteredLogs.length})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: secondaryTextColor,
                      ),
                    ),
                    const Text(
                      'Last 24 Hours',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0D9488),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                if (filteredLogs.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: borderColor),
                    ),
                    child: Center(
                      child: Text(
                        'No gate access logs matching the selected filter',
                        style:
                            TextStyle(color: secondaryTextColor, fontSize: 13),
                      ),
                    ),
                  )
                else
                  ...filteredLogs.map((log) {
                    final color = log.isEntry
                        ? const Color(0xFF10B981)
                        : (log.isExit
                            ? const Color(0xFF0284C7)
                            : const Color(0xFFEF4444));

                    final timeStr =
                        '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.2 : 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showLogDetail(context, log, isDark),
                          borderRadius: BorderRadius.circular(18),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    log.isEntry
                                        ? Icons.login_rounded
                                        : (log.isExit
                                            ? Icons.logout_rounded
                                            : Icons.block_rounded),
                                    color: color,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              log.visitorName,
                                              style: TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.bold,
                                                color: primaryTextColor,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color:
                                                  color.withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              log.actionLabel,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                                color: color,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Host: ${log.hostResident} • ${log.hostUnit}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: secondaryTextColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Token #${log.code} • ${log.gateLocation.split('(').first.trim()}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF0D9488),
                                            ),
                                          ),
                                          Text(
                                            timeStr,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: secondaryTextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 24),
              ],
            ),
          )),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, int index, bool isDark) {
    final isSelected = _selectedFilter == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0D9488)
              : (isDark ? const Color(0xFF161E2E) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0D9488)
                : (isDark ? const Color(0xFF26334D) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }
}
