import 'package:auto_injector/auto_injector.dart';

import 'app/(modules)/devices/interactor/controllers/home_page_controller.dart';

final injector = AutoInjector(
  on: (injector) {
    injector.addLazySingleton(HomePageController.new);
  },
);