import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:serverpod_chat_client/module.dart';
import 'package:serverpod_chat_flutter/serverpod_chat_flutter.dart';
import 'package:serverpod_chat_flutter/src/chat_dispatch.dart';

const _offsetForRequestingNextChunk = 100.0;

typedef ChatTileBuilder = Widget Function(
    BuildContext context, ChatMessage message, ChatMessage? previous);

class ChatView extends StatefulWidget {
  final ChatController controller;
  final ChatTileBuilder? tileBuilder;

  /// Optional widget to be shown on top of the oldest chat message
  final Widget? leading;

  const ChatView({
    Key? key,
    required this.controller,
    this.tileBuilder,
    this.leading,
  }) : super(key: key);

  @override
  _ChatViewState createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _fadeInAnimation;

  var _jumpToBottom = true;
  var _messageAdded = false;
  var _messageAddedByUser = false;
  var _offset = 0.0;
  var _maxExtent = 0.0;

  var _lastHeight = 0.0;

  @override
  void initState() {
    super.initState();

    widget.controller.addMessageReceivedListener(_handleNewChatMessage);
    widget.controller.addMessageUpdatedListener(_handleUpdatedChatMessage);
    widget.controller.addReceivedMessageChunkListener(_handleNewMessageChunk);

    // Restore scroll
    _scrollController = ScrollController(
      initialScrollOffset: widget.controller.scrollOffset,
    );
    _jumpToBottom = widget.controller.scrollAtBottom;

    _scrollController.addListener(() {
      widget.controller.scrollOffset = _scrollController.offset;
      widget.controller.scrollAtBottom = _scrollController.offset ==
          _scrollController.position.maxScrollExtent;
      if (widget.controller.scrollAtBottom) {
        widget.controller.markLastMessageRead();
      }

      if (_scrollController.offset < _offsetForRequestingNextChunk &&
          widget.controller.hasOlderMessages &&
          !_jumpToBottom &&
          _distanceToBottomBeforeMessageChunk == null) {
        widget.controller.requestNextMessageChunk();
      }
    });

    // Fade in animation to mask initial jump to bottom of scroll view
    _fadeInAnimation = AnimationController(vsync: this);
    _fadeInAnimation.value = 0.0;
    _fadeInAnimation.addListener(() {
      setState(() {});
    });

    if (!_jumpToBottom) {
      _fadeIn();
    }
  }

  @override
  void dispose() {
    widget.controller.removeMessageReceivedListener(_handleNewChatMessage);
    widget.controller.removeMessageUpdatedListener(_handleUpdatedChatMessage);
    widget.controller
        .removeReceivedMessageChunkListener(_handleNewMessageChunk);
    _scrollController.dispose();
    _fadeInAnimation.dispose();
    super.dispose();
  }

  void _handleNewChatMessage(ChatMessage message, bool addedByUser) {
    _offset = _scrollController.offset;
    _maxExtent = _scrollController.position.maxScrollExtent;
    _messageAdded = true;
    _messageAddedByUser = addedByUser;

    setState(() {});
  }

  void _handleUpdatedChatMessage() {
    setState(() {});
  }

  double? _distanceToBottomBeforeMessageChunk;

  void _handleNewMessageChunk() {
    _distanceToBottomBeforeMessageChunk =
        _scrollController.position.maxScrollExtent - _scrollController.offset;
    setState(() {});
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent -
          _distanceToBottomBeforeMessageChunk!);
      _distanceToBottomBeforeMessageChunk = null;
    });
  }

  void _fadeIn() {
    _fadeInAnimation.animateTo(1.0,
        duration: const Duration(milliseconds: 500));
  }

  void _scrollToBottom() {
    _scrollController
        .animateTo(
      _scrollController.position.maxScrollExtent,
      curve: Curves.linear,
      duration: const Duration(milliseconds: 200),
    )
        .then((_) {
      if (_scrollController.offset !=
          _scrollController.position.maxScrollExtent) {
        _scrollToBottom();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_messageAdded) {
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        if (_offset == _maxExtent || _messageAddedByUser) {
          _scrollToBottom();
          _messageAddedByUser = false;
        }
      });
      _messageAdded = false;
    }
    if (_jumpToBottom) {
      // Check if jump to bottom is complete (we may need multiple attempts as
      // maxScrollExtent is a guesstimate).
      if (_scrollController.hasClients &&
          _scrollController.offset ==
              _scrollController.position.maxScrollExtent) {
        _jumpToBottom = false;

        // Start the fade in when we know we are at the bottom.
        _fadeIn();
      }
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        widget.controller.markLastMessageRead();

        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
        // Trigger another build.
        setState(() {});
      });
    }

    return Opacity(
      opacity: _fadeInAnimation.value,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (_lastHeight != constraints.maxHeight) {
            _lastHeight = constraints.maxHeight;

            if (_scrollController.hasClients &&
                _scrollController.offset ==
                    _scrollController.position.maxScrollExtent) {
              WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
                _scrollController
                    .jumpTo(_scrollController.position.maxScrollExtent);
              });
            }
          }

          // _pinnedToBottom = _scrollController.position == _scrollController.position.maxScrollExtent;

          return Align(
            alignment: Alignment.bottomCenter,
            child: ListView.builder(
              shrinkWrap: true,
              reverse: false,
              controller: _scrollController,
              itemBuilder: _chatItemBuilder,
              itemCount: widget.controller.messages.length +
                  (widget.leading != null ? 1 : 0),
            ),
          );
        },
      ),
    );
  }

  Widget _chatItemBuilder(BuildContext context, int item) {
    final leading = widget.leading;
    if (leading != null) {
      // If we have a leading widget, show that on top
      if (item == 0) {
        return leading;
      }

      // Align `item` so it matches the indices of the messages
      item--;
    }

    // Revers the list, because the scroll view is reversed
    var message = widget.controller.messages[item];
    ChatMessage? previous;
    if (item > 0) {
      previous = widget.controller.messages[item - 1];
    }
    var tileBuilder = widget.tileBuilder ?? _defaultTileBuilder;
    return tileBuilder(context, message, previous);
  }

  Widget _defaultTileBuilder(BuildContext context, ChatMessage message) {
    return ListTile(
      title: Text(message.message),
      subtitle: Text(message.senderInfo?.userName ?? 'Unknown user'),
    );
  }
}
