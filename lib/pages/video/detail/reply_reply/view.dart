import 'package:PiliPalaX/grpc/app/main/community/reply/v1/reply.pb.dart';
import 'package:PiliPalaX/http/loading_state.dart';
import 'package:PiliPalaX/pages/video/detail/reply/widgets/reply_item_grpc.dart';
import 'package:PiliPalaX/pages/video/detail/reply_new/reply_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/common/skeleton/video_reply.dart';
import 'package:PiliPalaX/common/widgets/http_error.dart';
import 'package:PiliPalaX/models/common/reply_type.dart';
import 'package:get/get_navigation/src/dialog/dialog_route.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../../utils/utils.dart';
import 'controller.dart';

class VideoReplyReplyPanel extends StatefulWidget {
  const VideoReplyReplyPanel({
    // this.rcount,
    this.id,
    this.oid,
    this.rpid,
    this.firstFloor,
    this.source,
    this.replyType,
    super.key,
  });
  // final dynamic rcount;
  final dynamic id;
  final int? oid;
  final int? rpid;
  final ReplyInfo? firstFloor;
  final String? source;
  final ReplyType? replyType;

  @override
  State<VideoReplyReplyPanel> createState() => _VideoReplyReplyPanelState();
}

class _VideoReplyReplyPanelState extends State<VideoReplyReplyPanel> {
  late VideoReplyReplyController _videoReplyReplyController;
  late final _savedReplies = {};

  @override
  void initState() {
    super.initState();
    _videoReplyReplyController = Get.put(
      VideoReplyReplyController(
        widget.firstFloor != null,
        widget.id,
        widget.oid,
        widget.rpid.toString(),
        widget.replyType!,
      ),
      tag: widget.rpid.toString(),
    );
  }

  @override
  void dispose() {
    _videoReplyReplyController.controller?.dispose();
    Get.delete<VideoReplyReplyController>(tag: widget.rpid.toString());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height:
          widget.source == 'videoDetail' ? Utils.getSheetHeight(context) : null,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          if (widget.source == 'videoDetail')
            Container(
              height: 45,
              padding: const EdgeInsets.only(left: 12, right: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('评论详情'),
                  IconButton(
                    tooltip: '关闭',
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: Get.back,
                  ),
                ],
              ),
            ),
          Divider(
            height: 1,
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _videoReplyReplyController.onRefresh();
              },
              child: Obx(
                () => ScrollablePositionedList.builder(
                  itemCount:
                      _itemCount(_videoReplyReplyController.loadingState.value),
                  itemScrollController:
                      _videoReplyReplyController.itemScrollCtr,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemBuilder: (_, index) {
                    if (widget.firstFloor != null) {
                      if (index == 0) {
                        return ReplyItemGrpc(
                          replyItem: widget.firstFloor!,
                          replyLevel: '2',
                          showReplyRow: false,
                          replyType: widget.replyType,
                          needDivider: false,
                          onReply: () {
                            _onReply(widget.firstFloor!);
                          },
                          upMid: _videoReplyReplyController.upMid,
                        );
                      } else if (index == 1) {
                        return Divider(
                          height: 20,
                          color:
                              Theme.of(context).dividerColor.withOpacity(0.1),
                          thickness: 6,
                        );
                      } else if (index == 2) {
                        return _sortWidget;
                      } else {
                        return Obx(() => _buildBody(
                            _videoReplyReplyController.loadingState.value,
                            index - 3));
                      }
                    } else {
                      if (index == 0) {
                        return _sortWidget;
                      } else {
                        return Obx(() => _buildBody(
                            _videoReplyReplyController.loadingState.value,
                            index - 1));
                      }
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget get _sortWidget => Container(
        height: 40,
        padding: const EdgeInsets.fromLTRB(12, 0, 6, 0),
        color: Theme.of(context).colorScheme.surface,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Obx(
              () => _videoReplyReplyController.count.value != -1
                  ? Text(
                      '相关回复共${_videoReplyReplyController.count.value}条',
                      style: const TextStyle(fontSize: 13),
                    )
                  : const SizedBox.shrink(),
            ),
            SizedBox(
              height: 35,
              child: TextButton.icon(
                onPressed: () => _videoReplyReplyController.queryBySort(),
                icon: const Icon(Icons.sort, size: 16),
                label: Obx(
                  () => Text(
                    _videoReplyReplyController.mode.value == Mode.MAIN_LIST_HOT
                        ? '按热度'
                        : '按时间',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            )
          ],
        ),
      );

  void _onReply(ReplyInfo? item) {
    dynamic oid = item?.oid.toInt();
    dynamic root = item?.id.toInt();
    dynamic parent = item?.id.toInt();
    dynamic key = oid + root + parent;
    Navigator.of(context)
        .push(
      GetDialogRoute(
        pageBuilder: (buildContext, animation, secondaryAnimation) {
          return ReplyPage(
            oid: oid,
            root: root,
            parent: parent,
            replyType: ReplyType.video,
            replyItem: item,
            savedReply: _savedReplies[key],
            onSaveReply: (reply) {
              _savedReplies[key] = reply;
            },
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.linear;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    )
        .then((value) {
      // 完成评论，数据添加              // TODO: data cast
      if (value != null && value['data'] is ReplyInfo) {
        _savedReplies[key] = null;
        List<ReplyInfo> list =
            _videoReplyReplyController.loadingState.value is Success
                ? (_videoReplyReplyController.loadingState.value as Success)
                    .response
                : <ReplyInfo>[];
        list.add(value['data']);
        _videoReplyReplyController.loadingState.value =
            LoadingState.success(list);
      }
    });
  }

  Widget _buildBody(LoadingState loadingState, int index) {
    if (loadingState is Success) {
      if (index == loadingState.response.length) {
        _videoReplyReplyController.onLoadMore();
        return Container(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          height: MediaQuery.of(context).padding.bottom + 100,
          child: Center(
            child: Obx(
              () => Text(
                _videoReplyReplyController.noMore.value,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          ),
        );
      } else {
        return _videoReplyReplyController.index == index
            ? AnimatedBuilder(
                animation: _videoReplyReplyController.colorAnimation!,
                builder: (context, child) {
                  return ColoredBox(
                    color: _videoReplyReplyController.colorAnimation?.value ??
                        Theme.of(Get.context!).colorScheme.onInverseSurface,
                    child: _replyItem(loadingState.response[index]),
                  );
                },
              )
            : _replyItem(loadingState.response[index]);
      }
    } else if (loadingState is Error) {
      return CustomScrollView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          HttpError(
            errMsg: loadingState.errMsg,
            fn: _videoReplyReplyController.onReload,
          )
        ],
      );
    } else {
      return CustomScrollView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return const VideoReplySkeleton();
              },
              childCount: 8,
            ),
          )
        ],
      );
    }
  }

  Widget _replyItem(replyItem) {
    return ReplyItemGrpc(
      replyItem: replyItem,
      replyLevel: '2',
      showReplyRow: false,
      replyType: widget.replyType,
      onReply: () {
        _onReply(replyItem);
      },
      onDelete: (rpid, frpid) {
        List list =
            (_videoReplyReplyController.loadingState.value as Success).response;
        list = list.where((item) => item.id != rpid).toList();
        _videoReplyReplyController.loadingState.value =
            LoadingState.success(list);
      },
      upMid: _videoReplyReplyController.upMid,
    );
  }

  int _itemCount(LoadingState loadingState) {
    int itemCount = 0;
    if (widget.firstFloor != null) {
      itemCount = 2;
    }
    if (loadingState is Success) {
      return loadingState.response.length + itemCount + 2;
    } else {
      return itemCount + 2;
    }
  }
}
