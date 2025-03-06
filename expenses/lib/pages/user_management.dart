import 'package:expenses/bd/bd.dart';
import 'package:flutter/material.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<Map<String, dynamic>> _users = []; // Lista de usuários
  bool _isLoading = false; // Controle de carregamento

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  //Função para carregar outros usuários do BD
  void _loadUsers() async {
    final db = await DatabaseHelper.instance.database;
    final users = await db.query('users'); // carrega todos os usuários
    setState(() {
      _users = users;
    });
  }

  // Função para adicionar usuário
  Future<void> _addUser() async {
    final name = _nameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, preencha todos os campos!')),
      );
      return;
    }

    // Adicionando o usuário no banco de dados
    await DatabaseHelper.instance.registerUser(name, email, password);

    _loadUsers(); // Recarrega os usuários após adicionar

    //Limpa os campos
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Usuário adicionado com sucesso!')));
  }

  //Função para remover usuário do banco de dados
  void _removeUser(int userID) async {
    await DatabaseHelper.instance.deleteUser(userID); // Exclui do BD
    _loadUsers(); // ATT a lista

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Usuário removido com sucesso!')));
  }

  @override
  void initState() {
    super.initState();
    _loadUsers(); // carrega os usuários assim que a tela for carregada
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gerenciar Usuários'),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Inputs para adicionar usuários
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'E-mail'),
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Senha'),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: _addUser,
              child: Text('Adicionar Usuário'),
            ),

            const SizedBox(height: 20),

            // Exibição da lista de usuários ou carregamento
            _isLoading
                ? Center(
                  child: CircularProgressIndicator(),
                ) // Exibe o indicador ded carregamento
                : Expanded(
                  child: ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return ListTile(
                        title: Text(user['name'] ?? 'Sem Nome'),
                        subtitle: Text(user['email'] ?? 'Sem Email'),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeUser(user['id']),
                        ),
                      );
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
