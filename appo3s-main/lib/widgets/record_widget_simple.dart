//record_widget_simple.dart
import 'package:flutter/material.dart';
import 'package:appo3s/models/muestreo.dart';

class record_widget_simple extends StatefulWidget {

  final Text contaminante;
  final Text concentracion;
  final Text fechaHora;

   record_widget_simple({
    super.key,
    required this.fechaHora,
    required this.contaminante,
    required this.concentracion,
  });

  @override
  State<record_widget_simple> createState() => _record_widget_simpleState();
}

class _record_widget_simpleState extends State<record_widget_simple>  {


@override
Widget build(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(8),  // Reducido de 10
    decoration: BoxDecoration(
      color: Colors.grey[200],
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribuye el espacio
     mainAxisSize: MainAxisSize.max, // Ocupa todo el ancho disponible
      children: [
  // Contaminante
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black, // Default text color
                ),
                children: [
                  const TextSpan(text: 'Contaminante: '),
                  TextSpan(
                    text: widget.contaminante.data, // Access the text content
                    style: widget.contaminante.style ?? const TextStyle(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            
            // Concentración
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black,
                ),
                children: [
                  const TextSpan(text: 'Concentración: '),
                  TextSpan(
                    text: widget.concentracion.data,
                    style: widget.concentracion.style ?? const TextStyle(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            
            // Fecha y Hora
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black,
                ),
                children: [
                  const TextSpan(text: 'Fecha/Hora: '),
                  TextSpan(
                    text: widget.fechaHora.data,
                    style: widget.fechaHora.style ?? const TextStyle(),
                  ),
                ],
              ),
            ),

               const SizedBox(height: 6),
          ],
    ),
  );

   
 }
}