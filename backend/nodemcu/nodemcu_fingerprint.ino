#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <WiFiClient.h>
#include <ArduinoJson.h>
#include <Adafruit_Fingerprint.h>

// ================== CONFIGURATION ==================
const char* WIFI_SSID     = "YOUR_WIFI_NAME";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";

// Your Render deployment URL (no trailing slash)
const char* API_BASE = "https://campuslink-api.onrender.com";

// Must match DEVICE_API_KEY in the backend env vars
const char* DEVICE_API_KEY = "paste-device-api-key-here";

const unsigned long HEARTBEAT_INTERVAL_MS = 30000;   // heartbeat every 30 s
const unsigned long COMMAND_POLL_MS      = 3000;     // poll commands every 3 s
// ===================================================

HardwareSerial &fpSerial = Serial;
Adafruit_Fingerprint finger = Adafruit_Fingerprint(&fpSerial);

HTTPClient http;
WiFiClient wifiClient;

unsigned long lastHeartbeat = 0;
unsigned long lastCommandPoll = 0;
String currentCommandId = "";
String currentStudentId = "";
bool enrolling = false;

void setup() {
  Serial.begin(57600);
  delay(100);

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println();
  Serial.print("Connected. IP: ");
  Serial.println(WiFi.localIP());

  if (finger.verifyPassword()) {
    Serial.println("Fingerprint sensor found.");
  } else {
    Serial.println("Fingerprint sensor NOT found!");
  }
}

void loop() {
  unsigned long now = millis();

  if (WiFi.status() != WL_CONNECTED) {
    WiFi.reconnect();
    delay(1000);
    return;
  }

  if (now - lastHeartbeat >= HEARTBEAT_INTERVAL_MS) {
    lastHeartbeat = now;
    sendHeartbeat();
  }

  if (!enrolling && now - lastCommandPoll >= COMMAND_POLL_MS) {
    lastCommandPoll = now;
    pollCommands();
  }

  if (enrolling) {
    runEnrollment();
  }
}

// ----------------- HTTP helpers -----------------

void sendHeartbeat() {
  String payload = "{\"device_id\":\"default\",\"device_name\":\"fingerprint-scanner\",\"ip\":\"" +
                   WiFi.localIP().toString() + "\"}";
  if (http.begin(wifiClient, String(API_BASE) + "/api/device/heartbeat")) {
    http.addHeader("Content-Type", "application/json");
    http.addHeader("x-device-key", DEVICE_API_KEY);
    http.POST(payload);
    http.end();
  }
}

void pollCommands() {
  if (!http.begin(wifiClient, String(API_BASE) + "/api/device/commands/next?device_id=default")) return;
  http.addHeader("x-device-key", DEVICE_API_KEY);
  int code = http.GET();
  if (code == 200) {
    String body = http.getString();
    http.end();

    StaticJsonDocument<512> doc;
    if (deserializeJson(doc, body) == DeserializationError::Ok && doc["has_command"].as<bool>()) {
      currentCommandId = String((const char*)doc["id"]);
      currentStudentId = String((const char*)doc["student_id"]);
      if (doc["command"] == String("enroll")) {
        enrolling = true;
        reportProgress("place_finger", "Waiting for first scan");
      }
    }
  } else {
    http.end();
  }
}

void reportProgress(const char* status, const char* message) {
  StaticJsonDocument<256> doc;
  doc["status"] = status;
  doc["message"] = message;
  String payload;
  serializeJson(doc, payload);

  if (http.begin(wifiClient, String(API_BASE) + "/api/device/commands/" + currentCommandId + "/result")) {
    http.addHeader("Content-Type", "application/json");
    http.addHeader("x-device-key", DEVICE_API_KEY);
    http.POST(payload);
    http.end();
  }
}

// ----------------- Enrollment -----------------

// Two-scan enrollment, mirroring Adafruit's example flow.
void runEnrollment() {
  int id = currentStudentId.toInt();
  if (id <= 0) id = 1;

  reportProgress("place_finger", "Place finger on the scanner");
  Serial.println("Waiting for valid finger #1...");
  while (finger.getImage() != FINGERPRINT_OK) { delay(50); }
  if (finger.image2Tz(1) != FINGERPRINT_OK) {
    fail("Could not read fingerprint"); return;
  }

  reportProgress("remove_finger", "Remove your finger");
  Serial.println("Remove finger");
  delay(1200);
  while (finger.getImage() != FINGERPRINT_NOFINGER) { delay(50); }

  reportProgress("place_finger_again", "Place the same finger again");
  Serial.println("Waiting for valid finger #2...");
  while (finger.getImage() != FINGERPRINT_OK) { delay(50); }
  if (finger.image2Tz(2) != FINGERPRINT_OK) {
    fail("Could not read fingerprint"); return;
  }

  if (finger.createModel() != FINGERPRINT_OK) {
    fail("Fingerprints did not match"); return;
  }
  if (finger.storeModel(id) != FINGERPRINT_OK) {
    fail("Could not store fingerprint"); return;
  }

  reportProgress("success", "Enrollment successful");
  Serial.println("Enrolled!");
  enrolling = false;
}

void fail(const char* message) {
  reportProgress("failed", message);
  Serial.println(message);
  enrolling = false;
}
