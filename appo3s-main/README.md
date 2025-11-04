# appo3s

\# Aplicación appo3s



\\##Descripción general del proyecto



\\\*\\\*Aplicación appo3s\\\*\\\* es una aplicación de escritorio diseñada para recibir y mostrar los registros de diferentes sensores del ESP32, graficando en tiempo real y almacenando en una base de datos para su posterior recuperación\\\*\\\*.  



---



\\##  Objetivo y contexto



Automatización del Monitoreo de un Reactor por ozonización para el saneamiento de agua. Se trata de un proyecto resultado de la colaboración de alumnos de diversas carreras reunidos por el Verano de Investigación Lasallista 2025.

El proyecto contribuye a la obtención de agua limpia de manera eficiente y asegura que el proceso de ozonización se efectuó correctamente al medir los valores de temperatura, pH y conductividad. Los investigadores encargados del seguimiento del proceso introducían instrumentos de medición en la muestra de agua y grababan todo el proceso, posteriormente revisaban el video de acuerdo con el tiempo de muestreo que querían y lo pausaban para tomar los datos requeridos y escribirlos en una tabla de Excel, al tener todos los datos reunidos se graficaba. Esto representa un problema al volver significativamente más tardado e ineficiente a gran escala.

Para resolver esta problemática, se construyó un prototipo que implementa los sensores de temperatura, pH y conductividad para el monitoreo de los valores de la muestra que está en el proceso de ozonización. La lectura de los sensores es enviada mediante conexión Wi-fi a la aplicación de escritorio. En esta es posible personalizar el tiempo y cantidad de muestras, visualizar en tiempo real la gráfica respectiva a los valores de los sensores y almacenar cada proceso para su posterior recuperación.

A través del uso de nuestra aplicación en conjunto con los sensores se agiliza el trabajo de los investigadores y permite una posterior implementación a mayor escala.

Al mejorar los tiempos de trabajo para los investigadores se obtiene y una mayor eficiencia en el proceso de saneamiento por ozonización, permitiendo el acceso más rápido y confiable a agua limpia, contribuyendo al objetivo de desarrollo sostenible de la ONU numero 6: Agua limpia y saneamiento.

---







\\##  Requerimientos de hardware y software



\\###  Hardware



\\- Computadora  (versión recomendada: \\\*\\\*Windows 11\\\*\\\*)  

\\- ESP32 + Sensores: Ozono, pH, Temperatura, Conductividad eléctrica

\\-Conexión Wi-fi 2.4 GHz





\\###  Software



\\- \\\*\\\*Sistema operativo:\\\*\\\* Windows 10 o superior  



\\- \\\*\\\*IDE recomendado:\\\*\\\* Visual Studio Code o Android Studio  



\\- \\\*\\\*Lenguaje:\\\*\\\* Dart / Flutter  \& C para Arduino



---







\\##  Instrucciones de instalación y ejecución





1\\. \\\*\\\*Clonar el repositorio o descargar el proyecto.\\\*\\\*



\&nbsp;  ```bash



\&nbsp;  git clone https://github.com/jojisagi/appo3s-main-main.git







2\\. Abrir el proyecto en Visual Studio Code o Android Studio.





3\\. Instalar dependencias:



\&nbsp;   ```bash



\&nbsp;   flutter pub get



4\\. Modificar en el código del Arduino a una red 2.4 GHz y conectar la computadora a la misma red (NO funciona con ninguna de las redes de La Salle por temas de seguridad que tienen las redes)





La estructura principal del proyecto es:

/lib  contiene Código fuente

/doc documentacion extra del sistema

/Arduino  contiene código fuente para cargar al arduino





Créditos y autores





Desarrolladores:



Katia Marcela Carpio Domínguez



Jorge Sánchez Girón



Responsable del proyecto:



Dr. Hipólito Aguilar Sierra









