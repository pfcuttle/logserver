#include <MsTimer2.h>
#include <SPI.h>
#include <Ethernet.h>


#define HEADERS \
"HTTP/1.0 200 OK\r\n" \
"Content-Type: text/html; charset=utf-8\r\n" \
"\r\n"

#define FOUND \
"HTTP/1.0 302 Found\r\n" \
"Location: http://192.168.50.142/\r\n" \
"\r\n"

#define NOT_FOUND \
"HTTP/1.0 404 Not Found\r\n" \
"Content-type: text/html\r\n" \
"\r\n" \
"<h1>404 &emdash; Not Found</h1>\r\n" \
"\r\n"

#define PAGE_1 \
"<!DOCTYPE html>" \
"<html>" \
"    <head>" \
"        <title>logserver</title>" \
"    </head>" \
"    <style type=\"text/css\">\r\n" \
"        body {margin: 2em auto; width: 80em; background-color: #112; color: white; font-family: sans-serif; text-align: center;}\r\n" \
"        h1 {margin: 1em 0; padding: 1em 0;}\r\n" \
"        a {border-bottom: dotted 1px orange; color: orange; text-decoration: none;}\r\n" \
"        ul {margin: 1em 0; padding: 1em;}\r\n" \
"        form {margin: 1em 0; padding: 1em;}\r\n" \
"        .rounded {border: solid 1px white; background-color: #222; boder-radius: 4px; -moz-border-radius: 4px; -webkit-border-radius: 4px; -o-border-radius: 4px;}\r\n" \
"    </style>\r\n" \
"    <body>" \
"        <h1 class=\"rounded\"><img src=\"face.png\" /> logserver</h1>" \
"        <p>Cette page est sur un" \
"            <a href=\"http://www.seeedstudio.com/depot/seeeduino-mega-p-717.html?cPath=132\">Seeeduino Mega</a>, " \
"            avec un <a href=\"http://www.seeedstudio.com/depot/wiznet-ethernet-shield-w5100-p-518.html?cPath=132_134\">Wiznet Ethernet Shield</a>." \
"        </p>" \
"        <p>Le board a été initialisé il y a: <strong>"

#define PAGE_2 \
"</strong>.</p>" \
"        <div class=\"rounded\">" \
"            <ul>"

#define PAGE_3 \
"            </ul>" \
"            <form action=\"http://192.168.50.142\" method=\"GET\">" \
"                <input type=\"text\" name=\"msg\" maxsize=\"200\" />" \
"                <input type=\"submit\" value=\"Poster!\" />" \
"            </form>" \
"        </div>" \
"    </body>" \
"</html>"

#define LOGSIZE 10
#define LINESIZE 255

#define pgm_println(x) ServerPrintln_P(PSTR(x))


byte mac[] = {0x00, 0x1B, 0x77, 0x8D, 0x20, 0xCA};
byte ip[] = {192, 168, 50, 142};

volatile static unsigned int secs = 0;
volatile static unsigned int mins = 0;
volatile static unsigned int hours = 0;


Server server(80);


/* Pretty messages */
char pretty[LOGSIZE][LINESIZE];
unsigned int p_index = 0;


/*
 * Called each second to update uptime.
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


/*
 * Print a flash stored string
 *
 * Inspired by `SdFatUtil::SerialPrintln_P'
 */
void ServerPrintln_P(PGM_P str) {
    uint8_t c;

    for (c = 0; (c = pgm_read_byte(str)); ++str) {
        server.print(c);
    }

    server.println();
}


void setup() {
    Serial.begin(9600);

    Ethernet.begin(mac, ip);
    server.begin();

    memset(*pretty, LOGSIZE * LINESIZE, '\0');

    MsTimer2::set(1000, timer_cb);
    MsTimer2::start();
}


void loop() {
    Client client = server.available();
    
    bool has_equal = false;
    char line[LINESIZE];
    unsigned int index = 0;
    unsigned int i = 0;

    if (client) {
        while (client.available()) {
            /* Parse request */

            char c = client.read();

            line[index] = c;
            index++;

            if (c == '=') {
                has_equal = true;
            }

            if (c == '\r' || c == '\n') {
                break;
            }
        }

        line[index] = '\0';

        Serial.print(">>>Request: ");
        Serial.println(line);

        if (strstr(line, "GET / ")) {

            /* Print index page */

            pgm_println(HEADERS);

            pgm_println(PAGE_1);
            server.print(hours);
            server.print(" heures, ");
            server.print(mins);
            server.print(" minutes et ");
            server.print(secs);
            server.print(" secondes");
            pgm_println(PAGE_2);

            for (i = 0; i < p_index; ++i) {
                server.print("<li>");
                server.print(pretty[i]);
                server.println("</li>\r");
            }

            pgm_println(PAGE_3);

        } else if (has_equal) {

            /* Get submitted message */

            char *msg = strtok(line, " ");
            msg = strtok(NULL, "=");
            msg = strtok(NULL, " ");
            Serial.println();
            Serial.println(msg);
            Serial.println("----");

            /*
             * Augment string to compensate for urldecode last character
             * bug.
             */
            for (i = 0; msg[i] != '\0'; ++i)
                ;
            msg[i] = ' ';
            msg[i+1] = '\0';

            /* Prettify */
            if (p_index < LOGSIZE) {
                urldecode(pretty[p_index++], LINESIZE, msg);
            } else {
                for (i = 1; i < LOGSIZE; ++i) {
                    strncpy(pretty[i-1], pretty[i], LINESIZE);
                }
                urldecode(pretty[LOGSIZE-1], LINESIZE, msg);
            }

            /* Redirect to clear GET params */
            server.println(FOUND);
        } else if (strstr(line, "GET /face.png")) {

            /* Serve logo */

            file_serve("face.png");

        } else {

            /* Default to not found */

            server.println(NOT_FOUND);
        }

        delay(1);
        client.stop();
    }
}


// vim: ft=cpp
