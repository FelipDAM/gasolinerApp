import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_place/google_place.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SearchBar extends StatefulWidget {
  final Function(LatLng) onSelected;
  final void Function(bool hasPredictions)? onPredictionStateChanged;
  final void Function(String)? onChanged;

  const SearchBar({
    required this.onSelected,
    this.onPredictionStateChanged,
    this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  late GooglePlace googlePlace;
  List<AutocompletePrediction> predictions = [];
  TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    googlePlace = GooglePlace(dotenv.env['GOOGLE_MAPS_API_KEY']!);
  }

  void autoCompleteSearch(String value) async {
    if (value.isNotEmpty) {
      var result = await googlePlace.autocomplete.get(value);

      setState(() {
        predictions = result?.predictions ?? [];
      });

      widget.onPredictionStateChanged?.call(predictions.isNotEmpty);
    } else {
      setState(() {
        predictions = [];
      });

      widget.onPredictionStateChanged?.call(false);
    }

    // Notificar el cambio de texto al padre
    widget.onChanged?.call(value);
  }

  void _selectPrediction(AutocompletePrediction p) async {
    final details = await googlePlace.details.get(p.placeId!);
    if (details != null &&
        details.result != null &&
        details.result!.geometry != null &&
        details.result!.geometry!.location != null) {
      final loc = details.result!.geometry!.location!;
      widget.onSelected(LatLng(loc.lat!, loc.lng!));

      setState(() {
        predictions = [];
        controller.text = details.result!.name ?? '';
      });
    }
  }

  TextField buscador() {
    return TextField(
      decoration: InputDecoration(
        hintText: "Buscar localidad o dirección",
        prefixIcon:
            Icon(Icons.search, color: const Color.fromARGB(255, 84, 84, 84)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      onChanged: autoCompleteSearch,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: buscador(),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: predictions.map((p) {
              return GestureDetector(
                onTap: () => _selectPrediction(p),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    p.description ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
