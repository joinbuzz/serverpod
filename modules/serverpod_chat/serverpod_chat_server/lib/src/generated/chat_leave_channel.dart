/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: unused_import

import 'package:serverpod_serialization/serverpod_serialization.dart';
import 'dart:typed_data';
import 'protocol.dart';

class ChatLeaveChannel extends SerializableEntity {
  @override
  String get className => 'serverpod_chat_server.ChatLeaveChannel';

  int? id;
  late String channel;

  ChatLeaveChannel({
    this.id,
    required this.channel,
  });

  ChatLeaveChannel.fromSerialization(Map<String, dynamic> serialization) {
    var _data = unwrapSerializationData(serialization);
    id = _data['id'];
    channel = _data['channel']!;
  }

  @override
  Map<String, dynamic> serialize() {
    return wrapSerializationData({
      'id': id,
      'channel': channel,
    });
  }

  @override
  Map<String, dynamic> serializeAll() {
    return wrapSerializationData({
      'id': id,
      'channel': channel,
    });
  }
}
