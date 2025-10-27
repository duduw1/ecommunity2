import 'package:ecommunity/providers/auth_provider.dart';
import 'package:ecommunity/repositories/user_repository.dart';
import 'package:ecommunity/screens/social/social_feed_screen.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/user_model.dart';
import '../home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Chave global para identificar e validar nosso formulário.
  final _formKey = GlobalKey<FormState>();
  final UserRepository userRepository = UserRepository();

  // Controladores para ler os valores dos campos de texto.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Variáveis de estado da UI.
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Libera os controladores da memória quando a tela é descartada.
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Função chamada quando o botão de login é pressionado.
  Future<void> _signIn() async {
    // Valida os campos do formulário.
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });
      User? user = await userRepository.getUserByEmail(_emailController.text);
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuário com este email não existe')),
          );
        }
      } else if (user.password == _passwordController.text) {
        SessionManager().login(user);
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => App()));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Senha incorreta')));
        }
      }
      // --- LÓGICA DE LOGIN COM FIREBASE ENTRARIA AQUI ---
      // Exemplo:
      // await authRepository.signInWithEmail(
      //   email: _emailController.text,
      //   password: _passwordController.text,
      // );
      // ----------------------------------------------------

      // Após a conclusão, para o indicador de carregamento.
      // Em um app real, você navegaria para a home screen em caso de sucesso.
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Login bem-sucedido!')));
        // Navigator.of(context).pushReplacementNamed('/home');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrar'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Título da tela
                Text(
                  'Bem-vindo de volta!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Faça login para continuar.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Campo de Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, insira seu e-mail.';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Por favor, insira um e-mail válido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo de Senha
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira sua senha.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Botão de Login
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isLoading ? null : _signIn,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text('Entrar', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 24),

                // Link para a tela de Cadastro
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Não tem uma conta?'),
                    TextButton(
                      onPressed: () {
                        // TODO: Adicionar navegação para a tela de Cadastro
                        // Navigator.of(context).pushReplacementNamed('/signup');
                      },
                      child: const Text('Cadastre-se'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
