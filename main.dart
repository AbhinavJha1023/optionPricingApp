import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

void main() => runApp(OptionPricingApp());

class OptionPricingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Option Pricing',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueGrey,
        scaffoldBackgroundColor: Colors.black,
        sliderTheme: SliderTheme.of(context).copyWith(
          activeTrackColor: Colors.blueAccent,
          inactiveTrackColor: Colors.grey,
          thumbColor: Colors.blueAccent,
          overlayColor: Colors.blue.withAlpha(32),
          valueIndicatorColor: Colors.blueAccent,
          valueIndicatorTextStyle: TextStyle(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: EdgeInsets.symmetric(vertical: 15.0),
            textStyle: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.white, fontSize: 16.0),
          bodyMedium: TextStyle(color: Colors.white, fontSize: 16.0),
          titleLarge: TextStyle(color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.bold),
        ),
      ),
      home: OptionPricingHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class OptionPricingHome extends StatefulWidget {
  @override
  _OptionPricingHomeState createState() => _OptionPricingHomeState();
}

class _OptionPricingHomeState extends State<OptionPricingHome> with SingleTickerProviderStateMixin {
  double S0 = 100; // Stock Price
  double E = 100; // Strike Price
  double T = 1; // Expiry in years
  double rf = 0.05; // Risk-free rate
  double sigma = 0.2; // Volatility
  double iterations = 100000; // Number of iterations
  String callOptionPrice = "";
  String putOptionPrice = "";
  bool isCalculating = false;

  // Box-Muller transform to generate normal distribution
  double _generateGaussianRandom() {
    double u1 = Random().nextDouble();
    double u2 = Random().nextDouble();
    return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);
  }

  // Monte Carlo Simulation for Call Option
  Future<double> callOptionSimulation() async {
    double sum = 0.0;
    for (int i = 0; i < iterations; i++) {
      double rand = _generateGaussianRandom();
      double stockPrice = S0 *
          exp(T * (rf - 0.5 * sigma * sigma) +
              sigma * sqrt(T) * rand);
      sum += max(0, stockPrice - E);
    }
    return exp(-rf * T) * (sum / iterations);
  }

  // Monte Carlo Simulation for Put Option
  Future<double> putOptionSimulation() async {
    double sum = 0.0;
    for (int i = 0; i < iterations; i++) {
      double rand = _generateGaussianRandom();
      double stockPrice = S0 *
          exp(T * (rf - 0.5 * sigma * sigma) +
              sigma * sqrt(T) * rand);
      sum += max(0, E - stockPrice);
    }
    return exp(-rf * T) * (sum / iterations);
  }

  // Black-Scholes Formula for Call Option
  double blackScholesCall() {
    double d1 = (log(S0 / E) + (rf + 0.5 * sigma * sigma) * T) / (sigma * sqrt(T));
    double d2 = d1 - sigma * sqrt(T);
    return S0 * _cnd(d1) - E * exp(-rf * T) * _cnd(d2);
  }

  // Black-Scholes Formula for Put Option
  double blackScholesPut() {
    double d1 = (log(S0 / E) + (rf + 0.5 * sigma * sigma) * T) / (sigma * sqrt(T));
    double d2 = d1 - sigma * sqrt(T);
    return E * exp(-rf * T) * _cnd(-d2) - S0 * _cnd(-d1);
  }

  // Cumulative normal distribution function
  double _cnd(double x) {
    var l = 1.0 / (1.0 + 0.2316419 * x.abs());
    var k = 1.0 - 1.0 / sqrt(2 * pi) * exp(-0.5 * x * x) *
        (0.319381530 * l - 0.356563782 * pow(l, 2) +
            1.781477937 * pow(l, 3) - 1.821255978 * pow(l, 4) +
            1.330274429 * pow(l, 5));
    return x < 0 ? 1.0 - k : k;
  }

  void calculateMonteCarloOptions() async {
    setState(() {
      isCalculating = true;
      callOptionPrice = "";
      putOptionPrice = "";
    });

    // Run simulations concurrently
    double callPrice = await callOptionSimulation();
    double putPrice = await putOptionSimulation();

    setState(() {
      callOptionPrice = callPrice.toStringAsFixed(2);
      putOptionPrice = putPrice.toStringAsFixed(2);
      isCalculating = false;
    });
  }

  void calculateBlackScholesOptions() {
    setState(() {
      isCalculating = true;
      callOptionPrice = blackScholesCall().toStringAsFixed(2);
      putOptionPrice = blackScholesPut().toStringAsFixed(2);
      isCalculating = false;
    });
  }

  // Function to build a gradient button with ripple effect and hover animation
  Widget _buildGradientButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.purpleAccent],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30.0),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.6),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Function(double) onChanged,
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: ${value.toStringAsFixed(2)}${suffix ?? ''}",
          style: TextStyle(fontWeight: FontWeight.normal),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: value.toStringAsFixed(2),
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Option Pricing Simulator'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    buildSlider(
                      label: "Underlying Stock Price (S₀)",
                      value: S0,
                      min: 50,
                      max: 200,
                      divisions: 150,
                      onChanged: (value) {
                        setState(() {
                          S0 = value;
                        });
                      },
                    ),
                    buildSlider(
                      label: "Strike Price (E)",
                      value: E,
                      min: 50,
                      max: 200,
                      divisions: 150,
                      onChanged: (value) {
                        setState(() {
                          E = value;
                        });
                      },
                    ),
                    buildSlider(
                      label: "Expiry (T) in years",
                      value: T,
                      min: 0.1,
                      max: 5.0,
                      divisions: 50,
                      onChanged: (value) {
                        setState(() {
                          T = value;
                        });
                      },
                    ),
                    buildSlider(
                      label: "Risk-Free Rate (rₓ)",
                      value: rf,
                      min: 0.01,
                      max: 0.10,
                      divisions: 100,
                      onChanged: (value) {
                        setState(() {
                          rf = value;
                        });
                      },
                      suffix: '',
                    ),
                    buildSlider(
                      label: "Volatility (σ)",
                      value: sigma,
                      min: 0.1,
                      max: 1.0,
                      divisions: 100,
                      onChanged: (value) {
                        setState(() {
                          sigma = value;
                        });
                      },
                    ),
                    buildSlider(
                      label: "Iterations",
                      value: iterations,
                      min: 10000,
                      max: 1000000,
                      divisions: 100,
                      onChanged: (value) {
                        setState(() {
                          iterations = value;
                        });
                      },
                      suffix: '',
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            isCalculating
                ? CircularProgressIndicator()
                : SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildGradientButton(
                    text: 'Monte Carlo Options',
                    icon: Icons.calculate,
                    onPressed: calculateMonteCarloOptions,
                  ),
                  SizedBox(height: 20,),
                  _buildGradientButton(
                    text: 'Black-Scholes Options',
                    icon: Icons.calculate,
                    onPressed: calculateBlackScholesOptions,
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            Text(
              'Call Option Price: \$${callOptionPrice}',
              style: TextStyle(fontSize: 22, color: Colors.green),
            ),
            SizedBox(height: 10),
            Text(
              'Put Option Price: \$${putOptionPrice}',
              style: TextStyle(fontSize: 22, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
