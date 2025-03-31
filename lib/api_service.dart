import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final String _apiUrl = dotenv.get('API_URL');

  static String? _jwtToken;

  // Función para validar que el correo tenga un formato correcto
  static bool _isValidEmail(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email);
  }

  // Función para obtener el token desde SharedPreferences
  static Future<String?> _getTokenFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');  // Recupera el token almacenado
  }

  // Login al backend y guarda el token JWT
  static Future<String?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_apiUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _jwtToken = data['token'];

      // Guardar el token en SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('jwt_token', _jwtToken!);  // Guardar el token como una cadena

      return _jwtToken; // Se retorna el token para que el main pueda validarlo
    } else {
      throw Exception('Login fallido: ${response.body}');
    }
  }

  // Nuevo método para registrar un usuario (se utiliza el correo como username)
  static Future<String?> register(String email, String password) async {
    // Validar el formato del correo antes de hacer la llamada al API
    if (!_isValidEmail(email)) {
      throw Exception('El formato de correo no es válido');
    }

    final response = await http.post(
      Uri.parse('$_apiUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': email, // usamos el correo como username
        'password': password,
      }),
    );

    if (response.statusCode == 201) { // 201: creado exitosamente
      final data = json.decode(response.body);
      _jwtToken = data['token'];
      return _jwtToken;
    } else {
      throw Exception('Registro fallido: ${response.body}');
    }
  }

  // Headers con JWT
  static Future<Map<String, String>> _authHeaders() async {
    String? token = await _getTokenFromSharedPreferences();  // Obtener el token de SharedPreferences

    // Retorna el encabezado Authorization con el token si existe
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Obtener todas las tareas
  static Future<List<Map<String, dynamic>>> getTasks() async {
    final response = await http.get(
      Uri.parse('$_apiUrl/tareas'),
      headers: await _authHeaders(),  // Llamar a _authHeaders para agregar el token
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Error al cargar las tareas');
    }
  }

  // Obtener una tarea por ID
  static Future<Map<String, dynamic>> getTaskById(int id) async {
    final response = await http.get(
      Uri.parse('$_apiUrl/tareas/$id'),
      headers: await _authHeaders(),  // Llamar a _authHeaders para agregar el token
    );
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(response.body));
    } else {
      throw Exception('Error al cargar la tarea');
    }
  }

  // Crear una nueva tarea
  static Future<Map<String, dynamic>> createTask(Map<String, dynamic> task) async {
    final response = await http.post(
      Uri.parse('$_apiUrl/tareas'),
      headers: await _authHeaders(),  // Llamar a _authHeaders para agregar el token
      body: json.encode(task),
    );
    if (response.statusCode == 201) {  // Cambié a 201 para indicar creación exitosa
      return Map<String, dynamic>.from(json.decode(response.body));
    } else {
      throw Exception('Error al crear la tarea: ${response.body}');
    }
  }

  // Actualizar una tarea
  static Future<Map<String, dynamic>> updateTask(int id, Map<String, dynamic> task) async {
    final response = await http.put(
      Uri.parse('$_apiUrl/tareas/$id'),
      headers: await _authHeaders(),  // Llamar a _authHeaders para agregar el token
      body: json.encode(task),
    );
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(response.body));
    } else {
      throw Exception('Error al actualizar la tarea');
    }
  }

  // Marcar una tarea como completada
  static Future<Map<String, dynamic>> toggleTaskCompletion(int id, bool completed) async {
    final response = await http.patch(
      Uri.parse('$_apiUrl/tareas/$id'),
      headers: await _authHeaders(),  // Llamar a _authHeaders para agregar el token
      body: json.encode({'completada': completed}),
    );
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(response.body));
    } else {
      throw Exception('Error al actualizar la tarea');
    }
  }

  // Eliminar una tarea
  static Future<void> deleteTask(int id) async {
    final response = await http.delete(
      Uri.parse('$_apiUrl/tareas/$id'),
      headers: await _authHeaders(),  // Llamar a _authHeaders para agregar el token
    );
    if (response.statusCode != 204) {
      throw Exception('Error al eliminar la tarea');
    }
  }
}
