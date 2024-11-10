import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageProcessor {
  final TextRecognizer textRecognizer = TextRecognizer();

  Future<void> processImages() async {
    await requestStoragePermission();
    try {
      final inputDir = Directory('/sdcard/images/');
      final directory = await getExternalStorageDirectory();

      if (directory == null) {
        print("External storage directory is not available.");
        return;
      }

      // Ensure the output directory exists or create it
      final outputDir = Directory('${directory.path}/output');
      if (!await outputDir.exists()) {
        await outputDir.create(
            recursive: true); // Create the directory if it doesn't exist
      }

      final outputFile = File('${outputDir.path}/prices.txt');

      if (inputDir.existsSync()) {
        List<String> results = [];
        for (var image in inputDir.listSync()) {
          if (image is File &&
              (image.path.endsWith(".jpg") || image.path.endsWith(".png"))) {
            final inputImage = InputImage.fromFilePath(image.path);
            final recognizedText =
                await textRecognizer.processImage(inputImage);

            String price = extractPrice(recognizedText.text);
            print("Extracted Price: $price");
            results.add("${image.uri.pathSegments.last} $price");
          }
        }

        await outputFile.writeAsString(results.join('\n'));
        print("Results written to: ${outputFile.path}");
      } else {
        print("Input directory does not exist: ${inputDir.path}");
      }
    } catch (e) {
      print("An error occurred while processing images: $e");
    } finally {
      textRecognizer.close();
    }
  }

  Future<String?> processSingleImage({File? imageFile}) async {
    if (imageFile == null) {
      print("No image file provided.");
      return null;
    }

    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final recognizedText = await textRecognizer.processImage(inputImage);

      String price = extractPrice(recognizedText.text);
      print("Extracted Price from single image: $price");

      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final outputDir = Directory('${directory.path}/output');
        if (!await outputDir.exists()) {
          await outputDir.create(
              recursive: true); // Ensure the directory is created
        }

        final outputFile = File('${outputDir.path}/single_image_price.txt');
        await outputFile.writeAsString("File: ${imageFile.path}\nPrice: $price",
            mode: FileMode.append);

        print("Single image result written to: ${outputFile.path}");
      } else {
        print("Output directory not available.");
      }

      return price;
    } catch (e) {
      print("An error occurred while processing the image: $e");
      return null;
    }
  }

  String extractPrice(String text) {
    // Regular expression to match numbers with exactly two decimal places (e.g., 78.99) or numbers followed by '/-'
    final priceRegExp = RegExp(r'\b\d+\.\d{2}\b|\b\d+/-(?=\s|$)');

    // Find the first match of the specified pattern
    final match = priceRegExp.firstMatch(text);

    if (match != null) {
      print("Price found: ${match.group(0)}");
      return match.group(0) ?? "no price found";
    } else {
      print("No price found");
      return "no price found";
    }
  }

  Future<void> requestStoragePermission() async {
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      print("Storage permission denied");
    }
  }
}
