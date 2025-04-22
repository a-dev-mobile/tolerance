#!/bin/bash

# Check if filename was provided
if [ $# -ne 2 ]; then
  echo "Usage: $0 input_file.txt output_file.dart"
  exit 1
fi

INPUT_FILE=$1
OUTPUT_FILE=$2

# Begin writing the Dart class
echo "class ToleranceConstants {" > $OUTPUT_FILE
echo "  // Tolerance values for different size intervals" >> $OUTPUT_FILE
echo "  static const Map<String, Map<String, String>> toleranceValues = {" >> $OUTPUT_FILE

# Read input file as JSON and process
cat $INPUT_FILE | jq -c '.[]' | while read -r row; do
  # Extract interval
  interval=$(echo $row | jq -r '."Interval\\n(mm)"')
  
  # Begin interval entry
  echo "    \"$interval\": {" >> $OUTPUT_FILE
  
  # Process all keys except interval and rowid
  echo $row | jq -r 'keys[] | select(. != "Interval\\n(mm)" and . != "rowid")' | while read -r key; do
    value=$(echo $row | jq -r ".[\"$key\"]" | sed 's/\\n/\\n/g')
    # Write key-value pair
    echo "      \"$key\": \"$value\"," >> $OUTPUT_FILE
  done
  
  # End interval entry
  echo "    }," >> $OUTPUT_FILE
done

# End class definition
echo "  };" >> $OUTPUT_FILE
echo "}" >> $OUTPUT_FILE

echo "Conversion complete. Output written to $OUTPUT_FILE"