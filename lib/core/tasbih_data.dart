import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _customKey = 'tasbih_custom';
const String _progressKey = 'tasbih_progress';
const String _vibrationKey = 'tasbih_vibration';

// The open tasbih has no steps, so it vibrates at every multiple of this.
const int kOpenTasbihMilestone = 100;

// One step of a tasbih: a phrase and how many times to say it.
// A count of 0 means "no limit" (used by the open tasbih).
class TasbihStep {
  final String text;
  final int count;

  const TasbihStep(this.text, this.count);

  Map<String, Object> toJson() => {'text': text, 'count': count};

  static TasbihStep? fromJson(Object? json) {
    if (json is! Map) return null;
    final Object? text = json['text'];
    final Object? count = json['count'];
    if (text is! String || count is! int) return null;
    return TasbihStep(text, count);
  }
}

// A tasbih is a list of steps. The built-in ones and the custom ones use the
// same structure, so one counter screen works for all of them.
class Tasbih {
  final String id;
  final String name;
  final String? subtitle;
  final List<TasbihStep> steps;
  final bool isBuiltIn;

  const Tasbih({
    required this.id,
    required this.name,
    required this.steps,
    this.subtitle,
    this.isBuiltIn = false,
  });

  // True for a tasbih with one step and no limit.
  bool get isOpen => steps.length == 1 && steps.first.count == 0;

  // Total number of counts to finish the tasbih (0 if it has no limit).
  int get totalCount => steps.fold(0, (sum, s) => sum + s.count);

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'steps': steps.map((s) => s.toJson()).toList(),
  };
}

// Tasbih of Fatima al-Zahra (peace be upon her), in the usual Shia order.
const Tasbih kZahraTasbih = Tasbih(
  id: 'zahra',
  name: 'تسبيح الزهراء',
  subtitle: 'تسبيح السيدة فاطمة الزهراء (عليها السلام)',
  isBuiltIn: true,
  steps: [
    TasbihStep('الله أكبر', 34),
    TasbihStep('الحمد لله', 33),
    TasbihStep('سبحان الله', 33),
  ],
);

// A free counter with no limit. Its single step has no text on screen.
const Tasbih kOpenTasbih = Tasbih(
  id: 'open',
  name: 'مسبحة مفتوحة',
  subtitle: 'تسبيح حر لأي ذكر تختاره',
  isBuiltIn: true,
  steps: [TasbihStep('', 0)],
);

// Where the user is inside a tasbih: the step index and the count in it.
// When [step] equals the number of steps, the tasbih is finished.
class TasbihProgress {
  final int step;
  final int count;

  const TasbihProgress(this.step, this.count);
}

// What a tap did. The screen uses it to choose the vibration.
enum TasbihEvent { none, stepDone, allDone }

// Screens listen to these, so they rebuild when something changes.
final ValueNotifier<List<Tasbih>> customTasbihsNotifier =
ValueNotifier<List<Tasbih>>(<Tasbih>[]);

final ValueNotifier<Map<String, TasbihProgress>> tasbihProgressNotifier =
ValueNotifier<Map<String, TasbihProgress>>(<String, TasbihProgress>{});

// Whether the phone vibrates when a step is finished.
final ValueNotifier<bool> tasbihVibrationNotifier = ValueNotifier<bool>(true);

void setTasbihVibration(bool enabled) {
  tasbihVibrationNotifier.value = enabled;
  unawaited(_persistVibration());
}

Future<void> _persistVibration() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_vibrationKey, tasbihVibrationNotifier.value);
}

// ---------- Reading the progress ----------

// Saved progress, or a fresh start if it is missing or no longer fits.
TasbihProgress progressOf(Tasbih t) {
  final TasbihProgress? saved = tasbihProgressNotifier.value[t.id];
  if (saved == null || saved.step < 0 || saved.step > t.steps.length) {
    return const TasbihProgress(0, 0);
  }
  if (saved.step == t.steps.length) return TasbihProgress(saved.step, 0);
  return saved;
}

bool isTasbihFinished(Tasbih t) => progressOf(t).step >= t.steps.length;

// How many counts were already done in this tasbih.
int doneCountOf(Tasbih t) {
  final TasbihProgress p = progressOf(t);
  int sum = p.count;
  for (int i = 0; i < p.step && i < t.steps.length; i++) {
    sum += t.steps[i].count;
  }
  return sum;
}

// Progress from 0 to 1 (always 0 for a tasbih with no limit).
double progressFractionOf(Tasbih t) {
  final int total = t.totalCount;
  if (total == 0) return 0;
  return (doneCountOf(t) / total).clamp(0.0, 1.0).toDouble();
}

// ---------- Changing the progress ----------

void _setProgress(String id, TasbihProgress progress) {
  // The screen updates first, the saving happens in the background,
  // so the tap feels instant.
  tasbihProgressNotifier.value = {
    ...tasbihProgressNotifier.value,
    id: progress,
  };
  unawaited(_persistProgress());
}

// Counts one tap and tells what happened.
TasbihEvent tapTasbih(Tasbih t) {
  final TasbihProgress p = progressOf(t);
  if (p.step >= t.steps.length) return TasbihEvent.none; // already finished

  final TasbihStep step = t.steps[p.step];
  final int count = p.count + 1;

  if (step.count > 0 && count >= step.count) {
    final TasbihProgress next = TasbihProgress(p.step + 1, 0);
    _setProgress(t.id, next);
    return next.step >= t.steps.length
        ? TasbihEvent.allDone
        : TasbihEvent.stepDone;
  }

  _setProgress(t.id, TasbihProgress(p.step, count));

  // No limit: give a signal at every 100 counts (100, 200, 300...).
  if (step.count == 0 && count % kOpenTasbihMilestone == 0) {
    return TasbihEvent.stepDone;
  }
  return TasbihEvent.none;
}

// Takes back the last tap (it can also go back to the previous step).
void undoTasbih(Tasbih t) {
  final TasbihProgress p = progressOf(t);

  if (p.count > 0) {
    _setProgress(t.id, TasbihProgress(p.step, p.count - 1));
  } else if (p.step > 0) {
    final TasbihStep previous = t.steps[p.step - 1];
    _setProgress(
      t.id,
      TasbihProgress(p.step - 1, previous.count > 0 ? previous.count - 1 : 0),
    );
  }
}

void resetTasbih(String id) {
  final Map<String, TasbihProgress> next = {...tasbihProgressNotifier.value};
  next.remove(id);
  tasbihProgressNotifier.value = next;
  unawaited(_persistProgress());
}

// ---------- Custom tasbihs ----------

// Adds a new custom tasbih, or replaces the one with the same id.
// When a tasbih is edited, its progress is kept as far as it still fits.
void saveCustomTasbih(Tasbih tasbih) {
  final List<Tasbih> next = [...customTasbihsNotifier.value];
  final int index = next.indexWhere((t) => t.id == tasbih.id);
  final bool isEdit = index != -1;

  if (isEdit) {
    next[index] = tasbih;
  } else {
    next.add(tasbih);
  }
  customTasbihsNotifier.value = next;
  unawaited(_persistCustom());

  if (isEdit) _fitProgressToSteps(tasbih);
}

// Keeps the saved progress after an edit when it still makes sense.
void _fitProgressToSteps(Tasbih t) {
  final TasbihProgress? saved = tasbihProgressNotifier.value[t.id];
  if (saved == null) return;

  // Steps were removed and the old position no longer exists.
  if (saved.step > t.steps.length) {
    resetTasbih(t.id);
    return;
  }

  // The tasbih was finished: it stays finished.
  if (saved.step == t.steps.length) return;

  // The new limit is not bigger than what was already counted:
  // that step counts as done, so move on to the next one.
  final int limit = t.steps[saved.step].count;
  if (limit > 0 && saved.count >= limit) {
    _setProgress(t.id, TasbihProgress(saved.step + 1, 0));
  }
}

void deleteCustomTasbih(String id) {
  customTasbihsNotifier.value =
      customTasbihsNotifier.value.where((t) => t.id != id).toList();
  unawaited(_persistCustom());
  resetTasbih(id);
}

// ---------- Saving and loading ----------

Future<void> _persistCustom() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _customKey,
    jsonEncode(customTasbihsNotifier.value.map((t) => t.toJson()).toList()),
  );
}

Future<void> _persistProgress() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final Map<String, List<int>> out = {
    for (final e in tasbihProgressNotifier.value.entries)
      e.key: [e.value.step, e.value.count],
  };
  await prefs.setString(_progressKey, jsonEncode(out));
}

// Call once before runApp to restore everything that was saved.
Future<void> loadTasbih() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  try {
    final String? rawCustom = prefs.getString(_customKey);
    if (rawCustom != null) {
      final Object? decoded = jsonDecode(rawCustom);
      final List<Tasbih> list = [];
      if (decoded is List) {
        for (final Object? item in decoded) {
          if (item is! Map) continue;
          final Object? id = item['id'];
          final Object? name = item['name'];
          final Object? stepsRaw = item['steps'];
          if (id is! String || name is! String || stepsRaw is! List) continue;

          final List<TasbihStep> steps =
          stepsRaw.map(TasbihStep.fromJson).whereType<TasbihStep>().toList();
          if (steps.isEmpty) continue;
          list.add(Tasbih(id: id, name: name, steps: steps));
        }
      }
      customTasbihsNotifier.value = list;
    }

    final String? rawProgress = prefs.getString(_progressKey);
    if (rawProgress != null) {
      final Object? decoded = jsonDecode(rawProgress);
      final Map<String, TasbihProgress> map = {};
      if (decoded is Map) {
        for (final MapEntry<dynamic, dynamic> e in decoded.entries) {
          final Object? value = e.value;
          if (e.key is String &&
              value is List &&
              value.length == 2 &&
              value[0] is int &&
              value[1] is int) {
            map[e.key as String] =
                TasbihProgress(value[0] as int, value[1] as int);
          }
        }
      }
      tasbihProgressNotifier.value = map;
    }
  } on FormatException {
    // Damaged saved data: start clean instead of crashing the app.
  }
}