
import 'dart:io';

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
  
  Future<void> pickAndUploadPhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);

    var request = http.MultipartRequest(
        'POST', Uri.parse('http://localhost:3000/upload'));
    request.files.add(await http.MultipartFile.fromPath('photo', imageFile.path));
    var response = await request.send();

    if (response.statusCode == 200) {
      fetchPhotos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("업로드 실패")));
    }
  }

  Future<void> fetchPhotos() async {
    try {
      var response = await http.get(Uri.parse('http://localhost:3000/photos'));
      if (response.statusCode == 200) {
        // 서버에서 JSON 배열로 URL 반환한다고 가정
        setState(() {
          photoUrls = List<String>.from(
              (response.body.isNotEmpty ? response.body.split(',') : []));
        });
      }
    } catch (e) {
      print("사진 목록 불러오기 실패: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ㅇㅇ"),
      ),
      body: Column(children: [ElevatedButton(
        onPressed: null //pickAndUploadPhoto
      , child: const Text("사진 찍기")
      ),
      Expanded(
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
          itemCount: photoUrls.length,
          itemBuilder: (context, index) {
            return Image.network(photoUrls[index], fit: BoxFit.cover);
          },
          )),
        ],
      ),
    );
  }
}
