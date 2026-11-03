import 'dart:async';

import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/widgets/animated_column.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_dialog.dart';
import 'package:globetrottr_front/core/widgets/neu_list_card.dart';
import 'package:globetrottr_front/core/widgets/neu_list_row.dart';
import 'package:globetrottr_front/core/widgets/neu_primary_button.dart';
import 'package:globetrottr_front/core/widgets/neu_text_field.dart';
import 'package:globetrottr_front/core/widgets/section_header.dart';
import 'package:globetrottr_front/debug/animations/demo_section.dart';
import 'package:globetrottr_front/features/auth/screens/widgets/password_rules_checklist.dart';
import 'package:globetrottr_front/features/map/screens/widgets/map_status_pill.dart';

class MapPillDemo extends StatefulWidget {
  const MapPillDemo({super.key});

  @override
  State<MapPillDemo> createState() => _MapPillDemoState();
}

class _MapPillDemoState extends State<MapPillDemo> {
  bool _recording = false;
  double _newArea = 0;

  @override
  Widget build(BuildContext context) => DemoSection(
    title: 'Map pill: start and stop the walk',
    controls: {'+0.05 km²': () => setState(() => _newArea += 0.05)},
    child: MapStatusPillView(
      share: 0.42,
      regionName: 'Kazimierz',
      newArea: _newArea,
      recording: _recording,
      onRecord: () => setState(() => _recording = !_recording),
    ),
  );
}

class ListRowsDemo extends StatefulWidget {
  const ListRowsDemo({super.key});

  @override
  State<ListRowsDemo> createState() => _ListRowsDemoState();
}

class _ListRowsDemoState extends State<ListRowsDemo> {
  List<int> _rows = [1, 2, 3];
  int _next = 4;

  @override
  Widget build(BuildContext context) => DemoSection(
    title: 'List rows coming and going',
    controls: {
      'Add': () => setState(() => _rows = [..._rows, _next++]),
      'Remove 2nd': () => setState(
        () => _rows = [
          for (var i = 0; i < _rows.length; i++)
            if (i != 1) _rows[i],
        ],
      ),
    },
    child: NeuListCard(
      rows: [
        for (final row in _rows)
          NeuListRow(
            key: ValueKey(row),
            leading: const AppIcon(AppIcons.pin),
            title: 'Row $row',
          ),
      ],
    ),
  );
}

/// Sections that arrive with the data, as on the Friends and Quests tabs.
class DataLoadDemo extends StatefulWidget {
  const DataLoadDemo({super.key});

  @override
  State<DataLoadDemo> createState() => _DataLoadDemoState();
}

class _DataLoadDemoState extends State<DataLoadDemo> {
  static const _loading = Duration(milliseconds: 600);

  bool _loaded = true;
  Timer? _arrival;

  void _reload() {
    _arrival?.cancel();
    setState(() => _loaded = false);
    _arrival = Timer(_loading, () {
      if (mounted) setState(() => _loaded = true);
    });
  }

  @override
  void dispose() {
    _arrival?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DemoSection(
    title: 'Data arriving',
    controls: {'Load again': _reload},
    child: AnimatedColumn(
      spacing: 16,
      appearing: !_loaded,
      children: [
        const Text('Friends', key: ValueKey('title')),
        if (_loaded) ...[
          const SectionHeader('This week', key: ValueKey('week')),
          const NeuListCard(
            key: ValueKey('list'),
            rows: [
              NeuListRow(
                key: ValueKey('ola'),
                leading: AppIcon(AppIcons.pin),
                title: 'ola',
              ),
              NeuListRow(
                key: ValueKey('kuba'),
                leading: AppIcon(AppIcons.pin),
                title: 'kuba',
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

class PasswordDemo extends StatefulWidget {
  const PasswordDemo({super.key});

  @override
  State<PasswordDemo> createState() => _PasswordDemoState();
}

class _PasswordDemoState extends State<PasswordDemo> {
  String _password = '';

  @override
  Widget build(BuildContext context) => DemoSection(
    title: 'Password rules',
    child: Column(
      spacing: 14,
      children: [
        NeuTextField(
          placeholder: 'Type a password',
          onChanged: (value) => setState(() => _password = value),
        ),
        PasswordRulesChecklist(password: _password),
      ],
    ),
  );
}

class DialogDemo extends StatelessWidget {
  const DialogDemo({super.key});

  @override
  Widget build(BuildContext context) => DemoSection(
    title: 'Dialog',
    child: NeuPrimaryButton(
      label: 'Open a dialog',
      onPressed: () => showNeuDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('A dialog'),
          content: const Text('It grows a little while it fades in.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    ),
  );
}
