
Cadastro de Tarefas – Flutter + SQLite
Aplicativo Flutter de lista de tarefas profissionais com armazenamento local em SQLite usando o pacote sqflite.
Permite criar, visualizar, editar, concluir e excluir tarefas, com priorização e filtros por status.

Funcionalidades
Cadastro de tarefas com:

Título

Descrição

Prioridade: Baixa, Média ou Alta

Status: Pendente, Resolvido, Aguardando ou Agendamento

Data/hora de agendamento (opcional, exibida quando o status é “Agendamento”)

Armazenamento local em banco SQLite (tarefas_app.db) usando sqflite.

Lista de tarefas com:

Ícone e cor indicando o status (pendente, concluída etc.).

Ícone e cor indicando a prioridade.

Indicação da data/hora agendada quando houver.

Título riscado e em cinza quando a tarefa está concluída.

Ações por item via menu de contexto:

Marcar como Concluída/Pendente (toggle de status entre Resolvido e Pendente)

Editar tarefa

Excluir tarefa

Filtro por abas na parte superior:

Todas: exibe todas as tarefas

Concluídas: apenas tarefas com status Resolvido

Pendentes: todas as demais (Pendente, Aguardando, Agendamento)

Tela de formulário para criação/edição com validação simples:

Impede salvar tarefa sem título

Valida formato da data de agendamento (dd/MM/yyyy HH:mm)

Geração de JSON da tarefa salva/atualizada:

Cada vez que uma tarefa é salva, o objeto é convertido em JSON e impresso no console (TAREFA JSON: {...}), útil para debug e comprovação na avaliação.

Tecnologias Utilizadas
Flutter (Material 3)

Dart

SQLite via pacote sqflite​

path para montar o caminho do arquivo do banco​

intl para formatação de datas e horas​

Estrutura Principal
main.dart

createDatabase(): cria/abre o banco tarefas_app.db, define a tabela tarefas e cuida de upgrades simples de versão.

tarefaToJson(Map<String, dynamic>): converte o mapa da tarefa em string JSON.

MyApp: configura tema e define TarefasPage como tela inicial.

TarefasPage (tela de listagem com abas):

Abre o banco.

Lê todas as tarefas do SQLite.

Filtra em memória conforme a aba selecionada (Todas / Concluídas / Pendentes).

Exibe itens usando o widget TarefaListItem.

Abre o formulário (TarefaFormPage) para criar/editar.

TarefaListItem:

Monta o ListTile de cada tarefa com ícones, cores e menu popup (editar, excluir, alternar status).

TarefaFormPage:

Formulário de criação/edição.

Salva os dados no banco (INSERT/UPDATE) ou exclui (DELETE).

Valida título e formato de data.

Mostra a data de criação da tarefa.
