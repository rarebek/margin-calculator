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
    // When selling price is not empty, disable margin field
    setState(() {
      // Calculate margin value but keep the priority on selling price
    });

    _calculateOnChange();
  }

  // Handler for margin changes
  void _onMarginChanged() {
    // When margin is not empty, disable selling price field
    setState(() {
      // Calculate selling price but keep the priority on margin
    });

    _calculateOnChange();
  }

  // Real-time calculation based on which fields have values
  void _calculateOnChange() {
    // Skip calculation if bought price is empty
    if (!_boughtPriceController.text.isNotEmpty) {
      return;
    }

    // Case 1: Calculate selling price if we have bought price and margin
    // Only if not actively clearing or editing selling price
    if (_boughtPriceController.text.isNotEmpty &&
        _marginController.text.isNotEmpty &&
        (!_sellingPriceFocus.hasFocus || _isMarginBeingEdited) &&
        !_isSellingPriceBeingCleared) {
      _calculateSellingPrice(updateUI: true);
    }
    // Case 2: Calculate margin if we have bought price and selling price
    // Only if margin is not being actively edited
    else if (_boughtPriceController.text.isNotEmpty &&
             _sellingPriceController.text.isNotEmpty &&
             !_marginFocus.hasFocus &&
             !_isMarginBeingEdited) {
      // Always calculate margin when both prices are available
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
          _sellingPriceController.removeListener(_calculateOnChange);

          // Don't format, just use basic string conversion to respect user preference
          _sellingPriceController.text = sellingPrice.toString();

          _sellingPriceController.addListener(_calculateOnChange);

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
          _marginController.removeListener(_calculateOnChange);

          // Don't format, just use basic string conversion to respect user preference
          _marginController.text = margin.toString();

          _marginController.addListener(_calculateOnChange);

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
                                  enabled: true, // Always enabled - user should be able to type here
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
                                    // If the field is being cleared
                                    if (value.isEmpty) {
                                      // Set flag to prevent selling price recalculation
                                      setState(() {
                                        _isSellingPriceBeingCleared = true;
                                      });

                                      // Clear margin to prevent auto-recalculation of selling price
                                      _marginController.removeListener(_onMarginChanged);
                                      _marginController.text = '';
                                      _marginController.addListener(_onMarginChanged);

                                      // Reset flag after a short delay to allow for emptying
                                      Future.delayed(const Duration(milliseconds: 100), () {
                                        setState(() {
                                          _isSellingPriceBeingCleared = false;
                                        });
                                      });
                                    } else {
                                      // When value is not empty, always calculate margin
                                      if (_boughtPriceController.text.isNotEmpty) {
                                        _calculateMargin(updateUI: true);
                                      }
                                    }
                                  },
                                  // Add focus listeners to handle focus state
                                  onTap: () {
                                    // When field gets focus, disable auto-filling selling price
                                    setState(() {
                                      _isSellingPriceBeingCleared = true;
                                    });
                                  },
                                  onEditingComplete: () {
                                    // Re-enable calculations when done editing
                                    setState(() {
                                      _isSellingPriceBeingCleared = false;
                                    });
                                    _calculateOnChange();
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
                                          _sellingPriceController.removeListener(_calculateOnChange);
                                          _sellingPriceController.text = convertedValue.toString();
                                          _sellingPriceController.addListener(_calculateOnChange);
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
                        RawKeyboardListener(
                          focusNode: FocusNode(),
                          onKey: (event) => _handleMarginKeyEvent(event, _marginController),
                          child: TextField(
                            controller: _marginController,
                            focusNode: _marginFocus,
                            enabled: _sellingPriceController.text.isEmpty, // Only disabled when selling price has a value
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
                              // If margin is changed, recalculate selling price
                              if (_boughtPriceController.text.isNotEmpty && value.isNotEmpty) {
                                setState(() {
                                  _isMarginBeingEdited = true;
                                });
                                _calculateSellingPrice(updateUI: true);

                                // Reset flag after a short delay
                                Future.delayed(const Duration(milliseconds: 100), () {
                                  setState(() {
                                    _isMarginBeingEdited = false;
                                  });
                                });
                              } else if (value.isEmpty) {
                                // If margin is deleted, also clear selling price
                                setState(() {
                                  // Prevent recalculation while clearing
                                  _isSellingPriceBeingCleared = true;

                                  // Clear selling price field
                                  _sellingPriceController.removeListener(_onSellingPriceChanged);
                                  _sellingPriceController.text = '';
                                  _sellingPriceController.addListener(_onSellingPriceChanged);

                                  // Reset the flag after clearing
                                  Future.delayed(const Duration(milliseconds: 100), () {
                                    _isSellingPriceBeingCleared = false;
                                  });
                                });
                              }
                            },
                            // Add focus listeners to handle focus state
                            onTap: () {
                              // When margin field gets focus, mark it as being edited
                              setState(() {
                                _isMarginBeingEdited = true;
                              });
                            },
                            onEditingComplete: () {
                              // Re-enable calculations when done editing
                              setState(() {
                                _isMarginBeingEdited = false;
                              });
                              if (_boughtPriceController.text.isNotEmpty && _marginController.text.isNotEmpty) {
                                _calculateSellingPrice(updateUI: true);
                              }
                            },
                          ),
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
