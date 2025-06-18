import 'package:appo3s/widgets/timer_widget.dart';
import 'package:flutter/material.dart';
import '../widgets/creando_ozone_chart.dart';
import '../widgets/creando_conductivity_chart.dart';
import '../widgets/creando_ph_chart.dart';
import '../widgets/record_form.dart';
import '../widgets/editing_samples.dart';
import '../models/muestreo.dart';

class CreandoRegistros extends StatefulWidget {
  const CreandoRegistros({super.key});

  @override
  State<CreandoRegistros> createState() => _CreandoRegistrosState();
}

class _CreandoRegistrosState extends State<CreandoRegistros> {
   Muestreo muestreo_ozone = Muestreo();
   
   Muestreo muestreo_ph = Muestreo();
   Muestreo muestreo_conductivity = Muestreo();
   Muestreo muestreo_time = Muestreo();




  @override
  Widget build(BuildContext context) {
      //esta linea es para llenar las muestras con datos de ejemplo***************************************************
      muestreo_ozone.llenarMuestras();  muestreo_ph.llenarMuestras(); muestreo_conductivity.llenarMuestras();  muestreo_time.llenarMuestras();
    //**************************************** 
    return Scaffold(
      appBar: AppBar(title: const Text('Gráficas')),
      body: _GraphsBody(muestreo_ozone: muestreo_ozone, muestreo_ph: muestreo_ph, 
                        muestreo_conductivity: muestreo_conductivity, muestreo_time: muestreo_time ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'EditingSamples',
            child: const Icon(Icons.timer),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => Padding(
                padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20, top: 10),
                child: EditingSamples(muestreo: muestreo_time),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'RecordForm',
            child: const Icon(Icons.check),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => Padding(
                padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20, top: 10),
                child: RecordForm(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GraphsBody extends StatelessWidget {
     Muestreo muestreo_ozone = Muestreo();
     Muestreo muestreo_ph = Muestreo();
     Muestreo muestreo_conductivity = Muestreo();
     Muestreo muestreo_time = Muestreo();

   _GraphsBody({
    required this.muestreo_ozone,
    required this.muestreo_ph,
    required this.muestreo_conductivity,  
    required this.muestreo_time,
    });

    
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timer en la parte superior
          TimerWidget(muestreo: muestreo_ozone),
          const SizedBox(height: 20),
          
          // Gráficas en dos columnas debajo
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                     Creando_OzoneChart(muestreo:muestreo_ozone),
                     SizedBox(height: 12),
                    //const AUCWidget(),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                     Creando_ConductivityChart( muestreo: muestreo_conductivity),
                    const SizedBox(height: 12),
                     Creando_PhChart(muestreo:muestreo_ph),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}