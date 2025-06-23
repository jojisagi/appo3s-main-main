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

  void _iniciarTime(Muestreo otro) {
    setState(() {
      muestreo_time = otro.deepCopy();
      muestreo_ozone.inicializar_con_otro_muestreo(otro);
      muestreo_ph.inicializar_con_otro_muestreo(otro);
      muestreo_conductivity.inicializar_con_otro_muestreo(otro);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gráficas')),
      body: _GraphsBody(
        key: ValueKey(muestreo_time.hashCode),
        muestreo_ozone: muestreo_ozone,
        muestreo_ph: muestreo_ph,
        muestreo_conductivity: muestreo_conductivity,
        muestreo_time: muestreo_time,
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'EditingSamples',
            child: const Icon(Icons.timer),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20, top: 10),
                  child: EditingSamples(
                    muestreo: muestreo_time.deepCopy(),
                    onSamplesUpdated: _iniciarTime,
                  ),
                ),
              );
            },
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
                child: RecordForm(
                  muestreo_ozone: muestreo_ozone,
                  muestreo_ph: muestreo_ph,
                  muestreo_conductivity: muestreo_conductivity, 
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GraphsBody extends StatelessWidget {
  final Muestreo muestreo_ozone;
  final Muestreo muestreo_ph;
  final Muestreo muestreo_conductivity;
  final Muestreo muestreo_time;

  const _GraphsBody({
    super.key,
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
          TimerWidget(muestreo: muestreo_time),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Gráfica de Ozono ---
              Creando_OzoneChart(
                key: ValueKey(muestreo_ozone.hashCode),
                muestreo: muestreo_ozone,
              ),
              const SizedBox(height: 20),

              // --- Gráfica de Conductividad ---
              Row(
              children: [
                // --- Gráfica de Conductividad ---
                Expanded(
                  child: Creando_ConductivityChart(
                    key: ValueKey(muestreo_conductivity.hashCode),
                    muestreo: muestreo_conductivity,
                  ),
                ),
                const SizedBox(width: 20), // Espacio horizontal entre gráficas
                
                // --- Gráfica de pH ---
                Expanded(
                  child: Creando_PhChart(
                    key: ValueKey(muestreo_ph.hashCode),
                    muestreo: muestreo_ph,
                  ),
                ),
              ],
            ),
              const SizedBox(height: 20),
            ],
          ),

        ],
      ),
    );
  }
}

//al hacer set no deje iniciar y que el set se pase automaticamente al muestreo de todas las tablas y que ya
// cuando lo inicie puedo añadir tiempo y a menos que no seacabe el tiempo no puedo ingresar registros
// ejemplo: timer 1:30 no puedo agregar nada antes del 1.30 sino más
//funcion vacía: si el timer llega a una cuenta que es igual al tiempo de muestreo que jale un valor random como prueba para despues pasarlo en tiempo real
//ya que quede hacer la prueba real

//para el historial de registro que se vea poco a poco como se va construyendo cómo ya jaló de la bd, toma en cuenta iniciar el timer y que cuando corresponda del tiempo de muestreo ponga
// el dato y que ya guardó en el mongo