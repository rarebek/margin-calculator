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

  // Currently selected currencies for each input
  String _boughtPriceCurrency = 'UZ';
  String _sellingPriceCurrency = 'UZ';

  // Static currency conversion rates (relative to UZ)
  final Map<String, double> _currencyRates = {
    'UZ': 1.0,
    'USD': 12500.0, // 1 USD = 12,500 UZ (example rate)
    'RUB': 130.0,   // 1 RUB = 130 UZ (example rate)
  };

  // Result message
  String _resultMessage = '';

  // Focus nodes for input fields
  final FocusNode _boughtPriceFocus = FocusNode();
  final FocusNode _sellingPriceFocus = FocusNode();
  final FocusNode _marginFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    // Add listeners to all text controllers for real-time calculations
    _boughtPriceController.addListener(_calculateOnChange);
    _sellingPriceController.addListener(_calculateOnChange);
    _marginController.addListener(_calculateOnChange);
  }

  @override
  void dispose() {
    // Remove listeners
    _boughtPriceController.removeListener(_calculateOnChange);
    _sellingPriceController.removeListener(_calculateOnChange);
    _marginController.removeListener(_calculateOnChange);

    // Dispose controllers
    _boughtPriceController.dispose();
    _sellingPriceController.dispose();
    _marginController.dispose();

    // Dispose focus nodes
    _boughtPriceFocus.dispose();
    _sellingPriceFocus.dispose();
    _marginFocus.dispose();

    super.dispose();
  }

  // Real-time calculation based on which fields have values
  void _calculateOnChange() {
    // Skip calculation if any text change is in progress or text is empty
    if (!_boughtPriceController.text.isNotEmpty) {
      return;
    }

    // Case 1: Calculate selling price if we have bought price and margin
    if (_boughtPriceController.text.isNotEmpty &&
        _marginController.text.isNotEmpty &&
        _sellingPriceController.text.isEmpty) {
      _calculateSellingPrice(updateUI: true);
    }
    // Case 2: Calculate margin if we have bought price and selling price
    else if (_boughtPriceController.text.isNotEmpty &&
             _sellingPriceController.text.isNotEmpty) {
      _calculateMargin(updateUI: true);
    }
  }

  // Convert value from one currency to another
  double _convertCurrency(double value, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return value;

    // Convert to base currency (UZ) first, then to target currency
    double valueInUZ = value * _currencyRates[fromCurrency]!;
    return valueInUZ / _currencyRates[toCurrency]!;
  }

  // Calculate selling price based on bought price and margin
  void _calculateSellingPrice({bool updateUI = false}) {
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

      // Convert bought price to selling price currency if needed
      if (_boughtPriceCurrency != _sellingPriceCurrency) {
        boughtPrice = _convertCurrency(
          boughtPrice,
          _boughtPriceCurrency,
          _sellingPriceCurrency
        );
      }

      // Calculate selling price: boughtPrice + (boughtPrice * margin / 100)
      double sellingPrice = boughtPrice * (1 + margin / 100);

      if (updateUI) {
        setState(() {
          // Don't trigger the listener to avoid infinite loop
          _sellingPriceController.removeListener(_calculateOnChange);
          _sellingPriceController.text = sellingPrice.toStringAsFixed(2);
          _sellingPriceController.addListener(_calculateOnChange);

          _resultMessage = 'You should sell for ${sellingPrice.toStringAsFixed(2)} $_sellingPriceCurrency to get $margin% margin';
        });
      } else {
        _sellingPriceController.text = sellingPrice.toStringAsFixed(2);
      }
    } catch (e) {
      setState(() {
        _resultMessage = 'Invalid input values';
      });
    }
  }

  // Calculate margin based on bought price and selling price
  void _calculateMargin({bool updateUI = false}) {
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

      // Convert bought price to selling price currency if they're different
      if (_boughtPriceCurrency != _sellingPriceCurrency) {
        boughtPrice = _convertCurrency(
          boughtPrice,
          _boughtPriceCurrency,
          _sellingPriceCurrency
        );
      }

      // Calculate margin: ((sellingPrice - boughtPrice) / boughtPrice) * 100
      double margin = ((sellingPrice - boughtPrice) / boughtPrice) * 100;

      if (updateUI) {
        setState(() {
          // Don't trigger the listener to avoid infinite loop
          _marginController.removeListener(_calculateOnChange);
          _marginController.text = margin.toStringAsFixed(2);
          _marginController.addListener(_calculateOnChange);

          _resultMessage = 'Your margin is ${margin.toStringAsFixed(2)}%';
        });
      } else {
        _marginController.text = margin.toStringAsFixed(2);
      }
    } catch (e) {
      setState(() {
        _resultMessage = 'Invalid input values';
      });
    }
  }

  // Clear all focus to dismiss keyboard
  void _unfocusAll() {
    _boughtPriceFocus.unfocus();
    _sellingPriceFocus.unfocus();
    _marginFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Dismiss keyboard when tapping outside input fields
      onTap: _unfocusAll,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Margin Calculator'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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

                        // Bought Price Input with Currency
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 7,
                              child: TextField(
                                controller: _boughtPriceController,
                                focusNode: _boughtPriceFocus,
                                decoration: const InputDecoration(
                                  labelText: 'Bought Price',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.price_change),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                value: _boughtPriceCurrency,
                                decoration: const InputDecoration(
                                  labelText: 'Currency',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                ),
                                items: _currencyRates.keys.map((String currency) {
                                  return DropdownMenuItem<String>(
                                    value: currency,
                                    child: Text(currency),
                                  );
                                }).toList(),
                                onChanged: (String? newCurrency) {
                                  if (newCurrency != null && newCurrency != _boughtPriceCurrency) {
                                    setState(() {
                                      _boughtPriceCurrency = newCurrency;
                                    });
                                    _calculateOnChange();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Selling Price Input with Currency
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 7,
                              child: TextField(
                                controller: _sellingPriceController,
                                focusNode: _sellingPriceFocus,
                                decoration: const InputDecoration(
                                  labelText: 'Selling Price',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.attach_money),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                value: _sellingPriceCurrency,
                                decoration: const InputDecoration(
                                  labelText: 'Currency',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                ),
                                items: _currencyRates.keys.map((String currency) {
                                  return DropdownMenuItem<String>(
                                    value: currency,
                                    child: Text(currency),
                                  );
                                }).toList(),
                                onChanged: (String? newCurrency) {
                                  if (newCurrency != null && newCurrency != _sellingPriceCurrency) {
                                    setState(() {
                                      _sellingPriceCurrency = newCurrency;
                                    });
                                    _calculateOnChange();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Margin Input
                        TextField(
                          controller: _marginController,
                          focusNode: _marginFocus,
                          decoration: const InputDecoration(
                            labelText: 'Margin (%)',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.percent),
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

                const SizedBox(height: 24),

                // Help text
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How to use:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text('• Enter bought price + margin to calculate selling price'),
                        Text('• Enter bought price + selling price to calculate margin'),
                        Text('• Each price can have its own currency'),
                        Text('• Calculations happen automatically'),
                      ],
                    ),
                  ),
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
      ),
    );
  }
}
