import 'package:flutter/material.dart';

class CombustibleSelector extends StatelessWidget {
  final String value;
  final Function(String?) onChanged;

  const CombustibleSelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        isExpanded: true, // Hacemos que el dropdown ocupe todo el ancho
        icon: Icon(
          Icons.arrow_drop_down,
          color: const Color.fromARGB(255, 85, 85, 85),
        ),
        iconSize: 30,
        underline: SizedBox(), // Eliminamos la línea de debajo del dropdown
        style: TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        items: <String>[
          'Gasóleo A',
          'Gasóleo B',
          'Gasóleo Premium',
          'Gasolina 95 E5',
          'Gasolina 95 E10',
          'Gasolina 95 E5 Premium',
          'Gasolina 98 E5',
          'Gasolina 98 E10',
          'Biodiésel',
          'Bioetanol',
        ].map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
