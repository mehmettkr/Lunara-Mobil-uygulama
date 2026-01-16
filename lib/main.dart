import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
// import 'firebase_options.dart'; // Kaldırıldı
import 'package:intl/date_symbol_data_local.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Default seçenekler kullanılacak (google-services.json)


  initializeDateFormatting('tr_TR', null).then((_) => runApp(const DreamFriendApp()));
}
