import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ExpenseProvider(),
      child: const SpendifyApp(),
    ),
  );
}

// ---------------- APP ----------------
class SpendifyApp extends StatelessWidget {
  const SpendifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Spendify",
      themeMode: provider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.light,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E88E5),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.dark,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E88E5),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

// ---------------- MODEL ----------------
class Transaction {
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final bool isExpense;

  Transaction({
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.isExpense = true,
  });
}

// ---------------- PROVIDER ----------------
class ExpenseProvider with ChangeNotifier {
  final List<Transaction> _transactions = [
    Transaction(title: "Lunch", amount: 300, category: "Food", date: DateTime.now()),
    Transaction(title: "Salary", amount: 20000, category: "Income", date: DateTime.now(), isExpense: false),
  ];

  String _userEmail = "";
  bool _isDarkMode = false;

  List<Transaction> get transactions => _transactions;
  String get userEmail => _userEmail;
  bool get isDarkMode => _isDarkMode;

  void setUserEmail(String email) {
    _userEmail = email;
    notifyListeners();
  }

  void toggleDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  double get totalBalance {
    double total = 0;
    for (var tx in _transactions) {
      tx.isExpense ? total -= tx.amount : total += tx.amount;
    }
    return total;
  }

  void addTransaction(Transaction tx) {
    _transactions.add(tx);
    notifyListeners();
  }

  String get spendingInsight {
    final expenses = _transactions.where((t) => t.isExpense).toList();
    final totalExpense = expenses.fold(0.0, (a, b) => a + b.amount);

    double food = 0;
    for (var tx in expenses) {
      if (tx.category == "Food") food += tx.amount;
    }

    if (totalExpense == 0) return "No expenses yet. Start tracking!";

    if (food > totalExpense * 0.4) return "⚠ You're spending heavily on food this month.";

    return "✅ Your spending looks balanced.";
  }
}

// ---------------- LOGIN ----------------
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.monetization_on, size: 80, color: Colors.white),
            const Text("Spendify",
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                hintText: "Email Address",
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Password",
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Provider.of<ExpenseProvider>(context, listen: false)
                      .setUserEmail(emailController.text.trim());
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MainNavigation()),
                  );
                },
                child: const Text("LOG IN"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- MAIN NAVIGATION ----------------
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    HistoryScreen(),
    ReportScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1E88E5),
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: "Report"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        backgroundColor: const Color(0xFF1E88E5),
        onPressed: () => _showAddExpenseSheet(context),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void _showAddExpenseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: const AddExpenseScreen(),
            ),
          );
        },
      ),
    );
  }
}

// ---------------- DASHBOARD ----------------
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);

    String firstName = "User";
    if (provider.userEmail.contains("@")) {
      final namePart = provider.userEmail.split("@")[0];
      if (namePart.isNotEmpty) {
        firstName = namePart.contains(".") ? namePart.split(".").first : namePart;
        firstName = firstName[0].toUpperCase() + firstName.substring(1);
      }
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hello $firstName 👋",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text("Total Balance", style: TextStyle(color: Colors.white70)),
                  Text(
                    "KES ${provider.totalBalance.toStringAsFixed(2)}",
                    style: const TextStyle(
                        fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                provider.spendingInsight,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- ADD EXPENSE ----------------
class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  String _selectedCategory = "Food";
  bool _isExpense = true;

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Add Transaction", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Title")),
        TextField(
          controller: _amountController,
          decoration: const InputDecoration(labelText: "Amount"),
          keyboardType: TextInputType.number,
        ),
        SwitchListTile(
          title: Text(_isExpense ? "Expense" : "Income"),
          value: _isExpense,
          onChanged: (val) => setState(() => _isExpense = val),
        ),
        DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          items: ["Food", "Transport", "Rent", "Bills", "Other"].map((value) {
            return DropdownMenuItem(value: value, child: Text(value));
          }).toList(),
          onChanged: (val) => setState(() => _selectedCategory = val!),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5), minimumSize: const Size(double.infinity, 50)),
          onPressed: () {
            final title = _titleController.text.trim();
            final amount = double.tryParse(_amountController.text.trim());

            if (title.isNotEmpty && amount != null && amount > 0) {
              Provider.of<ExpenseProvider>(context, listen: false).addTransaction(
                Transaction(
                  title: title,
                  amount: amount,
                  category: _selectedCategory,
                  date: DateTime.now(),
                  isExpense: _isExpense,
                ),
              );
              Navigator.of(context).pop();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please enter a valid title and amount")),
              );
            }
          },
          child: const Text("SAVE", style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ---------------- HISTORY ----------------
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactions = Provider.of<ExpenseProvider>(context).transactions;

    return Scaffold(
      appBar: AppBar(title: const Text("Transaction History")),
      body: ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final tx = transactions[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: tx.isExpense ? Colors.red.shade100 : Colors.green.shade100,
              child: Icon(tx.isExpense ? Icons.remove : Icons.add,
                  color: tx.isExpense ? Colors.red : Colors.green),
            ),
            title: Text(tx.title),
            subtitle: Text(DateFormat.yMMMd().format(tx.date)),
            trailing: Text(
              "${tx.isExpense ? "-" : "+"}KES ${tx.amount.toStringAsFixed(2)}",
              style: TextStyle(
                  color: tx.isExpense ? Colors.red : Colors.green, fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }
}

// ---------------- REPORT ----------------
class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);

    final Map<String, double> categoryTotals = {};
    for (var tx in provider.transactions.where((t) => t.isExpense)) {
      categoryTotals[tx.category] = (categoryTotals[tx.category] ?? 0) + tx.amount;
    }

    final total = categoryTotals.values.fold(0.0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(title: const Text("Report")),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text("This Month", style: TextStyle(fontSize: 18)),
          SizedBox(
            height: 300,
            child: PieChart(
              PieChartData(
                sections: categoryTotals.entries.map((entry) {
                  final percent = total == 0 ? 0 : (entry.value / total) * 100;
                  return PieChartSectionData(
                    value: entry.value,
                    title: "${entry.key} ${percent.toStringAsFixed(1)}%",
                    radius: 50,
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- SETTINGS ----------------
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("User Name"),
            subtitle: Text(provider.userEmail.isEmpty ? "Email Address" : provider.userEmail),
          ),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text("User Data"),
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text("Currency"),
            trailing: const Icon(Icons.chevron_right),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text("Dark Mode"),
            value: provider.isDarkMode,
            onChanged: (v) => provider.toggleDarkMode(v),
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text("Manage Categories"),
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Log Out", style: TextStyle(color: Colors.red)),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
          ),
        ],
      ),
    );
  }
}