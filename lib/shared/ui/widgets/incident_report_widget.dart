import 'package:flutter/material.dart';
import 'package:estate/shared/ui/widgets/auth_layout.dart';

typedef ReportLoader = Future<List<Map<String, dynamic>>> Function();
typedef ReportSubmitter = Future<void> Function(Map<String, dynamic> body);

/// Reusable incident report form and report history.
///
/// Kept in `shared/` so both the report screen and the SOS screen can host it
/// without either app module depending on the other.
class IncidentReportWidget extends StatefulWidget {
  final ReportLoader load;
  final ReportSubmitter submit;
  final bool showHeading;

  const IncidentReportWidget({
    super.key,
    required this.load,
    required this.submit,
    this.showHeading = true,
  });

  @override
  IncidentReportWidgetState createState() => IncidentReportWidgetState();
}

class IncidentReportWidgetState extends State<IncidentReportWidget> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _description = TextEditingController();
  String _severity = 'low';
  bool _anonymous = false, _busy = false, _loading = true;
  String? _error, _listError;
  List<Map<String, dynamic>> _reports = const [];

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  void dispose() {
    for (final c in [_title, _location, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  Future<void> refresh() async {
    setState(() {
      _loading = true;
      _listError = null;
    });
    try {
      final reports = await widget.load();
      if (!mounted) return;
      setState(() => _reports = reports);
    } on Exception catch (e) {
      if (mounted) setState(() => _listError = _message(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.submit({
        'title': _title.text.trim(),
        'location': _location.text.trim(),
        'description': _description.text.trim(),
        'severity': _severity,
        'is_anonymous': _anonymous,
      });
      if (!mounted) return;
      _form.currentState!.reset();
      for (final c in [_title, _location, _description]) {
        c.clear();
      }
      setState(() {
        _severity = 'low';
        _anonymous = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Report sent to your estate caretaker.')));
      await refresh();
    } on Exception catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _required(String? v, int min, String label) =>
      v == null || v.trim().length < min
          ? '$label needs at least $min characters'
          : null;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeading) ...[
          Text('What happened?', style: text.titleLarge),
          const SizedBox(height: 8),
          const Text(
              'Your caretaker is notified and you will see status updates here and in your inbox. For emergencies, use the SOS alarm.',
              style: TextStyle(fontSize: 13)),
          const SizedBox(height: 20),
        ] else
          const SizedBox(height: 4),
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                  controller: _title,
                  enabled: !_busy,
                  maxLength: 120,
                  decoration:
                      authInput('Short title', Icons.report_outlined),
                  validator: (v) => _required(v, 3, 'Title')),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _location,
                  enabled: !_busy,
                  maxLength: 200,
                  decoration:
                      authInput('Location', Icons.location_on_outlined),
                  validator: (v) => _required(v, 2, 'Location')),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _description,
                  enabled: !_busy,
                  maxLength: 2000,
                  minLines: 3,
                  maxLines: 6,
                  decoration: authInput('Details', Icons.notes_outlined),
                  validator: (v) => _required(v, 10, 'Details')),
              const SizedBox(height: 12),
              Text('Severity', style: text.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'low', label: Text('Low')),
                  ButtonSegment(value: 'medium', label: Text('Medium')),
                  ButtonSegment(value: 'high', label: Text('High')),
                ],
                selected: {_severity},
                onSelectionChanged: _busy
                    ? null
                    : (s) => setState(() => _severity = s.first),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Hide my name from the caretaker'),
                value: _anonymous,
                onChanged:
                    _busy ? null : (v) => setState(() => _anonymous = v),
              ),
              const SizedBox(height: 12),
              if (_error != null) AuthError(_error!),
              FilledButton(
                  onPressed: _busy ? null : _send,
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52)),
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Send report')),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text('Your reports', style: text.titleLarge),
        const SizedBox(height: 12),
        if (_loading)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator()))
        else if (_listError != null)
          Text(_listError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error))
        else if (_reports.isEmpty)
          const Text('You have not reported any incidents yet.')
        else
          ..._reports.map((r) => Card(
                child: ListTile(
                  title: Text('${r['title']}'),
                  subtitle: Text([
                    '${r['location']}',
                    if (r['resolution_note'] != null)
                      'Caretaker: ${r['resolution_note']}',
                  ].join('\n')),
                  isThreeLine: r['resolution_note'] != null,
                  trailing: Chip(label: Text('${r['status']}')),
                ),
              )),
      ],
    );
  }
}
