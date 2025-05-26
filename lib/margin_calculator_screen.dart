import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MarginCalculatorScreen extends StatefulWidget {
  const MarginCalculatorScreen({Key? key}) : super(key: key);

  @override
  _MarginCalculatorScreenState createState() => _MarginCalculatorScreenState();
}

class _MarginCalculatorScreenState extends State<MarginCalculatorScreen> {
  // Text controllers for the input fields
  final TextEditingController _boughtPriceController = TextEditingController();
  final TextEditingController _sellingPriceController = TextEditingController();
  final TextEditingController _marginController = TextEditingController();

  // Currently selected currency
  String _selectedCurrency = 'UZ';

  // Static currency conversion rates (relative to UZ)
  final Map<String, double> _currencyRates = {
    'UZ': 1.0,
    'USD': 12500.0, // 1 USD = 12,500 UZ (example rate)
    'RUB': 130.0,   // 1 RUB = 130 UZ (example rate)
  };

  // Result message
  String _resultMessage = '';

  @override
  void dispose() {
    _boughtPriceController.dispose();
    _sellingPriceController.dispose();
    _marginController.dispose();
    super.dispose();
  }

  // Calculate selling price based on bought price and margin
  void _calculateSellingPrice() {
    if (_boughtPriceController.text.isEmpty || _marginController.text.isEmpty) {
      setState(() {
        _resultMessage = 'Please enter both bought price and margin';
      });
      return;
    }

    try {
      double boughtPrice = double.parse(_boughtPriceController.text);
      double margin = double.parse(_marginController.text);

      if (boughtPrice <= 0) {
        setState(() {
          _resultMessage = 'Bought price must be greater than zero';
        });
        return;
      }

      // Calculate selling price: boughtPrice + (boughtPrice * margin / 100)
      double sellingPrice = boughtPrice * (1 + margin / 100);

      setState(() {
        _sellingPriceController.text = sellingPrice.toStringAsFixed(2);
        _resultMessage = 'You should sell for ${sellingPrice.toStringAsFixed(2)} $_selectedCurrency to get $margin% margin';
      });
    } catch (e) {
      setState(() {
        _resultMessage = 'Invalid input values';
      });
    }
  }

  // Calculate margin based on bought price and selling price
  void _calculateMargin() {
    if (_boughtPriceController.text.isEmpty || _sellingPriceController.text.isEmpty) {
      setState(() {
        _resultMessage = 'Please enter both bought price and selling price';
      });
      return;
    }

    try {
      double boughtPrice = double.parse(_boughtPriceController.text);
      double sellingPrice = double.parse(_sellingPriceController.text);

      if (boughtPrice <= 0) {
        setState(() {
          _resultMessage = 'Bought price must be greater than zero';
        });
        return;
      }

      if (sellingPrice <= 0) {
        setState(() {
          _resultMessage = 'Selling price must be greater than zero';
        });
        return;
      }

      // Calculate margin: ((sellingPrice - boughtPrice) / boughtPrice) * 100
      double margin = ((sellingPrice - boughtPrice) / boughtPrice) * 100;

      setState(() {
        _marginController.text = margin.toStringAsFixed(2);
        _resultMessage = 'Your margin is ${margin.toStringAsFixed(2)}%';
      });
    } catch (e) {
      setState(() {
        _resultMessage = 'Invalid input values';
      });
    }
  }

  // Convert currency when selection changes
  void _onCurrencyChanged(String? newCurrency) {
    if (newCurrency == null || newCurrency == _selectedCurrency) return;

    double conversionFactor = _currencyRates[_selectedCurrency]! / _currencyRates[newCurrency]!;

    // Convert values in controllers
    if (_boughtPriceController.text.isNotEmpty) {
      double boughtPrice = double.parse(_boughtPriceController.text) * conversionFactor;
      _boughtPriceController.text = boughtPrice.toStringAsFixed(2);
    }

    if (_sellingPriceController.text.isNotEmpty) {
      double sellingPrice = double.parse(_sellingPriceController.text) * conversionFactor;
      _sellingPriceController.text = sellingPrice.toStringAsFixed(2);
    }

    setState(() {
      _selectedCurrency = newCurrency;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Margin Calculator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Currency Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Currency',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedCurrency,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        items: _currencyRates.keys.map((String currency) {
                          return DropdownMenuItem<String>(
                            value: currency,
                            child: Text(currency),
                          );
                        }).toList(),
                        onChanged: _onCurrencyChanged,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Input Fields
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enter Values',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bought Price Input
                      TextField(
                        controller: _boughtPriceController,
                        decoration: InputDecoration(
                          labelText: 'Bought Price ($_selectedCurrency)',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _boughtPriceController.clear(),
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Selling Price Input
                      TextField(
                        controller: _sellingPriceController,
                        decoration: InputDecoration(
                          labelText: 'Selling Price ($_selectedCurrency)',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _sellingPriceController.clear(),
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Margin Input
                      TextField(
                        controller: _marginController,
                        decoration: InputDecoration(
                          labelText: 'Margin (%)',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _marginController.clear(),
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Calculation Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _calculateSellingPrice,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Calculate Selling Price'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _calculateMargin,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Calculate Margin'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Result Display
              if (_resultMessage.isNotEmpty)
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _resultMessage,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
