import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';

const Color primaryColor = Colors.lightBlue;
const Color secondaryColor = Colors.cyan;
const Color iceBlueBackground = Color.fromARGB(255, 200, 233, 233);
const String statusPendente = 'Pendente';
const String statusConcluida = 'Concluída';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

Future<Database> createDatabase() async {
  final databasePath = await getDatabasesPath();
  final dbPath = path.join(databasePath, 'tarefas_app.db');

  print('DB DIR: $databasePath');
  print('DB PATH: $dbPath');

  return openDatabase(
    dbPath,
    version: 2,
    onCreate: (db, _) async {
      await db.execute('''
        CREATE TABLE tarefas (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          titulo TEXT,
          descricao TEXT,
          prioridade TEXT,
          status TEXT DEFAULT '$statusPendente',
          dataAgendamento TEXT,
          criadoEm TEXT
        )
      ''');
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        try {
          await db.execute(
              'ALTER TABLE tarefas ADD COLUMN status TEXT DEFAULT "$statusPendente"');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE tarefas ADD COLUMN dataAgendamento TEXT');
        } catch (_) {}
      }
    },
  );
}

String tarefaToJson(Map<String, dynamic> tarefa) {
  return jsonEncode(tarefa);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cadastro de Tarefas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          secondary: secondaryColor,
          surface: iceBlueBackground,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: secondaryColor,
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const TarefasPage(),
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
  List<Map<String, dynamic>> _todasTarefas = [];
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _openDb();
  }

  Future<void> _openDb() async {
    db = await createDatabase();
    if (mounted) readTarefas();
  }

  Future<void> readTarefas() async {
    if (db == null) return;
    final data = await db!.query(
      'tarefas',
      orderBy: 'status = "$statusPendente" DESC, prioridade DESC, criadoEm DESC',
    );
    if (mounted) setState(() => _todasTarefas = data);
  }

  List<Map<String, dynamic>> _getTarefasFiltradas(int index) {
    if (_todasTarefas.isEmpty) return [];

    switch (index) {
      case 1:
        return _todasTarefas
            .where((t) => (t['status'] ?? statusPendente) == 'Resolvido')
            .toList();
      case 2:
        return _todasTarefas
            .where((t) => (t['status'] ?? statusPendente) != 'Resolvido')
            .toList();
      case 0:
      default:
        return _todasTarefas;
    }
  }

  Future<void> _deleteTarefa(int id) async {
    await db?.delete(
      'tarefas',
      where: 'id = ?',
      whereArgs: [id],
    );
    readTarefas();
  }

  Future<void> _toggleStatus(Map<String, dynamic> tarefa) async {
    final newStatus = (tarefa['status'] ?? statusPendente) == 'Resolvido'
        ? statusPendente
        : 'Resolvido';

    await db?.update(
      'tarefas',
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [tarefa['id']],
    );
    readTarefas();
  }

  void _openTarefaForm([Map<String, dynamic>? tarefa]) {
    if (db == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext ctx) => TarefaFormPage(
          db: db!,
          tarefa: tarefa,
        ),
      ),
    ).then((_) => readTarefas());
  }

  Widget _buildTarefaList(List<Map<String, dynamic>> listaTarefas) {
    if (listaTarefas.isEmpty) {
      return const Center(child: Text('Nenhuma tarefa nesta categoria.'));
    }
    return ListView.builder(
      itemCount: listaTarefas.length,
      itemBuilder: (context, i) {
        final tarefa = listaTarefas[i];
        return TarefaListItem(
          tarefa: tarefa,
          onEdit: () => _openTarefaForm(tarefa),
          onDelete: () => _deleteTarefa(tarefa['id']),
          onToggleStatus: () => _toggleStatus(tarefa),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: _tabIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lista de Tarefas'),
          bottom: TabBar(
            onTap: (index) => setState(() => _tabIndex = index),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: 'Todas'),
              Tab(text: 'Concluídas'),
              Tab(text: 'Pendentes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTarefaList(_getTarefasFiltradas(0)),
            _buildTarefaList(_getTarefasFiltradas(1)),
            _buildTarefaList(_getTarefasFiltradas(2)),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openTarefaForm(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class TarefaListItem extends StatelessWidget {
  final Map<String, dynamic> tarefa;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const TarefaListItem({
    super.key,
    required this.tarefa,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  IconData _getPrioridadeIcon(String? prioridade) {
    switch (prioridade) {
      case 'Alta':
        return Icons.keyboard_double_arrow_up;
      case 'Média':
        return Icons.keyboard_arrow_up;
      case 'Baixa':
      default:
        return Icons.keyboard_arrow_down;
    }
  }

  Color _getPrioridadeColor(String? prioridade) {
    switch (prioridade) {
      case 'Alta':
        return Colors.red;
      case 'Média':
        return Colors.amber.shade700;
      case 'Baixa':
      default:
        return Colors.green;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'Resolvido':
        return Icons.check_circle_outline;
      case 'Aguardando':
        return Icons.access_time_filled;
      case 'Agendamento':
        return Icons.schedule;
      case statusPendente:
      default:
        return Icons.error_outline;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Resolvido':
        return Colors.green;
      case 'Aguardando':
        return Colors.amber;
      case 'Agendamento':
        return Colors.orange;
      case statusPendente:
      default:
        return Colors.red.shade700;
    }
  }

  String _formatDate(String isoDate) {
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(isoDate));
    } catch (_) {
      return 'Data inválida';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = tarefa['status'] ?? statusPendente;
    final prioridade = tarefa['prioridade'] ?? 'Baixa';
    final isConcluida = status == 'Resolvido';
    final statusText = status == 'Resolvido' ? statusConcluida : status;
    final toggleActionText =
        isConcluida ? 'Marcar como Pendente' : 'Marcar como Concluída';

    return ListTile(
      leading: Icon(_getStatusIcon(status), color: _getStatusColor(status)),
      title: Text(
        tarefa['titulo'],
        style: isConcluida
            ? const TextStyle(
                decoration: TextDecoration.lineThrough, color: Colors.grey)
            : null,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tarefa['descricao'] ?? 'Sem descrição'),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                _getPrioridadeIcon(prioridade),
                color: _getPrioridadeColor(prioridade),
                size: 18,
              ),
              Text(
                ' $prioridade',
                style: TextStyle(
                  color: _getPrioridadeColor(prioridade),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              if (tarefa['dataAgendamento'] != null)
                Text(
                  '| Agendado: ${_formatDate(tarefa['dataAgendamento'])}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.blueGrey,
                  ),
                ),
            ],
          ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'edit') {
            onEdit();
          } else if (value == 'delete') {
            onDelete();
          } else if (value == 'toggle_status') {
            onToggleStatus();
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'toggle_status',
            child: Text(toggleActionText),
          ),
          const PopupMenuItem<String>(
            value: 'edit',
            child: Text('Editar'),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            value: 'delete',
            child: Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
        icon: const Icon(Icons.more_vert),
      ),
      onTap: onEdit,
    );
  }
}

class TarefaFormPage extends StatefulWidget {
  final Database db;
  final Map<String, dynamic>? tarefa;

  const TarefaFormPage({super.key, required this.db, this.tarefa});

  @override
  State<TarefaFormPage> createState() => _TarefaFormPageState();
}

class _TarefaFormPageState extends State<TarefaFormPage> {
  late final TextEditingController _tituloController;
  late final TextEditingController _descricaoController;
  late final TextEditingController _dataAgendamentoController;
  String _prioridadeSelecionada = 'Baixa';
  String _statusSelecionado = statusPendente;
  String? _dataCriacao;

  final List<String> _prioridades = ['Baixa', 'Média', 'Alta'];
  final List<String> _statuses = [
    statusPendente,
    'Resolvido',
    'Aguardando',
    'Agendamento',
  ];
  bool get isEditing => widget.tarefa != null;
  bool get showDataAgendamento => _statusSelecionado == 'Agendamento';

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController();
    _descricaoController = TextEditingController();
    _dataAgendamentoController = TextEditingController();

    if (isEditing) {
      _tituloController.text = widget.tarefa!['titulo'] ?? '';
      _descricaoController.text = widget.tarefa!['descricao'] ?? '';
      final prioridade = widget.tarefa!['prioridade'] as String?;
      _prioridadeSelecionada =
          _prioridades.contains(prioridade) ? prioridade! : 'Baixa';
      _statusSelecionado = widget.tarefa!['status'] ?? statusPendente;
      _dataAgendamentoController.text =
          widget.tarefa!['dataAgendamento'] != null
              ? DateFormat('dd/MM/yyyy HH:mm')
                  .format(DateTime.parse(widget.tarefa!['dataAgendamento']))
              : '';
      _dataCriacao = widget.tarefa!['criadoEm'];
    } else {
      _dataCriacao = DateTime.now().toIso8601String();
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _dataAgendamentoController.dispose();
    super.dispose();
  }

  Future<void> _saveTarefa() async {
    if (_tituloController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O título da tarefa não pode ser vazio.')),
      );
      return;
    }

    String? dataAgendamentoIso;
    if (showDataAgendamento && _dataAgendamentoController.text.isNotEmpty) {
      try {
        final dataHora = DateFormat('dd/MM/yyyy HH:mm')
            .parse(_dataAgendamentoController.text);
        dataAgendamentoIso = dataHora.toIso8601String();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Formato de data inválido. Use: dd/MM/yyyy HH:mm'),
          ),
        );
        return;
      }
    }

    final data = {
      'titulo': _tituloController.text.trim(),
      'descricao': _descricaoController.text.trim(),
      'prioridade': _prioridadeSelecionada,
      'status': _statusSelecionado,
      'dataAgendamento': dataAgendamentoIso,
      'criadoEm': _dataCriacao ?? DateTime.now().toIso8601String(),
    };

    final json = tarefaToJson(data);
    print('TAREFA JSON: $json');

    if (isEditing && widget.tarefa!['id'] != null) {
      await widget.db.update(
        'tarefas',
        data,
        where: 'id = ?',
        whereArgs: [widget.tarefa!['id']],
      );
    } else {
      await widget.db.insert('tarefas', data);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _deleteTarefa() async {
    if (!isEditing || widget.tarefa!['id'] == null) return;
    await widget.db.delete(
      'tarefas',
      where: 'id = ?',
      whereArgs: [widget.tarefa!['id']],
    );
    if (mounted) Navigator.pop(context);
  }

  String _formatDate(String isoDate) {
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(isoDate));
    } catch (_) {
      return 'Data inválida';
    }
  }

  List<DropdownMenuItem<String>> _buildPrioridadeItems() {
    return _prioridades
        .map((p) => DropdownMenuItem<String>(value: p, child: Text(p)))
        .toList();
  }

  List<DropdownMenuItem<String>> _buildStatusItems() {
    return _statuses
        .map((s) => DropdownMenuItem<String>(value: s, child: Text(s)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Tarefa' : 'Nova Tarefa'),
        actions: isEditing && widget.tarefa!['id'] != null
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteTarefa,
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _tituloController,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descricaoController,
              decoration: const InputDecoration(labelText: 'Descrição'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Prioridade'),
              value: _prioridades.contains(_prioridadeSelecionada)
                  ? _prioridadeSelecionada
                  : null,
              items: _buildPrioridadeItems(),
              onChanged: (String? value) => value != null
                  ? setState(() => _prioridadeSelecionada = value)
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Status'),
              value: _statuses.contains(_statusSelecionado)
                  ? _statusSelecionado
                  : null,
              items: _buildStatusItems(),
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _statusSelecionado = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _dataAgendamentoController,
                    decoration: const InputDecoration(
                      labelText: 'Data/Hora Agendamento',
                      hintText: 'dd/MM/yyyy HH:mm',
                    ),
                    keyboardType: TextInputType.datetime,
                  ),
                  const Text(
                    'Exemplo: 30/11/2025 14:30',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              crossFadeState: showDataAgendamento
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
            const SizedBox(height: 16),
            if (_dataCriacao != null)
              Text(
                'Criado em: ${_formatDate(_dataCriacao!)}',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saveTarefa,
              icon: const Icon(Icons.save),
              label:
                  Text(isEditing ? 'Atualizar Tarefa' : 'Salvar Tarefa'),
            ),
            if (isEditing && widget.tarefa!['id'] != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _deleteTarefa,
                icon:
                    const Icon(Icons.delete_forever, color: Colors.red),
                label: const Text(
                  'Excluir Tarefa',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
