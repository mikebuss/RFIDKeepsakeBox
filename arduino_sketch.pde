//  Keepsake Box
//  http://mikebuss.com/2014/02/23/rfid-keepsake-box/  
//
//  Written by Mike Buss
//  http://mikebuss.com
//
// References:
// - RFID code written by BARRAGAN, modified for Arduino by djmatic
//   http://playground.arduino.cc/Learning/PRFID#.UwpqeUJdXj0
// 
// - Piezo speaker "PlayMelody" example
//   http://www.arduino.cc/en/Tutorial/PlayMelody#.Uwpr30JdXj0
//

#include <Servo.h> 
#include <EEPROM.h>

int redPin = 8;
int greenPin = 4;
int bluePin = 3;

// AUDIO
// TONES  ==========================================
// Start by defining the relationship between 
//       note, period, &  frequency. 
#define  c     3830    // 261 Hz 
#define  d     3400    // 294 Hz 
#define  e     3038    // 329 Hz 
#define  f     2864    // 349 Hz 
#define  g     2550    // 392 Hz 
#define  a     2272    // 440 Hz 
#define  b     2028    // 493 Hz 
#define  C     1912    // 523 Hz 
// Define a special note, 'R', to represent a rest
#define  R     0

// SETUP ============================================
// Set up speaker on a PWM pin (digital 9, 10 or 11)
int speakerOut = 11;
// Do we want debugging on serial out? 1 for yes, 0 for no
int DEBUG = 0;

// AUDIO
// MELODY and TIMING  =======================================
//  melody[] is an array of notes, accompanied by beats[], 
//  which sets each note's relative length (higher #, longer note) 
int melody[] = {  C, g,  a, b, a,  g,  R,  f, g,  a, b, a, C};
//int melody[] = {  c,  d,  e,  d,  e,   d,  R,  R,  R,  R, R, R };
int beats[]  = { 8, 8, 8,  8,  30,  32, 16, 8, 8, 8, 8, 30, 32 }; 
int MAX_COUNT = sizeof(melody) / 2; // Melody length, for looping.

// Set overall tempo
long tempo = 30000;
// Set length of pause between notes
int pause = 700;
// Loop variable to increase Rest length 
int rest_count = 100; //<-BLETCHEROUS HACK; See NOTES

// Initialize core variables
int audioTone = 0;
int beat = 0;
long duration  = 0;
// END AUDIO

Servo myservo;
int  val = 0; 
char code[10]; 
int bytesread = 0; 
int numberOfCorrectAttempts = 0;
int requiredCorrectAttempts = 1;
int LEDpin = 13;
int UNLOCKED = 0;
int LOCKED = 1;
int PololuPIN = 7;
int lockedPosition = 10;
int unlockedPosition = 60;
boolean hasShutDown;
int delayAfterServoMoves = 120;

long timeLapsed = 0;
// ----------------------------------------------------

// Show each specific LED color
void showWhite(){
  digitalWrite(greenPin, HIGH);
  digitalWrite(redPin, HIGH);
  digitalWrite(bluePin, HIGH); 
}

void showRed(){
  digitalWrite(greenPin, LOW);
  digitalWrite(redPin, HIGH);
  digitalWrite(bluePin, LOW); 
}

void showBlue(){
  digitalWrite(greenPin, LOW);
  digitalWrite(redPin, LOW);
  digitalWrite(bluePin, HIGH); 
}

void showGreen(){
  digitalWrite(greenPin, HIGH);
  digitalWrite(redPin, LOW);
  digitalWrite(bluePin, LOW); 
}

// Unlock the box
void unlockBox(){
  digitalWrite(LEDpin, LOW);
  showGreen();
  myservo.attach(9);
  myservo.write(unlockedPosition);
  delay(delayAfterServoMoves);
  myservo.detach();
      
}

// Lock the box
void lockBox(){
  digitalWrite(LEDpin, LOW);
  showRed();
  myservo.attach(9);
  myservo.write(lockedPosition);
  delay(delayAfterServoMoves);
  myservo.detach();
}


// Reverse the position of the servo
// and write the current state to EEPROM
void reverseBox(){
 if (boxIsUnlocked()) {
      lockBox();
      EEPROM.write(0, LOCKED);
    } else {
      unlockBox();
      EEPROM.write(0, UNLOCKED);
    } 
}

boolean boxIsUnlocked(){
  int readValue = EEPROM.read(0);
  if (readValue == 0)
    return true;
  else if (readValue == 1)
    return false;
  else
    return false;
}

// Play sound with the piezo speaker
void playSound(){
  for (int i=0; i<MAX_COUNT; i++) {
    audioTone = melody[i];
    beat = beats[i];

    // Set up timing
    duration = beat * tempo; 

    playTone();
    
    // A pause between notes...
    delayMicroseconds(pause);
    
  }
}

// Flash the LED on the box
void flashLED(){
 digitalWrite(LEDpin, LOW); 
 delay(50);
 digitalWrite(LEDpin, HIGH); 
 delay(50);
 digitalWrite(LEDpin, LOW); 
 delay(50);
 digitalWrite(LEDpin, HIGH); 
 delay(50);
 digitalWrite(LEDpin, LOW); 
 delay(50);
 digitalWrite(LEDpin, HIGH); 
 delay(50);

}

// Shut down the Arduino
void shutDownPololu(){
 // Turn off the Pololu switch
 delay(2500);
 digitalWrite(PololuPIN, HIGH);  
 delay(1000);
 digitalWrite(LEDpin, LOW); 
 digitalWrite(greenPin, LOW); 
 digitalWrite(redPin, LOW); 
 
}


void inactivity(){
 digitalWrite(LEDpin, LOW); 
 delay(50);
 digitalWrite(LEDpin, HIGH); 
 delay(50);
 digitalWrite(LEDpin, LOW); 
 delay(50);
 digitalWrite(LEDpin, HIGH); 
 delay(50);
 digitalWrite(LEDpin, LOW); 
 delay(50);
 digitalWrite(LEDpin, HIGH); 
 delay(50);
 
 // Turn off the Pololu switch
 digitalWrite(PololuPIN, HIGH); 
}



// PLAY TONE  ==============================================
// Pulse the speaker to play a tone for a particular duration
void playTone() {
  long elapsed_time = 0;
  if (audioTone > 0) { // if this isn't a Rest beat, while the tone has 
    //  played less long than 'duration', pulse speaker HIGH and LOW
    while (elapsed_time < duration) {

      digitalWrite(speakerOut,HIGH);
      delayMicroseconds(audioTone / 2);

      // DOWN
      digitalWrite(speakerOut, LOW);
      delayMicroseconds(audioTone / 2);

      // Keep track of how long we pulsed
      elapsed_time += (audioTone);
    } 
  }
  else { // Rest beat; loop times delay
    for (int j = 0; j < rest_count; j++) { // See NOTE on rest_count
      delayMicroseconds(duration);  
    }                                
  }                                 
}


// END AUDIO


void setup() { 
  pinMode(speakerOut, OUTPUT);
  hasShutDown = false;
  Serial.begin(2400); // RFID reader SOUT pin connected to Serial RX pin at 2400bps 
  pinMode(2,OUTPUT);   // Set digital pin 2 as OUTPUT to connect it to the RFID /ENABLE pin 
  digitalWrite(2, LOW);                  // Activate the RFID reader

  pinMode(redPin, OUTPUT);
  pinMode(bluePin, OUTPUT);
  pinMode(greenPin, OUTPUT);
  digitalWrite(redPin, LOW);
  digitalWrite(bluePin, LOW);
  digitalWrite(greenPin, LOW);
  
  if (boxIsUnlocked())
  {
    //Serial.println("Box was unlocked when last turned off");
    //Serial.println("Servo is at 40");
    digitalWrite(greenPin, HIGH);
    myservo.attach(9);
    myservo.write(unlockedPosition);
    delay(delayAfterServoMoves);
    myservo.detach();
  } else {
      
    //Serial.println("Box was locked when last turned off");
    //Serial.println("Servo is at 0");
    digitalWrite(redPin, HIGH);
    myservo.attach(9);
    myservo.write(lockedPosition);
    delay(delayAfterServoMoves);
    myservo.detach();
  }
  
  
  pinMode(LEDpin, OUTPUT);
  
  
  
  pinMode(PololuPIN, OUTPUT);
  digitalWrite(PololuPIN, LOW);
  digitalWrite(LEDpin, HIGH);
}  


 void loop() { 
  if(Serial.available() > 0 && hasShutDown == false) {          // if data available from reader 
  
  // ONLY IF NOT SHUT DOWN
  
    if((val = Serial.read()) == 10) {   // check for header 
      bytesread = 0; 
      while(bytesread<10) {              // read 10 digit code 
        if( Serial.available() > 0) { 
          val = Serial.read(); 
          if((val == 10)||(val == 13)) { // if header or stop bytes before the 10 digit reading 
            break;                       // stop reading 
          } 
          code[bytesread] = val;         // add the digit           
          bytesread++;                   // ready to read next digit  
        } 
      } 
      if(bytesread == 10) {
        // if 10 digit read is complete 
        if (code[0] == '2' && code[1] == '5' && code[2] == '0' && code[3] == '0' )
        {
            //Serial.println("Correct code!");
            numberOfCorrectAttempts++;
        }
        
        if (code[0] == '3' && code[1] == 'A' && code[2] == '0' && code[3] == '0' )
        {
            //Serial.println("Correct code!");
            numberOfCorrectAttempts++;
        }
        
        // If we have read the same tag X number of times
        // we know it's not noise
        if (numberOfCorrectAttempts == requiredCorrectAttempts)
        {
          numberOfCorrectAttempts = 0;

          // Disable the RFID reader
          digitalWrite(2, HIGH);
          
          // Color the LED white
          showWhite();
          
          if (hasShutDown == false){
            hasShutDown = true;

            // Flash the LED
            flashLED();

            // Play the tune
            playSound();
            delay(500);

            // Reverse the position of the servo
            reverseBox();
            delay(100);

            // Shutdown the box to conserve power
            shutDownPololu();
          }


        }
      } 
        bytesread = 0; 
        delay(500);
    } 
  } 
  
  // Turn off the box if it has been inactive
  timeLapsed = timeLapsed + 1;
  if (timeLapsed >= 800000)
  {
    timeLapsed = 0;
    inactivity();
    
  }
} 