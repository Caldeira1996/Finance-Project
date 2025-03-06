import 'package:expenses/bd/bd.dart';
import 'package:expenses/login/register.dart';
import 'package:expenses/pages/user_management.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';
import 'components/transaction_form.dart';
import '/models/transaction.dart';
import 'components/transaction_list.dart';
import './components/chart.dart';
import 'login/login.dart';
import 'login/home_screen.dart';
import 'package:http/http.dart';

void main() => runApp(const ExpensesApp());

class ExpensesApp extends StatelessWidget {
  const ExpensesApp({Key? key}) : super(key: key);
  //final ThemeData tema = ThemeData();

  @override
  Widget build(BuildContext context) {
    //SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return MaterialApp(
      initialRoute: '/login', //Define a tela inicial para login
      routes: {
        '/login': (context) => Login(), //Tela de login
        '/home': (context) => MyHomePage(),
        '/register': (context) => RegisterScreen(),
        '/user-management':
            (context) =>
                UserManagementScreen(), // rota para gerenciamento de usuários
      },
      theme: ThemeData(
        useMaterial3: false,
        fontFamily: 'Quicksand',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          primary: Colors.purple,
          secondary: Colors.amber,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          labelLarge: TextStyle(
            // Botões
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
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Dados de login do usuário
  final String loggedUserEmail = 'root'; // email logado
  final String masterEmail = 'root'; // definindo o usuário master

  final List<Transaction> _transactions = [];
  bool _showChart = false;

  // Função para carregar as transações do banco de dados local
  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  //Função para carregar as transações do banco de dados local
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

  // Função para filtrar as transações recentes
  List<Transaction> get _recentTransactions {
    return _transactions.where((tr) {
      return tr.date.isAfter(
        DateTime.now().subtract(const Duration(days: 7)),
      ); // filtra transação dos últimos 7 dias
    }).toList();
  }

  // Função para adicionar transação
  void _addTransaction(String title, double value, DateTime date) async {
    final newTransaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      value: value,
      date: date,
    );

    try {
      // primeiro salva localmente
      await DatabaseHelper.instance.insertTransaction(newTransaction);

      setState(() {
        _transactions.add(newTransaction);
      });

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transação adicionada com sucesso!')),
      );
    } catch (e) {
      print('Erro ao salvar localmente: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar transação: ${e.toString}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  //Função para remover transação
  void _removeTransaction(String id) async {
    try {
      //Remove localmente do banco de dados
      await DatabaseHelper.instance.deleteTransaction(id);
      setState(() {
        _transactions.removeWhere((tr) => tr.id == id);
      });
    } catch (e) {
      print('Erro ao remover a transação: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao remover transação!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Função para abrir o formulário de transação
  _openTransactionFormModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return TransactionForm(_addTransaction);
      },
    );
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

    // Icones para android e IOS mudança do gráfico e lista
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
        Platform.isIOS ? CupertinoIcons.add : Icons.add,
        () => _openTransactionFormModal(context),
      ),
    ];

    final PreferredSizeWidget appBar = AppBar(
      title: const Text('Despesas Pessoais'),
      actions: actions,
    );

    // Adicionando Media query
    final availableHeight =
        mediaQuery.size.height -
        appBar.preferredSize.height -
        mediaQuery.padding.top;

    final bodyPage = SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (_showChart || !isLandscape)
              SizedBox(
                height: availableHeight * (isLandscape ? 0.60 : 0.25),
                child: Chart(_recentTransactions),
              ),
            if (!_showChart || !isLandscape)
              SizedBox(
                height: availableHeight * (isLandscape ? 1 : 0.65),
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
            trailing: Row(mainAxisSize: MainAxisSize.min, children: actions),
          ),
          child: bodyPage,
        )
        : Scaffold(
          appBar: appBar,
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text('Nome de usuário'),
                  accountEmail: Text('email@dominio.com'),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Colors.purple),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.home),
                  title: Text('Inicio'),
                  onTap: () {
                    Navigator.pop(context); //Fecha o menu
                  },
                ),
                ListTile(
                  leading: Icon(Icons.account_circle),
                  title: Text('Perfil'),
                  onTap: () {
                    Navigator.pop(context); //Fecha o menu
                  },
                ),
                ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Configurações'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),

                // Adiciona a opção de gerenciamento de usuários para o master
                if (loggedUserEmail == masterEmail) // verificação de usuário
                  ListTile(
                    leading: Icon(Icons.admin_panel_settings),
                    title: Text('Gerenciar Usuários'),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/user-management',
                      ); // Rota para gerenciar usuários
                    },
                  ),

                ListTile(
                  leading: Icon(Icons.exit_to_app),
                  title: Text('Sair'),
                  onTap: () {
                    Navigator.pushReplacementNamed(
                      context,
                      '/login',
                    ); // volta para o login
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
                    borderRadius: BorderRadius.circular(30),
                    child: Icon(CupertinoIcons.add, color: Colors.white),
                    onPressed: () => _openTransactionFormModal(context),
                  )
                  : FloatingActionButton(
                    child: Icon(Icons.add_shopping_cart_sharp),
                    onPressed: () => _openTransactionFormModal(context),
                  ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        );
  }
}
