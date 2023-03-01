# measure_tio

This ruby program is written for measurement of TiO absorption band in M-type stellar spectrum as equivalent with.

1.usage

 ruby measure_tio.rb "20200102bete.txt" > out.txt   # for measuring a sigle file
or
 ruby measure_tio.rb @input.lst > out.txt        #measuring files more than two

 
2. Input File to be measured

input file/files  is/are  as a single file name or  a list file name of file names to be measured
single file:
named as like this "20200102bete.txt"
list file name
@+file name   ex. "@iput.lst"

"input.lst"
20200102bete.txt
20200103bete.txt
...

the type of input file/files is/are a text file/files which is consist of two columns as following.
# wavelength in Aongstroem  and flax in absolute or relative value
4000.10 1.188e-01
4000.66 1.292e-01
4001.23 1.395e-01
4001.79 1.346e-01
4002.36 1.266e-01
....
file name is have to include strings of 8 digits of "YYYYMMDD" or 7 digit of integer of Julian day.
like this


