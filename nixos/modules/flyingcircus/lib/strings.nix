{ lib }:
with lib;
rec {

  # Strip whitespace around a string
  stripString = s:
    (removeSuffix " "
    (removeSuffix "\n"
    (removeSuffix "\t"
    (removePrefix " "
    (removePrefix "\n"
    (removePrefix "\t"
    s))))));
}
