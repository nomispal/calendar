import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';
import '../services/notification_service.dart';
import 'add_suggestions_dialog.dart';
import 'address_search_field.dart';
import 'package:intl/intl.dart';


class EventDialog extends StatefulWidget {
  final DateTime date;
  final Map<DateTime, String> selectedAddresses;
  final Function() onSave;
  final Event? event;


  const EventDialog({
    super.key,
    required this.date,
    required this.onSave,
    required this.selectedAddresses,
    this.event,
  });

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
  final _containerColor = Colors.white;
  final _borderColor = Colors.grey;
  final _accentColor = Colors.grey;
  int _reminderMonths = 0;
  bool _isRecurring = false;
  int? _recurrenceInterval;
  int _reminderDays = 0;
  int _reminderMinutes = 0;
  int _recurrenceDays = 0;
  int _recurrenceMinutes = 0;

  final _eventTypes = [
    {'value': 'meeting', 'icon': Icons.people},
    {'value': 'personal', 'icon': Icons.person},
    {'value': 'work', 'icon': Icons.work},
    {'value': 'social', 'icon': Icons.call_missed_outgoing},
    {'value': 'other', 'icon': Icons.more_horiz},
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
    _setupListeners();
  }

  void _initializeData() {
    if (widget.event != null) {
      _titleController.text = widget.event!.title;
      _autocompleteController.text = widget.event!.title;
      _descriptionController.text = widget.event!.description ?? '';
      _selectedTime = TimeOfDay.fromDateTime(widget.event!.startTime);
      _selectedAddress = widget.selectedAddresses[widget.date] ?? '';
      _selectedType = widget.event!.type;
    }
    _loadSuggestions();
  }

  void _setupListeners() {
    _titleController.addListener(() {
      if (_titleController.text.isNotEmpty && _titleError != null) {
        setState(() => _titleError = null);
      }
    });
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
        _eventSuggestions = querySnapshot.docs.map((doc) => doc['title'] as String).toList();
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
      builder: (context) => const AddSuggestionDialog(),
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

  Widget _buildAddressSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedAddress.isEmpty ? 'No Property Selected' : _selectedAddress,
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.grey[800],
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _selectAddress,
            icon: Icon(
              _selectedAddress.isEmpty ? Icons.add_location : Icons.edit_location,
              color: Colors.blue[700],
            ),
            label: Text(
              _selectedAddress.isEmpty ? 'Add Property' : 'Change Property',
              style: TextStyle(color: Colors.blue[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _eventTypes.map((type) {
          final isSelected = type['value'] == _selectedType;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    type['icon'] as IconData,
                    size: 18,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    type['value'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.grey[100],
              selectedColor: Colors.blue[500],
              onSelected: (bool selected) {
                setState(() => _selectedType = type['value'] as String);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReminderSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Reminder Settings'),
        DropdownButton<int>(
          value: _reminderMonths,
          items: const [
            DropdownMenuItem(value: 0, child: Text('No reminder')),
            DropdownMenuItem(value: 1, child: Text('1 month before')),
            DropdownMenuItem(value: 4, child: Text('4 months before')),
            DropdownMenuItem(value: -1, child: Text('Custom')),
          ],
          onChanged: (value) => setState(() => _reminderMonths = value!),
        ),
        if (_reminderMonths == -1)
          Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Days before',
                  hintText: 'Enter days',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _reminderDays = int.tryParse(value) ?? 0;
                  });
                },
              ),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Minutes before',
                  hintText: 'Enter minutes',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _reminderMinutes = int.tryParse(value) ?? 0;
                  });
                },
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildRecurrenceSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          title: const Text('Recurring Task'),
          value: _isRecurring,
          onChanged: (value) => setState(() => _isRecurring = value!),
        ),
        if (_isRecurring)
          Column(
            children: [
              DropdownButton<int>(
                value: _recurrenceInterval ?? 12,
                items: const [
                  DropdownMenuItem(value: 3, child: Text('Every 3 months')),
                  DropdownMenuItem(value: 6, child: Text('Every 6 months')),
                  DropdownMenuItem(value: 12, child: Text('Annual')),
                  DropdownMenuItem(value: -1, child: Text('Custom')),
                ],
                onChanged: (value) => setState(() => _recurrenceInterval = value!),
              ),
              if (_recurrenceInterval == -1)
                Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Days',
                        hintText: 'Enter days',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _recurrenceDays = int.tryParse(value) ?? 0;
                        });
                      },
                    ),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Minutes',
                        hintText: 'Enter minutes',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _recurrenceMinutes = int.tryParse(value) ?? 0;
                        });
                      },
                    ),
                  ],
                ),
            ],
          ),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    final dialogWidth = MediaQuery.of(context).size.width * 0.4;

    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(
        widget.event == null ? 'Add New Event' : 'Edit Event',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: dialogWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAddressSection(),
              const SizedBox(height: 16),
              const Text(
                'Event Type',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _buildTypeSelector(),
              const SizedBox(height: 16),
            Autocomplete<String>(
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
                    labelText: 'Event Title',
                    labelStyle: TextStyle(
                      color: Colors.black
                    ),
                    errorText: _titleError,
                    prefixIcon: const Icon(Icons.event),
                    border: OutlineInputBorder(  // Outlined border
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(  // Border when focused
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                );

              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: dialogWidth,
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: Colors.grey[100], // Background color when suggestions appear
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          return ListTile(
                            title: Text(option),
                            onTap: () => onSelected(option),
                            hoverColor: Colors.grey[300], // Background color on hover
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Comments',
                  labelStyle: TextStyle(
                    color: Colors.black,
                  ),
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(  // Outlined border
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.black, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(  // Border when focused
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.black, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 16),

              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _pickTime,
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: _containerColor,
                      border: Border.all(color: _timeError != null ? Colors.red : _borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_selectedTime?.format(context) ?? 'Select Time'),
                        Icon(Icons.access_time, color: _accentColor),
                      ],
                    ),
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
              if (_timeError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _timeError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _addNewSuggestionDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add New Suggestion'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue[700],
                ),
              ),
              _buildReminderSettings(),
              _buildRecurrenceSettings(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final currentTitle = _autocompleteController.text;

            setState(() {
              _titleError = currentTitle.isEmpty ? 'Event title is required' : null;
              _timeError = _selectedTime == null ? 'Please select a time' : null;
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
                address: _selectedAddress.isNotEmpty ? _selectedAddress : 'No Address Selected',
                startTime: selectedDateTime,
                description: _descriptionController.text,
                type: _selectedType,
                reminderPeriodMonths: _reminderMonths,
                reminderDays: _reminderDays,
                reminderMinutes: _reminderMinutes,
                isRecurring: _isRecurring,
                recurrenceInterval: _isRecurring ? _recurrenceInterval : null,
                recurrenceDays: _recurrenceDays,
                recurrenceMinutes: _recurrenceMinutes,
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
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[500],
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  // Add this helper method
  DateTime _calculateNextDueDate(DateTime currentDate) {
    return DateTime(
      currentDate.year + (_recurrenceInterval! ~/ 12),
      currentDate.month + (_recurrenceInterval! % 12),
      currentDate.day,
      currentDate.hour,
      currentDate.minute,
    );
  }

  void _selectAddress() async {
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
  }

}