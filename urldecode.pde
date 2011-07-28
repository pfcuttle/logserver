/*
 * Taken from: http://stackoverflow.com/questions/2673207/c-c-url-decode-library/2766963#2766963
 *
 * Modified to translate `+' into ` '.
 */

#include <assert.h>


void urldecode(char *pszDecodedOut, size_t nBufferSize, const char *pszEncodedIn)
{
    memset(pszDecodedOut, 0, nBufferSize);

    enum DecodeState_e
    {
        STATE_SEARCH = 0, ///< searching for an ampersand to convert
        STATE_CONVERTING, ///< convert the two proceeding characters from hex
    };

    DecodeState_e state = STATE_SEARCH;

    for(unsigned int i = 0; i < strlen(pszEncodedIn)-1; ++i)
    {
        switch(state)
        {
        case STATE_SEARCH:
            {
                if(pszEncodedIn[i] == '+') {
                    strncat(pszDecodedOut, " ", 1);
                    break;
                }

                if(pszEncodedIn[i] != '%')
                {
                    strncat(pszDecodedOut, &pszEncodedIn[i], 1);
                    break;
                }

                // We are now converting
                state = STATE_CONVERTING;
            }
            break;

        case STATE_CONVERTING:
            {
                // Conversion complete (i.e. don't convert again next iter)
                state = STATE_SEARCH;

                // Create a buffer to hold the hex. For example, if %20, this
                // buffer would hold 20 (in ASCII)
                char pszTempNumBuf[3] = {0};
                strncpy(pszTempNumBuf, &pszEncodedIn[i], 2);

                // Ensure both characters are hexadecimal
                bool bBothDigits = true;

                for(int j = 0; j < 2; ++j)
                {
                    if(!isxdigit(pszTempNumBuf[j]))
                        bBothDigits = false;
                }

                if(!bBothDigits)
                    break;

                // Convert two hexadecimal characters into one character
                int nAsciiCharacter;
                sscanf(pszTempNumBuf, "%x", &nAsciiCharacter);

                // Ensure we aren't going to overflow
                assert(strlen(pszDecodedOut) < nBufferSize);

                // Concatenate this character onto the output
                strncat(pszDecodedOut, (char*)&nAsciiCharacter, 1);

                // Skip the next character
                i++;
            }
            break;
        }
    }
}

// vim: ft=cpp
