import 'package:flutter/material.dart';
import '../models/event.dart';

class EventDialog extends StatefulWidget {
  final DateTime date;
  final Map<DateTime, String> selectedAddresses; // Add this parameter
  final Function() onSave;

  const EventDialog({
    Key? key,
    required this.date,
    required this.onSave,
    required this.selectedAddresses, // Initialize it
  }) : super(key: key);

  @override
  _EventDialogState createState() => _EventDialogState();
}

class _EventDialogState extends State<EventDialog> {
  final TextEditingController _titleController = TextEditingController();
  TimeOfDay? _selectedTime;

  final List<String> _eventSuggestions = [
    'Mortgage',
    'Gas Safety Checks',
    'Insurance',
    'Repairs',
    'Inspection',
    'Remortgage',
    'gas',
    'safety',
    'certificate',
    'insurance',
    'EPC',
    'EICR',
    'PAT',
    'emergency',
    'lighting',
    'fire alarm',
    'smoke detectors',
    'carbon monoxide detector',
    'oil',
    'right to rent',
    'legionella',
    'AST'
  ];

  void _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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
      title: const Text('Add Event'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                  decoration: const InputDecoration(hintText: 'Event title'),
                );
              },
              optionsViewBuilder: (BuildContext context,
                  AutocompleteOnSelected<String> onSelected,
                  Iterable<String> options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
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
          GestureDetector(
            onTap: _pickTime,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedTime == null
                        ? 'Select Time'
                        : _selectedTime!.format(context),
                  ),
                  const Icon(Icons.access_time),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
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

              // Get the selected address for this date
              final address = widget.selectedAddresses[widget.date] ?? 'No Address Selected';

              Event.addEvent(Event(
                title: _titleController.text,
                date: selectedDateTime,
                id: '',
                address: address,
              ));
              widget.onSave();
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
