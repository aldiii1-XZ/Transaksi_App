import 'package:flutter/material.dart';
import '../widgets/futuristic_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FuturisticPage(
      title: "Masuk",
      child: Column(
        children: [
          const SizedBox(height: 20),

          TextField(
            decoration: _field("Username"),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 20),

          TextField(
            decoration: _field("Password"),
            obscureText: true,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 30),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.15),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 45),
            ),
            onPressed: () {},
            child: const Text(
              "Masuk",
              style: TextStyle(fontSize: 18),
            ),
          )
        ],
      ),
    );
  }

  InputDecoration _field(String text) {
    return InputDecoration(
      labelText: text,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(18),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white),
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}
