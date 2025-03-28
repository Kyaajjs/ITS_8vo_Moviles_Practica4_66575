  import 'package:flutter/material.dart';
  import 'package:flutter_dotenv/flutter_dotenv.dart';
  import 'api_service.dart';



  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env"); // Cargar variables de entorno
    runApp(const MyApp());
  }

  class MyApp extends StatelessWidget {
    const MyApp({super.key});

    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        title: 'ToDo List App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        initialRoute: '/register',
        routes: {
          '/register': (context) => const RegisterScreen(),
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const MyHomePage(title: 'ToDo List'),
        },
      );
    }
  }


  //app original

  class MyHomePage extends StatefulWidget {
    const MyHomePage({super.key, required this.title});

    final String title;

    @override
    State<MyHomePage> createState() => _MyHomePageState();
  }

  class _MyHomePageState extends State<MyHomePage> {
    List<Map<String, dynamic>> tasks = [];

    @override
    void initState() {
      super.initState();
      _loadTasks();
    }

    Future<void> _loadTasks() async {
      try {
        final tasksFromApi = await ApiService.getTasks();
        setState(() {
          tasks = tasksFromApi;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }

    void _navigateToTaskScreen({int? index}) async {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TaskScreen(
            task: index != null ? tasks[index] : null,
          ),
        ),
      );

      if (result != null) {
        try {
          if (index != null) {
            await ApiService.updateTask(tasks[index]['id'], result);
          } else {
            await ApiService.createTask(result);
          }
          _loadTasks();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }

    void _deleteTask(int index) async {
      try {
        await ApiService.deleteTask(tasks[index]['id']);
        _loadTasks();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }

    void _toggleTaskCompletion(int index) async {
      try {
        await ApiService.toggleTaskCompletion(
          tasks[index]['id'],
          !tasks[index]['completada'],
        );
        _loadTasks();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: tasks.isEmpty
            ? const Center(
          child: Text(
            'No hay tareas pendientes',
            style: TextStyle(fontSize: 18),
          ),
        )
            : ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text(
                  task['titulo'],
                  style: TextStyle(
                    decoration: task['completada']
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                subtitle: Text(task['descripcion']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        _navigateToTaskScreen(index: index);
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        task['completada']
                            ? Icons.check_circle
                            : Icons.check_circle_outline,
                      ),
                      onPressed: () {
                        _toggleTaskCompletion(index);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        _deleteTask(index);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _navigateToTaskScreen();
          },
          tooltip: 'Agregar tarea',
          child: const Icon(Icons.add),
        ),
      );
    }
  }
  //Pantalla de registro


  class RegisterScreen extends StatefulWidget {
    const RegisterScreen({Key? key}) : super(key: key);

    @override
    State<RegisterScreen> createState() => _RegisterScreenState();
  }

  class _RegisterScreenState extends State<RegisterScreen> {
    final TextEditingController _usernameController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();

    bool _isLoading = false;

    // Función para registrar al usuario
    void _register() async {
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      if (username.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor completa todos los campos')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        // Llamada al método register de ApiService
        final token = await ApiService.register(username, password);
        if (token != null) {
          // Si el backend retorna el token, navegamos al login
          Navigator.pushReplacementNamed(context, '/login');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error en registro: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }

    // Campo de texto con estilo redondeado
    Widget _buildRoundedTextField({
      required TextEditingController controller,
      required String label,
      required String hint,
      bool obscure = false,
      TextInputType keyboardType = TextInputType.text,
    }) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          // Efecto de sombra para darle profundidad
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            labelStyle: const TextStyle(color: Colors.white70),
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.black54, // Fondo semitransparente
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 24,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      );
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        // Usamos un Container con gradiente para el fondo
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0F2027),
                Color(0xFF203A43),
                Color(0xFF2C5364),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Título futurista
                  Text(
                    "REGISTER",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      // Un gradiente en el texto con 'Shader'
                      foreground: Paint()
                        ..shader = const LinearGradient(
                          colors: <Color>[
                            Color(0xFFDA22FF),
                            Color(0xFF9733EE),
                          ],
                        ).createShader(
                          Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
                        ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Campo de texto para usuario
                  _buildRoundedTextField(
                    controller: _usernameController,
                    label: "Username",
                    hint: "Enter your username",
                  ),

                  // Campo de texto para contraseña
                  _buildRoundedTextField(
                    controller: _passwordController,
                    label: "Password",
                    hint: "Enter your password",
                    obscure: true,
                  ),
                  const SizedBox(height: 32),

                  // Botón de registrar o CircularProgressIndicator
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: const Color(0xFF9733EE),
                      ),
                      child: const Text(
                        "SUBMIT",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }


  // Pantalla de Login



  class LoginScreen extends StatefulWidget {
    const LoginScreen({super.key});

    @override
    State<LoginScreen> createState() => _LoginScreenState();
  }

  class _LoginScreenState extends State<LoginScreen> {
    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();
    bool _isLoading = false;

    void _login() async {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor ingresa correo y contraseña')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        // Llamamos a la función real de login que devuelve un token
        final token = await ApiService.login(email, password);
        if (token != null) {
          // Aquí podrías almacenar el token de forma segura (ej: secure_storage)
          // Navegar a la pantalla principal
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MyHomePage(title: 'ToDo List'),
            ),
          );
        } else {
          throw 'Credenciales incorrectas';
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }

    // Reutilizamos un método para crear campos de texto con estilo redondeado
    Widget _buildRoundedTextField({
      required TextEditingController controller,
      required String label,
      bool obscure = false,
      TextInputType keyboardType = TextInputType.text,
    }) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          // Sombra para el efecto “flotante”
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.black54, // Fondo semitransparente
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 24,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      );
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        // Eliminamos el AppBar para un diseño “full screen”
        body: Container(
          // Gradiente oscuro de fondo
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0F2027),
                Color(0xFF203A43),
                Color(0xFF2C5364),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Título con gradiente en el texto
                  Text(
                    "INICIAR SESIÓN",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..shader = const LinearGradient(
                          colors: <Color>[
                            Color(0xFFDA22FF),
                            Color(0xFF9733EE),
                          ],
                        ).createShader(
                          Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
                        ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Logo (opcional)

                  const SizedBox(height: 24),

                  // Campo de correo
                  _buildRoundedTextField(
                    controller: _emailController,
                    label: 'Correo',
                    keyboardType: TextInputType.emailAddress,
                  ),

                  // Campo de contraseña
                  _buildRoundedTextField(
                    controller: _passwordController,
                    label: 'Contraseña',
                    obscure: true,
                  ),

                  const SizedBox(height: 32),

                  // Botón de login o indicador de carga
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: const Color(0xFF9733EE),
                      ),
                      child: const Text(
                        'INICIAR SESIÓN',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }


  // Pantalla para agregar/editar tareas
  class TaskScreen extends StatefulWidget {
    final Map<String, dynamic>? task;

    const TaskScreen({super.key, this.task});

    @override
    State<TaskScreen> createState() => _TaskScreenState();
  }

  class _TaskScreenState extends State<TaskScreen> {
    final TextEditingController _titleController = TextEditingController();
    final TextEditingController _descriptionController = TextEditingController();
    bool _isCompleted = false;

    @override
    void initState() {
      super.initState();
      if (widget.task != null) {
        _titleController.text = widget.task!['titulo'];
        _descriptionController.text = widget.task!['descripcion'];
        _isCompleted = widget.task!['completada'];
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.task == null ? 'Agregar tarea' : 'Editar tarea'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  hintText: 'Ingresa el título de la tarea',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Ingresa la descripción de la tarea',
                ),
                maxLines: null,
                keyboardType: TextInputType.multiline,
              ),
              CheckboxListTile(
                title: const Text('Completada'),
                value: _isCompleted,
                onChanged: (value) {
                  setState(() {
                    _isCompleted = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_titleController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('El título es obligatorio'),
                      ),
                    );
                  } else {
                    Navigator.pop(context, {
                      'titulo': _titleController.text,
                      'descripcion': _descriptionController.text,
                      'completada': _isCompleted,
                    });
                  }
                },
                child: Text(widget.task == null ? 'Guardar' : 'Actualizar'),
              ),
            ],
          ),
        ),
      );
    }
  }

