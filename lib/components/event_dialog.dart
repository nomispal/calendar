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
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedAddress = '';
  TimeOfDay? _selectedTime;
  String _selectedType = 'other'; // Default to 'other'
  List<String> _eventSuggestions = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
    if (widget.event != null) {
      _titleController.text = widget.event!.title;
      _descriptionController.text = widget.event!.description ?? '';
      _selectedTime = TimeOfDay.fromDateTime(widget.event!.startTime);
      _selectedAddress = widget.selectedAddresses[widget.date] ?? '';
      _selectedType = widget.event!.type; // Set the event type
    }
  }

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

  Future<void> _addNewSuggestion(String suggestion) async {
    try {
      await _firestore.collection('suggestions').add({
        'title': suggestion,
      });
      await _loadSuggestions();
    } catch (e) {
      print('Error adding suggestion: $e');
    }
  }

  void _addNewSuggestionDialog() async {
    final newSuggestion = await showDialog<String>(
      context: context,
      builder: (context) => AddSuggestionDialog(),
    );

    if (newSuggestion != null && newSuggestion.isNotEmpty) {
      await _addNewSuggestion(newSuggestion);
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
              backgroundColor: Colors.grey[300],
              hourMinuteColor: Colors.white,
              hourMinuteTextColor: Colors.black,
              dayPeriodColor: Colors.white,
              dayPeriodTextColor: Colors.black,
              dialHandColor: Colors.grey,
              dialBackgroundColor: Colors.grey[200],
              dialTextColor: Colors.black,
              entryModeIconColor: Colors.grey,
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
          // Location Widget
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
          // Event Type Dropdown
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Event Type',
              border: OutlineInputBorder(),
            ),
            items: ['meeting', 'personal', 'work', 'social', 'other']
                .map((type) => DropdownMenuItem(
              value: type,
              child: Text(type),
            ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedType = value!;
              });
            },
          ),
          const SizedBox(height: 16.0),
          // Title Autocomplete
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.5,
            child: Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return _eventSuggestions.where((String suggestion) {
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
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    enabledBorder: const OutlineInputBorder(
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
                    color: Colors.grey[300],
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
            decoration: const InputDecoration(
              hintText: 'Comments',
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16.0),
          // Time Picker
          GestureDetector(
            onTap: _pickTime,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedTime == null
                        ? 'Select Time'
                        : _selectedTime!.format(context),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const Icon(Icons.access_time, color: Colors.white),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          // Add New Suggestion Button
          ElevatedButton(
            onPressed: _addNewSuggestionDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
            ),
            child: const Text(
              'Add New Suggestion',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      actions: [
        // Cancel Button
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
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

              final address = _selectedAddress.isNotEmpty
                  ? _selectedAddress
                  : 'No Address Selected';

              final event = Event(
                title: _titleController.text,
                date: selectedDateTime,
                id: widget.event?.id ?? '', // Use existing ID if updating
                address: address,
                startTime: selectedDateTime,
                description: _descriptionController.text,
                type: _selectedType, // Include the selected type
              );

              if (widget.event == null) {
                Event.addEvent(event);
              } else {
                Event.updateEvent(event);
              }

              widget.onSave();
              Navigator.pop(context);
            }
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}