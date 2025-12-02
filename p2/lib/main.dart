import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}


Future<Database> createDatabase() async {
  final databasePath = await getDatabasesPath();
  final dbPath = path.join(databasePath, '202310010e202310105.db');

  print('DB DIR: $databasePath');
  print('DB PATH: $dbPath');

  return openDatabase(
    dbPath,
    version: 1,
    onCreate: (db, _) async {
      await db.execute('''
        CREATE TABLE tarefas (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          titulo TEXT,
          descricao TEXT,
          prioridade TEXT,
          status TEXT,
          dataAgendamento TEXT,
          criadoEm TEXT
        )
      ''');
    },
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cadastro de Tarefas',
      home: TarefasPage(),
    );
  }
}

class TarefasPage extends StatefulWidget {
  const TarefasPage({super.key});

  @override
  State<TarefasPage> createState() => _TarefasPageState();
}

class _TarefasPageState extends State<TarefasPage> {
  Database? db;
  List<Map<String, dynamic>> tarefas = [];

  @override
  void initState() {
    super.initState();
    _openDb();
  }

  Future<void> _openDb() async {
    db = await createDatabase();
    // Banco criado, mas ainda não há CRUD; lista fica vazia
    if (mounted) setState(() => tarefas = []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro de Tarefas'),
      ),
      body: tarefas.isEmpty
          ? const Center(child: Text('Nenhuma tarefa cadastrada.'))
          : ListView.builder(
              itemCount: tarefas.length,
              itemBuilder: (context, i) {
                final tarefa = tarefas[i];
                return ListTile(
                  title: Text(tarefa['titulo'] ?? ''),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // CRUD ainda não implementado
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}