import 'package:get/get.dart';

enum GroupTab { myGroups, discover }

class GroupeController extends GetxController {
  final selectedTab = GroupTab.myGroups.obs;

  void setTab(GroupTab tab) {
    selectedTab.value = tab;
  }
}
