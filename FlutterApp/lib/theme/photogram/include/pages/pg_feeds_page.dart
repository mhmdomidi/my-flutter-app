import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:photogram/core/helpers/extensions.dart';

import 'package:photogram/import/core.dart';
import 'package:photogram/import/bloc.dart';
import 'package:photogram/import/data.dart';
import 'package:photogram/import/interface.dart';

import 'package:photogram/theme/photogram/include/pg_utils.dart';
import 'package:photogram/theme/photogram/include/widgets/post/pg_feed_post_widget.dart';

class PgFeedsPage extends FeedsPage {
  const PgFeedsPage({Key? key}) : super(key: key);

  @override
  _PgFeedsPageState createState() => _PgFeedsPageState();
}

class _PgFeedsPageState extends State<PgFeedsPage> with AppActiveContentInfiniteMixin, AppUtilsMixin {
  final _postIds = <int>[];

  final _infinitePostIds = <int>[];
  var _switchedToInfiniteMode = false;
  var _infiniteModeSwitchIndex = -1;

  @override
  void onLoadEvent() {
    _loadPosts(latest: true);
  }

  @override
  onReloadBeforeEvent() {
    _postIds.clear();
    _infinitePostIds.clear();
    _switchedToInfiniteMode = false;
    _infiniteModeSwitchIndex = -1;
    return true;
  }

  @override
  onReloadAfterEvent() {
    _loadPosts(latest: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SvgPicture.asset(
          AppIcons.logo,
          height: 25,
          colorFilter: ThemeBloc.colorScheme.onBackground.toColorFilter,
        ),
        actions: [
          GestureDetector(
            onTap: () => PgUtils.openCreatePostPage(utilMixinSetState),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: contentMixinReloadPage,
        child: Stack(
          children: [
            if (isLoadingLatest)
              Positioned(
                top: 0,
                width: MediaQuery.of(context).size.width,
                child: Container(
                  alignment: Alignment.topCenter,
                  padding: const EdgeInsets.all(5),
                  color: ThemeBloc.colorScheme.background,
                  child: PgUtils.darkCupertinoActivityIndicator(),
                ),
              ),
            ListView.builder(
              itemCount: (isLoadingBottom || _switchedToInfiniteMode) ? _postIds.length + 1 : _postIds.length,
              itemBuilder: _buildPost,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPost(BuildContext context, int index) {
    // agressive prefetching posts
    if (_postIds.length - 3 < index) {
      _loadPosts(waitForFrame: true);
    }

    if (_switchedToInfiniteMode && index == _infiniteModeSwitchIndex) {
      return _buildFeedsSwitchedInfoBlock();
    }

    if (_postIds.length > index) {
      return PgFeedPostWidget(
        postId: _postIds[index],
        showFollowButton: _switchedToInfiniteMode && index > _infiniteModeSwitchIndex,
      );
    }

    if (isEndOfResults) {
      return const SizedBox.shrink();
    }

    return PgUtils.darkCupertinoActivityIndicator();
  }

  Widget _buildFeedsSwitchedInfoBlock() {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 250),
            child: Column(
              children: [
                PgUtils.sizedBoxH(15),
                _infiniteModeSwitchIndex == 0 ? const Icon(Icons.favorite_outline) : const Icon(Icons.check),
                PgUtils.sizedBoxH(10),
                Text(
                  _infiniteModeSwitchIndex == 0
                      ? AppLocalizations.of(context)!.youMadeIt
                      : AppLocalizations.of(context)!.youAreAllCaughtUp,
                  style: ThemeBloc.textInterface.boldBlackH2TextStyle(),
                  textAlign: TextAlign.center,
                ),
                PgUtils.sizedBoxH(10),
                Text(
                  _infiniteModeSwitchIndex == 0
                      ? AppLocalizations.of(context)!.welcomeToYourFeedsDescription
                      : AppLocalizations.of(context)!.showingSuggestedPostsDescription,
                  style: ThemeBloc.textInterface.normalGreyH5TextStyle(),
                  textAlign: TextAlign.center,
                ),
                PgUtils.sizedBoxH(20),
                ThemeBloc.widgetInterface.divider(),
                if (_infiniteModeSwitchIndex == 0) PgUtils.sizedBoxH(60),
                if (_infiniteModeSwitchIndex == 0)
                  Text(
                    AppLocalizations.of(context)!.keepScrollForNewestPosts,
                    style: ThemeBloc.textInterface.normalGreyH5TextStyle(),
                    textAlign: TextAlign.center,
                  ),
                if (_infiniteModeSwitchIndex == 0) PgUtils.sizedBoxH(20),
                if (_infiniteModeSwitchIndex == 0) const Icon(Icons.arrow_downward_outlined),
                PgUtils.sizedBoxH(25),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadPosts({bool latest = false, bool waitForFrame = false}) async {
    if (_switchedToInfiniteMode) {
      return contentMixinLoadContent(
        latest: false,
        waitForFrame: waitForFrame,
        responseHandler: handleResponse,
        latestEndpoint: '',
        bottomEndpoint: REQ_TYPE_POST_INFINITE_LOAD,
        requestDataGenerator: () => {
          RequestTable.offset: {
            PostTable.tableName: {PostTable.id: _infinitePostIds.isEmpty ? 0 : _infinitePostIds.reduce(min)},
          }
        },
      );
    }

    contentMixinLoadContent(
      latest: latest,
      waitForFrame: waitForFrame,
      responseHandler: handleResponse,
      latestEndpoint: REQ_TYPE_POST_GLOBAL_FEED_LOAD_LATEST,
      bottomEndpoint: REQ_TYPE_POST_GLOBAL_FEED_LOAD_BOTTOM,
      requestDataGenerator: () => {
        RequestTable.offset: {
          PostTable.tableName: {PostTable.id: latest ? latestContentId : bottomContentId},
        },
      },
    );
  }

  handleResponse({
    bool latest = false,
    required ResponseModel responseModel,
  }) {
    setState(() {
      activeContent.handleResponse(responseModel);

      activeContent.pagedModels<PostModel>().forEach((postId, postModel) {
        if (!_postIds.contains(postId)) {
          _postIds.add(postId);
        }

        if (_switchedToInfiniteMode) {
          if (!_infinitePostIds.contains(postId)) {
            _infinitePostIds.add(postId);
          }
        }
      });

      if (!_switchedToInfiniteMode) {
        contentMixinUpdateData(
          setLatestContentId: _postIds.isEmpty ? 0 : _postIds.reduce(max),
          setBottomContentId: _postIds.isEmpty ? 0 : _postIds.reduce(min),
        );

        if (endOfResults()) {
          _switchedToInfiniteMode = true;
          _infiniteModeSwitchIndex = _postIds.length;

          Future.delayed(Duration.zero, () {
            endOfResults(false);
            _postIds.add(0);
            _loadPosts();
          });
        }
      }
    });
  }
}
