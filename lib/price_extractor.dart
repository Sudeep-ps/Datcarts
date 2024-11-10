import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:price_extractor/image_processor.dart';

class PriceExtractor extends StatefulWidget {
  final List<CameraDescription> cameras;

  PriceExtractor({required this.cameras});

  @override
  _PriceExtractorState createState() => _PriceExtractorState();
}

class _PriceExtractorState extends State<PriceExtractor> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    requestCameraPermission(context);
  }

  Future<void> requestStoragePermission() async {
    if (await Permission.storage.request().isGranted) {
      print("Storage permission granted.");
    } else {
      print("Storage permission denied.");
    }
  }

  Future<void> requestCameraPermission(BuildContext context) async {
    var status = await Permission.camera.request();

    if (status.isGranted) {
      setState(() {
        _isPermissionGranted = true;
      });
      initializeCamera();
    } else if (status.isDenied) {
      _showPermissionDeniedDialog(context);
    } else if (status.isPermanentlyDenied) {
      _showPermanentlyDeniedDialog(context);
    }
  }

  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Camera Permission Required"),
          content: Text(
              "This app needs camera access to function. Please grant camera permission."),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showPermanentlyDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Permission Permanently Denied"),
          content: Text(
              "Camera access has been permanently denied. Please go to settings to enable it."),
          actions: [
            TextButton(
              child: Text("Open Settings"),
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
            ),
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> initializeCamera() async {
    if (!_isPermissionGranted) return;

    _controller = CameraController(
      widget.cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } on CameraException catch (e) {
      print("Camera initialization error: ${e.description}");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> captureAndProcessImage() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      print("CameraController is not initialized or has been disposed.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Camera is not ready. Please try again.'),
        ),
      );
      return;
    }

    try {
      final image = await _controller!.takePicture();
      final processor = ImageProcessor();
      final price =
          await processor.processSingleImage(imageFile: File(image.path));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(price != 'no price found'
              ? 'Price : $price \n Processing complete! Check output/prices.txt'
              : 'Non recognized'),
        ),
      );
    } on CameraException catch (e) {
      print("Error capturing image: ${e.description}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred while capturing the image.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PRICE EXTRACTOR',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(2, -2),
                color: Colors.blueGrey,
                blurRadius: 5,
              )
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (_isCameraInitialized)
              Expanded(child: CameraPreview(_controller!)),
            SizedBox(height: 5),
            MaterialButton(
              child: Icon(Icons.camera_alt),
              onPressed: _isCameraInitialized ? captureAndProcessImage : null,
              height: MediaQuery.of(context).size.height * 0.08,
              minWidth: MediaQuery.of(context).size.width * 0.2,
              color: Colors.blue[200],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Center(
              child: Builder(
                builder: (context) {
                  return MaterialButton(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    color: Colors.blue[200],
                    minWidth: MediaQuery.of(context).size.width * 0.9,
                    height: MediaQuery.of(context).size.height * 0.05,
                    onPressed: () async {
                      await requestStoragePermission();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Storage permission granted! Ready to capture images.'),
                        ),
                      );
                    },
                    child: Text('Extract Prices from Images'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
