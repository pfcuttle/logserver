#!/usr/bin/env python

'''Make a C array from a (binary) file

This script outputs a C array from an input file for unwieldy data that has to
be included in a program. The output automatically points to program space with
the PGM_P define given in `avr/pgmspace.h'.
'''

import sys


def main():
    if len(sys.argv) != 4:
        sys.stderr.write(
                'Usage: {} <infile> <array name> <outfile>\n'.format(
                    sys.argv[0]))
        sys.exit(1)

    in_data = open(sys.argv[1], 'rb').read()
    array = sys.argv[2]

    with open(sys.argv[3], 'wb') as out_file:
        out_data = '#define {0}_LENGTH {1}\n\n'.format(
                array.upper(), len(in_data))
        out_data += ' '.join(['PGM_P', array + '[]', '= {\n'])
        out_data += ', '.join('{:#04x}'.format(x) for x in in_data)
        out_data += '\n};\n'

        out_file.write(bytes(out_data, 'utf-8'))


if __name__ == '__main__':
    main()
