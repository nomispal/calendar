import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';
import 'add_suggestions_dialog.dart';
import 'address_search_field.dart';

class EventDialog extends StatefulWidget {
  final DateTime date;
  final Map<DateTime, String> selectedAddresses;
  final Function() onSave;
  final Event? event;

  const EventDialog({
    Key? key,
    required this.date,
    required this.onSave,
    required this.selectedAddresses,
    this.event,
  }) : super(key: key);

  @override
  _EventDialogState createState() => _EventDialogState();
}

class _EventDialogState extends State<EventDialog> {
  final TextEditingController _titleController = TextEditingController();
  late TextEditingController _autocompleteController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedAddress = '';
  TimeOfDay? _selectedTime;
  String _selectedType = 'other';
  List<String> _eventSuggestions = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _titleError;
  String? _timeError;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() {
      if (_titleController.text.isNotEmpty && _titleError != null) {
        setState(() => _titleError = null);
      }
    });
    _loadSuggestions();
    if (widget.event != null) {
      _titleController.text = widget.event!.title;
      _autocompleteController.text = widget.event!.title;
      _descriptionController.text = widget.event!.description ?? '';
      _selectedTime = TimeOfDay.fromDateTime(widget.event!.startTime);
      _selectedAddress = widget.selectedAddresses[widget.date] ?? '';
      _selectedType = widget.event!.type;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _autocompleteController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
        _timeError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dialogWidth = MediaQuery.of(context).size.width * 0.4;

    return AlertDialog(
      backgroundColor: Colors.grey[300],
      title: const Text('Add Event'),
      content: SizedBox(
        width: dialogWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: dialogWidth,
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _selectedAddress.isEmpty
                          ? 'No Property Selected'
                          : _selectedAddress,
                      style: const TextStyle(fontSize: 12.0),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
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
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                        decoration: BoxDecoration(
                          color: _selectedAddress.isEmpty ? Colors.grey : Colors.blueGrey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _selectedAddress.isEmpty ? 'Add Property' : 'Change Property',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              SizedBox(
                width: dialogWidth,
                child: DropdownButtonFormField<String>(
                  value: _selectedType,
                  dropdownColor: Colors.grey[300],
                  decoration: const InputDecoration(
                    labelStyle: TextStyle(color: Colors.black),
                    labelText: 'Event Type',
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black)),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey)),
                  ),
                  items: ['meeting', 'personal', 'work', 'social', 'other']
                      .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedType = value!);
                  },
                ),
              ),
              const SizedBox(height: 16.0),
              SizedBox(
                width: dialogWidth,
                child: Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    return _eventSuggestions.where((suggestion) =>
                        suggestion.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (selection) {
                    _titleController.text = selection;
                    _autocompleteController.text = selection;
                  },
                  fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                    _autocompleteController = controller;
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onChanged: (value) {
                        _titleController.text = value;
                      },
                      decoration: InputDecoration(
                        hintText: 'Event title',
                        errorText: _titleError,
                        errorBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.red)),
                        focusedErrorBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.red)),
                        focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black)),
                        enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey)),
                      ),
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        color: Colors.grey[300],
                        child: Container(
                          width: dialogWidth,
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                title: Text(option),
                                onTap: () => onSelected(option),
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
              SizedBox(
                width: dialogWidth,
                child: TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    hintText: 'Comments',
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black)),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey)),
                  ),
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 16.0),
              SizedBox(
                width: dialogWidth,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickTime,
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(12.0)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_selectedTime?.format(context) ?? 'Select Time',
                                style: const TextStyle(color: Colors.white)),
                            const Icon(Icons.access_time, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                    if (_timeError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          _timeError!,
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              GestureDetector(
                onTap: _addNewSuggestionDialog,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Add New Suggestion',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: Colors.black),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final currentTitle = _autocompleteController.text;

            setState(() {
              _titleError = currentTitle.isEmpty
                  ? 'Event title is required'
                  : null;
              _timeError = _selectedTime == null
                  ? 'Please select a time'
                  : null;
            });

            if (currentTitle.isNotEmpty && _selectedTime != null) {
              final selectedDateTime = DateTime(
                widget.date.year,
                widget.date.month,
                widget.date.day,
                _selectedTime!.hour,
                _selectedTime!.minute,
              );

              final event = Event(
                title: currentTitle,
                date: selectedDateTime,
                id: widget.event?.id ?? '',
                address: _selectedAddress.isNotEmpty
                    ? _selectedAddress
                    : 'No Address Selected',
                startTime: selectedDateTime,
                description: _descriptionController.text,
                type: _selectedType,
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
          style: TextButton.styleFrom(foregroundColor: Colors.black),
          child: const Text('Save'),
        ),
      ],
    );
  }
}