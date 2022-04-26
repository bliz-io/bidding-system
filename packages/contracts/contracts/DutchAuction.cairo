# This indicates we're creating a starknet contract, rather than a pure Cairo program
%lang starknet

# Builtins are low-level execution units that perform some predefined computations useful to Cairo programs
#   pedersen is the builtin for Perdern hash computations
#   range_check is useful for numerical comparison operations
# Read more at: https://www.cairo-lang.org/docs/how_cairo_works/builtins.html
%builtins pedersen range_check
