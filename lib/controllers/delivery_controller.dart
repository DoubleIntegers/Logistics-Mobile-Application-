import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/delivery_task_model.dart';

enum DeliveryControllerState { idle, scanning, uploading, success, error }

class DeliveryController extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  DeliveryControllerState _state = DeliveryControllerState.idle;
  List<DeliveryTaskModel> _tasks = DeliveryTaskModel.dummyList;
  String? _errorMessage;
  String? _scannedCode;
  double _uploadProgress = 0;

  DeliveryControllerState get state => _state;
  List<DeliveryTaskModel> get tasks => List.unmodifiable(_tasks);
  String? get errorMessage => _errorMessage;
  String? get scannedCode => _scannedCode;
  double get uploadProgress => _uploadProgress;

  bool get isUploading => _state == DeliveryControllerState.uploading;
  bool get isIdle => _state == DeliveryControllerState.idle;

  List<DeliveryTaskModel> get activeTasks => _tasks
      .where((t) =>
          t.status == DeliveryStatus.inTransit ||
          t.status == DeliveryStatus.pending)
      .toList();

  List<DeliveryTaskModel> get completedTasks => _tasks
      .where((t) => t.status == DeliveryStatus.delivered)
      .toList();

  /// Called when QR scanner detects a code.
  /// Returns the matched task or null.
  DeliveryTaskModel? onQrScanned(String code) {
    _scannedCode = code;
    log('📷 QR Scanned: $code');

    final matched = _tasks.cast<DeliveryTaskModel?>().firstWhere(
          (t) => t!.receiptCode == code,
          orElse: () => null,
        );

    if (matched != null) {
      log('✅ Matched task: ${matched.id} — ${matched.itemName}');
    } else {
      log('⚠️ No task matched for code: $code');
    }

    notifyListeners();
    return matched;
  }

  /// Upload proof image → Supabase Storage → update task status.
  Future<bool> confirmDelivery({
    required String taskId,
    required File imageFile,
  }) async {
    try {
      _state = DeliveryControllerState.uploading;
      _uploadProgress = 0;
      _errorMessage = null;
      notifyListeners();

      // ── Step 1: Upload to Supabase Storage ─────────────
      final ext = p.extension(imageFile.path).replaceAll('.', '');
      final mimeType =
          lookupMimeType(imageFile.path) ?? 'image/jpeg';
      final fileName =
          'proof_${taskId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final storagePath = 'delivery_proofs/$fileName';

      log('📤 Uploading proof image...');
      log('   Path   : $storagePath');
      log('   MIME   : $mimeType');
      log('   Size   : ${(await imageFile.length() / 1024).toStringAsFixed(1)} KB');

      _uploadProgress = 0.3;
      notifyListeners();

      await _supabase.storage
          .from('proof-of-delivery') // bucket name
          .upload(
            storagePath,
            imageFile,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: false,
            ),
          );

      _uploadProgress = 0.7;
      notifyListeners();

      // ── Step 2: Get public URL ──────────────────────────
      final publicUrl = _supabase.storage
          .from('proof-of-delivery')
          .getPublicUrl(storagePath);

      log('🔗 Public URL: $publicUrl');

      _uploadProgress = 0.85;
      notifyListeners();

      // ── Step 3: Update delivery_tasks table ────────────
      await _supabase.from('delivery_tasks').update({
        'status': 'delivered',
        'proof_image_url': publicUrl,
        'delivered_at': DateTime.now().toIso8601String(),
      }).eq('id', taskId);

      log('✅ Task $taskId marked as DELIVERED');

      // ── Step 4: Update local state ──────────────────────
      _tasks = _tasks.map((t) {
        if (t.id == taskId) {
          return t.copyWith(
            status: DeliveryStatus.delivered,
            proofImageUrl: publicUrl,
            deliveredAt: DateTime.now(),
          );
        }
        return t;
      }).toList();

      _uploadProgress = 1.0;
      _state = DeliveryControllerState.success;
      notifyListeners();
      return true;
    } catch (e) {
      log('❌ confirmDelivery error: $e');
      _state = DeliveryControllerState.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void resetState() {
    _state = DeliveryControllerState.idle;
    _scannedCode = null;
    _uploadProgress = 0;
    _errorMessage = null;
    notifyListeners();
  }
}