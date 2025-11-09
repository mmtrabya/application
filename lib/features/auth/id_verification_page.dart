// lib/features/auth/id_verification_page.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../core/widgets/gradient_container.dart';
import '../../providers/user_provider.dart';

class IDVerificationPage extends StatefulWidget {
  const IDVerificationPage({Key? key}) : super(key: key);

  @override
  State<IDVerificationPage> createState() => _IDVerificationPageState();
}

class _IDVerificationPageState extends State<IDVerificationPage> {
  XFile? _nationalIdFront;
  XFile? _nationalIdBack;
  XFile? _drivingLicense;
  bool _isLoading = false;
  final _nationalIdController = TextEditingController();
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
  }

  @override
  void dispose() {
    _nationalIdController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isDenied) {
      _showError('Camera permission is required to capture ID photos');
    }
  }

  Future<void> _capturePhoto(String type) async {
    await _requestCameraPermission();

    if (_cameras == null || _cameras!.isEmpty) {
      _showError('No camera found on device');
      return;
    }

    if (!mounted) return;

    final result = await Navigator.push<XFile>(
      context,
      MaterialPageRoute(
        builder: (context) => CameraCapturePage(
          camera: _cameras!.first,
          captureType: type,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        switch (type) {
          case 'national_id_front':
            _nationalIdFront = result;
            break;
          case 'national_id_back':
            _nationalIdBack = result;
            break;
          case 'driving_license':
            _drivingLicense = result;
            break;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_getTypeLabel(type)} captured successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'national_id_front':
        return 'National ID (Front)';
      case 'national_id_back':
        return 'National ID (Back)';
      case 'driving_license':
        return 'Driving License';
      default:
        return 'Document';
    }
  }

  Future<void> _submitVerification() async {
    if (_nationalIdController.text.isEmpty) {
      _showError('Please enter your National ID number');
      return;
    }

    if (_nationalIdFront == null) {
      _showError('Please capture National ID front photo');
      return;
    }

    if (_nationalIdBack == null) {
      _showError('Please capture National ID back photo');
      return;
    }

    if (_drivingLicense == null) {
      _showError('Please capture Driving License photo');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload documents to Firebase Storage
      await Provider.of<UserProvider>(context, listen: false)
          .uploadVerificationDocuments(
        nationalId: _nationalIdController.text,
        nationalIdFront: File(_nationalIdFront!.path),
        nationalIdBack: File(_nationalIdBack!.path),
        drivingLicense: File(_drivingLicense!.path),
      );

      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documents submitted successfully! Verification pending.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to submit documents: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Identity Verification'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GradientContainer(
                padding: const EdgeInsets.all(24),
                child: const Icon(
                  Icons.verified_user,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Verify Your Identity',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'To rent a vehicle, we need to verify your identity and driving license',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontFamily: 'Inter',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // National ID Number
              TextFormField(
                controller: _nationalIdController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'National ID Number',
                  prefixIcon: Icon(
                    Icons.badge_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
              ),
              const SizedBox(height: 24),

              // National ID Front
              _buildCaptureCard(
                title: 'National ID (Front)',
                subtitle: 'Capture front side of your National ID',
                icon: Icons.credit_card,
                isCaptured: _nationalIdFront != null,
                imagePath: _nationalIdFront?.path,
                onTap: () => _capturePhoto('national_id_front'),
              ),
              const SizedBox(height: 16),

              // National ID Back
              _buildCaptureCard(
                title: 'National ID (Back)',
                subtitle: 'Capture back side of your National ID',
                icon: Icons.credit_card,
                isCaptured: _nationalIdBack != null,
                imagePath: _nationalIdBack?.path,
                onTap: () => _capturePhoto('national_id_back'),
              ),
              const SizedBox(height: 16),

              // Driving License
              _buildCaptureCard(
                title: 'Driving License',
                subtitle: 'Capture your Driving License',
                icon: Icons.car_rental,
                isCaptured: _drivingLicense != null,
                imagePath: _drivingLicense?.path,
                onTap: () => _capturePhoto('driving_license'),
              ),
              const SizedBox(height: 32),

              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Your documents will be verified within 24 hours',
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                      : const Text(
                    'Submit for Verification',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isCaptured,
    String? imagePath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCaptured
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isCaptured ? Icons.check_circle : Icons.camera_alt,
                  color: isCaptured
                      ? Colors.green
                      : Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
              ],
            ),
            if (isCaptured && imagePath != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(imagePath),
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Camera Capture Page
class CameraCapturePage extends StatefulWidget {
  final CameraDescription camera;
  final String captureType;

  const CameraCapturePage({
    Key? key,
    required this.camera,
    required this.captureType,
  }) : super(key: key);

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();

      if (!mounted) return;
      Navigator.pop(context, image);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error capturing photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Capture ${widget.captureType.replaceAll('_', ' ')}'),
        backgroundColor: Colors.black,
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                Center(
                  child: CameraPreview(_controller),
                ),
                Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FloatingActionButton.large(
                      onPressed: _takePicture,
                      backgroundColor: const Color(0xFFD6FF3F),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 36,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}