// lib/services/activity_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/activity.dart';
import 'user_session_service.dart';

class ActivityService {
  final String _baseUrl;
  final String _storageKey = 'cached_activities';
  final StreamController<List<Activity>> _activitiesController = 
      StreamController<List<Activity>>.broadcast();

  ActivityService({
    String? baseUrl,
  })  : _baseUrl = baseUrl ?? kBaseUrl;

  Stream<List<Activity>> get activitiesStream => _activitiesController.stream;

  Future<List<Activity>> _fetchActivitiesFromBackend({int limit = 10}) async {
    try {
      final token = await UserSessionService.getUserToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/activities?limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Activity.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load activities: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error fetching activities from backend: $e');
      }
      rethrow;
    }
  }

  Future<List<Activity>> getRecentActivities({int limit = 10}) async {
    try {
      // Try to get from cache first for immediate response
      final cached = await _getCachedActivities();
      if (cached.isNotEmpty) {
        _activitiesController.add(cached.take(limit).toList());
      }

      // Fetch fresh activities from backend
      final activities = await _fetchActivitiesFromBackend(limit: limit);
      
      // Update cache with fresh data
      await _cacheActivities(activities);
      
      // Update stream with fresh data
      final result = activities.take(limit).toList();
      _activitiesController.add(result);
      return result;
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error in getRecentActivities: $e');
      }
      // Return empty list instead of falling back to notifications
      return [];
    }
  }

  Future<void> markAsRead(String activityId) async {
    try {
      final token = await UserSessionService.getUserToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/activities/$activityId/mark-read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Update local state
        final currentActivities = await _getCachedActivities();
        final updated = currentActivities.map((activity) {
          if (activity.id == activityId) {
            return activity.copyWith(isRead: true);
          }
          return activity;
        }).toList();

        await _cacheActivities(updated);
        _activitiesController.add(updated);
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error saving activities to cache: $e');
      }
      rethrow;
    }
  }

  // Caching
  Future<void> _cacheActivities(List<Activity> activities) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = activities.map((a) => a.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  Future<List<Activity>> _getCachedActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString == null) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => Activity.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error loading cached activities: $e');
      }
      return [];
    }
  }

  void dispose() {
    _activitiesController.close();
  }
}