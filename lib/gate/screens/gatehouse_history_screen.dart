import 'package:estate/gate/models/gate_log_model.dart';
import 'package:estate/gate/state/gatehouse_store.dart';
import 'package:estate/gate/ui/gate_style.dart';
import 'package:estate/shared/ui/theme.dart';
import 'package:flutter/material.dart';

class GatehouseHistoryScreen extends StatefulWidget {
  final bool isDark;

  const GatehouseHistoryScreen({super.key, required this.isDark});

  @override
  State<GatehouseHistoryScreen> createState() => _GatehouseHistoryScreenState();
}

class _GatehouseHistoryScreenState extends State<GatehouseHistoryScreen> {
  final _store = GatehouseStore.instance;
  int _selectedFilter = 0;
  String _searchQuery = '';
  bool _initialLoad = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _store.refreshHistory();
    if (mounted && _initialLoad) setState(() => _initialLoad = false);
  }

  String _label(GateLogEntry log) {
    final label = log.actionLabel.toLowerCase();
    return label[0].toUpperCase() + label.substring(1);
  }

  Color _color(GateLogEntry log, GatePalette palette) {
    if (log.isEntry) return palette.accent;
    if (log.isExit) return palette.info;
    return palette.danger;
  }

  IconData _icon(GateLogEntry log) {
    if (log.isEntry) return Icons.login;
    if (log.isExit) return Icons.logout;
    if (log.isEmergency) return Icons.emergency_outlined;
    return Icons.block;
  }

  void _showLogDetail(GateLogEntry log, GatePalette palette) {
    final label = _label(log);
    final icon = _icon(log);
    final color = _color(log, palette);
    final localizations = MaterialLocalizations.of(context);
    final timestamp = log.timestamp;
    final time = TimeOfDay.fromDateTime(timestamp).format(context);

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: palette.surface,
      sheetAnimationStyle: AnimationStyle.noAnimation,
      builder: (context) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                  alignment: Alignment.centerLeft,
                  child: GateIcon(icon, color)),
              const SizedBox(height: 10),
              Text(log.visitorName,
                  style: TextStyle(
                      color: palette.ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Align(
                  alignment: Alignment.centerLeft,
                  child: GateStatus(label, color)),
              const SizedBox(height: 12),
              for (final field in {
                'Log ID': log.id,
                'Token': log.code,
                'Host resident': log.hostResident,
                'Host unit': log.hostUnit,
                'Gate location': log.gateLocation,
                'Duty officer': log.officerName,
                'Verification method': log.verificationMethod,
                'Timestamp':
                    '${localizations.formatMediumDate(timestamp)} · $time',
                if (log.denialReason != null)
                  'Denial reason': log.denialReason!,
              }.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: Text(field.key,
                              style: TextStyle(color: palette.muted))),
                      const SizedBox(width: 16),
                      Expanded(
                          child: Text(field.value,
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                  color: palette.ink,
                                  fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: palette.action,
                    foregroundColor: palette.dark ? TokenTheme.darkBg : Colors.white,
                    minimumSize: const Size(0, 48)),
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = GatePalette.of(context);
    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: gateHeader(context, 'Gate history', subtitle: 'Last 24 hours'),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _store,
          builder: (context, _) {
            final logs = _store.logs;
            final query = _searchQuery.trim().toLowerCase();
            final matches = logs.where((log) {
              if (_selectedFilter == 1 && !log.isEntry) return false;
              if (_selectedFilter == 2 && !log.isExit) return false;
              if (_selectedFilter == 3 && !log.isDenied) return false;
              return [log.visitorName, log.hostResident, log.hostUnit, log.code]
                  .any((value) => value.toLowerCase().contains(query));
            }).toList();
            final filters = [
              'All (${logs.length})',
              'Entries (${_store.todayEntriesCount})',
              'Exits (${_store.todayExitsCount})',
              'Denied (${_store.todayDeniedCount})',
            ];

            return RefreshIndicator(
              color: palette.accent,
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(TokenTheme.pageSidePadding,
                    16, TokenTheme.pageSidePadding, 96),
                children: [
                  TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: TextStyle(color: palette.ink),
                    decoration: InputDecoration(
                      labelText: 'Search gate logs',
                      hintText: 'Visitor, host, unit or token',
                      labelStyle: TextStyle(color: palette.muted),
                      prefixIcon: Icon(Icons.search, color: palette.muted),
                      filled: true,
                      fillColor: palette.surface,
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: palette.line)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: palette.accent, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (var i = 0; i < filters.length; i++)
                        ChoiceChip(
                          label: Text(filters[i]),
                          selected: _selectedFilter == i,
                          onSelected: (_) =>
                              setState(() => _selectedFilter = i),
                          backgroundColor: palette.surface,
                          selectedColor: palette.tint,
                          checkmarkColor: palette.accent,
                          labelStyle: TextStyle(color: palette.ink),
                          side: BorderSide(
                              color: _selectedFilter == i
                                  ? palette.accent
                                  : palette.line),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_store.historyError != null)
                    Container(
                      decoration: palette.panel(),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_store.historyError!,
                              style: TextStyle(color: palette.danger)),
                          TextButton(
                              onPressed: _load, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  if (_initialLoad)
                    LinearProgressIndicator(color: palette.accent)
                  else if (matches.isEmpty && _store.historyError == null)
                    GateEmptyState(
                        Icons.history,
                        query.isEmpty && _selectedFilter == 0
                            ? 'No gate activity in the last 24 hours.'
                            : 'No logs match your search or filter.')
                  else
                    for (final log in matches) _logTile(log, palette),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _logTile(GateLogEntry log, GatePalette palette) {
    final label = _label(log);
    final icon = _icon(log);
    final color = _color(log, palette);
    final time = TimeOfDay.fromDateTime(log.timestamp).format(context);
    final gate = log.gateLocation.split('(').first.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        shape: RoundedRectangleBorder(
            side: BorderSide(color: palette.line),
            borderRadius: BorderRadius.circular(12)),
        color: palette.surface,
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          onTap: () => _showLogDetail(log, palette),
          leading: GateIcon(icon, color),
          title: Text(log.visitorName,
              style:
                  TextStyle(color: palette.ink, fontWeight: FontWeight.w700)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${log.hostResident} · ${log.hostUnit}',
                  style: TextStyle(color: palette.muted)),
              Text('#${log.code} · $gate · $time',
                  style: TextStyle(color: palette.muted)),
              const SizedBox(height: 6),
              GateStatus(label, color),
            ],
          ),
          trailing: Icon(Icons.chevron_right, color: palette.muted),
        ),
      ),
    );
  }
}
