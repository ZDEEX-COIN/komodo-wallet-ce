import 'dart:convert';

// ignore: unnecessary_import
import 'package:universal_html/js.dart';
import 'package:universal_html/js_util.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api.dart';
import 'package:web_dex/mm2/mm2.dart';
import 'package:web_dex/mm2/rpc_web.dart';
import 'package:web_dex/platform/platform.dart';
import 'package:web_dex/shared/utils/utils.dart';

class MM2Web extends MM2 implements MM2WithInit {
  final RPCWeb _rpc = const RPCWeb();

  @override
  Future<void> init() async {
    // TODO! Test for breaking changes to mm2 initialisation accross reloads
    while (isBusyPreloading == true) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      // TODO: Safe guard for max retries
    }

    if (isPreloaded == false) {
      await promiseToFuture<dynamic>(initWasm());
    }
  }

  /// TODO: Document
  bool? get isBusyPreloading => context['is_mm2_preload_busy'] as bool?;

  /// TODO: Document
  bool? get isPreloaded => context['is_mm2_preloaded'] as bool?;

  @override
  Future<void> start(String? passphrase) async {
    final Map<String, dynamic> params = await MM2.generateStartParams(
      passphrase: passphrase,
      gui: 'web_dex ZDEEX',
      dbDir: null,
      userHome: null,
    );

    await promiseToFuture<void>(
      wasmRunMm2(
        jsonEncode(params),
        allowInterop<Future<void> Function(int level, String message)>(
          _handleLog,
        ),
      ),
    );
  }

  @override
  Future<void> stop() async {
    // todo: consider using FFI instead of RPC here
    await mm2Api.stop();
  }

  @override
  Future<String> version() async {
    return wasmVersion();
  }

  @override
  Future<MM2Status> status() async {
    return MM2Status.fromInt(wasmMm2Status());
  }

  @override
  Future<dynamic> call(dynamic reqStr) async {
    return await _rpc.call(MM2.prepareRequest(reqStr));
  }

  Future<void> _handleLog(int level, String message) async {
    log(message, path: 'mm2 log');
  }
}
