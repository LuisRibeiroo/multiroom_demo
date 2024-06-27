import 'dart:async';

import 'package:flutter/material.dart';
import '../../widgets/icon_title.dart';
import 'package:routefly/routefly.dart';
import 'package:signals/signals_flutter.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../injector.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/selectable_list_view.dart';
import '../../shared/pages/options_bottom_sheet.dart';
import '../../widgets/device_controls.dart';
import '../../widgets/device_info_header.dart';
import '../interactor/home_page_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = injector.get<HomePageController>();

  void _showDevicesBottomSheet() {
    context.showCustomModalBottomSheet(
      child: Watch(
        (_) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const IconTitle(
              title: "Zonas",
              icon: Icons.surround_sound_rounded,
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: _getDeviceZoneTiles(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChannelsBottomSheet() {
    context.showCustomModalBottomSheet(
      isScrollControlled: false,
      child: Watch(
        (_) => SelectableListView(
          title: "Canais",
          icon: Icons.input_rounded,
          options: _controller.channels,
          onSelect: _controller.setCurrentChannel,
          selectedOption: _controller.currentChannel.value,
        ),
      ),
    );
  }

  void _showEqualizersBottomSheet() {
    context.showCustomModalBottomSheet(
      isScrollControlled: false,
      child: Watch(
        (_) => SelectableListView(
          title: "Equalizadores",
          icon: Icons.equalizer_rounded,
          options: _controller.equalizers,
          onSelect: _controller.setEqualizer,
          selectedOption: _controller.currentEqualizer.value,
        ),
      ),
    );
  }

  void _showProjectsBottomSheet() {
    context.showCustomModalBottomSheet(
      isScrollControlled: false,
      child: Watch(
        (_) => SelectableListView(
          title: "Projetos",
          icon: Icons.group_work_rounded,
          options: _controller.projects,
          onSelect: _controller.setProject,
          selectedOption: _controller.currentProject.value,
        ),
      ),
    );
  }

  List<Widget> _getDeviceZoneTiles() {
    final tiles = <Widget>[];

    for (final device in _controller.currentProject.value.devices) {
      for (final zone in device.groupedZones) {
        tiles.add(
          ListTile(
            title: Text(zone.name),
            subtitle: Text(
              device.name,
              style: context.textTheme.labelSmall!.copyWith(color: context.theme.disabledColor),
            ),
            trailing: Visibility(
              visible: zone.id == _controller.currentZone.value.id &&
                  device.serialNumber == _controller.currentDevice.value.serialNumber,
              child: const Icon(Icons.check_rounded),
            ),
            onTap: () {
              _controller.setCurrentDeviceAndZone(device, zone);
              Routefly.pop(context);
            },
          ),
        );
      }
    }

    return tiles;
  }

  @override
  void initState() {
    super.initState();

    scheduleMicrotask(() async {
      await _controller.init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Watch(
      (_) => VisibilityDetector(
        key: const ValueKey(HomePage),
        onVisibilityChanged: (info) async {
          if (info.visibleFraction == 1) {
            await _controller.syncLocalData();
          }
        },
        child: LoadingOverlay(
          state: _controller.state,
          child: Scaffold(
            appBar: AppBar(
              leading: Image.asset("assets/logo.png"),
              title: const Text('Multiroom'),
              actions: [
                IconButton(
                  onPressed: () => OptionsMenu.showOptionsBottomSheet(context),
                  icon: const Icon(Icons.more_vert_rounded),
                ),
              ],
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DeviceInfoHeader(
                        showProjectsButton: _controller.hasMultipleProjects.value,
                        project: _controller.currentProject.value,
                        deviceName: _controller.currentDevice.value.name,
                        currentZone: _controller.currentZone.value,
                        currentChannel: _controller.currentChannel.value,
                        onChangeActive: _controller.setZoneActive,
                        onChangeDevice: _showDevicesBottomSheet,
                        onChangeChannel: _showChannelsBottomSheet,
                        onChangeProject: _showProjectsBottomSheet,
                      ),
                      12.asSpace,
                      DeviceControls(
                        currentZone: _controller.currentZone.value,
                        currentEqualizer: _controller.currentEqualizer.value,
                        equalizers: _controller.equalizers.value,
                        onChangeBalance: _controller.setBalance,
                        onChangeVolume: _controller.setVolume,
                        onUpdateFrequency: _controller.setFrequency,
                        onChangeEqualizer: _showEqualizersBottomSheet,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
