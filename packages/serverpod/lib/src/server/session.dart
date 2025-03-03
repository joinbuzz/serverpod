import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:serverpod/src/server/message_central.dart';
import 'package:serverpod_serialization/serverpod_serialization.dart';
import 'package:serverpod_shared/serverpod_shared.dart';

import '../authentication/scope.dart';
import '../authentication/util.dart';
import '../cache/caches.dart';
import '../cloud_storage/cloud_storage.dart';
import '../database/database.dart';
import '../generated/protocol.dart';
import 'log_manager.dart';
import 'server.dart';
import 'serverpod.dart';

/// When a call is made to the [Server] a [Session] object is created. It
/// contains all data associated with the current connection and provides
/// easy access to the database.
abstract class Session {
  /// The [Server] that created the session.
  final Server server;

  /// The [Serverpod] this session is running on.
  Serverpod get serverpod => server.serverpod;

  /// A temporary session id used internally by the server.
  late int temporarySessionId;

  /// Max lifetime of the session, after it will be forcefully terminated.
  final Duration maxLifeTime;

  late DateTime _startTime;

  /// The time the session object was created.
  DateTime get startTime => _startTime;

  /// Log messages saved during the session.
  // final List<LogEntry> logs = [];
  late final SessionLogEntryCache sessionLogs;

  int? _authenticatedUser;
  Set<Scope>? _scopes;

  /// An custom object associated with this [Session]. This is especially
  /// useful for keeping track of the state in a [StreamingEndpoint].
  dynamic userObject;

  /// Access to the database.
  late final Database db;

  String? _authenticationKey;

  /// The authentication key passed from the client.
  String? get authenticationKey => _authenticationKey;

  /// Provides access to all caches used by the server.
  Caches get caches => server.caches;

  /// Map of passwords loaded from config/passwords.yaml
  Map<String, String> get passwords => server.passwords;

  /// Methods related to user authentication.
  late final UserAuthetication auth;

  /// Provides access to the cloud storages used by this [Serverpod].
  late final StorageAccess storage;

  /// Access to the [MessageCentral] for passing real time messages between
  /// web socket streams and other listeners.
  late MessageCentralAccess messages;

  bool _closed = false;

  /// Creates a new session. This is typically done internally by the [Server].
  Session({
    required this.server,
    String? authenticationKey,
    this.maxLifeTime = const Duration(minutes: 1),
    HttpRequest? httpRequest,
    WebSocket? webSocket,
    String? futureCallName,
  }) {
    _startTime = DateTime.now();
    temporarySessionId = serverpod.logManager.nextTemporarySessionId();

    auth = UserAuthetication._(this);
    storage = StorageAccess._(this);
    messages = MessageCentralAccess._(this);

    db = Database(session: this);

    sessionLogs = server.serverpod.logManager.initializeSessionLog(this);
  }

  bool _initialized = false;

  Future<void> _initialize() async {
    if (server.authenticationHandler != null && _authenticationKey != null) {
      var authenticationInfo =
          await server.authenticationHandler!(this, _authenticationKey!);
      _scopes = authenticationInfo?.scopes;
      _authenticatedUser = authenticationInfo?.authenticatedUserId;
    }
    _initialized = true;
  }

  /// Returns the scopes associated with an authenticated user.
  Future<Set<Scope>?> get scopes async {
    if (!_initialized) await _initialize();
    return _scopes;
  }

  /// Returns true if the user is signed in.
  Future<bool> get isUserSignedIn async {
    return (await auth.authenticatedUserId) != null;
  }

  /// Returns the duration this session has been open.
  Duration get duration => DateTime.now().difference(_startTime);

  /// Closes the session. This method should only be called if you have
  /// manually created a the [Session] e.g. by calling [createSession] on
  /// [Serverpod]. Closing the session finalizes and writes logs to the
  /// database. After a session has been closed, you should not call any
  /// more methods on it. Optionally pass in an [error]/exception and
  /// [stackTrace] if the session ended with an error and it should be written
  /// to the logs. Returns the session id, if the session has been logged to the
  /// database.
  Future<int?> close({
    dynamic error,
    StackTrace? stackTrace,
    bool logSession = true,
  }) async {
    if (_closed) return null;
    _closed = true;

    try {
      server.messageCentral.removeListenersForSession(this);
      return await server.serverpod.logManager.finalizeSessionLog(
        this,
        exception: '$error',
        stackTrace: stackTrace,
        authenticatedUserId: _authenticatedUser,
        logSession: logSession,
      );
    } catch (e, stackTrace) {
      stderr.writeln('Failed to close session: $e');
      stderr.writeln('$stackTrace');
    }
  }

  /// Logs a message. Default [LogLevel] is [LogLevel.info]. The log is written
  /// to the database when the session is closed.
  void log(String message,
      {LogLevel? level, dynamic exception, StackTrace? stackTrace}) {
    assert(
        !_closed, 'Session is closed, and logging can no longer be performed.');

    sessionLogs.logEntries.add(
      LogEntry(
        sessionLogId: temporarySessionId,
        serverId: server.serverId,
        logLevel: (level ?? LogLevel.info).index,
        message: message,
        time: DateTime.now(),
        error: exception != null ? '$exception' : null,
        stackTrace: stackTrace != null ? '$stackTrace' : null,
      ),
    );
  }
}

/// A Session used internally in the [ServerPod]. Typically used to access
/// the database and do logging for events that are not triggered from a call,
/// or a stream.
class InternalSession extends Session {
  /// Creates a new [InternalSession]. Consider using the createSession
  /// method of [ServerPod] to create a new session.
  InternalSession({required Server server}) : super(server: server);
}

/// When a call is made to the [Server] a [MethodCallSession] object is created.
/// It contains all data associated with the current connection and provides
/// easy access to the database.
class MethodCallSession extends Session {
  /// The uri that was used to call the server.
  final Uri uri;

  /// The body of the server call.
  final String body;

  /// Query parameters of the server call.
  late final Map<String, String> queryParameters;

  /// The name of the called [Endpoint].
  final String endpointName;

  /// The name of the method that is being called.
  late final String methodName;

  /// The [HttpRequest] associated with the call.
  final HttpRequest httpRequest;

  /// Creates a new [Session] for a method call to an endpoint.
  MethodCallSession({
    required Server server,
    required this.uri,
    required this.body,
    required this.endpointName,
    required this.httpRequest,
    String? authenticationKey,
  }) : super(server: server) {
    // Read query parameters
    var queryParameters = <String, String>{};
    if (body != '' && body != 'null') {
      queryParameters = jsonDecode(body).cast<String, String>();
    }

    // Add query parameters from uri
    queryParameters.addAll(uri.queryParameters);
    this.queryParameters = queryParameters;

    var methodName = queryParameters['method'];
    if (methodName == null && endpointName == 'webserver') methodName = '';
    this.methodName = methodName!;

    // Get the the authentication key, if any
    _authenticationKey = authenticationKey ?? queryParameters['auth'];
  }
}

/// When a web socket connection is opened to the [Server] a [StreamingSession]
/// object is created. It contains all data associated with the current
/// connection and provides easy access to the database.
class StreamingSession extends Session {
  /// The uri that was used to call the server.
  final Uri uri;

  /// Query parameters of the server call.
  late final Map<String, String> queryParameters;

  /// The [HttpRequest] associated with the call.
  final HttpRequest httpRequest;

  /// The underlying web socket that handles communication with the server.
  final WebSocket webSocket;

  /// Creates a new [Session] for the web socket stream.
  StreamingSession({
    required Server server,
    required this.uri,
    required this.httpRequest,
    required this.webSocket,
  }) : super(server: server) {
    // Read query parameters
    var queryParameters = <String, String>{};
    queryParameters.addAll(uri.queryParameters);
    this.queryParameters = queryParameters;

    // Get the the authentication key, if any
    _authenticationKey = queryParameters['auth'];
  }
}

/// Created when a [FutureCall] is being made. It contains all data associated
/// with the current call and provides easy access to the database.
class FutureCallSession extends Session {
  /// Name of the [FutureCall].
  final String futureCallName;

  /// Creates a new [Session] for a [FutureCall].
  FutureCallSession({
    required Server server,
    required this.futureCallName,
  }) : super(server: server);
}

/// Collects methods for authenticating users.
class UserAuthetication {
  final Session _session;

  UserAuthetication._(this._session);

  /// Returns the id of an authenticated user or null if the user isn't signed
  /// in.
  Future<int?> get authenticatedUserId async {
    if (!_session._initialized) await _session._initialize();
    return _session._authenticatedUser;
  }

  /// Signs in an user to the server. The user should have been authenticated
  /// before signing them in. Send the AuthKey.id and key to the client and
  /// use that to authenticate in future calls. In most cases, it's more
  /// convenient to use the serverpod_auth module for authentication.
  Future<AuthKey> signInUser(int userId, String method,
      {Set<Scope> scopes = const {}}) async {
    var signInSalt = _session.passwords['authKeySalt'] ?? defaultAuthKeySalt;

    var key = generateRandomString();
    var hash = hashString(signInSalt, key);

    var scopeNames = <String>[];
    for (var scope in scopes) {
      if (scope.name != null) scopeNames.add(scope.name!);
    }

    var authKey = AuthKey(
      userId: userId,
      hash: hash,
      key: key,
      scopeNames: scopeNames,
      method: method,
    );

    await _session.db.insert(authKey);

    _session._authenticatedUser = userId;

    return authKey;
  }

  /// Signs out a user from the server and deletes all authentication keys.
  /// This means that the user will be signed out from all connected devices.
  Future<void> signOutUser({int? userId}) async {
    userId ??= await authenticatedUserId;
    if (userId == null) return;

    await _session.db.delete(tAuthKey, where: tAuthKey.userId.equals(userId));
    _session._authenticatedUser = null;
  }
}

/// Collects methods for accessing cloud storage.
class StorageAccess {
  final Session _session;

  StorageAccess._(this._session);

  /// Store a file in the cloud storage. [storageId] is typically 'public' or
  /// 'private'. The public storage can be accessed through a public URL. The
  /// file is stored at the [path] relative to the cloud storage root directory,
  /// if a file already exists it will be replaced.
  Future<void> storeFile({
    required String storageId,
    required String path,
    required ByteData byteData,
    DateTime? expiration,
  }) async {
    var storage = _session.server.serverpod.storage[storageId];
    if (storage == null) {
      throw CloudStorageException('Storage $storageId is not registered');
    }

    await storage.storeFile(session: _session, path: path, byteData: byteData);
  }

  /// Retrieve a file from cloud storage.
  Future<ByteData?> retrieveFile({
    required String storageId,
    required String path,
  }) async {
    var storage = _session.server.serverpod.storage[storageId];
    if (storage == null) {
      throw CloudStorageException('Storage $storageId is not registered');
    }

    return await storage.retrieveFile(session: _session, path: path);
  }

  /// Checks if a file exists in cloud storage.
  Future<bool> fileExists({
    required String storageId,
    required String path,
  }) async {
    var storage = _session.server.serverpod.storage[storageId];
    if (storage == null) {
      throw CloudStorageException('Storage $storageId is not registered');
    }

    return await storage.fileExists(session: _session, path: path);
  }

  /// Deletes a file from cloud storage.
  Future<void> deleteFile({
    required String storageId,
    required String path,
  }) async {
    var storage = _session.server.serverpod.storage[storageId];
    if (storage == null) {
      throw CloudStorageException('Storage $storageId is not registered');
    }

    await storage.deleteFile(session: _session, path: path);
  }

  /// Gets the public URL for a file, if the [storageId] is a public storage.
  Future<Uri?> getPublicUrl({
    required String storageId,
    required String path,
  }) async {
    var storage = _session.server.serverpod.storage[storageId];
    if (storage == null) {
      throw CloudStorageException('Storage $storageId is not registered');
    }

    return await storage.getPublicUrl(session: _session, path: path);
  }

  /// Creates a new file upload description, that can be passed to the client's
  /// [FileUploader]. After the file has been uploaded, the
  /// [verifyDirectFileUpload] method should be called, or the file may be
  /// deleted.
  Future<String?> createDirectFileUploadDescription({
    required String storageId,
    required String path,
  }) async {
    var storage = _session.server.serverpod.storage[storageId];
    if (storage == null) {
      throw CloudStorageException('Storage $storageId is not registered');
    }

    return await storage.createDirectFileUploadDescription(
        session: _session, path: path);
  }

  /// Call this method after a file has been uploaded. It will return true
  /// if the file was successfully uploaded.
  Future<bool> verifyDirectFileUpload({
    required String storageId,
    required String path,
  }) async {
    var storage = _session.server.serverpod.storage[storageId];
    if (storage == null) {
      throw CloudStorageException('Storage $storageId is not registered');
    }

    return await storage.verifyDirectFileUpload(session: _session, path: path);
  }
}

/// Provides access to the Serverpod's [MessageCentral].
class MessageCentralAccess {
  final Session _session;

  MessageCentralAccess._(this._session);

  /// Adds a listener to a named channel. Whenever a message is posted using
  /// [postMessage], the [listener] will be notified.
  void addListener(
      String channelName, MessageCentralListenerCallback listener) {
    _session.server.messageCentral.addListener(_session, channelName, listener);
  }

  /// Removes a listener from a named channel.
  void removeListener(
      String channelName, MessageCentralListenerCallback listener) {
    _session.server.messageCentral
        .removeListener(_session, channelName, listener);
  }

  /// Posts a [message] to a named channel. Optionally a [destinationServerId]
  /// can be provided, in which case the message is sent only to that specific
  /// server within the cluster. If no [destinationServerId] is provided, the
  /// message is passed on to all servers in the cluster.
  void postMessage(String channelName, SerializableEntity message,
      {int? destinationServerId}) {
    _session.server.messageCentral.postMessage(channelName, message,
        destinationServerId: destinationServerId);
  }
}
