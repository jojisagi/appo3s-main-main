#include <WiFi.h>
#include <WebServer.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <WiFiUdp.h>  // Añadido para UDP

#define ONE_WIRE_BUS 18

//Wifi variables
const char* ssid = "Gal";
const char* password = "Katham2874";

const char* ssid2="INFINITUM63A0_2.4";
const char* password2 = "C0c4YF10abc123";

WebServer server(80);
WiFiUDP udp;                // Objeto UDP
const unsigned int UDP_PORT = 4210; // Puerto UDP para discovery

//sensors inicialiting
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);
//ph vaRIABLES
const int PH_PIN = 34;
const float V_REF = 3.3;
const int ADC_MAX = 4095;

const float V_CAL = 1.3;
const float SLOPE_MV_PER_PH = 63.33;
//conductivity values


//temperature values
#define TdsSensorPin 32     // GPIO32 del ESP32

#define VREF 3.3              // Voltaje de referencia del ADC
#define SCOUNT 50             // Muestras para TDS
#define NUM_PH_SAMPLES 10     // Muestras para promedio de pH
#define ADC_MAX 4095          // Resolución de 12 bits

// Variables para TDS
int analogBuffer[SCOUNT];
int analogBufferTemp[SCOUNT];
int analogBufferIndex = 0, copyIndex = 0;
float averageVoltage = 0, tdsValue = 0, temperature = 25.0;

//current values
float currentTemperature = 0.0;
float currentPh=0.0;
float currentConductivity=0.0;
float currentOzone=0.0;

// Para mostrar IP periódicamente
unsigned long lastIpPrint = 0;
const unsigned long ipPrintInterval = 10000; // cada 10 segundos

void handleStatus() {
  server.send(200, "text/plain", "OK");
}

void handleData() {
  String data = "{";
  data += "\"temperature\":" + String(currentTemperature, 2) + ",";
  data += "\"ph\":" + String(currentPh, 2) + ",";
  data += "\"conductivity\":" + String(currentConductivity, 2) + ",";
  data += "\"ozone\":" + String(currentOzone, 2);
  data += "}";
  server.send(200, "application/json", data);
}


void setup() {
  pinMode(TdsSensorPin, INPUT);
  Serial.begin(115200);
  analogReadResolution(12);
  sensors.begin();

  WiFi.begin(ssid, password);
  WiFi.setSleep(false);
  WiFi.setTxPower(WIFI_POWER_19_5dBm); 
  Serial.print("Conectando a Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(100);
    Serial.print(".");
  }
  Serial.println();
  Serial.print("Conectado, IP: ");
  Serial.println(WiFi.localIP());

  udp.begin(UDP_PORT); // Iniciar UDP en el puerto definido

  server.on("/status", handleStatus);
  server.on("/data", handleData);

  server.begin();

    //obteniendo valores
  getPh();
  getConductivity();
  getTemperature();
  getOzone();  

}

void loop() {
  server.handleClient();
  // Manejar UDP discovery
  check_command();
  //obteniendo valores
  getPh();
  getConductivity();
  getTemperature();
  getOzone();  

  printAll();
  // Mostrar IP periódicamente
  if (WiFi.status() == WL_CONNECTED) {
   // if (millis() - lastIpPrint > ipPrintInterval) {
     // lastIpPrint = millis();
      //Serial.print("IP actual: ");
    //}
  } else {
    WiFi.reconnect();
     Serial.println(WiFi.localIP());
  }

  // Comandos por serial
  if (Serial.available() > 0) {
    String command = Serial.readStringUntil('\n');
    command.trim();

    if (command == "GET_DATA") {
        String respuesta = String(currentTemperature) + "," +
                   String(currentPh) + "," +
                   String(currentConductivity) + "," +
                   String(currentOzone) + ",";
        Serial.println(respuesta);
      }
     else if (command == "STATUS") {
      Serial.println("OK");
    }
  
  }

  delay(100);
}



void check_command(){
int packetSize = udp.parsePacket();
  if (packetSize) {
    char incomingPacket[255];
    int len = udp.read(incomingPacket, 255);
    if (len > 0) {
      incomingPacket[len] = 0; // Null-terminate string
    }
    Serial.printf("Paquete UDP recibido: %s\n", incomingPacket);

      if (strcmp(incomingPacket, "ESP32_DISCOVER") == 0) {
        String respuesta = "ESP32_RESPONSE:";
        respuesta += WiFi.localIP().toString();
        delay(10);  // Mejora estabilidad
       udp.begin(WiFi.localIP(), UDP_PORT);

        udp.write((const uint8_t *)respuesta.c_str(), respuesta.length()); // <-- aquí la corrección
        udp.endPacket();
        Serial.printf("Respondido a %s con %s\n", udp.remoteIP().toString().c_str(), respuesta.c_str());
      }
      if (strcmp(incomingPacket, "ESP32_DATA") == 0) {
                  String respuesta = String(currentTemperature) + "," +
                   String(currentPh) + "," +
                   String(currentConductivity) + "," +
                   String(currentOzone) + ",";

        delay(10);  // Mejora estabilidad
        udp.begin(WiFi.localIP(), UDP_PORT);
        udp.write((const uint8_t *)respuesta.c_str(), respuesta.length()); // <-- aquí la corrección
        udp.endPacket();
        Serial.printf("Respondido a %s con %s\n", udp.remoteIP().toString().c_str(), respuesta.c_str());
      }

      if (strcmp(incomingPacket, "T") == 0) {
        String respuesta = "T:";
        respuesta +=currentTemperature;

        udp.beginPacket(udp.remoteIP(), udp.remotePort());
        udp.write((const uint8_t *)respuesta.c_str(), respuesta.length()); // <-- aquí la corrección
        udp.endPacket();
        Serial.printf("Respondido a %s con %s\n", udp.remoteIP().toString().c_str(), respuesta.c_str());
      }

      if (strcmp(incomingPacket, "Ph") == 0) {
        String respuesta = "Ph:";
        respuesta += currentPh;

        udp.beginPacket(udp.remoteIP(), udp.remotePort());
        udp.write((const uint8_t *)respuesta.c_str(), respuesta.length()); // <-- aquí la corrección
        udp.endPacket();
        Serial.printf("Respondido a %s con %s\n", udp.remoteIP().toString().c_str(), respuesta.c_str());
      }

      if (strcmp(incomingPacket, "C") == 0) {
        String respuesta = "C:";
        respuesta += currentConductivity;

        udp.beginPacket(udp.remoteIP(), udp.remotePort());
        udp.write((const uint8_t *)respuesta.c_str(), respuesta.length()); // <-- aquí la corrección
        udp.endPacket();
        Serial.printf("Respondido a %s con %s\n", udp.remoteIP().toString().c_str(), respuesta.c_str());
      }

      
      if (strcmp(incomingPacket, "O") == 0) {
        String respuesta = "O:";
        respuesta += currentOzone;

        udp.beginPacket(udp.remoteIP(), udp.remotePort());
        udp.write((const uint8_t *)respuesta.c_str(), respuesta.length()); // <-- aquí la corrección
        udp.endPacket();
        Serial.printf("Respondido a %s con %s\n", udp.remoteIP().toString().c_str(), respuesta.c_str());
      }

  }


}


float getPh (){

  int raw = analogRead(PH_PIN);
  float voltage = raw * V_REF / ADC_MAX;
  float pH = 7.0 + ((V_CAL - voltage) * 1000.0) / SLOPE_MV_PER_PH;

 currentPh=pH;

return pH;
}

float getConductivity(){
  static unsigned long analogSampleTimepoint = millis();
  static unsigned long printTimepoint = millis();
  
  // Lectura cada 40 ms
  if (millis() - analogSampleTimepoint > 40U) {
    analogSampleTimepoint = millis();
    analogBuffer[analogBufferIndex] = analogRead(TdsSensorPin);
    analogBufferIndex = (analogBufferIndex + 1) % SCOUNT;
  }

  // Cálculo cada 800 ms
  if (millis() - printTimepoint > 800U) {
    printTimepoint = millis();

    // Copia el buffer para cálculo
    memcpy(analogBufferTemp, analogBuffer, sizeof(analogBuffer));
    
    averageVoltage = getMedianNum(analogBufferTemp, SCOUNT) * VREF / ADC_MAX;

    // Usa la temperatura actual (no la variable global temperature)
    float currentTemp = getTemperature();
    float compensationCoefficient = 1.0 + 0.02 * (currentTemp - 25.0);
    float compensationVoltage = averageVoltage / compensationCoefficient;

        tdsValue = (133.42 * pow(compensationVoltage, 3)
                - 255.86 * pow(compensationVoltage, 2)
                + 857.39 * compensationVoltage) * 0.5;

  }

  currentConductivity = tdsValue;
  return tdsValue;
}

void printAll(){
  String data = "T:" + String(currentTemperature, 2) + ",";
        data += "\"ph\":" + String(currentPh, 2) + ",";
        data += "\"conductivity\":" + String(currentConductivity, 2) + ",";
        data += "\"ozone\":" + String(currentOzone, 2);
        data += "}\n";
  Serial.print (data);
}


int getMedianNum(int bArray[], int iFilterLen) {
  int bTab[iFilterLen];
  for (byte i = 0; i < iFilterLen; i++)
    bTab[i] = bArray[i];


  int i, j, bTemp;
  for (j = 0; j < iFilterLen - 1; j++) {
    for (i = 0; i < iFilterLen - j - 1; i++) {
      if (bTab[i] > bTab[i + 1]) {
        bTemp = bTab[i];
        bTab[i] = bTab[i + 1];
        bTab[i + 1] = bTemp;
      }
    }
  }


  if ((iFilterLen & 1) > 0)
    bTemp = bTab[(iFilterLen - 1) / 2];
  else
    bTemp = (bTab[iFilterLen / 2] + bTab[iFilterLen / 2 - 1]) / 2;


return bTemp;
}

float getOzone(){
  float ozone=0;

  currentOzone=ozone;
  return ozone;
}


float getTemperature(){

  sensors.requestTemperatures();
  float tempC = sensors.getTempCByIndex(0);
 //float tempC = sensors.getTempCByIndex(0);
 currentTemperature = tempC;

  
  if (tempC != DEVICE_DISCONNECTED_C) {
    currentTemperature = tempC;
    //Serial.print("Temperatura: ");
    //Serial.print(currentTemperature);
  } else {
    //Serial.println("Error: sensor no detectado.");
  }
a
  return tempC;
}