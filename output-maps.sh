read -r -d '' header <<- EOM
VERSION 1 # Currently, this should only be 1.

# Supports all alphanumeric ASCII, and ' ', '_', '-', '+' - can also be NULL
TRACKNAME Iridium L1

# Can be POLY, DRUM, MPE, or NULL
TYPE POLY

# Can be A, B, C, D, USBD, USBH, CVGx (x between 1&4), CVx, Gx, or NULL
OUTPORT B

# Can be x (between 1-16), or NULL -- this is ignored if output port is not MIDI
OUTCHAN 1

# Can be NONE, ALLACTIVE, A, B, USBH, USBD, CVG, or NULL
INPORT NULL

# Can be x (between 1-16), ALL, or NULL. This definition will be ignored if INPORT is NONE, ALLACTIVE or CVG
INCHAN NULL

# DRUMLANES
# Syntax: ROW:TRIG:CHAN:NOTENUMBER NAME
# ROW must be between 1 and 8
# TRIG can be between 0 and 127, or NULL
# CHAN can be a number between 1 and 16, Gx, CVx, CVGx (x between 1 and 4), or NULL
# NOTENUMBER can be between 0 and 127, or NULL
# NAME supports all alphanumeric ASCII, and ' ', '_', '-', '+' - can also be NULL
# Please note this section will be discarded for tracks which are not DRUM tracks
[DRUMLANES]
[/DRUMLANES]


# PC
# Syntax: NUMBER NAME
# number must be either:
#   - A number (for simple PC)
#   - Three numbers, delimited by ':', which represent PC:MSB:LSB. You can put 'NULL' to not set the MSB/LSB.
# PC must be between 1...128
# MSB/LSB must be between 0...127
[PC]
[/PC]


# CC
# Syntax: CC_NUMBER NAME or CC_NUMBER:DEFAULT=xx NAME
# DEFAULT_VALUE must be a valid number between 0 and 127
[CC]
EOM

read -r -d '' footer <<- EOM
[/CC]


# NRPN
# Syntax: "MSB:LSB:DEPTH NAME" or "MSB:LSB:DEPTH:DEFAULT=xx NAME"
# Lsb & msb should be between 0 and 127
# DEPTH can be 7 or 14
# For NRPN: DEFAULT_VALUE must be a valid number, either between 0 and 127 (for 7 bit NRPNs) or between 0 and 16383 (for 14bit NRPNs)
[NRPN]
[/NRPN]


# ASSIGN
# Syntax: POT_NUMBER TYPE:VALUE or POT_NUMBER TYPE:VALUE DEFAULT=DEFAULT_VALUE
# POT_NUMBER must be between 1 and 8
# TYPE can be "CC", "PB" (pitchbend), "AT" (aftertouch), "CV", "NRPN", or "NULL" (this won't assign the pot).
# Non explicitly-defined pots will be considered "NULL"
# VALUE VALIDATION
#### For CC: Value must be a valid number between 0 and 119
#### For PB and AT, any text after the TYPE will be ignored
#### For CV, value must be between 1 and 4
#### For NRPN, value must be MSB:LSB:DEPTH, with both lsb & msb bebtween 0 and 127, and DEPTH being either 7 or 14
# DEFAULT VALUE
#### For CC: DEFAULT_VALUE must be a valid number between 0 and 127
#### For PB: DEFAULT_VALUE must be a valid number between 0 and 16383
#### For NRPN: DEFAULT_VALUE must be a valid number, either between 0 and 127 (for 7 bit NRPNs) or between 0 and 16383 (for 14bit NRPNs)
#### For CV: DEFAULT_VALUE must be either a valid number between 0 and 65535, or a voltage between -5V and 5V, e.g. "-4.25V" or "1.7V"
#### Please note default value will be ignored for PB and AT messages.
[ASSIGN]
[/ASSIGN]


# AUTOMATION
# Syntax: TYPE:VALUE
# TYPE can be "CC", "PB" (pitchbend), "AT" (aftertouch), "CV", or "NRPN"
# VALUE VALIDATION
#### For CC: Value must be a valid number between 0 and 119
#### For PB and AT, any text after the TYPE will be ignored
#### For CV, value must be between 1 and 4
#### For NRPN, value must be MSB:LSB:DEPTH, with both lsb & msb bebtween 0 and 127, and DEPTH being either 7 or 14
[AUTOMATION]
[/AUTOMATION]


# This section will be readable from Hapax.
[COMMENT]
[/COMMENT]
EOM

input_file='master-map.csv'
mimap_file='iridium-generated.mimap'
instrument_definition_file1='iridium-layer1.txt'
instrument_definition_file2='iridium-layer2.txt'

parameter_id=( $(tail -n +2 $input_file | cut -d ',' -f1) )
description=( $(tail -n +2 $input_file | cut -d ',' -f2) )
midi_cc=( $(tail -n +2 $input_file | cut -d ',' -f4) )

#echo "array of descriptions  : ${description[@]}"
# echo "array of Qty   : ${arr_record2[@]}"
# echo "array of Price : ${arr_record3[@]}"
# echo "array of Value : ${arr_record4[@]}"
echo "Removing old files"
rm $mimap_file
rm $instrument_definition_file1
rm $instrument_definition_file2

echo "Building map files"
echo "$header" >> $instrument_definition_file1
header_2=$(echo "$header" | sed 's/OUTCHAN[[:space:]]1/OUTCHAN 2/g' | sed 's/Iridium[[:space:]]L1/Iridium L2/g')
echo  "$header_2" >> $instrument_definition_file2
index=0

write_values () {
    echo "PidForCC$1\t$param_id" >> $mimap_file
    pretty_description=$(echo "${description[$index]}" | sed 's/\([a-z1-9]\)\([A-Z]\)/\1 \2/g' | sed 's/Wavetable/WT/g' | sed 's/Waveform/WF/g' | sed 's/Particle/PT/g')
    echo "$1 $pretty_description" >> $instrument_definition_file1
    echo "$1 $pretty_description" >> $instrument_definition_file2
}

for param_id in "${parameter_id[@]}"
do
    if [ $index -gt 0 ] #
    then
        # cc=$(($index + 1))
        # echo "PidForCC$cc\t$param_id" >> $mimap_file
        write_values $(($index + 1))
    else
        write_values $index
        # echo "PidForCC$index\t$param_id" >> $mimap_file
    fi
    # pretty_description=$(echo "${description[$index]}" | sed 's/\([a-z1-9]\)\([A-Z]\)/\1 \2/g' | sed 's/Wavetable/WT/g' | sed 's/Waveform/WF/g' | sed 's/Particle/PT/g')
    # echo "$index $pretty_description" >> $instrument_definition_file1
    # echo "$index $pretty_description" >> $instrument_definition_file2
	((index++))
done
echo "$footer" >> $instrument_definition_file1
echo "$footer" >> $instrument_definition_file2

echo "Trying to copy files to removable media"
cp $mimap_file /Volumes/Kingston
cp $instrument_definition_file1 /Volumes/hapax/hapax
cp $instrument_definition_file2 /Volumes/hapax/hapax
echo "Done"