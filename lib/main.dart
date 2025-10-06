
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

    @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Picker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const PhotoUploadPage(),
    );
  }
}

class PhotoUploadPage extends StatefulWidget {
  const PhotoUploadPage({super.key});
  
    @override
  State<PhotoUploadPage> createState() => _PhotoUploadPageState();
}

class _PhotoUploadPageState extends State<PhotoUploadPage> {
  final ImagePicker _picker = ImagePicker();
  List<String> photoUrls = [];
  
  @override
  void initState() {
    super.initState();
    fetchPhotos(); // 앱 시작 시 서버에서 사진 불러오기
  }
  
  static const String apiBaseUrl = "http://192.168.68.100:3000"; // 개발용 서버 주소

// 카메라에서 사진 선택 및 업로드
  Future<void> pickAndUploadFromCamera() async {
    await _pickAndUpload(ImageSource.camera);
  }

// 갤러리에서 사진 선택 및 업로드
  Future<void> pickAndUploadFromGallery() async {
    await _pickAndUpload(ImageSource.gallery);
  }

// (공통) 사진 선택 및 업로드
  Future<void> _pickAndUpload(ImageSource source) async {
    try{
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) return;

      File imageFile = File(pickedFile.path);

      var request = http.MultipartRequest('POST', Uri.parse('$apiBaseUrl/upload'));
      request.files.add(await http.MultipartFile.fromPath('photo', imageFile.path));

      var response = await request.send();

      if (response.statusCode == 200) 
      {
        await fetchPhotos();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("업로드 성공")));
      }
      else
      {
        if(!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("업로드 실패")));
      }

    } catch (e) {
      debugPrint("업로드 중 오류: $e");
    }
  }

// 서버에서 사진 목록 불러오기
  Future<void> fetchPhotos() async {
    try {
      var response = await http.get(Uri.parse('$apiBaseUrl/photos'));
      if (response.statusCode == 200) {
        final body = response.body;
        final List<dynamic> jsonData = json.decode(body);
        setState(() {
          photoUrls = jsonData.cast<String>();
        });
      } else {
        debugPrint("사진 목록 불러오기 실패: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("사진 목록 불러오기 예외: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("사진 업로드"),
      ),
      body: Column(
        children: [
          IconButton.filled(
            onPressed: pickAndUploadFromCamera,
            icon: Icon(Icons.camera_alt),
          ),
          IconButton.filled(
            onPressed: pickAndUploadFromGallery,
            icon: Icon(Icons.image)
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: photoUrls.length,
              itemBuilder: (context, index) {
                return Image.network(
                  photoUrls[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}