import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

class StorageService {
  final _storage = FirebaseStorage.instance;

  Future<String> uploadImageFromUrl(String imageUrl, String fileName) async {
    try {
      // 1. Resmi indir
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Resim indirilemedi: ${response.statusCode}');
      }

      // 2. Storage referansı oluştur
      // Dosya adını benzersiz yapmak için timestamp veya uuid eklenebilir ama 
      // çağıran yer (fileName) bunu halledecek.
      final ref = _storage.ref().child('dream_images/$fileName.png');

      // 3. Resmi yükle
      final uploadTask = await ref.putData(
        response.bodyBytes,
        SettableMetadata(contentType: 'image/png'),
      );

      // 4. Kalıcı URL'i al
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Resim yükleme hatası: $e');
    }
  }
}
