/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: public_member_api_docs
// ignore_for_file: unused_import

import 'dart:typed_data' as typed_data;
import 'package:serverpod/serverpod.dart';

import 'protocol.dart';

import '../endpoints/cache.dart';
import '../endpoints/insights.dart';

class Endpoints extends EndpointDispatch {
  @override
  void initializeEndpoints(Server server) {
    var endpoints = <String, Endpoint>{
      'cache': CacheEndpoint()..initialize(server, 'cache', null),
      'insights': InsightsEndpoint()..initialize(server, 'insights', null),
    };

    connectors['cache'] = EndpointConnector(
      name: 'cache',
      endpoint: endpoints['cache']!,
      methodConnectors: {
        'put': MethodConnector(
          name: 'put',
          params: {
            'priority': ParameterDescription(
                name: 'priority', type: bool, nullable: false),
            'key': ParameterDescription(
                name: 'key', type: String, nullable: false),
            'data': ParameterDescription(
                name: 'data', type: String, nullable: false),
            'group': ParameterDescription(
                name: 'group', type: String, nullable: true),
            'expiration': ParameterDescription(
                name: 'expiration', type: DateTime, nullable: true),
          },
          call: (Session session, Map<String, dynamic> params) async {
            return (endpoints['cache'] as CacheEndpoint).put(
              session,
              params['priority'],
              params['key'],
              params['data'],
              params['group'],
              params['expiration'],
            );
          },
        ),
        'get': MethodConnector(
          name: 'get',
          params: {
            'priority': ParameterDescription(
                name: 'priority', type: bool, nullable: false),
            'key': ParameterDescription(
                name: 'key', type: String, nullable: false),
          },
          call: (Session session, Map<String, dynamic> params) async {
            return (endpoints['cache'] as CacheEndpoint).get(
              session,
              params['priority'],
              params['key'],
            );
          },
        ),
        'invalidateKey': MethodConnector(
          name: 'invalidateKey',
          params: {
            'priority': ParameterDescription(
                name: 'priority', type: bool, nullable: false),
            'key': ParameterDescription(
                name: 'key', type: String, nullable: false),
          },
          call: (Session session, Map<String, dynamic> params) async {
            return (endpoints['cache'] as CacheEndpoint).invalidateKey(
              session,
              params['priority'],
              params['key'],
            );
          },
        ),
        'invalidateGroup': MethodConnector(
          name: 'invalidateGroup',
          params: {
            'priority': ParameterDescription(
                name: 'priority', type: bool, nullable: false),
            'group': ParameterDescription(
                name: 'group', type: String, nullable: false),
          },
          call: (Session session, Map<String, dynamic> params) async {
            return (endpoints['cache'] as CacheEndpoint).invalidateGroup(
              session,
              params['priority'],
              params['group'],
            );
          },
        ),
        'clear': MethodConnector(
          name: 'clear',
          params: {
            'priority': ParameterDescription(
                name: 'priority', type: bool, nullable: false),
          },
          call: (Session session, Map<String, dynamic> params) async {
            return (endpoints['cache'] as CacheEndpoint).clear(
              session,
              params['priority'],
            );
          },
        ),
      },
    );

    connectors['insights'] = EndpointConnector(
      name: 'insights',
      endpoint: endpoints['insights']!,
      methodConnectors: {
        'getRuntimeSettings': MethodConnector(
          name: 'getRuntimeSettings',
          params: {},
          call: (Session session, Map<String, dynamic> params) async {
            return (endpoints['insights'] as InsightsEndpoint)
                .getRuntimeSettings(
              session,
            );
          },
        ),
        'setRuntimeSettings': MethodConnector(
          name: 'setRuntimeSettings',
          params: {
            'runtimeSettings': ParameterDescription(
                name: 'runtimeSettings',
                type: RuntimeSettings,
                nullable: false),
          },
          call: (Session session, Map<String, dynamic> params) async {
            return (endpoints['insights'] as InsightsEndpoint)
                .setRuntimeSettings(
              session,
              params['runtimeSettings'],
            );
          },
        ),
        'reloadRuntimeSettings': MethodConnector(
          name: 'reloadRuntimeSettings',
          params: {},
          call: (Session session, Map<String, dynamic> params) async {
            return (endpoints['insights'] as InsightsEndpoint)
                .reloadRuntimeSettings(
              session,
            );
          },
        ),
        'clearAllLogs': MethodConnector(
          name: 'clearAllLogs',
          params: {},
          call: (Session session, Map<String, dynamic> params) async {
            return (endpoints['insights'] as InsightsEndpoint).clearAllLogs(
              session,
            );
          },
        ),
        'getSessionLog': MethodConnector(
          name: 'getSessionLog',
          params: {
            'numEntries': ParameterDescription(
                name: 'numEntries', type: int, nullable: true),
            'filter': ParameterDescription(
                name: 'filter', type: SessionLogFilter, nullable: true),
          },
          call: (Session session, Map<String, dynamic> params) async {
            return (endpoints['insights'] as InsightsEndpoint).getSessionLog(
              session,
              params['numEntries'],
              params['filter'],
            );
          },
        ),
        'getOpenSessionLog': MethodConnector(
          name: 'getOpenSessionLog',
          params: {
            'numEntries': ParameterDescription(
                name: 'numEntries', type: int, nullable: true),
            'filter': ParameterDescription(
                name: 'filter', type: SessionLogFilter, nullable: true),
          },
          call: (Session session, Map<String, dynamic> params) async {
            return (endpoints['insights'] as InsightsEndpoint)
                .getOpenSessionLog(
              session,
              params['numEntries'],
              params['filter'],
            );
          },
        ),
        'getCachesInfo': MethodConnector(
          name: 'getCachesInfo',
          params: {
            'fetchKeys': ParameterDescription(
                name: 'fetchKeys', type: bool, nullable: false),
          },
          call: (Session session, Map<String, dynamic> params) async {
            return (endpoints['insights'] as InsightsEndpoint).getCachesInfo(
              session,
              params['fetchKeys'],
            );
          },
        ),
        'shutdown': MethodConnector(
          name: 'shutdown',
          params: {},
          call: (Session session, Map<String, dynamic> params) async {
            return (endpoints['insights'] as InsightsEndpoint).shutdown(
              session,
            );
          },
        ),
        'checkHealth': MethodConnector(
          name: 'checkHealth',
          params: {},
          call: (Session session, Map<String, dynamic> params) async {
            return (endpoints['insights'] as InsightsEndpoint).checkHealth(
              session,
            );
          },
        ),
      },
    );
  }

  @override
  void registerModules(Serverpod pod) {}
}
