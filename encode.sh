#!/bin/bash

# ---------------        Encode simple        ------------------------  
#  Cryptage simple de motdepasse
#   encode est reversible. 
#     si on passe en paramettre motdepasseenclair
#        encode renvoi nlgwvkzhhvvmxozri
#     si on passe en paramettre nlgwvkzhhvvmxozri
#        encode renvoi motdepasseenclair
# Depot gitlab : Encode
# Prerequis : aucun
# Usage : en ligne de commande : encode.sh motdepasseenclair --> renvoi nlgwvkzhhvvmxozri
#         dans un script       : password=$(./encode.sh $cryptpassword) 
#   2025/02/07 : b.tran 
# ---------------        Encode simple        ------------------------  

encode() {
    local pw="$1"
    local epw=""
    local char
    for ((i=0; i<${#pw}; i++)); do
        char="${pw:i:1}"
        if [[ "$char" =~ [a-z] ]]; then
            epw+=$(printf "\\$(printf '%03o' $((219 - $(printf '%d' "'$char'"))))")
        elif [[ "$char" =~ [A-Z] ]]; then
            epw+=$(printf "\\$(printf '%03o' $((155 - $(printf '%d' "'$char'"))))")
        elif [[ "$char" =~ [0-9] ]]; then
           epw+=$(printf "\\$(printf '%03o' $((105 - $(printf '%d' "'$char'"))))")
        else
            epw+="$char"
        fi
    done
    echo "$epw"
}

echo "$(encode "$1")"
exit