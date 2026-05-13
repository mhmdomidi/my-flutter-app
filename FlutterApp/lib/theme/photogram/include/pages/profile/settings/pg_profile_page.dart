import 'dart:async';

import 'package:flutter/material.dart';

import 'package:photogram/import/core.dart';
import 'package:photogram/import/bloc.dart';
import 'package:photogram/import/data.dart';
import 'package:photogram/import/interface.dart';

import 'package:photogram/theme/photogram/include/pg_utils.dart';
import 'package:photogram/theme/photogram/include/pages/profile/pg_profile_tab_bar_header_delegate.dart';
import 'package:photogram/theme/photogram/include/pages/profile/pg_profile_user_tagged_in_posts_grid_view.dart';
import 'package:photogram/theme/photogram/include/pages/profile/pg_profile_users_posts_grid_view.dart';
import 'package:photogram/theme/photogram/include/widgets/bottomsheet/pg_bottom_sheet_action.dart';
import 'package:photogram/theme/photogram/include/widgets/profile/pg_menu_item_widget.dart';
import 'package:photogram/theme/photogram/include/widgets/profile/pg_profile_avatar_big.dart';

import 'package:photogram/theme/photogram/include/pages/pg_context.dart';
import 'package:url_launcher/url_launcher_string.dart';

class PgProfilePage extends ProfilePage {
  final int userId;

  const PgProfilePage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  _PgProfilePageState createState() => _PgProfilePageState();
}

class _PgProfilePageState extends State<PgProfilePage> with AppActiveContentInfiniteMixin, AppUserMixin, AppUtilsMixin {
  late UserModel _userModel;
  late VoidCallback _onShowMenu;

  var _profileUserPostsStateInstanceId = PgUtils.random();
  var _profileUserTaggedInPostsStateInstanceId = PgUtils.random();

  var _userLoadingInProgress = false;

  @override
  void onLoadEvent() {
    _userModel = activeContent.watch<UserModel>(widget.userId) ?? UserModel.none();

    if (_userModel.isNotModel) {
      _loadUser(doSetState: true);
    }
  }

  @override
  onReloadAfterEvent() {
    _loadUser();

    _profileUserPostsStateInstanceId = PgUtils.random();
    _profileUserTaggedInPostsStateInstanceId = PgUtils.random();
  }

  @override
  Widget build(BuildContext context) {
    if (_userModel.isNotModel) {
      return PgUtils.darkCupertinoActivityIndicator();
    }

    // if logged in
    if (_userModel.isLoggedIn) {
      _onShowMenu = () {
        context.showBottomSheet(
          [
            PgBottomSheetAction(
              iconData: Icons.settings,
              title: AppLocalizations.of(context)!.settings,
              onTap: () {
                // push settings page
                AppNavigation.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ThemeBloc.pageInterface.settingsPage(userId: widget.userId),
                  ),
                  utilMixinSetState,
                );
              },
            ),
            PgBottomSheetAction(
              iconData: Icons.bookmark_border,
              title: AppLocalizations.of(context)!.savedPosts,
              onTap: () {
                AppNavigation.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ThemeBloc.pageInterface.collectionsPage(),
                  ),
                  utilMixinSetState,
                );
              },
            ),
            PgBottomSheetAction(
              iconData: Icons.dark_mode,
              title: AppLocalizations.of(context)!.toggleDarkMode,
              onTap: () => activeContent.themeBloc.pushEvent(
                ThemeEventToggleThemeMode(context, ThemeBloc.getThemeMode),
              ),
            ),
          ],
        );
      };
      // for random user
    } else {
      _onShowMenu = () {
        context.showBottomSheet(
          [
            PgBottomSheetAction(
              iconData: Icons.group_add,
              title: AppLocalizations.of(context)!.explore,
              onTap: () {
                AppNavigation.pop();
                NavigationBloc.of(context).pushEvent(NavigatorEventChangeNavigatorState(
                  context,
                  navigatorStateToSet: AppNavigation.searchPageNavigator,
                ));
              },
            ),
            PgBottomSheetAction(
              iconData: _userModel.isBlockedByCurrentUser ? Icons.add : Icons.cancel_outlined,
              title: _userModel.isBlockedByCurrentUser
                  ? AppLocalizations.of(context)!.unblockAccount
                  : AppLocalizations.of(context)!.blockAccount,
              onTap: () {
                AppNavigation.pop();
                userMixinBlockUser(_userModel, !_userModel.isBlockedByCurrentUser);
              },
            ),
          ],
        );
      };
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: _isOnRootPgProfilePage()
              ? null
              : GestureDetector(
                  onTap: AppNavigation.pop,
                  child: const Icon(Icons.arrow_back),
                ),
          centerTitle: false,
          title: ThemeBloc.textInterface.boldBlackH1Text(text: _userModel.username),
          actions: [
            IconButton(icon: const Icon(Icons.menu), onPressed: _onShowMenu),
          ],
        ),
        body: RefreshIndicator(
            onRefresh: contentMixinReloadPage,
            notificationPredicate: (notification) => notification.depth == (_isUserContentAvailable() ? 2 : 0),
            child: _buildUserContent()),
      ),
    );
  }

  Widget _buildUserContent() {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverToBoxAdapter(child: _buildProfileHeader()),
          if (_isUserContentAvailable())
            SliverPersistentHeader(
              pinned: true,
              delegate: PgProfileTabBarHeaderDelegate(
                child: SizedBox(
                  height: 48,
                  child: ColoredBox(
                    color: ThemeBloc.colorScheme.background,
                    child: TabBar(
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: ThemeBloc.colorScheme.onBackground,
                      tabs: [
                        Tab(icon: Icon(Icons.grid_on, color: ThemeBloc.colorScheme.onBackground)),
                        Tab(icon: Icon(Icons.person_outline, color: ThemeBloc.colorScheme.onBackground)),
                      ],
                    ),
                  ),
                ),
              ),
            )
        ];
      },
      body: _buildPostsSection(),
    );
  }

  Widget _buildProfileHeader() {
    return Material(
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PgProfileAvatarBig(userModel: _userModel),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () => AppNavigation.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ThemeBloc.pageInterface.profileUserPostsPage(
                              userId: widget.userId,
                              postIds: const [],
                              scrollToPostIndex: 0,
                            ),
                          ),
                          utilMixinSetState,
                        ),
                        child: PgMenuItemWidget(
                          title: AppUtils.compactNumber(
                            _userModel.cachePostsCount,
                          ),
                          content: AppLocalizations.of(context)!.posts,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => AppNavigation.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ThemeBloc.pageInterface.profileRelationshipsPage(
                              userId: widget.userId,
                              typeFollowers: true,
                            ),
                          ),
                          utilMixinSetState,
                        ),
                        child: PgMenuItemWidget(
                          title: AppUtils.compactNumber(
                            _userModel.cacheFollowersCount,
                          ),
                          content: AppLocalizations.of(context)!.followers,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => AppNavigation.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ThemeBloc.pageInterface.profileRelationshipsPage(
                              userId: widget.userId,
                              typeFollowers: false,
                            ),
                          ),
                          utilMixinSetState,
                        ),
                        child: PgMenuItemWidget(
                          title: AppUtils.compactNumber(
                            _userModel.cacheFollowingsCount,
                          ),
                          content: AppLocalizations.of(context)!.following,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ThemeBloc.textInterface.boldBlackH4Text(text: _userModel.name),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_userModel.displayBio.isNotEmpty)
                  ThemeBloc.textInterface.normalBlackH4Text(text: _userModel.displayBio),
                PgUtils.sizedBoxH(10),
                if (_userModel.displayWeb.isNotEmpty)
                  GestureDetector(
                    onTap: () => launchUrlString(_userModel.displayWeb),
                    child: ThemeBloc.textInterface.normalHrefH4Text(text: _userModel.displayWeb),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 16),
            width: double.infinity,
            child: userMixinBuildRelationshipButton(
              userModel: _userModel,
              size: AppButtonProperties.stretched,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPostsSection() {
    if (!_isUserContentAvailable()) {
      return Container(
        padding: const EdgeInsets.all(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ListTile(
                  leading: Icon(Icons.lock_outline, color: ThemeBloc.colorScheme.onBackground),
                  title: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: ThemeBloc.textInterface
                        .boldBlackH4Text(text: AppLocalizations.of(context)!.thisAccountIsPrivate),
                  ),
                  subtitle: ThemeBloc.textInterface
                      .normalGreyH5Text(text: AppLocalizations.of(context)!.followThisAccountToSeeTheirPosts),
                  contentPadding: const EdgeInsets.all(32),
                ),
              ]),
        ),
      );
    }

    return TabBarView(
      children: [
        PgProfileUserPostsGridView(
          userId: widget.userId,
          instanceStateId: _profileUserPostsStateInstanceId,
        ),
        PgProfileUserTaggedInPostsGridView(
          userId: widget.userId,
          instanceStateId: _profileUserTaggedInPostsStateInstanceId,
        ),
      ],
    );
  }

  Future<void> _loadUser({bool doSetState = false}) async {
    if (_userLoadingInProgress) return;
    _userLoadingInProgress = true;

    var responseModel = await AppProvider.of(context).apiRepo.userById(userId: widget.userId.toString());

    activeContent.handleResponse(responseModel);

    var userModel = activeContent.watch<UserModel>(widget.userId) ?? UserModel.none();
    if (userModel.isNotModel) {
      utilMixinSomethingWentWrongMessage();
      return;
    }

    if (doSetState) {
      utilMixinSetState(() {
        _userModel = userModel;
      });
    } else {
      _userModel = userModel;
    }

    _userLoadingInProgress = false;
  }

  bool _isOnRootPgProfilePage() => widget.key == KeyGen.from(AppWidgetKey.rootProfilePage);

  bool _isUserContentAvailable() {
    if (_userModel.isNotModel) return false;

    if (_userModel.isLoggedIn) return true;

    return !_userModel.isPrivateAccount || (_userModel.isFollowedByCurrentUser && !_userModel.isFollowRequestPending);
  }
}
