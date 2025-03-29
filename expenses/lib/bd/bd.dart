import 'package:async/async.dart';
import 'package:expenses/components/transaction_list.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transaction.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('transactions.db');
    return _database!;
  }

  //Função para inicializar o banco de dados
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 8, // Aumenta a versão para forçar a atualização
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // Nome da tabela e campos como constantes estáticas
  static const String tableTransactions = 'transactions';
  static const String columnId = 'id';
  static const String columnTitle = 'title';
  static const String columnValue = 'value';
  static const String columnDate = 'date';
  static const String columnIsSynced = 'isSynced';

  static const String tableUsers = 'users';
  static const String columnName = 'name';
  static const String columnEmail = 'email';
  static const String columnPassword = 'password';
  static const String columnVerificationCode = 'verification_code';

  //Função para criar as tabelas
  Future _createDB(Database db, int version) async {
    await db.execute(''' 
    CREATE TABLE $tableTransactions (
     $columnId TEXT PRIMARY KEY,
     $columnTitle TEXT NOT NULL,
     $columnValue REAL NOT NULL,
     $columnDate TEXT NOT NULL,
     $columnIsSynced INTEGER NOT NULL DEFAULT 0
    )
    
    ''');

    await db.execute(''' 
    CREATE TABLE $tableUsers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    $columnName TEXT NOT NULL,
    $columnEmail TEXT UNIQUE NOT NULL,
    $columnPassword TEXT NOT NULL,
    $columnVerificationCode TEXT
    )
    ''');

    // tabela para o profile
    await db.execute('''
    CREATE TABLE IF NOT EXISTS profile (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userId INTEGER NOT NULL,
      name TEXT NOT NULL,
      age TEXT,
      bio TEXT,
      imagePath TEXT,
      FOREIGN KEY (userId) REFERENCES users(id)
    )
    ''');

    // Tabel de saldo
    await db.execute('''
    CREATE TABLE IF NOT EXISTS wallet (
      userId INTEGER PRIMARY KEY,
      balance REAL NOT NULL DEFAULT 0.0,
      FOREIGN KEY (userId) REFERENCES users(id)
    )
    ''');
    print('Tabela wallet criada com sucesso!');

    //Tabela para visualizar histórico de saldo na carteira - CORRIGIDO users em vez de user
    await db.execute(''' 
    CREATE TABLE IF NOT EXISTS balance_history (
      id TEXT PRIMARY KEY,
      userId INTEGER NOT NULL,
      amount REAL NOT NULL,
      description TEXT,
      date TEXT NOT NULL,
      FOREIGN KEY(userId) REFERENCES users(id)
    )
    ''');
  }

  // FUNÇÃO PARA GERAR O HASH DA SENHA
  String generateHash(String password) {
    var bytes = utf8.encode(password); // CONVERTE A SENHA EM BYTES
    var digest = sha256.convert(bytes); // gerar o hash
    return digest.toString(); // Retorna o hash como string
  }

  // FUNÇÃO PARA CRIAR USUÁRIO
  Future<int> registerUser(String name, String email, String password) async {
    final hashedPassword = generateHash(password); // gerar o hash da senha
    final db = await database;

    final userID = await db.insert(tableUsers, {
      columnName: name,
      columnEmail: email,
      columnPassword: hashedPassword,
    });

    // Inicializa a carteira para o novo usuário
    await ensureWalletExists(userID);

    return userID;
  }

  //Função para excluir usuário
  Future<void> deleteUser(int userID) async {
    final db = await instance.database;
    await db.delete('users', where: 'id = ?', whereArgs: [userID]);
  }

  // FUNÇÃO PARA LOGIN DE USUÁRIO
  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final hashedPassword = generateHash(
      password,
    ); // Gerar o hash da senha fornecida
    final db = await database;
    final result = await db.query(
      'users',
      where: '$columnEmail = ? AND $columnPassword = ?',
      whereArgs: [email, hashedPassword], // Comparar o hash armazenado
    );
    print('Resultado da query: $result');

    if (result.isNotEmpty) {
      final userId = result.first['id'] as int;
      // Garante que a carteira existe após o login
      await ensureWalletExists(userId);
      return result.first;
    }
    return null;
  }

  // Método para garantir que a carteira existe
  Future<void> ensureWalletExists(
    int userId, [
    double initialBalance = 0.0,
  ]) async {
    final db = await database;

    // Verifica se a carteira já existe
    final walletResult = await db.query(
      'wallet',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    if (walletResult.isEmpty) {
      // Se não existir, cria a carteira
      print(
        'Criando carteira para o usuário $userId com saldo inicial $initialBalance',
      );
      await db.insert('wallet', {
        'userId': userId,
        'balance': initialBalance,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      print('Carteira já existe para o usuário $userId');
    }
  }

  // Atualiza a estrutura do banco ao mudar a versão
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE $tableTransactions ADD COLUMN $columnIsSynced INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 3) {
      //Verifica se a tabela já existe
      var result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='profile'",
      );

      if (result.isEmpty) {
        //Se a tabela não existir, cria a tabela
        await db.execute('''
        CREATE TABLE profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        name TEXT NOT NULL,
        age TEXT,
        bio TEXT,
        imagePath TEXT,
        FOREIGN KEY (userId) REFERENCES users(id)
        )
      ''');
      }
    }

    if (oldVersion < 5) {
      var result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='wallet'",
      );
      if (result.isEmpty) {
        await db.execute('''
        CREATE TABLE IF NOT EXISTS wallet (
          userId INTEGER PRIMARY KEY,
          balance REAL NOT NULL DEFAULT 0.0,
          FOREIGN KEY (userId) REFERENCES users(id)
        )
        ''');
        print('Tabela wallet criada durante a atualização');
      }
    }

    if (oldVersion < 8) {
      // Corrige a tabela balance_history para apontar para users
      try {
        // Verifica se a tabela existe
        var result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='balance_history'",
        );

        if (result.isNotEmpty) {
          // Salva os dados existentes
          var existingData = await db.query('balance_history');

          // Remove a tabela com referência errada
          await db.execute('DROP TABLE IF EXISTS balance_history');

          // Recria a tabela com a referência correta
          await db.execute('''
          CREATE TABLE IF NOT EXISTS balance_history (
            id TEXT PRIMARY KEY,
            userId INTEGER NOT NULL,
            amount REAL NOT NULL,
            description TEXT,
            date TEXT NOT NULL,
            FOREIGN KEY(userId) REFERENCES users(id)
          )
          ''');

          // Reinsere os dados
          for (var entry in existingData) {
            await db.insert('balance_history', entry);
          }
        } else {
          // Se a tabela não existir, cria com a referência correta
          await db.execute('''
          CREATE TABLE IF NOT EXISTS balance_history (
            id TEXT PRIMARY KEY,
            userId INTEGER NOT NULL,
            amount REAL NOT NULL,
            description TEXT,
            date TEXT NOT NULL,
            FOREIGN KEY(userId) REFERENCES users(id)
          )
          ''');
        }

        print('Tabela balance_history corrigida na atualização v8');
      } catch (e) {
        print('Erro ao corrigir tabela balance_history: $e');
      }

      // Garante que todos os usuários têm uma carteira
      try {
        final users = await db.query('users');
        for (var user in users) {
          final userId = user['id'] as int;
          final walletExists = await db.query(
            'wallet',
            where: 'userId = ?',
            whereArgs: [userId],
          );

          if (walletExists.isEmpty) {
            await db.insert('wallet', {'userId': userId, 'balance': 0.0});
            print('Carteira criada para usuário $userId durante atualização');
          }
        }
      } catch (e) {
        print('Erro ao garantir carteiras para usuários: $e');
      }
    }
  }

  Future insertTransaction(
    Transaction transaction, {
    bool isSynced = false,
  }) async {
    final db = await database;
    await db.insert(tableTransactions, {
      columnId: transaction.id,
      columnTitle: transaction.title,
      columnValue: transaction.value,
      columnDate: transaction.date.toIso8601String(),
      columnIsSynced: isSynced ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Transaction>> getTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableTransactions);
    //return List.generate(maps.length, (i) {
    return maps.map((map) {
      return Transaction(
        id: map[columnId],
        title: map[columnTitle],
        value: map[columnValue],
        date: DateTime.parse(map[columnDate]),
      );
    }).toList();
  }

  // Obtém apenas transações pendentes de sincronização
  Future<List<Transaction>> getPendingTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableTransactions,
      where: '$columnIsSynced = ?',
      whereArgs: [0],
    );
    return maps.map((map) {
      return Transaction(
        id: map[columnId],
        title: map[columnTitle],
        value: map[columnValue],
        date: DateTime.parse(map[columnDate]),
      );
    }).toList();
  }

  Future<void> markTransactionsAsSynced(String id) async {
    final db = await database;
    await db.update(
      tableTransactions,
      {columnIsSynced: 1},
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<double?> deleteTransaction(String id) async {
    final db = await database;
    final transaction = await db.query(
      tableTransactions,
      where: '$columnId = ?',
      whereArgs: [id],
    );

    if (transaction.isNotEmpty) {
      final value = transaction.first[columnValue] as double;

      await db.delete(
        tableTransactions,
        where: '$columnId = ?',
        whereArgs: [id],
      );
      return value; //Retorna valor transação excluída
    }
    return null; //Retorna null se a transação não existir
  }

  Future<void> deleteTransactionAndUpdateBalance(
    String transactionId,
    int userId,
  ) async {
    final deletedValue = await deleteTransaction(transactionId);

    if (deletedValue != null) {
      //Adiciona o valor de volta ao saldo
      await addToBalance(userId, deletedValue);
      print('Transação excluída e saldo atualizado: +$deletedValue.');
    } else {
      print('Transação não encontrada ou não excluída.');
    }
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }

  // Função para gerar um código aleatório de 6 dígitos
  String generateVerificationCode() {
    Random random = Random();
    String code = '';
    for (int i = 0; i < 6; i++) {
      code += random.nextInt(10).toString(); // gera números de 0 a 9
    }
    return code;
  }

  // Função para enviar o email
  Future<void> sendVerificationEmail(String recipientEmail, String code) async {
    String username = 'seu_email@example.com'; // Seu email
    String password = 'sua_senha_email';

    final smtpServer = gmail(username, password); // configura o servidor SMTP

    final message =
        Message()
          ..from = Address(username)
          ..recipients.add(recipientEmail)
          ..subject = 'Código de verificação'
          ..text = 'Seu código de verificação é: $code';

    try {
      final sendReport = await send(message, smtpServer);
      print('Email enviado: ' + sendReport.toString());
    } catch (e) {
      print('Erro ao enviar para o email: $e');
    }
  }

  // Função de registro de usuário com envio de código
  Future<int> registerUserCode(
    String name,
    String email,
    String password,
  ) async {
    final dbHelper =
        DatabaseHelper.instance; // cria a instancia do DatabaseHelper
    final hashedPassword = dbHelper.generateHash(password); // usa instancia
    final db =
        await dbHelper.database; // obtém o banco de dados a partir da instância

    // Gerar o código de verificação
    String verificationCode = generateVerificationCode();

    // Inserir o usuário no banco de dados
    final userId = await db.insert(tableUsers, {
      columnName: name,
      columnEmail: email,
      columnPassword: hashedPassword,
      columnVerificationCode: verificationCode, // Armazenar o código
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Inicializa a carteira para o novo usuário
    await ensureWalletExists(userId);

    //Enviar o email com o código de verificação
    await sendVerificationEmail(email, verificationCode);

    return userId; // Retorna o ID do usuário
  }

  //Função para verificar o código de verificação
  Future<bool> verifyCode(String email, String code) async {
    final db = await database;

    // consultar o DB para obter o código de verificação do usuário
    final result = await db.query(
      'users',
      where: 'email = ? AND verification_code = ?',
      whereArgs: [email, code],
    );

    // Se encontrar o código, retorna verdadeiro
    return result.isNotEmpty;
  }

  // Método para salvar o perfil
  Future<int> saveProfile(
    int userId,
    String name,
    String age,
    String bio,
    String? imagePath,
  ) async {
    final db = await database;
    return await db.insert('profile', {
      'userId': userId,
      'name': name,
      'age': age,
      'bio': bio,
      'imagePath': imagePath,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Método para atualizar o perfil
  Future<int> updateProfile(
    int userId,
    String name,
    String age,
    String bio,
    String? imagePath,
  ) async {
    final db = await database;
    return await db.update(
      'profile',
      {'name': name, 'age': age, 'bio': bio, 'imagePath': imagePath},
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  // Método para recuperar o perfil
  Future<Map<String, dynamic>?> getProfile(int userId) async {
    final db = await database;
    final result = await db.query(
      'profile',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    if (result.isNotEmpty) {
      return result.first..removeWhere((key, value) => value == null);
    }
    return null;
  }

  //------------------------------------------------------------------------

  // Método para obter saldo do usuário
  Future<double> getBalance(int userId) async {
    // Garante que a carteira existe antes de tentar obter o saldo
    await ensureWalletExists(userId);

    final db = await database;
    final result = await db.query(
      'wallet',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    if (result.isNotEmpty) {
      var balanceValue = result.first['balance'];
      if (balanceValue is int) {
        return balanceValue.toDouble();
      } else if (balanceValue is double) {
        return balanceValue;
      }
    }
    return 0.0;
  }

  // Método para atualizar o saldo do usuário
  Future<void> updateBalance(int userId, double newBalance) async {
    // Garante que a carteira existe
    await ensureWalletExists(userId);

    final db = await database;
    await db.update(
      'wallet',
      {'balance': newBalance},
      where: 'userId = ?',
      whereArgs: [userId],
    );
    print(
      'Saldo atualizado para usuário $userId: R\$${newBalance.toStringAsFixed(2)}',
    );
  }

  // Método para adicionar saldo a carteira
  Future<void> addToBalance(int userId, double amount) async {
    final currentBalance = await getBalance(userId);
    final newBalance = currentBalance + amount;
    await updateBalance(userId, newBalance);
    print(
      'Saldo adicionado: +R\$${amount.toStringAsFixed(2)}, Novo saldo: R\$${newBalance.toStringAsFixed(2)}',
    );
  }

  // Método para debitar o saldo ao adicionar uma transação
  Future<void> deductFromBalance(int userId, double amount) async {
    final currentBalance = await getBalance(userId);
    if (currentBalance >= amount) {
      final newBalance = currentBalance - amount;
      await updateBalance(userId, newBalance);
      print(
        'Valor debitado: -R\$${amount.toStringAsFixed(2)}, Novo saldo: R\$${newBalance.toStringAsFixed(2)}',
      );
    } else {
      throw Exception('Saldo Insuficiente');
    }
  }

  // Método para gerenciar histórico da carteira
  Future<int> addBalanceHistory({
    required int userId,
    required double amount,
    String description = '',
  }) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    print(
      'Adicionando entrada ao histórico: ID=$id, Valor=$amount, Descrição=$description',
    );

    return await db.insert('balance_history', {
      'id': id,
      'userId': userId,
      'amount': amount,
      'description': description,
      'date': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getBalanceHistory(int userId) async {
    final db = await database;
    return await db.query(
      'balance_history',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
  }

  Future<void> deleteBalanceEntry(String entryId) async {
    final db = await database;
    final result = await db.delete(
      'balance_history',
      where: 'id = ?',
      whereArgs: [entryId],
    );
    print('Entrada $entryId excluída do histórico: $result linhas afetadas');
  }
}
