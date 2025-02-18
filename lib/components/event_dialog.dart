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
  int _reminderMonths = 0;
  bool _isRecurring = false;
  int? _recurrenceInterval;
  int _reminderDays = 0;
  int _reminderMinutes = 0;
  int _recurrenceDays = 0;
  int _recurrenceMinutes = 0;

  final _eventTypes = [
    {'value': 'meeting', 'icon': Icons.people, 'label': 'Meeting'},
    {'value': 'personal', 'icon': Icons.person, 'label': 'Personal'},
    {'value': 'work', 'icon': Icons.work, 'label': 'Work'},
    {'value': 'social', 'icon': Icons.people_outline, 'label': 'Social'},
    {'value': 'other', 'icon': Icons.more_horiz, 'label': 'Other'},
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_outlined, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedAddress.isEmpty ? 'No Property Selected' : _selectedAddress,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _selectAddress,
            icon: Icon(
              _selectedAddress.isEmpty ? Icons.add : Icons.edit,
              size: 18,
              color: Colors.blue[700],
            ),
            label: Text(
              _selectedAddress.isEmpty ? 'Add Property' : 'Change Property',
              style: TextStyle(color: Colors.blue[700]),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: Colors.blue[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _eventTypes.map((type) {
        final isSelected = type['value'] == _selectedType;
        return FilterChip(
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
                type['label'] as String,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.grey[50],
          selectedColor: Colors.blue[600],
          onSelected: (bool selected) {
            setState(() => _selectedType = type['value'] as String);
          },
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? Colors.transparent : Colors.grey[300]!,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReminderSettings() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Reminder Settings'),
          DropdownButtonFormField<int>(
            value: _reminderMonths,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[400]!),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: const [
              DropdownMenuItem(value: 0, child: Text('No reminder')),
              DropdownMenuItem(value: 1, child: Text('1 month before')),
              DropdownMenuItem(value: 4, child: Text('4 months before')),
              DropdownMenuItem(value: -1, child: Text('Custom')),
            ],
            onChanged: (value) => setState(() => _reminderMonths = value!),
          ),
          if (_reminderMonths == -1) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Days before',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _reminderDays = int.tryParse(value) ?? 0;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Minutes before',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _reminderMinutes = int.tryParse(value) ?? 0;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecurrenceSettings() {
    return Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            _buildSectionTitle('Recurrence Settings'),
        SwitchListTile(
          title: const Text('Recurring Task'),
          value: _isRecurring,
          onChanged: (value) => setState(() => _isRecurring = value),
          contentPadding: EdgeInsets.zero,
        ),
        if (_isRecurring) ...[
    const SizedBox(height: 12),
    DropdownButtonFormField<int>(
    value: _recurrenceInterval ?? 0,
    decoration: InputDecoration(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: Colors.grey[400]!),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    items: const [
    DropdownMenuItem(value: 0, child: Text('Custom')),
    DropdownMenuItem(value: 1, child: Text('Daily')),
    DropdownMenuItem(value: 7, child: Text('Weekly')),
    DropdownMenuItem(value: 30, child: Text('Monthly (30 days)')),
    ],
    onChanged: (value) => setState(() {
    _recurrenceInterval = value!;
    // Reset custom values when selecting preset
    if (value != 0) {
    _recurrenceDays = value;
    _recurrenceMinutes = 0;
    }
    }),
    ),
    if (_recurrenceInterval == 0) ...[
    const SizedBox(height: 16),
    Row(
    children: [
    Expanded(
    child: TextFormField(
    initialValue: _recurrenceDays.toString(),
    decoration: InputDecoration(
    labelText: 'Days Between Recurrence',
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    ),
    ),
    keyboardType: TextInputType.number,
    validator: (value) {
    if (value == null || int.tryParse(value) == null || int.parse(value) < 0) {
    return 'Enter positive number';
    }
    return null;
    },
    onChanged: (value) {
    setState(() {
    _recurrenceDays = int.tryParse(value) ?? 0;
    });
    },
    ),
    ),
    const SizedBox(width: 16),
    Expanded(
    child: TextFormField(
    initialValue: _recurrenceMinutes.toString(),
    decoration: InputDecoration(
    labelText: 'Minutes Offset',
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    ),
    ),
    keyboardType: TextInputType.number,
    validator: (value) {
    if (value == null || int.tryParse(value) == null) {
    return 'Enter valid number';
    }
    return null;
    },
    onChanged: (value) {
    setState(() {
    _recurrenceMinutes = int.tryParse(value) ?? 0;
    });
    },
    ),
    ),
    ],
    ),
    ],
    ],
  ]),
    );
  }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          widget.event == null ? 'Add New Event' : 'Edit Event',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Container(
        width: MediaQuery.of(context).size.width * 0.4,
    child: SingleChildScrollView(
    child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    _buildAddressSection(),
    const SizedBox(height: 24),
    _buildSectionTitle('Event Type'),
    _buildTypeSelector(),
    const SizedBox(height: 24),
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
    errorText: _titleError,
    prefixIcon: const Icon(Icons.event),
    border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
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
    elevation: 4,
    borderRadius: BorderRadius.circular(8),
    child: ConstrainedBox(
    constraints: BoxConstraints(
    maxWidth: MediaQuery.of(context).size.width * 0.4,
    maxHeight: 200,
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
          );
        },
      ),
    ),
    ),
    );
    },
    ),
      const SizedBox(height: 24),
      TextField(
        controller: _descriptionController,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: 'Comments',
          prefixIcon: const Icon(Icons.description),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
      const SizedBox(height: 24),
      InkWell(
        onTap: _pickTime,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _timeError != null ? Colors.red : Colors.grey[300]!,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedTime?.format(context) ?? 'Select Time',
                style: TextStyle(
                  color: _selectedTime == null ? Colors.grey[600] : Colors.black87,
                ),
              ),
              Icon(Icons.access_time, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
      if (_timeError != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            _timeError!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ),
      const SizedBox(height: 24),
      ElevatedButton.icon(
        onPressed: _addNewSuggestionDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add New Suggestion'),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.blue[600],
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      const SizedBox(height: 24),
      _buildReminderSettings(),
      const SizedBox(height: 24),
      _buildRecurrenceSettings(),
    ],
    ),
    ),
        ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
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

                  if (_isRecurring) {
                    if (_recurrenceInterval == 0 && _recurrenceDays <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Custom recurrence requires at least 1 day'))
                      );
                      return;
                    }
                    if (_recurrenceInterval != 0 && _recurrenceInterval! < 1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invalid recurrence interval'))
                      );
                      return;
                    }
                  }

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
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue[600],
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    );
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

  void _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteColor: Colors.grey[100],
              hourMinuteTextColor: Colors.black87,
              dayPeriodColor: Colors.grey[100],
              dayPeriodTextColor: Colors.black87,
              dialHandColor: Colors.blue[600],
              dialBackgroundColor: Colors.grey[50],
              dialTextColor: Colors.black87,
              entryModeIconColor: Colors.grey[600],
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