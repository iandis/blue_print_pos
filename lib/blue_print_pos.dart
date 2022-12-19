import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:blue_print_pos/models/models.dart';
import 'package:blue_print_pos/receipt/receipt_section_text.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils.dart';
import 'package:fluetooth/fluetooth.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:qr_flutter/qr_flutter.dart';

export 'package:esc_pos_utils_plus/esc_pos_utils.dart' show PaperSize;
export 'package:fluetooth/fluetooth.dart' show FluetoothDevice;
export 'models/models.dart';
export 'receipt/receipt.dart';

class BluePrintPos {
  static final BluePrintPos _instance = BluePrintPos();

  static BluePrintPos get instance => _instance;

  static const MethodChannel _channel = MethodChannel('blue_print_pos');

  /// State to get bluetooth is connected
  bool _isConnected = false;

  /// Getter value [_isConnected]
  bool get isConnected => _isConnected;

  FluetoothDevice? _selectedDevice;

  /// Selected device after connecting
  FluetoothDevice? get selectedDevice => _selectedDevice;

  /// return bluetooth device list, handler Android and iOS in [BlueScanner]
  Future<List<FluetoothDevice>> scan() {
    return Fluetooth().getAvailableDevices();
  }

  /// When connecting, reassign value [selectedDevice] from parameter [device]
  /// and if connection time more than [timeout]
  /// will return [ConnectionStatus.timeout]
  /// When connection success, will return [ConnectionStatus.connected]
  Future<ConnectionStatus> connect(
    FluetoothDevice device, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final FluetoothDevice fDevice =
          await Fluetooth().connect(device.id).timeout(timeout);
      _selectedDevice = fDevice;
      _isConnected = true;
      return Future<ConnectionStatus>.value(ConnectionStatus.connected);
    } on Exception catch (error) {
      log('$runtimeType - Error $error');
      _isConnected = false;
      _selectedDevice = null;
      return Future<ConnectionStatus>.value(ConnectionStatus.timeout);
    }
  }

  /// To stop communication between bluetooth device and application
  Future<ConnectionStatus> disconnect() async {
    await Fluetooth().disconnect();
    _isConnected = false;
    _selectedDevice = null;
    return ConnectionStatus.disconnect;
  }

  /// This method only for print text
  /// value and styling inside model [ReceiptSectionText].
  /// [feedCount] to create more space after printing process done
  ///
  /// [useCut] to cut printing process
  ///
  /// [duration] the delay duration before converting the html to bytes.
  /// defaults to 0.
  ///
  /// [textScaleFactor] the text scale factor (must be > 0 or null).
  /// note that this currently only works on Android.
  /// defaults to system's font settings.
  /// 
  /// [batchPrintOptions] to print each [ReceiptSectionText]'s content in batch.
  /// defaults to [BatchPrintOptions.full].
  Future<void> printReceiptText(
    ReceiptSectionText receiptSectionText, {
    int feedCount = 0,
    bool useCut = false,
    bool useRaster = false,
    double duration = 0,
    PaperSize paperSize = PaperSize.mm58,
    double? textScaleFactor,
    BatchPrintOptions? batchPrintOptions,
  }) async {
    final int contentLength = receiptSectionText.contentLength;

    final BatchPrintOptions batchOptions =
        batchPrintOptions ?? BatchPrintOptions.full;

    final Iterable<List<Object>> startEndIter =
        batchOptions.getStartEnd(contentLength);

    for (final List<Object> startEnd in startEndIter) {
      final ReceiptSectionText section = receiptSectionText.getSection(
        startEnd[0] as int,
        startEnd[1] as int,
      );
      final bool isEndOfBatch = startEnd[2] as bool;
      final Uint8List bytes = await contentToImage(
        content: section.getContent(),
        duration: duration,
        textScaleFactor: textScaleFactor,
      );
      final List<int> byteBuffer = await _getBytes(
        bytes,
        paperSize: paperSize,
        feedCount: isEndOfBatch ? feedCount : batchOptions.feedCount,
        useCut: isEndOfBatch ? useCut : batchOptions.useCut,
        useRaster: useRaster,
      );
      await _printProcess(byteBuffer);
      log(
        'start: ${startEnd[0]} end: ${startEnd[1]}',
        name: 'BluePrintPos.printReceiptText',
      );

      if (batchOptions.delay != Duration.zero &&
          !batchOptions.delay.isNegative) {
        await Future<void>.delayed(batchOptions.delay);
      }
    }
  }

  /// This method only for print image with parameter [bytes] in List<int>
  /// define [width] to custom width of image, default value is 120
  /// [feedCount] to create more space after printing process done
  /// [useCut] to cut printing process
  Future<void> printReceiptImage(
    List<int> bytes, {
    int width = 120,
    int feedCount = 0,
    bool useCut = false,
    bool useRaster = false,
    PaperSize paperSize = PaperSize.mm58,
  }) async {
    final List<int> byteBuffer = await _getBytes(
      bytes,
      customWidth: width,
      feedCount: feedCount,
      useCut: useCut,
      useRaster: useRaster,
      paperSize: paperSize,
    );
    await _printProcess(byteBuffer);
  }

  /// This method only for print QR, only pass value on parameter [data]
  /// define [size] to size of QR, default value is 120
  /// [feedCount] to create more space after printing process done
  /// [useCut] to cut printing process
  Future<void> printQR(
    String data, {
    int size = 120,
    int feedCount = 0,
    bool useCut = false,
  }) async {
    final List<int> byteBuffer = await _getQRImage(data, size.toDouble());
    await printReceiptImage(
      byteBuffer,
      width: size,
      feedCount: feedCount,
      useCut: useCut,
    );
  }

  /// Reusable method for print text, image or QR based value [byteBuffer]
  /// Handler Android or iOS will use method writeBytes from ByteBuffer
  /// But in iOS more complex handler using service and characteristic
  Future<void> _printProcess(List<int> byteBuffer) async {
    try {
      if (!await Fluetooth().isConnected) {
        _isConnected = false;
        _selectedDevice = null;
        return;
      }
      await Fluetooth().sendBytes(byteBuffer);
    } on Exception catch (error) {
      log('$runtimeType - Error $error');
    }
  }

  /// This method to convert byte from [data] into as image canvas.
  /// It will automatically set width and height based [paperSize].
  /// [customWidth] to print image with specific width
  /// [feedCount] to generate byte buffer as feed in receipt.
  /// [useCut] to cut of receipt layout as byte buffer.
  Future<List<int>> _getBytes(
    List<int> data, {
    PaperSize paperSize = PaperSize.mm58,
    int customWidth = 0,
    int feedCount = 0,
    bool useCut = false,
    bool useRaster = false,
  }) async {
    List<int> bytes = <int>[];
    final CapabilityProfile profile = await CapabilityProfile.load();
    final Generator generator = Generator(paperSize, profile);
    final img.Image _resize = img.copyResize(
      img.decodeImage(data)!,
      width: customWidth > 0 ? customWidth : paperSize.width,
    );
    if (useRaster) {
      bytes += generator.imageRaster(_resize);
    } else {
      bytes += generator.image(_resize);
    }
    if (feedCount > 0) {
      bytes += generator.feed(feedCount);
    }
    if (useCut) {
      bytes += generator.cut();
    }
    return bytes;
  }

  /// Handler to generate QR image from [text] and set the [size].
  /// Using painter and convert to [Image] object and return as [Uint8List]
  Future<Uint8List> _getQRImage(String text, double size) async {
    try {
      final Image image = await QrPainter(
        data: text,
        version: QrVersions.auto,
        gapless: false,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
      ).toImage(size);
      final ByteData? byteData =
          await image.toByteData(format: ImageByteFormat.png);
      assert(byteData != null);
      return byteData!.buffer.asUint8List();
    } on Exception catch (exception) {
      print('$runtimeType - $exception');
      rethrow;
    }
  }

  /// Converts HTML content to bytes
  ///
  /// [content] the html text
  ///
  /// [duration] the delay duration before converting the html to bytes.
  /// defaults to 0.
  ///
  /// [textScaleFactor] the text scale factor (must be > 0 or null).
  /// note that this currently only works on Android.
  /// defaults to system's font settings.
  static Future<Uint8List> contentToImage({
    required String content,
    double duration = 0,
    double? textScaleFactor,
  }) async {
    assert(
      textScaleFactor == null || textScaleFactor > 0,
      '`textScaleFactor` must be either null or more than zero.',
    );
    final Map<String, dynamic> arguments = <String, dynamic>{
      'content': content,
      'duration': Platform.isIOS ? 2000 : duration,
      'textScaleFactor': textScaleFactor,
    };
    Uint8List results = Uint8List.fromList(<int>[]);
    try {
      results = await _channel.invokeMethod('contentToImage', arguments) ??
          Uint8List.fromList(<int>[]);
    } on Exception catch (e) {
      log('[method:contentToImage]: $e');
      throw Exception('Error: $e');
    }
    return results;
  }
}
