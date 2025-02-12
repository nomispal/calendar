import 'package:flutter/material.dart';

class EventFilterButton extends StatelessWidget {
  final VoidCallback onTap;

  const EventFilterButton({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 40
            ),
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(10),
                boxShadow: [
            BoxShadow(
            color: Colors.grey.withOpacity(0.8),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.filter_list, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  "Filter Tasks",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
