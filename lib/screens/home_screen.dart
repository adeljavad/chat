import 'package:animations/animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/all.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yaanyo/screens/settings/settings_screen.dart';
import 'package:yaanyo/screens/shopping/shopping_task_screen.dart';
import 'package:yaanyo/state_management/create_grid_state_manager.dart';
import 'package:yaanyo/state_management/providers.dart';
import 'package:yaanyo/state_management/shopping_task_state_manager.dart';
import 'package:yaanyo/widgets/alert_widget.dart';
import 'package:yaanyo/widgets/grid_box.dart';

import '../constants.dart';
import 'shopping/create_new_grid_box.dart';

final shoppingGridStream = StreamProvider<QuerySnapshot>((ref) {
  return ref.watch(shoppingServiceProvider).getShoppingGridStream();
});

class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final stream = watch(shoppingGridStream);
    final shoppingTaskManager = watch(shoppingTaskManagerProvider);

    return stream.when(
      loading: () => Center(child: CircularProgressIndicator()),
      data: (data) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: Scaffold(
            appBar: buildAppBar(context),
            floatingActionButton: buildFloatingActionButton(),
            body: data.docs.isEmpty
                ? AlertWidget(
                    lottie: 'assets/lottie/check.json',
                    label: 'No Tasks Found\nStart by adding tasks',
                    lottieHeight: MediaQuery.of(context).size.height * 0.3,
                  )
                : GridView.builder(
                    itemCount: data.docs.length,
                    padding: EdgeInsets.all(8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemBuilder: (context, index) {
                      final gridData = data.docs[index].data();

                      return OpenContainer(
                        closedElevation: 5,
                        closedColor: kGridColorList[gridData['gridColorInt']],
                        closedShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        closedBuilder: (context, closedWidget) {
                          return GridBox(
                            storeName: gridData['storeName'],
                            storeIcon: gridData['storeIcon'],
                          );
                        },
                        openBuilder: (context, openWidget) {
                          shoppingTaskManager.storeName = gridData['storeName'];
                          shoppingTaskManager.storeIcon = gridData['storeIcon'];
                          shoppingTaskManager.gridColor =
                              kGridColorList[gridData['gridColorInt']];

                          return ShoppingTaskScreen();
                        },
                      );
                    },
                  ),
          ),
        );
      },
      error: (error, stackTrace) => AlertWidget(
        label: error,
        iconData: Icons.warning_amber_rounded,
      ),
    );
  }

  OpenContainer buildFloatingActionButton() {
    return OpenContainer(
      closedShape: CircleBorder(),
      closedElevation: 8,
      useRootNavigator: true,
      closedBuilder: (context, closedWidget) {
        return FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: closedWidget,
        );
      },
      openBuilder: (context, openWidget) {
        final createGridProvider = context.read(createGridStateManagerProvider);

        createGridProvider.gridColor = null;
        createGridProvider.storeName = null;
        createGridProvider.storeIcon = null;

        return CreateNewGridBox();
      },
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      brightness: Brightness.dark,
      title: Text('Yaanyo'),
      actions: [
        IconButton(
          icon: Icon(Icons.settings),
          onPressed: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                transitionsBuilder:
                    (context, animation, secondAnimation, child) {
                  animation = CurvedAnimation(
                      parent: animation, curve: Curves.linearToEaseOut);

                  return SlideTransition(
                    position: Tween(
                      begin: Offset(1.0, 0.0),
                      end: Offset(0.0, 0.0),
                    ).animate(animation),
                    child: child,
                  );
                },
                pageBuilder: (context, animation, secondAnimation) {
                  return SettingsScreen();
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
