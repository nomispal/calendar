import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';
import 'add_suggestions_dialog.dart';
import 'address_search_field.dart';

class EventDialog extends StatefulWidget {
  final DateTime date;
  final Map<DateTime, String> selectedAddresses;
  final Function() onSave;
  final Event? event; // Optional event parameter for updating

  const EventDialog({
    Key? key,
    required this.date,
    required this.onSave,
    required this.selectedAddresses,
    this.event, // Add this line
  }) : super(key: key);

  @override
  _EventDialogState createState() => _EventDialogState();
}

class _EventDialogState extends State<EventDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();// Controller for description
  String _selectedAddress = '';

  TimeOfDay? _selectedTime;

  // Initialize the suggestions list
  List<String> _eventSuggestions = [];

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadSuggestions(); // Load suggestions when the dialog is opened
    if (widget.event != null) {
      _titleController.text = widget.event!.title;
      _descriptionController.text = widget.event!.description ?? '';
      _selectedTime = TimeOfDay.fromDateTime(widget.event!.startTime);
      _selectedAddress = widget.selectedAddresses[widget.date] ?? '';
    }
  }

  // Load suggestions from Firestore
  Future<void> _loadSuggestions() async {
    try {
      final querySnapshot = await _firestore.collection('suggestions').get();
      setState(() {
        _eventSuggestions =
            querySnapshot.docs.map((doc) => doc['title'] as String).toList();
      });
    } catch (e) {
      print('Error loading suggestions: $e');
    }
  }

  // Add a new suggestion to Firestore
  Future<void> _addNewSuggestion(String suggestion) async {
    try {
      await _firestore.collection('suggestions').add({
        'title': suggestion,
      });
      await _loadSuggestions(); // Reload suggestions after adding a new one
    } catch (e) {
      print('Error adding suggestion: $e');
    }
  }

  // Function to open a dialog for adding new suggestions
  void _addNewSuggestionDialog() async {
    final newSuggestion = await showDialog<String>(
      context: context,
      builder: (context) => AddSuggestionDialog(),
    );

    if (newSuggestion != null && newSuggestion.isNotEmpty) {
      await _addNewSuggestion(
          newSuggestion); // Add the new suggestion to Firestore
    }
  }

  void _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.grey[300], // Set background color to grey
              hourMinuteColor: Colors.white, // Set hour/minute selection color
              hourMinuteTextColor: Colors.black, // Set hour/minute text color
              dayPeriodColor: Colors.white, // Set AM/PM selection color
              dayPeriodTextColor: Colors.black, // Set AM/PM text color
              dialHandColor: Colors.grey, // Set clock hand color
              dialBackgroundColor: Colors.grey[200], // Set clock dial background
              dialTextColor: Colors.black, // Set clock numbers color
              entryModeIconColor: Colors.grey, // Set entry mode icon color
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[300],
      title: const Text('Add Event'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Location Widget inside the dialog
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _selectedAddress.isEmpty ? 'No Property Selected' : _selectedAddress,
                  style: const TextStyle(fontSize: 12.0),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final selectedAddress = await showDialog<String>(
                    context: context,
                    builder: (BuildContext context) {
                      return AddressAutocomplete(
                        onAddressSelected: (address) {
                          Navigator.of(context).pop(address);
                        },
                      );
                    },
                  );
                  if (selectedAddress != null) {
                    setState(() {
                      _selectedAddress = selectedAddress;
                      // Update the selectedAddresses map in the parent
                      widget.selectedAddresses[widget.date] = selectedAddress;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                  decoration: BoxDecoration(
                    color: _selectedAddress.isEmpty ? Colors.grey : Colors.blueGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _selectedAddress.isEmpty ? 'Add Property' : 'Change Property',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.5,
            child: Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return _eventSuggestions.where((String suggestion) {
                  // Case-insensitive comparison
                  return suggestion
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (String selection) {
                _titleController.text = selection;
              },
              fieldViewBuilder: (BuildContext context,
                  TextEditingController textEditingController,
                  FocusNode focusNode,
                  VoidCallback onFieldSubmitted) {
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'Event title',
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                );
              },
              optionsViewBuilder: (BuildContext context,
                  AutocompleteOnSelected<String> onSelected,
                  Iterable<String> options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    color: Colors.grey[300], // Set dropdown background color
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.5,
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final String option = options.elementAt(index);
                          return ListTile(
                            title: Text(option),
                            onTap: () {
                              onSelected(option);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16.0),
          // Description TextField
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              hintText: 'Comments',
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
            ),
            maxLines: 3, // Allow multiple lines for description
          ),
          const SizedBox(height: 16.0),
          GestureDetector(
            onTap: _pickTime,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  color: Colors.grey,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedTime == null
                          ? 'Select Time'
                          : _selectedTime!.format(context),
                      style: TextStyle(color: Colors.white),
                    ),
                    const Icon(Icons.access_time, color: Colors.white), // Set icon color to grey
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          // Button to add new suggestions
          ElevatedButton(
            onPressed: _addNewSuggestionDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey, // Set button color to grey
            ),
            child: const Text(
              'Add New Suggestion',
              style: TextStyle(color: Colors.white), // Set text color to white
            ),
          ),
        ],
      ),
      actions: [
        // Cancel Button
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.black, // Set text color to grey
          ),
          child: const Text('Cancel'),
        ),
        // Save Button
        TextButton(
          onPressed: () {
            if (_titleController.text.isNotEmpty && _selectedTime != null) {
              final selectedDateTime = DateTime(
                widget.date.year,
                widget.date.month,
                widget.date.day,
                _selectedTime!.hour,
                _selectedTime!.minute,
              );

              // Use the address selected in the dialog
              final address = _selectedAddress.isNotEmpty
                  ? _selectedAddress
                  : 'No Address Selected';

              Event.addEvent(Event(
                title: _titleController.text,
                date: selectedDateTime,
                id: '', // You might want to generate a unique ID here
                address: address,
                startTime: selectedDateTime, // Use selectedDateTime as startTime
                description: _descriptionController.text, // Add the description
              ));
              widget.onSave();
              Navigator.pop(context);
            }
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.black, // Set text color to grey
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}