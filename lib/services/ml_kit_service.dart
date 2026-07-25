import 'dart:io';
import 'dart:typed_data';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class MLKitService {
  static Future<String> analyzeImageLocally(Uint8List imageBytes) async {
    final tempDir = await getTemporaryDirectory();
    final filePath = p.join(tempDir.path, 'temp_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
    final file = File(filePath);
    await file.writeAsBytes(imageBytes);

    final inputImage = InputImage.fromFilePath(filePath);
    
    // Initialize recognizers
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final imageLabeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.5));
    final objectDetector = ObjectDetector(
      options: ObjectDetectorOptions(
        mode: DetectionMode.single,
        classifyObjects: true,
        multipleObjects: true,
      ),
    );

    try {
      // 1. Text Recognition
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      String detectedText = recognizedText.text.replaceAll('\n', ' ').trim();

      // 2. Image Labeling
      final List<ImageLabel> labels = await imageLabeler.processImage(inputImage);
      List<String> detectedLabels = labels.map((l) => l.label).toList();

      // 3. Object Detection
      final List<DetectedObject> objects = await objectDetector.processImage(inputImage);
      List<String> detectedObjects = [];
      for (var obj in objects) {
        for (var label in obj.labels) {
          detectedObjects.add(label.text);
        }
      }

      // Cleanup
      if (await file.exists()) {
        await file.delete();
      }

      // Format result
      StringBuffer sb = StringBuffer();
      sb.writeln("--- نتائج التحليل المحلي (ML Kit) ---");
      
      if (detectedText.isNotEmpty) {
        sb.writeln("النصوص المكتشفة: $detectedText");
      } else {
        sb.writeln("لم يتم اكتشاف نصوص واضحة.");
      }

      if (detectedLabels.isNotEmpty) {
        sb.writeln("العناصر المحتملة: ${detectedLabels.take(5).join(', ')}");
      }

      if (detectedObjects.isNotEmpty) {
        sb.writeln("الأشياء المحددة: ${detectedObjects.join(', ')}");
      }

      return sb.toString();
    } catch (e) {
      return "فشل التحليل المحلي: ${e.toString()}";
    } finally {
      // Close recognizers to free resources
      textRecognizer.close();
      imageLabeler.close();
      objectDetector.close();
    }
  }

  static void dispose() {
    // No-op now as we close inside the method
  }
}
