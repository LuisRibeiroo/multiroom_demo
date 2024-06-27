import 'dart:async';

import 'package:flutter/material.dart';
import 'package:routefly/routefly.dart';
import 'package:signals/signals_flutter.dart';

import '../../../../injector.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../interactor/controllers/scanner_page_controller.dart';
import '../interactor/models/network_device_model.dart';
import '../widgets/add_project_bottom_sheet.dart';
import '../widgets/device_list_tile.dart';
import '../widgets/network_devices_bottom_sheet.dart';
import '../widgets/project_list_bottom_sheet.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final _controller = injector.get<ScannerPageController>();

  void _showNetworkDevicesBottomSheet() {
    _controller.startUdpServer();

    context.showCustomModalBottomSheet(
      child: Watch(
        (_) => NetworkDevicesBottomSheet(
          hasAvailableSlots: _controller.hasAvailableSlots.value == false,
          networkDevices: _controller.networkDevices,
          onTapDevice: () {
            Routefly.pop(context);

            _showDeviceTypeSelectorBottomSheet();
          },
        ),
      ),
    );
  }

  void _showDeviceTypeSelectorBottomSheet() {
    context.showCustomModalBottomSheet(
      child: Watch(
        (_) => TypeSelectionBottomSheet(
          netDevice: _controller.networkDevices.first,
          deviceType: _controller.deviceType.value,
          onChangeType: _controller.deviceType.set,
          onTapConfirm: _controller.onConfirmAddDevice,
          masterAvailable: _controller.isMasterAvailable.value,
          slave1Available: _controller.slave1Available.value,
          slave2Available: _controller.slave2Available.value,
        ),
      ),
    );
  }

  void _showProjectListBottomSheet() {
    context.showCustomModalBottomSheet(
      child: Watch(
        (_) => ProjectListBottomSheet(
          projects: _controller.projects,
          onTapAddProject: () {
            Routefly.pop(context);
            _showAddProjectBottomSheet();
          },
          onTapProject: (project) {
            Routefly.pop(context);

            _controller.currentProject.set(project);
            _showNetworkDevicesBottomSheet();
          },
        ),
      ),
    );
  }

  void _showAddProjectBottomSheet() {
    context.showCustomModalBottomSheet(
      child: Watch(
        (_) => AddProjectBottomSheet(
          projectName: _controller.projectName.value,
          onChangeProjectName: _controller.projectName.set,
          isNameValid: _controller.isProjectNameValid.value,
          onAddProject: () {
            Routefly.pop(context);
            _controller.addProject();
            _showNetworkDevicesBottomSheet();
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    scheduleMicrotask(() async {
      await _controller.init();

      if (_controller.localDevices.value.isEmpty) {
        _showProjectListBottomSheet();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Watch(
      (_) => LoadingOverlay(
        state: _controller.state,
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Acesso Técnico"),
            actions: [
              Visibility(
                visible: _controller.isUdpListening.value,
                child: IconButton(
                  icon: const Icon(Icons.cancel_rounded),
                  onPressed: _controller.stopUdpServer,
                ),
              ),
              Visibility(
                visible: _controller.isUdpListening.value,
                child: const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(),
                ),
              ),
              24.asSpace,
            ],
          ),
          body: Watch(
            (_) => Visibility(
              visible: _controller.projects.isEmpty,
              replacement: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _controller.projects.length,
                itemBuilder: (_, index) => Watch(
                  (_) {
                    final proj = _controller.projects[index];

                    return Card.outlined(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Text(
                              proj.name,
                              style: context.textTheme.titleLarge,
                            ),
                            8.asSpace,
                            ...List.generate(
                              proj.devices.length,
                              (idx) => DeviceListTile(
                                device: proj.devices[idx],
                                onTapConfigDevice: _controller.onTapConfigDevice,
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              child: Center(
                key: const ValueKey("empty"),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.settings_input_antenna_rounded,
                      size: 80,
                    ),
                    Text(
                      'Nenhum dispositivo configurado',
                      style: context.textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            // onPressed: _showNetworkDevicesBottomSheet,
            onPressed: _showProjectListBottomSheet,
            child: const Icon(Icons.settings_input_antenna_rounded),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();

    _controller.dispose();
  }
}

class TypeSelectionBottomSheet extends StatelessWidget {
  const TypeSelectionBottomSheet({
    super.key,
    required this.netDevice,
    required this.deviceType,
    required this.onChangeType,
    required this.onTapConfirm,
    required this.masterAvailable,
    required this.slave1Available,
    required this.slave2Available,
  });

  final NetworkDeviceModel netDevice;
  final NetworkDeviceType deviceType;
  final Function(NetworkDeviceType) onChangeType;
  final Function(NetworkDeviceModel) onTapConfirm;
  final bool masterAvailable;
  final bool slave1Available;
  final bool slave2Available;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "Modo",
          style: context.textTheme.titleLarge,
        ),
        12.asSpace,
        Wrap(
          spacing: 24,
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          children: [
            ChoiceChip(
              label: Text(NetworkDeviceType.master.readable),
              selected: deviceType == NetworkDeviceType.master,
              onSelected: masterAvailable ? (_) => onChangeType(NetworkDeviceType.master) : null,
            ),
            ChoiceChip(
              label: Text(NetworkDeviceType.slave1.readable),
              selected: deviceType == NetworkDeviceType.slave1,
              onSelected: slave1Available ? (_) => onChangeType(NetworkDeviceType.slave1) : null,
            ),
            ChoiceChip(
              label: Text(NetworkDeviceType.slave2.readable),
              selected: deviceType == NetworkDeviceType.slave2,
              onSelected: slave2Available ? (_) => onChangeType(NetworkDeviceType.slave2) : null,
            ),
          ],
        ),
        24.asSpace,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: AppButton(
            leading: const Icon(Icons.add_rounded),
            text: "Adicionar",
            onPressed: deviceType != NetworkDeviceType.undefined
                ? () {
                    Routefly.pop(context);
                    onTapConfirm(netDevice);
                  }
                : null,
          ),
        ),
        24.asSpace,
      ],
    );
  }
}
