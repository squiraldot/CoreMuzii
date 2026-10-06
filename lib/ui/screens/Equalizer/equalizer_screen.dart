import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '/models/equalizer_model.dart';
import '/services/equalizer_controller.dart';
import '/services/autoeq_service.dart';
import '/ui/screens/Equalizer/components/spectrum_analyzer.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> with SingleTickerProviderStateMixin {
  late final EqualizerController eqController;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<EqualizerController>()) {
      eqController = Get.find<EqualizerController>();
    } else {
      eqController = Get.put(EqualizerController());
    }
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MDLovFi Equalizer'),
        actions: [
          Obx(() => Switch(
                value: eqController.isEnabled.value,
                onChanged: (val) => eqController.toggleEnabled(),
              )),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Flat',
            onPressed: () => eqController.resetFlat(),
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'save', child: Text('Save Custom Preset')),
              const PopupMenuItem(value: 'import', child: Text('Import .mdleq')),
              const PopupMenuItem(value: 'export', child: Text('Export .mdleq')),
              const PopupMenuItem(value: 'share', child: Text('Share via Telegram')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Graphic'),
            Tab(text: 'Parametric'),
            Tab(text: 'Advanced DSP'),
          ],
        ),
      ),
      body: Obx(() {
        final isEnabled = eqController.isEnabled.value;
        return Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: AbsorbPointer(
            absorbing: !isEnabled,
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildPresetSelector(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: SpectrumAnalyzerWidget(
                    bands: eqController.activeBands,
                    preampDb: eqController.preampDb.value,
                  ),
                ),
                _buildPreampSlider(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGraphicTab(),
                      _buildParametricTab(),
                      _buildAdvancedDspTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPresetSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          const Text('Preset:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<EQPreset>(
              isExpanded: true,
              value: eqController.allPresets.firstWhereOrNull(
                (p) => p.id == eqController.currentPreset.value?.id,
              ) ?? eqController.builtInPresets.first,
              items: eqController.allPresets.map((preset) {
                return DropdownMenuItem<EQPreset>(
                  value: preset,
                  child: Text(
                    preset.name + (preset.isBuiltIn ? '' : ' (User)'),
                    style: TextStyle(
                      color: preset.isBuiltIn ? Colors.white : Colors.amberAccent,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (newPreset) {
                if (newPreset != null) {
                  eqController.applyPreset(newPreset);
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.headphones),
            tooltip: 'AutoEQ Profiles',
            onPressed: _showAutoEqDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildPreampSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        children: [
          const SizedBox(width: 80, child: Text('Preamp:', style: TextStyle(fontSize: 13))),
          Expanded(
            child: Slider(
              value: eqController.preampDb.value,
              min: -15.0,
              max: 15.0,
              divisions: 60,
              label: '${eqController.preampDb.value.toStringAsFixed(1)} dB',
              onChanged: (val) => eqController.setPreamp(val),
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              '${eqController.preampDb.value >= 0 ? "+" : ""}${eqController.preampDb.value.toStringAsFixed(1)} dB',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphicTab() {
    return Obx(() {
      final bands = eqController.graphicBands;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            children: List.generate(bands.length, (index) {
              final band = bands[index];
              return Container(
                width: 54,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Column(
                  children: [
                    Text(
                      '${band.gainDb >= 0 ? "+" : ""}${band.gainDb.toStringAsFixed(1)}',
                      style: const TextStyle(fontSize: 10),
                    ),
                    Expanded(
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Slider(
                          value: band.gainDb,
                          min: -15.0,
                          max: 15.0,
                          divisions: 60,
                          onChanged: (val) => eqController.updateBandGain(index, val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      band.frequency >= 1000
                          ? '${(band.frequency / 1000).toStringAsFixed(band.frequency % 1000 == 0 ? 0 : 1)}k'
                          : '${band.frequency.toInt()}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      );
    });
  }

  Widget _buildParametricTab() {
    return Obx(() {
      final bands = eqController.parametricBands;
      return ListView.builder(
        itemCount: bands.length + 1,
        itemBuilder: (ctx, idx) {
          if (idx == bands.length) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Parametric Band'),
                onPressed: () {
                  bands.add(EQBand(
                    id: 'p_${DateTime.now().millisecondsSinceEpoch}',
                    type: FilterType.peaking,
                    frequency: 1000.0,
                    gainDb: 0.0,
                    q: 1.414,
                  ));
                  eqController.saveStateToHive();
                },
              ),
            );
          }
          final band = bands[idx];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      DropdownButton<FilterType>(
                        value: band.type,
                        items: FilterType.values.map((ft) {
                          return DropdownMenuItem(value: ft, child: Text(ft.displayName));
                        }).toList(),
                        onChanged: (ft) {
                          if (ft != null) {
                            bands[idx] = band.copyWith(type: ft);
                            eqController.saveStateToHive();
                          }
                        },
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () {
                          bands.removeAt(idx);
                          eqController.saveStateToHive();
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text('Freq: ${band.frequency.toInt()} Hz', style: const TextStyle(fontSize: 12)),
                      Expanded(
                        child: Slider(
                          value: band.frequency,
                          min: 20.0,
                          max: 20000.0,
                          onChanged: (v) {
                            bands[idx] = band.copyWith(frequency: v);
                            eqController.saveStateToHive();
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text('Gain: ${band.gainDb.toStringAsFixed(1)} dB', style: const TextStyle(fontSize: 12)),
                      Expanded(
                        child: Slider(
                          value: band.gainDb,
                          min: -15.0,
                          max: 15.0,
                          onChanged: (v) {
                            bands[idx] = band.copyWith(gainDb: v);
                            eqController.saveStateToHive();
                          },
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
    });
  }

  Widget _buildAdvancedDspTab() {
    return Obx(() {
      final dsp = eqController.dspSettings.value;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Limiter (Clipping Protection)'),
            subtitle: Text('Ceiling: ${dsp.limiterCeilingDb} dB'),
            value: dsp.limiterEnabled,
            onChanged: (v) {
              eqController.dspSettings.value = dsp.copyWith(limiterEnabled: v);
              eqController.saveStateToHive();
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Bass Boost'),
            value: dsp.bassBoostEnabled,
            onChanged: (v) {
              eqController.dspSettings.value = dsp.copyWith(bassBoostEnabled: v);
              eqController.saveStateToHive();
            },
          ),
          if (dsp.bassBoostEnabled)
            Slider(
              value: dsp.bassBoostAmount,
              min: 0.0,
              max: 100.0,
              label: '${dsp.bassBoostAmount.toInt()}%',
              onChanged: (v) {
                eqController.dspSettings.value = dsp.copyWith(bassBoostAmount: v);
                eqController.saveStateToHive();
              },
            ),
          const Divider(),
          SwitchListTile(
            title: const Text('Stereo Width'),
            subtitle: Text('${(dsp.stereoWidth * 100).toInt()}%'),
            value: dsp.stereoWidthEnabled,
            onChanged: (v) {
              eqController.dspSettings.value = dsp.copyWith(stereoWidthEnabled: v);
              eqController.saveStateToHive();
            },
          ),
          if (dsp.stereoWidthEnabled)
            Slider(
              value: dsp.stereoWidth,
              min: 0.0,
              max: 2.0,
              onChanged: (v) {
                eqController.dspSettings.value = dsp.copyWith(stereoWidth: v);
                eqController.saveStateToHive();
              },
            ),
        ],
      );
    });
  }

  void _handleMenuAction(String action) async {
    if (action == 'save') {
      final nameCtrl = TextEditingController();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Save Custom Preset'),
          content: TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(hintText: 'Preset Name'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  eqController.saveCustomPreset(nameCtrl.text.trim());
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    } else if (action == 'import') {
      final res = await FilePicker.platform.pickFiles(type: FileType.any);
      if (res != null && res.files.single.path != null) {
        final file = File(res.files.single.path!);
        final content = await file.readAsString();
        try {
          final preset = eqController.parseMdleqJson(content);
          eqController.importPreset(preset);
          Get.snackbar('Success', 'Imported preset "${preset.name}"');
        } catch (e) {
          Get.snackbar('Error', 'Failed to import preset: $e');
        }
      }
    } else if (action == 'export') {
      final str = eqController.exportPresetToMdleqString();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Export .mdleq Preset'),
          content: SingleChildScrollView(child: SelectableText(str)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        ),
      );
    } else if (action == 'share') {
      if (eqController.currentPreset.value != null) {
        AutoEQService.sharePresetToTelegram(eqController.currentPreset.value!);
      }
    }
  }

  void _showAutoEqDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final profiles = AutoEQService.searchHeadphones('');
        return AlertDialog(
          title: const Text('AutoEQ Headphone Profiles'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: profiles.length,
              itemBuilder: (c, i) {
                final prof = profiles[i];
                return ListTile(
                  title: Text('${prof.brand} ${prof.modelName}'),
                  subtitle: const Text('Harman Target Profile'),
                  onTap: () {
                    final preset = prof.toPreset();
                    eqController.importPreset(preset, applyImmediately: true);
                    Navigator.pop(ctx);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
