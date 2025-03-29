import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../bd/bd.dart';

class WalletScreen extends StatefulWidget {
  final int userId;

  const WalletScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _amountController = TextEditingController();
  double _currentBalance = 0.0;
  List<Map<String, dynamic>> _balanceHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWallet();
  }

  Future<void> _initializeWallet() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Garantir que a carteira existe antes de carregar os dados
      await DatabaseHelper.instance.ensureWalletExists(widget.userId);
      await _loadData();
    } catch (e) {
      print('Erro ao inicializar carteira: $e');
      _showErrorMessage('Erro ao inicializar carteira: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadData() async {
    await _loadBalance();
    await _loadHistory();
  }

  Future<void> _loadBalance() async {
    try {
      final balance = await DatabaseHelper.instance.getBalance(widget.userId);
      if (mounted) {
        setState(() {
          _currentBalance = balance;
        });
      }
      print('Saldo carregado: R\$${balance.toStringAsFixed(2)}');
    } catch (e) {
      print('Erro ao carregar saldo: $e');
      _showErrorMessage('Erro ao carregar saldo');
    }
  }

  Future<void> _loadHistory() async {
    try {
      final history = await DatabaseHelper.instance.getBalanceHistory(
        widget.userId,
      );
      if (mounted) {
        setState(() {
          _balanceHistory = history;
        });
      }
      print('Histórico carregado: ${history.length} entradas');
    } catch (e) {
      print('Erro ao carregar histórico: $e');
      _showErrorMessage('Erro ao carregar histórico');
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _addToBalance() async {
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insira um valor válido maior que zero')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await DatabaseHelper.instance.addToBalance(widget.userId, amount);
      await DatabaseHelper.instance.addBalanceHistory(
        userId: widget.userId,
        amount: amount,
        description: 'Depósito manual',
      );
      _amountController.clear();
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'R\$${amount.toStringAsFixed(2)} adicionados com sucesso!',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Erro ao adicionar saldo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteHistoryEntry(String entryId, double amount) async {
    final confirmed = true;
    // await showDialog<bool>(
    //   context: context,
    //   builder:
    //       (ctx) => AlertDialog(
    //         title: const Text('Remover registro?'),
    //         content: const Text('Esta ação não pode ser desfeita.'),
    //         actions: [
    //           TextButton(
    //             child: const Text('Cancelar'),
    //             onPressed: () => Navigator.of(ctx).pop(false),
    //           ),
    //           TextButton(
    //             child: const Text(
    //               'Remover',
    //               style: TextStyle(color: Colors.red),
    //             ),
    //             onPressed: () => Navigator.of(ctx).pop(true),
    //           ),
    //         ],
    //       ),
    // ) ??
    // false;

    if (confirmed) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Primeiro exclui o registro do histórico
        await DatabaseHelper.instance.deleteBalanceEntry(entryId);

        // Depois atualiza o saldo (subtrai o valor)
        await DatabaseHelper.instance.deductFromBalance(widget.userId, amount);

        // Recarrega os dados
        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registro removido com sucesso'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('Erro ao remover registro: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao remover: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carteira'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Seção do Saldo e Formulário
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'R\$${_currentBalance.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _amountController,
                          decoration: InputDecoration(
                            labelText: 'Valor a adicionar',
                            labelStyle: const TextStyle(color: Colors.blue),
                            prefixIcon: const Icon(
                              Icons.attach_money,
                              color: Colors.blue,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Colors.purple,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.blue,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.blue.shade50,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 20,
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: false,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*[,.]?\d{0,2}'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _addToBalance,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Adicionar Saldo',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Histórico
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Text(
                          'Histórico de Adições',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_balanceHistory.length} transações',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child:
                        _balanceHistory.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet_outlined,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Nenhuma transação registrada',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              itemCount: _balanceHistory.length,
                              itemBuilder: (context, index) {
                                final entry = _balanceHistory[index];
                                return Dismissible(
                                  key: Key(
                                    entry['id'] ?? DateTime.now().toString(),
                                  ),
                                  background: Container(
                                    color: Colors.red,
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (direction) async {
                                    return await showDialog<bool>(
                                          context: context,
                                          builder:
                                              (ctx) => AlertDialog(
                                                title: const Text(
                                                  'Remover registro?',
                                                ),
                                                content: const Text(
                                                  'Esta ação não pode ser desfeita.',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    child: const Text(
                                                      'Cancelar',
                                                    ),
                                                    onPressed:
                                                        () => Navigator.of(
                                                          ctx,
                                                        ).pop(false),
                                                  ),
                                                  TextButton(
                                                    child: const Text(
                                                      'Remover',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                    onPressed:
                                                        () => Navigator.of(
                                                          ctx,
                                                        ).pop(true),
                                                  ),
                                                ],
                                              ),
                                        ) ??
                                        false;
                                  },
                                  onDismissed:
                                      (direction) => _deleteHistoryEntry(
                                        entry['id'],
                                        entry['amount'],
                                      ),
                                  child: Card(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    elevation: 2,
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.green[100],
                                        child: const Icon(
                                          Icons.add,
                                          color: Colors.green,
                                        ),
                                      ),
                                      title: Text(
                                        'R\$${entry['amount'].toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        DateFormat(
                                          'dd/MM/yyyy - HH:mm',
                                        ).format(DateTime.parse(entry['date'])),
                                      ),
                                      trailing: Text(
                                        entry['description'] ?? '',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
