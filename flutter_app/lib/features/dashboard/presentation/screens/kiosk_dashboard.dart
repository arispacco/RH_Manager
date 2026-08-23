import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


import '../../../../app/config.dart';
import '../../../../app/di.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../services/postgresql_service.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';

/// Full-screen kiosk display for the QR code station.
/// Automatically refreshes the QR code every 15 seconds.
class KioskDashboard extends StatefulWidget {
  const KioskDashboard({super.key});

  @override
  State<KioskDashboard> createState() => _KioskDashboardState();
}

class _KioskDashboardState extends State<KioskDashboard> {
  Timer? _timer;
  late Timer _clockTimer;
  int _secondsRemaining = 15;
  int _rotationSeconds = 15;
  String _currentQrData = '';
  String _currentTime = '';
  String? _companyId;
  String? _qrSecret;
  bool _isLoadingConfig = true;

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
    
    _fetchKioskConfig();
  }

  Future<void> _fetchKioskConfig() async {
    try {
      if (AppConfig.isLocal) {
        await _fetchKioskConfigLocal();
      } else {
        await _fetchKioskConfigSupabase();
      }

      _generateNewQr();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 1) {
          if (mounted) {
            setState(() {
              _secondsRemaining--;
            });
          }
        } else {
          _generateNewQr();
        }
      });
    } catch (e) {
       // Ignore error handling for prototype simplicity, but set loading false
       if (mounted) setState(() { _isLoadingConfig = false; });
    }
  }

  Future<void> _fetchKioskConfigLocal() async {
    final postgres = sl<PostgreSQLService>();
    if (!postgres.isConnected) await postgres.initialize();

    final authUser = sl<AuthBloc>().state.user;
    final String profileId;
    if (authUser != null) {
      profileId = authUser.id;
    } else {
      final rows = await postgres.connection.execute(
        Sql.named('SELECT id FROM profiles ORDER BY created_at LIMIT 1'),
      );
      if (rows.isEmpty) throw Exception('No kiosk profile found');
      profileId = rows.first.toColumnMap()['id'].toString();
    }

    final profile = await postgres.getProfile(profileId);
    _companyId = profile.companyId;

    final config = await postgres.getKioskConfigForCompany(_companyId!);
    _qrSecret = config.qrSecret;
    _rotationSeconds = config.rotationSeconds;

    setState(() {
      _isLoadingConfig = false;
      _secondsRemaining = _rotationSeconds;
    });
  }

  Future<void> _fetchKioskConfigSupabase() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Kiosk not logged in');

    final profile = await supabase.from('profiles').select('company_id').eq('id', user.id).single();
    _companyId = profile['company_id'];

    final config = await supabase.from('qr_configs').select('qr_secret, rotation_seconds').eq('company_id', _companyId as Object).single();
    _qrSecret = config['qr_secret'];
    _rotationSeconds = (config['rotation_seconds'] as int?) ?? 15;
    
    setState(() {
      _isLoadingConfig = false;
      _secondsRemaining = _rotationSeconds;
    });
  }

  void _updateClock() {
    setState(() {
      _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
    });
  }

  void _generateNewQr() {
    if (_companyId == null || _qrSecret == null) return;
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final dataToSign = '$_companyId:$timestamp';
    _secondsRemaining = _rotationSeconds;
    
    // Generate HMAC-SHA256 signature
    final hmac = Hmac(sha256, utf8.encode(_qrSecret!));
    final signature = hmac.convert(utf8.encode(dataToSign)).toString();
    
    setState(() {
      _currentQrData = '$dataToSign:$signature';
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Responsive sizing based on screen height
    final isSmallScreen = screenHeight < 700;
    final double qrSize = isSmallScreen ? 200.0 : 300.0;
    final double titleFontSize = isSmallScreen ? 42.0 : 64.0;
    final double iconSize = isSmallScreen ? 48.0 : 64.0;
    final double spacingLarge = isSmallScreen ? 30.0 : 60.0;
    final double spacingSmall = isSmallScreen ? 12.0 : 24.0;
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            // Sign Out Button (Hidden in top left for maintenance)
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.grey),
                onPressed: () {
                  _showSignOutDialog(context);
                },
              ),
            ),
            
            Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  Icon(
                    Icons.business_center_rounded,
                    size: iconSize,
                    color: AppTheme.secondary,
                  ),
                  SizedBox(height: spacingSmall),
                  Text(
                    _currentTime,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: spacingLarge),
                  
                  // QR Code Card
                  if (_isLoadingConfig)
                    const CircularProgressIndicator()
                  else if (_currentQrData.isEmpty)
                    const Text('Error loading Kiosk configuration. Check if company has qr_configs set.')
                  else
                  Card(
                    elevation: 12,
                    shadowColor: AppTheme.primary.withAlpha(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          QrImageView(
                            data: _currentQrData,
                            version: QrVersions.auto,
                            size: qrSize,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: AppTheme.primary,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  value: _secondsRemaining / 15,
                                  strokeWidth: 3,
                                  backgroundColor: theme.colorScheme.outlineVariant,
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.secondary),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Refreshing in $_secondsRemaining seconds',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: spacingLarge),
                  Text(
                    'Scan with your AttendanceOS app to clock in',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Kiosk Mode'),
        content: const Text('Are you sure you want to sign out of the Kiosk?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
