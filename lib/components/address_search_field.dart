import 'dart:async';
import 'package:flutter/material.dart';
import '../services/address_service.dart';
class AddressAutocomplete extends StatefulWidget {
  final void Function(String) onAddressSelected;

  AddressAutocomplete({Key? key, required this.onAddressSelected}) : super(key: key);

  @override
  _AddressAutocompleteState createState() => _AddressAutocompleteState();
}

class _AddressAutocompleteState extends State<AddressAutocomplete> {
  final AddressService _addressService = AddressService();
  final TextEditingController _controller = TextEditingController();

  List<String> _suggestions = [];
  Timer? _debounce;
  bool _isLoading = false;
  final Map<String, List<String>> _cache = {};

  void _onTextChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (value.isNotEmpty) {
        if (_cache.containsKey(value)) {
          setState(() {
            _suggestions = _cache[value]!;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = true;
          });
          _addressService.getAddressSuggestions(value).then((results) {
            setState(() {
              _suggestions = results.take(5).toList();
              _cache[value] = results;
              _isLoading = false;
            });
          }).catchError((error) {
            setState(() {
              _suggestions = [];
              _isLoading = false;
            });
          });
        }
      } else {
        setState(() {
          _suggestions = [];
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Enter Address',
                  border: OutlineInputBorder(),
                ),
                onChanged: _onTextChanged,
              ),
              const SizedBox(height: 10),
              if (_isLoading)
                const CircularProgressIndicator()
              else if (_suggestions.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_suggestions[index]),
                        onTap: () {
                          widget.onAddressSelected(_suggestions[index]);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
