import 'package:flutter/material.dart';

class FiltroSelector extends StatefulWidget {
  final Function(bool isPrecioSelected) onFiltroChanged;

  const FiltroSelector({required this.onFiltroChanged, Key? key})
      : super(key: key);

  @override
  _FiltroSelectorState createState() => _FiltroSelectorState();
}

class _FiltroSelectorState extends State<FiltroSelector> {
  bool isASelected = true;

  @override
  Widget build(BuildContext context) {
    return ToggleButtons(
      isSelected: [isASelected, !isASelected],
      onPressed: (int index) {
        setState(() {
          isASelected = index == 0;
        });
        widget.onFiltroChanged(isASelected);
      },
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 23.0),
          child: Text(
            '€/L',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 23.0),
          child: Text(
            'KM',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
      borderRadius: BorderRadius.circular(8),
      selectedColor: Colors.white,
      fillColor: Color.fromARGB(255, 116, 165, 249),
      color: const Color.fromARGB(255, 116, 165, 249),
      renderBorder: true,
      borderColor: Colors.grey.shade300,
      borderWidth: 1.0,
    );
  }
}
