import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:price_extractor/price_extractor.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CameraDescription>>(
      future: availableCameras(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              home: PriceExtractor(cameras: snapshot.data!),
            );
          } else {
            return MaterialApp(
              home: Scaffold(
                body: Center(child: Text('No camera available')),
              ),
            );
          }
        } else {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
      },
    );
  }
}
