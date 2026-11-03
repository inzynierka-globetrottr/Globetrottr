import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/measure_format.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/animated_number.dart';
import 'package:globetrottr_front/core/widgets/progress_ring.dart';
import 'package:globetrottr_front/debug/animations/demo_section.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_route_bar.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_steps.dart';

const _fills = {'0%': 0.0, '30%': 0.3, '70%': 0.7, '100%': 1.0};

class NumberDemo extends StatefulWidget {
  const NumberDemo({super.key});

  @override
  State<NumberDemo> createState() => _NumberDemoState();
}

class _NumberDemoState extends State<NumberDemo> {
  double _value = 42;

  void _add(double delta) =>
      setState(() => _value = (_value + delta).clamp(0, 1000));

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    return DemoSection(
      title: 'Counting numbers',
      controls: {
        '+1': () => _add(1),
        '+10': () => _add(10),
        '-10': () => _add(-10),
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          AnimatedNumber(
            value: _value,
            format: (v) => '${formatPercent((v ?? 0) / 100)}%',
            style: typography.value,
          ),
          AnimatedNumber(
            value: _value / 33,
            format: (v) => '${formatKm2(v, 'en')} km²',
            style: typography.value.copyWith(color: context.palette.accent),
          ),
        ],
      ),
    );
  }
}

class RingDemo extends StatefulWidget {
  const RingDemo({super.key});

  @override
  State<RingDemo> createState() => _RingDemoState();
}

class _RingDemoState extends State<RingDemo> {
  double _fill = 0.3;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DemoSection(
      title: 'Progress ring',
      controls: {
        for (final MapEntry(key: label, value: fill) in _fills.entries)
          label: () => setState(() => _fill = fill),
      },
      child: Center(
        child: SizedBox.square(
          dimension: 80,
          child: ProgressRing(
            fill: _fill,
            color: palette.accent,
            trackColor: palette.placeholder,
            radiusRatio: 0.4,
            strokeRatio: 0.08,
          ),
        ),
      ),
    );
  }
}

class RouteBarDemo extends StatefulWidget {
  const RouteBarDemo({super.key});

  @override
  State<RouteBarDemo> createState() => _RouteBarDemoState();
}

class _RouteBarDemoState extends State<RouteBarDemo> {
  double _progress = 0.3;

  @override
  Widget build(BuildContext context) => DemoSection(
    title: 'Quest route bar',
    controls: {
      for (final MapEntry(key: label, value: fill) in _fills.entries)
        label: () => setState(() => _progress = fill),
    },
    child: QuestRouteBar(progress: _progress),
  );
}

class StepsDemo extends StatefulWidget {
  const StepsDemo({super.key});

  @override
  State<StepsDemo> createState() => _StepsDemoState();
}

class _StepsDemoState extends State<StepsDemo> {
  static const _count = 5;

  int _visited = 1;

  @override
  Widget build(BuildContext context) => DemoSection(
    title: 'Quest steps',
    controls: {
      'Visit next': () =>
          setState(() => _visited = (_visited + 1).clamp(0, _count)),
      'Reset': () => setState(() => _visited = 0),
    },
    child: QuestSteps(
      visited: [for (var i = 0; i < _count; i++) i < _visited],
      next: _visited < _count ? _visited : null,
    ),
  );
}
