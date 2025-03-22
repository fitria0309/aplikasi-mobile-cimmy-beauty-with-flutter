import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'otp.dart';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

// MyApp merupakan root widget aplikasi
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
  return MaterialApp(
    title: 'CimmyBeauty',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ), 
    initialRoute: '/login', // Set halaman awal
    routes: {
      '/otp' : (context) => const PhoneAuthScreen(),
      '/login': (context) => const LoginPage(),
      '/signup': (context) => const SignUpPage(),
      },
    );
  }
}
class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});
  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  String? _verificationId;
  String? _generatedCode;
  bool _showVerificationField = false;

  String _generateRandomCode() {
    final Random random = Random();
    return (random.nextInt(900000) + 100000).toString();
  }

  Future<void> _sendCode() async {
    final String phoneNumber = _phoneController.text.trim();
    await Future.delayed(const Duration(seconds: 3),(){
      setState(() {
      _generatedCode = _generateRandomCode();
      _showVerificationField = true;
    });
    }
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Verification code: $_generatedCode')),
    );

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number verified and user signed in!')),
        );
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: ${e.message}')),
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code sent.')),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        setState(() {
          _verificationId = verificationId;
        });
      },
    );
  }

  Future<void> _verifyCode() async {
    final String smsCode = _otpController.text.trim();
    if (smsCode == _generatedCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code verified successfully!')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DashboardPage(username: 'Welcome',))
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid verification code.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Authentication'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _sendCode,
              child: const Text('Send Code'),
            ),
            if (_showVerificationField) ...[
              const SizedBox(height: 16.0),
              if (_generatedCode != null)
                Text(
                  'Generated Code: $_generatedCode',
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Verification Code',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _verifyCode,
                child: const Text('Verify Code'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}



class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.9, end: 1.1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Mengirim data ke Firebase untuk sign up
  void _signUp() async {
    if (_usernameController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields must be filled")),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Menggunakan Firebase Authentication untuk mendaftar pengguna
      final UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _usernameController.text,
        password: _passwordController.text,
      );

      setState(() {
        _isLoading = false;
      });

      // Jika berhasil, arahkan ke halaman Dashboard
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PhoneAuthScreen()),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ScaleTransition(
                  scale: _animation,
                  child: Image.asset('assets/logo.png', height: 200),
                ),
                const SizedBox(height: 25),
                _buildTextField(_usernameController, 'Email', false),
                const SizedBox(height: 20),
                _buildTextField(_passwordController, 'Password', true),
                const SizedBox(height: 20),
                _buildTextField(_confirmPasswordController, 'Confirm Password', true),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    backgroundColor: const Color.fromARGB(255, 7, 89, 253),
                  ),
                  onPressed: _isLoading ? null : _signUp,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Sign Up', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login'); // Navigasi ke halaman login
                  },
                  child: const Text(
                    'Sudah memiliki akun?',
                    style: TextStyle(color: Colors.blue, fontSize: 16),
                  ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText, bool isPassword) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      obscureText: isPassword,
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage ({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.9, end: 1.1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _login() {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Username atau Password tidak boleh kosong")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });
      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(seconds: 1),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          pageBuilder: (context, animation, secondaryAnimation) {
            return DashboardPage(username: _usernameController.text);
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ScaleTransition(
                  scale: _animation,
                  child: Image.asset('assets/logoklinik.png', height: 200),
                ),
                const SizedBox(height: 25),
                _buildTextField(_usernameController, 'Username', false),
                const SizedBox(height: 20),
                _buildTextField(_passwordController, 'Password', true),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    backgroundColor: const Color.fromARGB(255, 7, 89, 253),
                  ),
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Login', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup'); // Navigasi ke halaman login
                  },
                  child: const Text(
                    'Daftar Akun',
                    style: TextStyle(color: Colors.blue, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText, bool isPassword) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      obscureText: isPassword,
    );
  }
}


// Halaman Dashboard (Daftar Produk)
class DashboardPage extends StatefulWidget {
  final String username;
  const DashboardPage({super.key, required this.username});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final List<Map<String, dynamic>> products = [
    {'name': 'Ultra Cover Powder', 'price': 150000, 'image': 'assets/image1.jpeg'},
    {'name': 'Matte Cushion', 'price': 145000, 'image': 'assets/image2.jpeg'},
    {'name': 'Setting Spray', 'price': 100000, 'image': 'assets/image3.jpeg'},
    {'name': 'Sunscreen Spray SPF 50+', 'price': 180000, 'image': 'assets/image4.jpg'},
    {'name': 'Low PH Cleanser', 'price': 90000, 'image': 'assets/image5.jpg'},
    {'name': 'Ceramide Toner', 'price': 120000, 'image': 'assets/image6.jpg'},
    {'name': 'Ceramide Moisturizer', 'price': 950000, 'image': 'assets/image7.jpg'},
    {'name': 'Ceramide Serum', 'price': 950000, 'image': 'assets/image8.jpg'},
  ];

  final List<Map<String, dynamic>> _cart = [];

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      _cart.add(product);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${product['name']} ditambahkan ke keranjang")),
    );
  }

  void _goToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartPage(cart: _cart),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${widget.username}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: _goToCart,
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => _showLogoutConfirmation(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2 / 3,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return GestureDetector(
              child: Card(
                elevation: 8,
                shadowColor: Colors.blueAccent.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15),
                        ),
                        child: Image.asset(
                          product['image'],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text(
                            product['name'],
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Rp ${product['price']}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          ElevatedButton(
                            onPressed: () => _addToCart(product),
                            child: const Text('Add to Cart'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Logout"),
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginPage(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// Halaman Keranjang (Cart Page)

class CartPage extends StatelessWidget {
  final List<Map<String, dynamic>> cart;

  const CartPage({super.key, required this.cart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cart.length,
              itemBuilder: (context, index) {
                final item = cart[index];
                return ListTile(
                  leading: Image.asset(item['image'], width: 50, height: 50),
                  title: Text(item['name']),
                  subtitle: Text('Rp ${item['price']}'),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DanaPaymentPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text(
                'Beli Sekarang',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DanaPaymentPage extends StatefulWidget {
  const DanaPaymentPage({super.key});

  @override
  _DanaPaymentPageState createState() => _DanaPaymentPageState();
}

class _DanaPaymentPageState extends State<DanaPaymentPage> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran DANA'),
      ),
      body: SingleChildScrollView(  // Membungkus seluruh body dengan SingleChildScrollView
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Pilih metode pembayaran:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Menampilkan QRIS
            const Text(
              'Scan QRIS untuk melakukan pembayaran:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Image.asset(
              'assets/qris.jpg',
              height: 200,
              width: 200,
            ),
            const SizedBox(height: 30),

            // Atau menampilkan nomor DANA
            const Text(
              'Atau transfer menggunakan nomor DANA:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '085123456789',  // Nomor DANA yang bisa diubah sesuai kebutuhan
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),

            // Form alamat
            const Text(
              'Masukkan alamat pengiriman:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                hintText: 'Alamat lengkap',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Form nomor telepon
            const Text(
              'Masukkan nomor telepon:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'Nomor telepon',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),

            // Tombol konfirmasi pembayaran
            ElevatedButton(
              onPressed: () {
                // Ambil data dari form
                String address = _addressController.text.trim();
                String phone = _phoneController.text.trim();

                if (address.isNotEmpty && phone.isNotEmpty) {
                  // Aksi konfirmasi pembayaran
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pembayaran DANA diproses')),
                  );

                  // Navigasi kembali ke DashboardScreen setelah konfirmasi
                  Navigator.pop(context);  // Ini akan kembali ke halaman sebelumnya (DashboardScreen)
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Alamat dan nomor telepon harus diisi')),
                  );
                }
              },
              child: const Text('Konfirmasi Pembayaran'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                backgroundColor: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
