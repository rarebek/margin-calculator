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

  // Flag to prevent auto-recalculation when user is clearing fields
  bool _isSellingPriceBeingCleared = false;

  // Add a flag to track when margin is being edited
  bool _isMarginBeingEdited = false;

  @override
  void initState() {
    super.initState();

    // Add listeners to all text controllers for real-time calculations
    _boughtPriceController.addListener(_calculateOnChange);
    _sellingPriceController.addListener(_onSellingPriceChanged);
    _marginController.addListener(_onMarginChanged);
  }

  @override
  void dispose() {
    // Remove listeners
    _boughtPriceController.removeListener(_calculateOnChange);
    _sellingPriceController.removeListener(_onSellingPriceChanged);
    _marginController.removeListener(_onMarginChanged);

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

  // Handler for selling price changes
  void _onSellingPriceChanged() {
    if (_boughtPriceController.text.isNotEmpty && _sellingPriceController.text.isNotEmpty) {
      // Don't calculate margin if selling price field has focus (user is still typing)
      if (!_sellingPriceFocus.hasFocus) {
        _calculateMargin(updateUI: true);
      }
    }
    setState(() {});  // Update UI to refresh disabled state
  }

  // Handler for margin changes
  void _onMarginChanged() {
    if (_boughtPriceController.text.isNotEmpty && _marginController.text.isNotEmpty) {
      // Don't calculate selling price if margin field has focus (user is still typing)
      if (!_marginFocus.hasFocus) {
        _calculateSellingPrice(updateUI: true);
      }
    }
    setState(() {});  // Update UI to refresh disabled state
  }

  // Real-time calculation based on which fields have values
  void _calculateOnChange() {
    // Skip calculation if bought price is empty
    if (_boughtPriceController.text.isEmpty) {
      return;
    }

    // Case 1: Calculate selling price if we have bought price and margin
    if (_boughtPriceController.text.isNotEmpty && _marginController.text.isNotEmpty) {
      _calculateSellingPrice(updateUI: true);
    }
    // Case 2: Calculate margin if we have bought price and selling price
    else if (_boughtPriceController.text.isNotEmpty && _sellingPriceController.text.isNotEmpty) {
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
      // Parse values handling both dot and comma as decimal separator
      double boughtPrice = _parseDouble(_boughtPriceController.text);
      double margin = _parseDouble(_marginController.text);

      if (boughtPrice <= 0) {
        setState(() {
          _resultMessage = 'Bought price must be greater than zero';
        });
        return;
      }

      if (margin >= 100) {
        setState(() {
          _resultMessage = 'Margin must be less than 100%';
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

      // Updated formula: sellingPrice = (boughtPrice * 100) / (100 - margin)
      double sellingPrice = (boughtPrice * 100) / (100 - margin);

      if (updateUI) {
        setState(() {
          // Don't trigger the listener to avoid infinite loop
          _sellingPriceController.removeListener(_onSellingPriceChanged);

          // Don't format, just use basic string conversion to respect user preference
          _sellingPriceController.text = sellingPrice.toString();

          _sellingPriceController.addListener(_onSellingPriceChanged);

          _resultMessage = 'You should sell for ${_formatDisplayValue(sellingPrice)} $_sellingPriceCurrency to get ${_formatDisplayValue(margin)}% margin';
        });
      } else {
        _sellingPriceController.text = sellingPrice.toString();
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
      // Parse values handling both dot and comma as decimal separator
      double boughtPrice = _parseDouble(_boughtPriceController.text);
      double sellingPrice = _parseDouble(_sellingPriceController.text);

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

      // Updated formula: margin = (sellingPrice - boughtPrice) / sellingPrice * 100
      double margin = (sellingPrice - boughtPrice) / sellingPrice * 100;

      if (updateUI) {
        setState(() {
          // Don't trigger the listener to avoid infinite loop
          _marginController.removeListener(_onMarginChanged);

          // Don't format, just use basic string conversion to respect user preference
          _marginController.text = margin.toString();

          _marginController.addListener(_onMarginChanged);

          _resultMessage = 'Your margin is ${_formatDisplayValue(margin)}%';
        });
      } else {
        _marginController.text = margin.toString();
      }
    } catch (e) {
      setState(() {
        _resultMessage = 'Invalid input values';
      });
    }
  }

  // Parse double value from string, handling both dot and comma as decimal separators
  double _parseDouble(String value) {
    // Replace comma with dot if present, then parse
    return double.parse(value.replaceAll(',', '.'));
  }

  // Format value for display only (used in result messages, not input fields)
  String _formatDisplayValue(double value) {
    // Format with 2 decimal places for display purposes only
    String formatted = value.toStringAsFixed(2);
    // Remove trailing zeros
    formatted = formatted.replaceAll(RegExp(r'\.?0+$'), '');
    return formatted;
  }

  // Clear all focus to dismiss keyboard
  void _unfocusAll() {
    _boughtPriceFocus.unfocus();
    _sellingPriceFocus.unfocus();
    _marginFocus.unfocus();
  }

  // Handle special key events for price inputs
  void _handlePriceKeyEvent(RawKeyEvent event, TextEditingController controller) {
    if (event is RawKeyDownEvent) {
      // Check if comma key was pressed
      if (event.logicalKey == LogicalKeyboardKey.comma) {
        // Get current text and cursor position
        final text = controller.text;
        final cursorPos = controller.selection.start;

        // If text doesn't contain a dot, add it
        if (!text.contains('.')) {
          final newText = text + '.';
          controller.text = newText;
          // Move cursor after the dot
          controller.selection = TextSelection.fromPosition(
            TextPosition(offset: newText.length)
          );
        } else {
          // If text already has a dot, move cursor after it
          final dotIndex = text.indexOf('.');
          controller.selection = TextSelection.fromPosition(
            TextPosition(offset: dotIndex + 1)
          );
        }
      }
    }
  }

  // Handle special key events for margin input
  void _handleMarginKeyEvent(RawKeyEvent event, TextEditingController controller) {
    if (event is RawKeyDownEvent) {
      // Check if comma key was pressed
      if (event.logicalKey == LogicalKeyboardKey.comma) {
        // Get current text and cursor position
        final text = controller.text;
        final cursorPos = controller.selection.start;

        // If text doesn't contain a dot, insert it at cursor position
        if (!text.contains('.')) {
          final beforeCursor = text.substring(0, cursorPos);
          final afterCursor = text.substring(cursorPos);
          final newText = beforeCursor + '.' + afterCursor;

          controller.text = newText;
          // Move cursor after the dot
          controller.selection = TextSelection.fromPosition(
            TextPosition(offset: cursorPos + 1)
          );
        } else {
          // If text already has a dot, move cursor after it
          final dotIndex = text.indexOf('.');
          controller.selection = TextSelection.fromPosition(
            TextPosition(offset: dotIndex + 1)
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // We need separate flags that don't influence each other
    // Only disable margin when selling price has content AND user isn't actively editing selling price
    bool isMarginDisabled = _sellingPriceController.text.isNotEmpty && !_sellingPriceFocus.hasFocus;

    // Only disable selling price when margin has content AND user isn't actively editing margin
    bool isSellingPriceDisabled = _marginController.text.isNotEmpty && !_marginFocus.hasFocus;

    // Debug print to see the state
    print("Margin disabled: $isMarginDisabled, Selling Price disabled: $isSellingPriceDisabled");
    print("Margin text: ${_marginController.text}, Selling Price text: ${_sellingPriceController.text}");

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
                              child: RawKeyboardListener(
                                focusNode: FocusNode(),
                                onKey: (event) => _handlePriceKeyEvent(event, _boughtPriceController),
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
                                    // Only allow digits and at most one decimal point
                                    TextInputFormatter.withFunction((oldValue, newValue) {
                                      // Allow empty string for clearing
                                      if (newValue.text.isEmpty) {
                                        return newValue;
                                      }

                                      // Replace comma with dot
                                      String text = newValue.text.replaceAll(',', '.');

                                      // Check if valid number format
                                      if (RegExp(r'^\d*\.?\d*$').hasMatch(text)) {
                                        return newValue.copyWith(text: text);
                                      }
                                      return oldValue;
                                    }),
                                  ],
                                ),
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
                                      // Save current value
                                      if (_boughtPriceController.text.isNotEmpty) {
                                        try {
                                          double currentValue = _parseDouble(_boughtPriceController.text);

                                          // Convert from current currency to new currency
                                          double convertedValue = _convertCurrency(
                                            currentValue,
                                            _boughtPriceCurrency,
                                            newCurrency
                                          );

                                          // Update controller with converted value (no formatting)
                                          _boughtPriceController.removeListener(_calculateOnChange);
                                          _boughtPriceController.text = convertedValue.toString();
                                          _boughtPriceController.addListener(_calculateOnChange);
                                        } catch (e) {
                                          // If parsing fails, keep the field as is
                                        }
                                      }

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
                              child: RawKeyboardListener(
                                focusNode: FocusNode(),
                                onKey: (event) => _handlePriceKeyEvent(event, _sellingPriceController),
                                child: TextField(
                                  controller: _sellingPriceController,
                                  focusNode: _sellingPriceFocus,
                                  enabled: !isSellingPriceDisabled, // Disabled when margin has a value
                                  decoration: const InputDecoration(
                                    labelText: 'Selling Price',
                                    border: OutlineInputBorder(),
                                    suffixIcon: Icon(Icons.attach_money),
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    // Only allow digits and at most one decimal point
                                    TextInputFormatter.withFunction((oldValue, newValue) {
                                      // Allow empty string for clearing
                                      if (newValue.text.isEmpty) {
                                        return newValue;
                                      }

                                      // Replace comma with dot
                                      String text = newValue.text.replaceAll(',', '.');

                                      // Check if valid number format
                                      if (RegExp(r'^\d*\.?\d*$').hasMatch(text)) {
                                        return newValue.copyWith(text: text);
                                      }
                                      return oldValue;
                                    }),
                                  ],
                                  onChanged: (value) {
                                    // Only manage state when value changes
                                    setState(() {});

                                    // If user clears the selling price field
                                    if (value.isEmpty) {
                                      // Only clear margin if it's not being edited
                                      if (!_marginFocus.hasFocus) {
                                        _marginController.removeListener(_onMarginChanged);
                                        _marginController.text = '';
                                        _marginController.addListener(_onMarginChanged);
                                      }
                                    } else if (_boughtPriceController.text.isNotEmpty) {
                                      // Calculate margin in real-time as user types, but don't disable selling price while typing
                                      _calculateMargin(updateUI: true);
                                    }
                                  },
                                ),
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
                                      // Save current value
                                      if (_sellingPriceController.text.isNotEmpty) {
                                        try {
                                          double currentValue = _parseDouble(_sellingPriceController.text);

                                          // Convert from current currency to new currency
                                          double convertedValue = _convertCurrency(
                                            currentValue,
                                            _sellingPriceCurrency,
                                            newCurrency
                                          );

                                          // Update controller with converted value (no formatting)
                                          _sellingPriceController.removeListener(_onSellingPriceChanged);
                                          _sellingPriceController.text = convertedValue.toString();
                                          _sellingPriceController.addListener(_onSellingPriceChanged);
                                        } catch (e) {
                                          // If parsing fails, keep the field as is
                                        }
                                      }

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
                          enabled: !isMarginDisabled, // Disabled when selling price has a value
                          decoration: const InputDecoration(
                            labelText: 'Margin (%)',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.percent),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            // Only allow digits and at most one decimal point
                            TextInputFormatter.withFunction((oldValue, newValue) {
                              // Allow empty string for clearing
                              if (newValue.text.isEmpty) {
                                return newValue;
                              }

                              // Replace comma with dot
                              String text = newValue.text.replaceAll(',', '.');

                              // Check if valid number format
                              if (RegExp(r'^\d*\.?\d*$').hasMatch(text)) {
                                return newValue.copyWith(text: text);
                              }
                              return oldValue;
                            }),
                          ],
                          onChanged: (value) {
                            // Only manage state when value changes
                            setState(() {});

                            // If user clears the margin field
                            if (value.isEmpty) {
                              // Only clear selling price if it's not being edited
                              if (!_sellingPriceFocus.hasFocus) {
                                _sellingPriceController.removeListener(_onSellingPriceChanged);
                                _sellingPriceController.text = '';
                                _sellingPriceController.addListener(_onSellingPriceChanged);
                              }
                            } else if (_boughtPriceController.text.isNotEmpty) {
                              // Calculate selling price in real-time as user types, but don't disable margin while typing
                              _calculateSellingPrice(updateUI: true);
                            }
                          },
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
