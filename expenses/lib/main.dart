// Versão corrigida do código Flutter

import 'package:expenses/bd/bd.dart';
import 'package:expenses/login/register.dart';
import 'package:expenses/pages/profile.dart';
import 'package:expenses/pages/user_management.dart';
import 'package:expenses/pages/wallet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:photo_view/photo_view.dart';
import 'dart:io';
import 'dart:math';
import 'components/transaction_form.dart';
import '/models/transaction.dart';
import 'components/transaction_list.dart';
import './components/chart.dart';
import 'login/login.dart';
import 'login/home_screen.dart';
import 'package:http/http.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  runApp(const ExpensesApp());
}

class ExpensesApp extends StatefulWidget {
  const ExpensesApp({Key? key}) : super(key: key);

  @override
  _ExpensesAppState createState() => _ExpensesAppState();
}

class _ExpensesAppState extends State<ExpensesApp> {
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/login',
      routes: {
        '/login': (context) => Login(),
        '/home':
            (context) =>
                MyHomePage(isDarkMode: _isDarkMode, toggleTheme: _toggleTheme),
        '/register': (context) => RegisterScreen(),
        '/user-management': (context) => UserManagementScreen(),
      },
      theme: ThemeData(
        useMaterial3: false,
        fontFamily: 'Quicksand',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          primary: Colors.purple,
          secondary: Colors.amber,
          brightness: Brightness.light,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          labelLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontFamily: 'OpenSans',
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: false,
        fontFamily: 'QuickSand',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          primary: Colors.purple,
          secondary: Colors.amber,
          brightness: Brightness.dark,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          labelLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontFamily: 'OpenSans',
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
    );
  }
}

class MyHomePage extends StatefulWidget {
  final bool isDarkMode;
  final Function toggleTheme;

  MyHomePage({Key? key, required this.isDarkMode, required this.toggleTheme})
    : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Dados de login do usuário
  final String loggedUserEmail = 'root';
  final String masterEmail = 'root';

  final List<Transaction> _transactions = [];
  bool _showChart = false;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() async {
    try {
      final transactions = await DatabaseHelper.instance.getTransactions();
      setState(() {
        _transactions.clear();
        _transactions.addAll(transactions);
      });
    } catch (e) {
      print('Erro ao carregar transações: $e');
    }
  }

  List<Transaction> get _recentTransactions {
    return _transactions.where((tr) {
      return tr.date.isAfter(DateTime.now().subtract(const Duration(days: 7)));
    }).toList();
  }

  void _addTransaction(String title, double value, DateTime date) async {
    final newTransaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      value: value,
      date: date,
    );

    try {
      final userId = 1;
      final currentBalance = await DatabaseHelper.instance.getBalance(userId);

      if (currentBalance >= value) {
        await DatabaseHelper.instance.deductFromBalance(userId, value);
        await DatabaseHelper.instance.insertTransaction(newTransaction);

        setState(() {
          _transactions.add(newTransaction);
        });

        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Transação adicionada com sucesso!',
              style: TextStyle(color: Colors.green),
            ),
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                "Saldo Insuficiente",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              content: Text(
                "Seu saldo atual é R\$${currentBalance.toStringAsFixed(2)}. "
                "Não é possível adicionar essa transação.",
                style: TextStyle(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              actions: [
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, // Fundo vermelho
                      foregroundColor: Colors.white, // Texto branco
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          8,
                        ), // Borda arredondada
                      ),
                    ),
                    child: Text("OK"),
                  ),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('Erro ao adicionar transação: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar transação: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeTransaction(String id) async {
    final confirmado =
        await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                elevation: 5,
                title: const Text('Excluir Transação'),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.red),
                  borderRadius: BorderRadius.circular(5),
                ),
                content: const Text(
                  'Você tem certeza que deseja excluir esta transação?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                actions: <Widget>[
                  TextButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                        Colors.grey.shade200,
                      ),
                      foregroundColor: MaterialStateProperty.all(Colors.black),
                      padding: MaterialStateProperty.all(
                        EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      ),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    child: const Text('Cancelar'),
                    onPressed: () => Navigator.of(ctx).pop(false),
                  ),
                  TextButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                        Colors.red.shade700,
                      ),
                      foregroundColor: MaterialStateProperty.all(Colors.white),
                      padding: MaterialStateProperty.all(
                        EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      ),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    child: const Text(
                      'Confirmar',
                      style: TextStyle(fontSize: 16),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirmado) return;

    //Id do usuário logado
    final userId = 1;

    // atualizar o saldo
    await DatabaseHelper.instance.deleteTransactionAndUpdateBalance(id, userId);

    setState(() {
      _transactions.removeWhere((tx) => tx.id == id);
    });

    void deleteTransaction(transactionId) async {
      try {
        await DatabaseHelper.instance.deleteTransaction(transactionId);

        setState(() {
          _transactions.removeWhere((tx) => tx.id == transactionId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transação removida e saldo atualizado!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Erro ao remover a transação: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover transação! ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<double> _loadBalance() async {
    final userId = 1;
    return await DatabaseHelper.instance.getBalance(userId);
  }

  void _openTransactionFormModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Adicionar Transação',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.red),
                  ),
                ],
              ),
              SizedBox(height: 20),
              TransactionForm(_addTransaction),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _getProfile() async {
    final userId = 1;
    final dbHelper = DatabaseHelper.instance;
    return await dbHelper.getProfile(userId);
  }

  void _openImageFullScreen(String imagePath) {
    if (imagePath != null && imagePath.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => Scaffold(
                appBar: AppBar(
                  title: Text('Imagem de Perfil'),
                  backgroundColor: Colors.black,
                ),
                body: PhotoView(
                  imageProvider: FileImage(File(imagePath)),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                  backgroundDecoration: BoxDecoration(color: Colors.black),
                ),
              ),
        ),
      );
    }
  }

  Future<void> _loadDataHome() async {
    await _loadBalanceHome();
  }

  Future<void> _loadBalanceHome() async {
    try {
      final balance = await DatabaseHelper.instance.database;
      if (mounted) {
        setState(() {
          return;
        });
      }
      print('Saldo carregado: R\$${balance.toString()}');
    } catch (e) {
      print('Erro ao carregar saldo: $e');
    }
  }

  Widget _getIconButton(IconData icon, Function() fn) {
    return Platform.isIOS
        ? GestureDetector(onTap: fn, child: Icon(icon))
        : IconButton(icon: Icon(icon), onPressed: fn);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    bool isLandscape = mediaQuery.orientation == Orientation.landscape;

    final iconList = Platform.isIOS ? CupertinoIcons.refresh : Icons.list;
    final chartList =
        Platform.isIOS ? CupertinoIcons.refresh : Icons.show_chart;

    final actions = [
      if (isLandscape)
        _getIconButton(_showChart ? iconList : chartList, () {
          setState(() {
            _showChart = !_showChart;
          });
        }),
      _getIconButton(
        Platform.isIOS ? CupertinoIcons.refresh : Icons.refresh,
        () => _loadBalanceHome(),
      ),
    ];

    final PreferredSizeWidget appBar = AppBar(
      title: const Text('Finanças'),
      actions: actions,
      elevation: 5,
    );

    final availableHeight =
        mediaQuery.size.height -
        appBar.preferredSize.height -
        mediaQuery.padding.top;

    return FutureBuilder<double>(
      future: _loadBalance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        final balance = snapshot.data ?? 0.0;

        final bodyPage = SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(1),
                  margin: EdgeInsets.only(top: 0),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Saldo Atual',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 0),
                        Text(
                          'R\$${balance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showChart || !isLandscape)
                  SizedBox(
                    height: availableHeight * (isLandscape ? 0.7 : 0.26),
                    child: Chart(_recentTransactions),
                  ),
                if (!_showChart || !isLandscape)
                  SizedBox(
                    height: availableHeight * (isLandscape ? 0.9 : 0.65),
                    child: TransactionList(_transactions, _removeTransaction),
                  ),
              ],
            ),
          ),
        );

        return Platform.isIOS
            ? CupertinoPageScaffold(
              navigationBar: CupertinoNavigationBar(
                middle: const Text('Despesas Pessoais'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions,
                ),
              ),
              child: bodyPage,
            )
            : Scaffold(
              appBar: appBar,
              drawer: Drawer(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    FutureBuilder<Map<String, dynamic>?>(
                      future: _getProfile(),
                      builder: (context, snapshot) {
                        final profile = snapshot.data;
                        final imagePath = profile?['imagePath'];

                        return UserAccountsDrawerHeader(
                          accountName: Text(
                            profile?['name'] ?? 'Nome de usuário',
                          ),
                          accountEmail: Text('email@dominio.com'),
                          currentAccountPicture: GestureDetector(
                            onTap: () {
                              if (imagePath != null) {
                                _openImageFullScreen(imagePath);
                              }
                            },
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              backgroundImage:
                                  imagePath != null
                                      ? FileImage(File(imagePath))
                                      : null,
                              child:
                                  imagePath == null
                                      ? Icon(Icons.person, color: Colors.purple)
                                      : null,
                            ),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.home),
                      title: Text('Inicio'),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.account_circle),
                      title: Text('Perfil'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.wallet),
                      title: Text('Carteira'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WalletScreen(userId: 1),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.add_chart_outlined),
                      title: Text('Investimentos'),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.settings),
                      title: Text('Configurações'),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    if (loggedUserEmail == masterEmail)
                      ListTile(
                        leading: Icon(Icons.admin_panel_settings),
                        title: Text('Gerenciar Usuários'),
                        onTap: () {
                          Navigator.pushNamed(context, '/user-management');
                        },
                      ),
                    const SizedBox(height: 10),
                    ListTile(
                      leading: Icon(
                        widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      ),
                      title: Text(
                        widget.isDarkMode ? 'Tema Claro' : 'Tema Escuro',
                      ),
                      onTap: () {
                        widget.toggleTheme();
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      leading: Icon(Icons.exit_to_app),
                      title: Text('Sair'),
                      onTap: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                    ),
                  ],
                ),
              ),
              body: bodyPage,
              floatingActionButton:
                  Platform.isIOS
                      ? CupertinoButton(
                        color: CupertinoColors.activeBlue,
                        padding: EdgeInsets.all(16),
                        borderRadius: BorderRadius.circular(50),
                        child: Text(
                          'Adicionar',
                          style: TextStyle(color: Colors.blue),
                        ),
                        onPressed: () => _openTransactionFormModal(context),
                      )
                      : FloatingActionButton(
                        child: Icon(Icons.add_shopping_cart_sharp),
                        onPressed: () => _openTransactionFormModal(context),
                      ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerFloat,
            );
      },
    );
  }
}
