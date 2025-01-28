import 'package:flutter/material.dart';

class AddSuggestionDialog extends StatefulWidget {
  const AddSuggestionDialog({Key? key}) : super(key: key);

  @override
  _AddSuggestionDialogState createState() => _AddSuggestionDialogState();
}

class _AddSuggestionDialogState extends State<AddSuggestionDialog> {
  final TextEditingController _suggestionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Suggestion'),
      content: TextField(
        controller: _suggestionController,
        decoration: const InputDecoration(hintText: 'Enter a new suggestion'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final newSuggestion = _suggestionController.text.trim();
            if (newSuggestion.isNotEmpty) {
              Navigator.pop(context, newSuggestion); // Return the new suggestion
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}