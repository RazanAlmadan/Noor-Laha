import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_colors.dart';
import '../core/arabic_text.dart';
import '../core/tasbih_data.dart';
import '../core/tasbih_icon.dart';
import 'tasbih_counter_screen.dart';

// Tasbih tab: the list of tasbihs (built-in and custom).
class TasbihScreen extends StatelessWidget {
  const TasbihScreen({super.key});

  void _openCounter(BuildContext context, Tasbih tasbih) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TasbihCounterScreen(tasbih: tasbih),
      ),
    );
  }

  // Opens the editor to create a tasbih, or to edit [initial].
  void _openEditor(BuildContext context, [Tasbih? initial]) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _TasbihEditorSheet(initial: initial),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Tasbih tasbih) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف المسبحة'),
        content: Text('هل تريد حذف «${tasbih.name}»؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok == true) deleteCustomTasbih(tasbih.id);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.backgroundTop, colors.background],
          ),
        ),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: Listenable.merge([
              customTasbihsNotifier,
              tasbihProgressNotifier,
            ]),
            builder: (context, _) {
              final List<Tasbih> custom = customTasbihsNotifier.value;

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  Text(
                    'المسبحة',
                    style: TextStyle(
                      color: colors.title,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _TasbihCard(
                    tasbih: kZahraTasbih,
                    onTap: () => _openCounter(context, kZahraTasbih),
                  ),
                  _TasbihCard(
                    tasbih: kOpenTasbih,
                    onTap: () => _openCounter(context, kOpenTasbih),
                  ),

                  const SizedBox(height: 14),
                  Text(
                    'مسابحي',
                    style: TextStyle(
                      color: colors.title,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (custom.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'أنشئ مسبحتك الخاصة',
                        style: TextStyle(
                          color: colors.mutedText,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  for (final Tasbih t in custom)
                    _TasbihCard(
                      tasbih: t,
                      onTap: () => _openCounter(context, t),
                      onEdit: () => _openEditor(context, t),
                      onDelete: () => _confirmDelete(context, t),
                    ),

                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    onPressed: () => _openEditor(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('إنشاء مسبحة'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.accent,
                      side: BorderSide(color: colors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// One tasbih in the list: name, its steps, and the progress.
class _TasbihCard extends StatelessWidget {
  final Tasbih tasbih;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _TasbihCard({
    required this.tasbih,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  String get _stepsSummary {
    if (tasbih.isOpen) return 'عدّاد حر بدون حد';
    return tasbih.steps
        .map((s) => '${s.text} ${toArabicDigits(s.count)}')
        .join(' · ');
  }

  String get _statusText {
    if (isTasbihFinished(tasbih)) return 'اكتملت';
    final int done = doneCountOf(tasbih);
    if (done == 0) return '';
    if (tasbih.isOpen) return 'العدد: ${toArabicDigits(done)}';
    return 'التقدم: ${toArabicDigits(done)} / ${toArabicDigits(tasbih.totalCount)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final String status = _statusText;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        elevation: 1,
        shadowColor: colors.shadow,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: colors.softSurface,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  alignment: Alignment.center,
                  child: TasbihIcon(size: 28, color: colors.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tasbih.name,
                        style: TextStyle(
                          color: colors.title,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _stepsSummary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.mutedText,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      if (status.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          status,
                          style: TextStyle(
                            color: colors.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!tasbih.isOpen) ...[
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progressFractionOf(tasbih),
                              minHeight: 5,
                              backgroundColor: colors.softSurface,
                              color: colors.accent,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                if (!tasbih.isBuiltIn)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: colors.mutedText),
                    onSelected: (value) {
                      if (value == 'edit') onEdit?.call();
                      if (value == 'delete') onDelete?.call();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('تعديل')),
                      PopupMenuItem(value: 'delete', child: Text('حذف')),
                    ],
                  )
                else
                  const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- Create / edit sheet ----------

// The two text fields of one step.
class _StepFields {
  final TextEditingController text;
  final TextEditingController count;

  _StepFields({String text = '', String count = ''})
      : text = TextEditingController(text: text),
        count = TextEditingController(text: count);

  void dispose() {
    text.dispose();
    count.dispose();
  }
}

// Turns "٣٠٠" or "300" into 300 (null if it is not a number).
int? _parseCount(String input) {
  final StringBuffer buffer = StringBuffer();
  for (final int unit in input.trim().runes) {
    // Arabic-Indic digits are U+0660..U+0669.
    if (unit >= 0x0660 && unit <= 0x0669) {
      buffer.writeCharCode(unit - 0x0660 + 0x30);
    } else {
      buffer.writeCharCode(unit);
    }
  }
  return int.tryParse(buffer.toString());
}

class _TasbihEditorSheet extends StatefulWidget {
  final Tasbih? initial;

  const _TasbihEditorSheet({this.initial});

  @override
  State<_TasbihEditorSheet> createState() => _TasbihEditorSheetState();
}

class _TasbihEditorSheetState extends State<_TasbihEditorSheet> {
  late final TextEditingController _name =
  TextEditingController(text: widget.initial?.name ?? '');

  late final List<_StepFields> _steps = widget.initial == null
      ? [_StepFields()]
      : [
    for (final TasbihStep s in widget.initial!.steps)
      _StepFields(text: s.text, count: s.count.toString()),
  ];

  String? _error;

  @override
  void dispose() {
    _name.dispose();
    for (final _StepFields f in _steps) {
      f.dispose();
    }
    super.dispose();
  }

  void _addStep() => setState(() => _steps.add(_StepFields()));

  void _removeStep(int index) {
    setState(() => _steps.removeAt(index).dispose());
  }

  void _save() {
    final String name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'اكتب اسماً للمسبحة');
      return;
    }

    final List<TasbihStep> steps = [];
    for (final _StepFields f in _steps) {
      final String text = f.text.text.trim();
      final int? count = _parseCount(f.count.text);
      if (text.isEmpty || count == null || count < 1 || count > 99999) {
        setState(() => _error = 'اكتب الذكر وعدداً بين ١ و٩٩٩٩٩ لكل خطوة');
        return;
      }
      steps.add(TasbihStep(text, count));
    }

    saveCustomTasbih(
      Tasbih(
        // A new tasbih gets a new id; editing keeps the old one.
        id: widget.initial?.id ?? 'c${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        steps: steps,
      ),
    );
    Navigator.of(context).pop();
  }

  InputDecoration _decoration(AppPalette colors, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colors.mutedText),
      counterText: '',
      filled: true,
      fillColor: colors.softSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bool editing = widget.initial != null;

    return SingleChildScrollView(
      // Moves up with the keyboard.
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              editing ? 'تعديل المسبحة' : 'مسبحة جديدة',
              style: TextStyle(
                color: colors.title,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _name,
              maxLength: 40,
              style: TextStyle(color: colors.bodyText),
              decoration: _decoration(colors, 'اسم المسبحة'),
            ),
            const SizedBox(height: 14),
            Text(
              'الخطوات',
              style: TextStyle(
                color: colors.title,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < _steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _steps[i].text,
                        maxLength: 60,
                        style: TextStyle(color: colors.bodyText),
                        decoration: _decoration(colors, 'الذكر'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 84,
                      child: TextField(
                        controller: _steps[i].count,
                        maxLength: 5,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9\u0660-\u0669]'),
                          ),
                        ],
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.bodyText),
                        decoration: _decoration(colors, 'العدد'),
                      ),
                    ),
                    // The last step cannot be removed.
                    SizedBox(
                      width: 40,
                      child: _steps.length > 1
                          ? IconButton(
                        tooltip: 'حذف الخطوة',
                        icon: Icon(
                          Icons.close_rounded,
                          color: colors.mutedText,
                        ),
                        onPressed: () => _removeStep(i),
                      )
                          : null,
                    ),
                  ],
                ),
              ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: _addStep,
                icon: const Icon(Icons.add_rounded),
                label: const Text('إضافة خطوة'),
                style: TextButton.styleFrom(foregroundColor: colors.accent),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 4),
              Text(
                _error!,
                style: const TextStyle(color: Color(0xFFB3261E), fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: colors.background,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('حفظ', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}