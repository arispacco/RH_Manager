import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../attendance/presentation/bloc/attendance_bloc.dart';
import '../../../attendance/presentation/bloc/attendance_event.dart';
import '../../../attendance/presentation/bloc/attendance_state.dart';

/// QR Scanner screen using the device camera.
///
/// On web/desktop, shows a manual code entry fallback.
/// On mobile, uses [MobileScannerController] for real camera scanning.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  MobileScannerController? _controller;
  bool _scanned = false;
  bool _isCameraAvailable = true;
  bool _torchOn = false;
  late final AnimationController _pulseController;
  final _manualCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );
    } catch (e) {
      setState(() => _isCameraAvailable = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _pulseController.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  void _onScanDetected(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() => _scanned = true);
    _processCode(barcode.rawValue!);
  }

  void _onManualSubmit() {
    final code = _manualCodeController.text.trim();
    if (code.isEmpty) return;
    setState(() => _scanned = true);
    _processCode(code);
  }

  void _processCode(String code) {
    // Clock in via the AttendanceBloc
    context.read<AttendanceBloc>().add(AttendanceClockIn(qrToken: code));

    // Show success and navigate back
    _showResult(context);
  }

  void _showResult(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return BlocBuilder<AttendanceBloc, AttendanceState>(
          builder: (context, state) {
            final isLoading = state.clockStatus == ClockStatus.loading;
            final success = state.clockStatus == ClockStatus.clockedIn;

            return Padding(
              padding: const EdgeInsets.all(28),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isLoading
                          ? Colors.blue.shade50
                          : success
                              ? const Color(0xFFE9F9F0)
                              : Colors.red.shade50,
                    ),
                    child: isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(strokeWidth: 3),
                          )
                        : Icon(
                            success
                                ? Icons.check_circle_rounded
                                : Icons.error_rounded,
                            size: 40,
                            color: success
                                ? const Color(0xFF1E7C4A)
                                : Colors.red,
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isLoading
                        ? 'Processing...'
                        : success
                            ? 'Clock-in Successful!'
                            : 'Clock-in Failed',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: success
                              ? const Color(0xFF1E7C4A)
                              : Colors.red,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLoading
                        ? 'Verifying your scan...'
                        : success
                            ? 'Your attendance has been recorded.'
                            : state.errorMessage ?? 'Please try again.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  if (!isLoading)
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        ctx.pop();
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: const Text('Done'),
                    ),
                ],
              ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Scan QR Code',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close_rounded),
        ),
        actions: [
          if (_isCameraAvailable && _controller != null)
            IconButton(
              onPressed: () {
                setState(() => _torchOn = !_torchOn);
                _controller!.toggleTorch();
              },
              icon: Icon(
                _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              ),
            ),
        ],
      ),
      body: _isCameraAvailable && _controller != null
          ? _buildCameraScanner(theme)
          : _buildManualEntry(theme),
    );
  }

  Widget _buildCameraScanner(ThemeData theme) {
    return Stack(
      children: [
        // Camera preview
        MobileScanner(
          controller: _controller!,
          onDetect: _onScanDetected,
        ),

        // Overlay with viewfinder
        Center(
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white
                        .withAlpha((100 + 155 * _pulseController.value).round()),
                    width: 3,
                  ),
                ),
              );
            },
          ),
        ),

        // Bottom instruction
        Positioned(
          bottom: 60,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Text(
                'Point your camera at the QR code',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  setState(() => _isCameraAvailable = false);
                },
                icon: const Icon(Icons.keyboard_rounded, color: Colors.white70),
                label: const Text(
                  'Enter code manually',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManualEntry(ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.qr_code_rounded,
                    size: 36,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Enter Code Manually',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Camera not available. Enter the code displayed on the check-in station.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _manualCodeController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    hintText: '000000',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade300,
                      letterSpacing: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _scanned ? null : _onManualSubmit,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('VERIFY CODE'),
                      SizedBox(width: 8),
                      Icon(Icons.check_rounded, size: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (_controller != null)
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _isCameraAvailable = true);
                    },
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Use camera instead'),
                  ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
