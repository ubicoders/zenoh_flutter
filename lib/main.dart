import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:zenoh_dart/zenoh_dart.dart';

void main() {
  runApp(const MyApp());
}

class LogEntry {
  final DateTime timestamp;
  final String topic;
  final String payload;
  final bool isSystem;
  final bool isError;

  LogEntry({
    required this.timestamp,
    this.topic = '',
    required this.payload,
    this.isSystem = false,
    this.isError = false,
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lidar View',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ZenohSubscriberPage(),
    );
  }
}

class ZenohSubscriberPage extends StatefulWidget {
  const ZenohSubscriberPage({super.key});

  @override
  State<ZenohSubscriberPage> createState() => _ZenohSubscriberPageState();
}

class _ZenohSubscriberPageState extends State<ZenohSubscriberPage> {
  ZenohClient? _client;
  ZenohSubscriber? _subscriber;
  StreamSubscription<ZenohSample>? _subscription;

  String _status = 'Disconnected';
  final List<LogEntry> _logs = [];

  // Connection config state
  String _protocol = 'tcp';
  String _topic = 'test/**';
  final List<String> _discoveredTopics = ['test/**'];
  bool _isDiscovering = false;
  late final TextEditingController _ipController;
  late final TextEditingController _portController;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(
      text: Platform.isAndroid ? '10.0.2.2' : '127.0.0.1',
    );
    _portController = TextEditingController(text: '7447');
    _initZenoh();
  }

  void _addSystemLog(String message, {bool isError = false}) {
    setState(() {
      _logs.insert(
        0,
        LogEntry(
          timestamp: DateTime.now(),
          payload: message,
          isSystem: true,
          isError: isError,
        ),
      );
      if (_logs.length > 5000) _logs.removeLast();
    });
    debugPrint(isError ? 'ZERR: $message' : 'ZSYS: $message');
  }

  void _addMessageLog(String topic, String payload) {
    setState(() {
      _logs.insert(
        0,
        LogEntry(timestamp: DateTime.now(), topic: topic, payload: payload),
      );
      if (_logs.length > 5000) _logs.removeLast();
    });
  }

  Future<void> _discoverTopics() async {
    if (_isDiscovering) return;
    setState(() {
      _isDiscovering = true;
      _status = 'Discovering topics...';
      _discoveredTopics.clear();
      _discoveredTopics.add('test/**');
      _topic = 'test/**';
    });

    ZenohClient? tempClient;
    ZenohSubscriber? tempSub;
    try {
      final locator =
          '$_protocol/${_ipController.text}:${_portController.text}';
      final config = ZenohConfig(mode: ZenohMode.client, locator: locator);

      tempClient = await ZenohClient.connect(config);
      tempSub = await tempClient.subscribe('test/**');

      final sub = tempSub.stream.listen((sample) {
        final topic = sample.keyExpr;
        if (!_discoveredTopics.contains(topic)) {
          setState(() {
            _discoveredTopics.add(topic);
          });
        }
      });

      // Listen for 2.5 seconds
      await Future.delayed(const Duration(milliseconds: 2500));
      await sub.cancel();

      setState(() {
        _status = 'Discovered ${_discoveredTopics.length - 1} actual topics';
      });
    } catch (e) {
      _addSystemLog('Discovery error: $e', isError: true);
      setState(() => _status = 'Discovery Error: $e');
    } finally {
      if (tempSub != null && tempClient != null) {
        unawaited(tempClient.undeclareSubscriber(tempSub));
      }
      if (tempClient != null) {
        unawaited(tempClient.close());
      }
      setState(() {
        _isDiscovering = false;
      });
    }
  }

  Future<void> _initZenoh() async {
    if (_status == 'Starting subscriber...') return;

    setState(() => _status = 'Starting subscriber...');
    _addSystemLog('Starting subscriber...');

    try {
      final locator =
          '$_protocol/${_ipController.text}:${_portController.text}';

      _addSystemLog('Connecting to Zenoh Router at $locator...');

      final config = ZenohConfig(mode: ZenohMode.client, locator: locator);

      final client = await ZenohClient.connect(config);
      _addSystemLog('Successfully connected!');

      final subscriber = await client.subscribe(_topic);
      _addSystemLog('Subscribed to $_topic');

      final subscription = subscriber.stream.listen(
        (sample) {
          final msg = sample.payloadAsString();
          _addMessageLog(sample.keyExpr, msg);
        },
        onError: (Object error) {
          _addSystemLog('Subscription error: $error', isError: true);
          setState(() => _status = 'Subscription error: $error');
        },
      );

      setState(() {
        _client = client;
        _subscriber = subscriber;
        _subscription = subscription;
        _status = 'Connected';
      });
    } catch (error, stack) {
      _addSystemLog('Error connecting: $error', isError: true);
      debugPrintStack(stackTrace: stack);
      setState(() => _status = 'Error: $error');
    }
  }

  Future<void> _disconnectZenoh() async {
    _addSystemLog('Disconnecting from router...');
    _subscription?.cancel();
    if (_client != null) {
      if (_subscriber != null) {
        unawaited(_client!.undeclareSubscriber(_subscriber!));
      }
      unawaited(_client!.close());
    }
    setState(() {
      _subscription = null;
      _subscriber = null;
      _client = null;
      _status = 'Disconnected';
    });
    _addSystemLog('Disconnected successfully.');
  }

  Widget _buildLogCard(LogEntry log) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      elevation: log.isSystem ? 0 : 1,
      color: log.isError
          ? Colors.red.shade50
          : log.isSystem
          ? Colors.transparent
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: log.isError
              ? Colors.red.shade200
              : log.isSystem
              ? Colors.grey.shade300
              : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!log.isSystem)
                  Expanded(
                    child: Text(
                      log.topic,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  Text(
                    log.isError ? 'System Error' : 'System Event',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: log.isError
                          ? Colors.red.shade700
                          : Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                Text(
                  log.timestamp
                      .toIso8601String()
                      .split('T')
                      .last
                      .substring(0, 12),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              log.payload,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                color: log.isError ? Colors.red.shade900 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isConnecting = _status == 'Starting subscriber...';
    final bool isConnected = _status == 'Connected';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Lidar View',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Server Status Bar (Config)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ROUTER CONFIGURATION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isConnected
                            ? Colors.green.shade50
                            : (isConnecting
                                  ? Colors.orange.shade50
                                  : Colors.red.shade50),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isConnected
                              ? Colors.green.shade200
                              : (isConnecting
                                    ? Colors.orange.shade200
                                    : Colors.red.shade200),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isConnected
                                  ? Colors.green
                                  : (isConnecting ? Colors.orange : Colors.red),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isConnected
                                ? 'Online'
                                : (isConnecting ? 'Connecting' : 'Offline'),
                            style: TextStyle(
                              color: isConnected
                                  ? Colors.green.shade700
                                  : (isConnecting
                                        ? Colors.orange.shade800
                                        : Colors.red.shade700),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _protocol,
                        decoration: InputDecoration(
                          labelText: 'Protocol',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'tcp', child: Text('TCP')),
                          DropdownMenuItem(value: 'udp', child: Text('UDP')),
                          DropdownMenuItem(value: 'ws', child: Text('WS')),
                        ],
                        onChanged: (isConnected || isConnecting)
                            ? null
                            : (val) {
                                if (val != null) {
                                  setState(() {
                                    _protocol = val;
                                    if (val == 'ws') {
                                      _portController.text = '8000';
                                    } else {
                                      _portController.text = '7447';
                                    }
                                  });
                                }
                              },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: _ipController,
                        enabled: !isConnected && !isConnecting,
                        decoration: InputDecoration(
                          labelText: 'IP Address',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _portController,
                        enabled: !isConnected && !isConnecting,
                        decoration: InputDecoration(
                          labelText: 'Port',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _topic,
                        decoration: InputDecoration(
                          labelText: 'Topic to Subscribe',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        items: _discoveredTopics.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Text(t == 'test/**' ? 'test/** (All)' : t),
                          );
                        }).toList(),
                        onChanged:
                            (isConnected || isConnecting || _isDiscovering)
                            ? null
                            : (val) {
                                if (val != null) {
                                  setState(() {
                                    _topic = val;
                                  });
                                }
                              },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: _isDiscovering
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.search,
                                color: Colors.deepPurple,
                              ),
                        tooltip: 'Discover Topics',
                        onPressed:
                            (_isDiscovering || isConnected || isConnecting)
                            ? null
                            : _discoverTopics,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isConnected
                              ? Colors.red.shade50
                              : Colors.deepPurple,
                          foregroundColor: isConnected
                              ? Colors.red.shade700
                              : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isConnected
                                  ? Colors.red.shade200
                                  : Colors.transparent,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: isConnecting
                            ? null
                            : (isConnected ? _disconnectZenoh : _initZenoh),
                        icon: Icon(
                          isConnected ? Icons.stop_circle : Icons.play_circle,
                        ),
                        label: Text(
                          isConnected ? 'Disconnect' : 'Connect',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isConnected &&
                    !isConnecting &&
                    _status != 'Disconnected') ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Text(
                      _status,
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Cards List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                return _buildLogCard(_logs[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();

    _subscription?.cancel();
    if (_client != null) {
      if (_subscriber != null) {
        unawaited(_client!.undeclareSubscriber(_subscriber!));
      }
      unawaited(_client!.close());
    }
    super.dispose();
  }
}
