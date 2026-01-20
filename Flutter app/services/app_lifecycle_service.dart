// lib/services/app_lifecycle_service.dart
import 'package:flutter/material.dart';
import 'websocket_service.dart';

class AppLifecycleService with WidgetsBindingObserver {
  final WebSocketService _webSocketService = WebSocketService();

  static final AppLifecycleService _instance = AppLifecycleService._internal();
  factory AppLifecycleService() => _instance;
  AppLifecycleService._internal();

  void initialize() {
    WidgetsBinding.instance.addObserver(this);
    _webSocketService.connect();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _webSocketService.connect();
    } else if (state == AppLifecycleState.paused) {
      _webSocketService.disconnect();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _webSocketService.disconnect();
  }
}