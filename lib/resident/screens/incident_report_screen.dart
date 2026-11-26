import 'package:flutter/material.dart';
import 'package:estate/resident/data/visitor_api.dart';
import 'package:estate/shared/sos/sos_center_screen.dart';
import 'package:estate/shared/ui/theme.dart';
import 'package:estate/shared/ui/widgets/incident_report_widget.dart';

Future<List<Map<String, dynamic>>> loadIncidentReports() async {
  final data = await VisitorApi.request('reports?limit=50') as Map;
  return List<Map<String, dynamic>>.from(data['reports'] as List);
}

Future<void> submitIncidentReport(Map<String, dynamic> body) =>
    VisitorApi.request('reports', body: body);

/// Lets any estate member report an incident to the caretaker and follow its status.
class IncidentReportScreen extends StatefulWidget {
  final ReportLoader load;
  final ReportSubmitter submit;

  const IncidentReportScreen({
    super.key,
    this.load = loadIncidentReports,
    this.submit = submitIncidentReport,
  });

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  final _reportKey = GlobalKey<IncidentReportWidgetState>();

  void _openSosCenter() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SosCenterScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report an incident'),
        actions: [
          IconButton(
            tooltip: 'SOS & emergencies',
            icon: const Icon(Icons.sos),
            onPressed: _openSosCenter,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              _reportKey.currentState?.refresh() ?? Future<void>.value(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: TokenTheme.pageSidePadding,
              vertical: 24,
            ),
            child: IncidentReportWidget(
              key: _reportKey,
              load: widget.load,
              submit: widget.submit,
            ),
          ),
        ),
      ),
    );
  }
}
