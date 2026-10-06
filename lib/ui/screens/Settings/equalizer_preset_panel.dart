import 'package:flutter/material.dart';

import '/models/equalizer.dart';
import '/models/equalizer_preset.dart';
import '/services/equalizer_preset_store.dart';

class EqualizerPresetPanel extends StatefulWidget {
  const EqualizerPresetPanel({
    super.key,
    required this.config,
    required this.onApplyConfig,
  });

  final EqualizerConfig config;
  final Future<void> Function(EqualizerConfig config) onApplyConfig;

  @override
  State<EqualizerPresetPanel> createState() => _EqualizerPresetPanelState();
}

class _EqualizerPresetPanelState extends State<EqualizerPresetPanel> {
  final _store = EqualizerPresetStore();
  List<EqualizerPreset> _customPresets = const [];
  String? _selectedPresetId;
  bool _loading = true;
  bool _applyingPreset = false;

  List<EqualizerPreset> get _presets => [
        ...EqualizerBuiltInPresets.all,
        ..._customPresets,
      ];

  EqualizerPreset? get _selected {
    for (final preset in _presets) {
      if (preset.id == _selectedPresetId) return preset;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant EqualizerPresetPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config == widget.config || _applyingPreset) return;
    _persistEditedConfig(widget.config);
  }

  Future<void> _load() async {
    final custom = await _store.listCustom();
    final selected = [
      ...EqualizerBuiltInPresets.all,
      ...custom,
    ].where((preset) => preset.config == widget.config).firstOrNull;
    if (!mounted) return;
    setState(() {
      _customPresets = custom;
      _selectedPresetId = selected?.id;
      _loading = false;
    });
  }

  Future<void> _persistEditedConfig(EqualizerConfig config) async {
    final selected = _selected;
    if (selected == null) return;

    if (selected.isBuiltIn) {
      final copy = await _store.duplicate(
        selected,
        name: selected.name + ' Custom',
      );
      final updated = await _store.update(copy, config: config);
      if (!mounted) return;
      setState(() {
        _customPresets = [..._customPresets, updated];
        _selectedPresetId = updated.id;
      });
      return;
    }

    final updated = await _store.update(selected, config: config);
    if (!mounted) return;
    setState(() {
      _customPresets = [
        for (final preset in _customPresets)
          preset.id == updated.id ? updated : preset,
      ];
    });
  }

  Future<void> _applyPreset(EqualizerPreset preset) async {
    setState(() => _selectedPresetId = preset.id);
    _applyingPreset = true;
    try {
      await widget.onApplyConfig(preset.config);
    } finally {
      _applyingPreset = false;
    }
  }

  Future<void> _saveAs() async {
    final controller = TextEditingController(
      text: _selected == null ? 'My Preset' : _selected!.name + ' Custom',
    );
    final name = await _nameDialog(
      title: 'Save preset',
      action: 'Save',
      controller: controller,
    );
    controller.dispose();
    if (name == null) return;

    final preset = await _store.create(
      name: name,
      config: widget.config,
    );
    if (!mounted) return;
    setState(() {
      _customPresets = [..._customPresets, preset];
      _selectedPresetId = preset.id;
    });
  }

  Future<void> _rename() async {
    final selected = _selected;
    if (selected == null || selected.isBuiltIn) return;

    final controller = TextEditingController(text: selected.name);
    final name = await _nameDialog(
      title: 'Rename preset',
      action: 'Rename',
      controller: controller,
    );
    controller.dispose();
    if (name == null) return;

    final updated = await _store.update(selected, name: name);
    if (!mounted) return;
    setState(() {
      _customPresets = [
        for (final preset in _customPresets)
          preset.id == updated.id ? updated : preset,
      ];
    });
  }

  Future<void> _duplicate() async {
    final selected = _selected;
    if (selected == null) return;
    final copy = await _store.duplicate(selected);
    if (!mounted) return;
    setState(() {
      _customPresets = [..._customPresets, copy];
      _selectedPresetId = copy.id;
    });
    await widget.onApplyConfig(copy.config);
  }

  Future<void> _delete() async {
    final selected = _selected;
    if (selected == null || selected.isBuiltIn) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete preset?'),
        content: Text('Delete ' + selected.name + '? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _store.delete(selected.id);
    if (!mounted) return;
    setState(() {
      _customPresets =
          _customPresets.where((preset) => preset.id != selected.id).toList();
      _selectedPresetId = null;
    });
  }

  Future<String?> _nameDialog({
    required String title,
    required String action,
    required TextEditingController controller,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Preset name'),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIsCustom = _selected?.isBuiltIn == false;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Preset',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                if (_loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            DropdownButton<String>(
              isExpanded: true,
              value: _presets.any((preset) => preset.id == _selectedPresetId)
                  ? _selectedPresetId
                  : null,
              hint: const Text('Choose a preset'),
              items: [
                for (final preset in _presets)
                  DropdownMenuItem<String>(
                    value: preset.id,
                    child: Row(
                      children: [
                        Expanded(child: Text(preset.name)),
                        if (preset.isBuiltIn)
                          const Icon(Icons.lock_outline, size: 16),
                      ],
                    ),
                  ),
              ],
              onChanged: _loading
                  ? null
                  : (id) {
                      if (id == null) return;
                      final preset =
                          _presets.firstWhere((item) => item.id == id);
                      _applyPreset(preset);
                    },
            ),
            Wrap(
              spacing: 4,
              runSpacing: 0,
              children: [
                TextButton.icon(
                  onPressed: _saveAs,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save as'),
                ),
                TextButton.icon(
                  onPressed: _selected == null ? null : _duplicate,
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Duplicate'),
                ),
                if (selectedIsCustom)
                  TextButton.icon(
                    onPressed: _rename,
                    icon: const Icon(Icons.drive_file_rename_outline),
                    label: const Text('Rename'),
                  ),
                if (selectedIsCustom)
                  TextButton.icon(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
