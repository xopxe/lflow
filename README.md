# lflow

Data-flow language for reactive robotics.


## Introduction

A programa is a collection of filter chains. Each chain is a collection of inputs and ouputs, and a filter in the middle. Each input and output is a data stream. Filters capture data from the input and send data on the ouput. Each output is labeled, and these labels are used to connect filter cains. You can also use constant values as inputs. Filters can generate output on their own, not only as a response to input data.

The language provedes a set of standard filters (check for them in the lflow/filters/ folder). You can extend the language adding new filters. You can also write the Lua source code for the filter right in the filter chain specification.

To do proper robotic control, lflow uses Toribio.

## File format

In a lflow file each filter chain goes on a line. A filter chain is 

\[inputs\] > filter_spec > \[outputs\]

where _inputs_ is a comma separated list of labels or constant values, and _ouputs_ is a comma separated list of labels.

You can add comments with #. There are several sample programs in the examples/ folder.

A trivial program is shown below (notice it has nothing robotic or reactive, it's just to show how a program looks):

```
1 > timer > tick
tick > print >
```

_timer_ and _print_ are filters. We pass the number 1 to the timer which will
start emitting a number each 1 second. This number will be labeled _tick_, and whe provide this to _print_ that prints it (and odes not generate any output).

If we want to print when 60 seconds have passed, we modify the program as follows:

```
1 > timer > tick
tick, 60 > equal > minute
'sec', tick > print >
'min', minute > print >
```

The output will be

```
sec	1
sec	2
sec	3
...
sec	58
sec	59
min	60
sec	60
sec	61
sec	62
...
```

Notice that each filter chain runs concurrently, so it is not wrong to show the "min 60" message before the "sec 60" message.

This program can be further improved into a proper clock (check the use of inlined functions):

```
1 > timer > tick
tick > function(s) if s%60==0 then return s/60 end end > minutes
tick > function(s) return s%60 end > seconds
'sec', seconds > print >
'min', minutes > print >
```

A sample reactive line follower robot (using the usb4butia controller) can be:

```
'gris:1', 0.1 > sensor_poll > sense_left
'gris:2', 0.1 > sensor_poll > sense_right

sense_left, '>', 200 > threshold > forward_left
sense_right, '>', 200 > threshold > forward_right

forward_left, forward_left > motores >

\# print on screen for debugging purposes
'readings:', sense_left, sense_left > print >
'actions:', forward_right, forward_right > print > 
```


## License

Same as Lua, see COPYRIGHT.


## Who?

Copyright (C) 2013 Jorge Visca, jvisca@fing.edu.uy



