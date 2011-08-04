#include <MsTimer2.h>
#include <SPI.h>
#include <Ethernet.h>


#define HEADERS "\
HTTP/1.0 200 OK\r\n\
Content-Type: text/html; charset=utf-8\r\n\
\r"

#define PAGE_1 \
"<!DOCTYPE html>\r\n" \
"<html>\r\n" \
"    <head>\r\n" \
"        <title>Bonjourduino!</title>\r\n" \
"    </head>\r\n" \
"    <style type=\"text/css\">\r\n" \
"        body {background-color: navy; color: white; font-family: sans-serif; text-align: center;}\r\n" \
"        a {border-bottom: dotted 1px orange; color: orange; text-decoration: none;}\r\n" \
"        ul {margin: 1em; padding: 1em; border: solid 1px white;}\r\n" \
"    </style>\r\n" \
"    <body>\r\n" \
"        <h1>Bonjour</h1>\r\n" \
"        <p>Cette page est sur un" \
"            <a href=\"http://www.seeedstudio.com/depot/seeeduino-mega-p-717.html?cPath=132\">Seeeduino Mega</a>, " \
"            avec un <a href=\"http://www.seeedstudio.com/depot/wiznet-ethernet-shield-w5100-p-518.html?cPath=132_134\">Wiznet Ethernet Shield</a>." \
"        </p>\r\n" \
"        <p>Le board a été initialisé il y a: <strong>"

#define PAGE_2 \
"</strong>.</p>\r\n" \
"        <ul>\r\n"

#define PAGE_3 \
"        </ul>\r\n" \
"        <form action=\"http://192.168.50.142\" method=\"GET\">\r\n" \
"            <input type=\"text\" name=\"msg\" maxsize=\"200\" />\r\n" \
"            <input type=\"submit\" value=\"Poster!\" />\r\n" \
"        </form>\r\n" \
"    </body>\r\n" \
"</html>\r"

#define LOGSIZE 10


byte mac[] = {0x00, 0x1B, 0x77, 0x8D, 0x20, 0xCA};
byte ip[] = {192, 168, 50, 142};

volatile static unsigned int secs = 0;
volatile static unsigned int mins = 0;
volatile static unsigned int hours = 0;


Server server(80);


/*
 * Called each second to update seconds count.
 */
void timer_cb(void) {
    secs++;

    if (secs == 60) {
        secs = 0;
        mins++;
    }

    if (mins == 60) {
        mins = 0;
        hours++;
    }
}


// Pretty messages
char pretty[LOGSIZE][255] = {"Demo"};
unsigned int p_index = 0;


void setup() {
    Serial.begin(9600);

    Ethernet.begin(mac, ip);
    server.begin();

    MsTimer2::set(1000, timer_cb);
    MsTimer2::start();
}


void loop() {
    Client client = server.available();
    
    bool has_equal = false;
    char line[255];
    unsigned int index = 0;
    unsigned int i = 0;

    if (client) {
        while (client.available()) {
            char c = client.read();
            Serial.print(c);

            line[index] = c;
            index++;

            if (c == '=') {
                has_equal = true;
            }

            if (c == '\r' || c == '\n') {
                break;
            }
        }

        if (has_equal) {
            /* Get submitted message */
            char *msg = strtok(line, " ");
            msg = strtok(NULL, "=");
            msg = strtok(NULL, " ");
            Serial.println();
            Serial.println(msg);
            Serial.println("----");

            for (i = 0; msg[i] != '\0'; ++i)
                ;
            msg[i] = ' ';
            msg[i+1] = '\0';

            /* Prettify */
            if (p_index < LOGSIZE) {
                urldecode(pretty[p_index++], 255, msg);
            } else {
                for (i = 1; i < LOGSIZE; ++i) {
                    strncpy(pretty[i-1], pretty[i], 255);
                }
                urldecode(pretty[LOGSIZE-1], 255, msg);
            }

        }

        /* Print whole page */

        server.println(HEADERS);

        server.println(PAGE_1);
        server.print(hours);
        server.print(" heures, ");
        server.print(mins);
        server.print(" minutes et ");
        server.print(secs);
        server.print(" secondes");
        server.println(PAGE_2);

        for (i = 0; i < p_index; ++i) {
            server.print("<li>");
            server.print(pretty[i]);
            server.println("</li>\r");
        }

        server.println(PAGE_3);

        delay(1);
        client.stop();
    }
}


// vim: ft=cpp
