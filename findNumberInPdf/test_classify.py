import sys
from find_number_in_pdf import classify_match

match_2 = {
    'type': 'range',
    'page': 269,
    'range': '1475.0 to 1826.0',
    'match': '1475-\n 1826',
    'context': '... any of SEQ ID NOS: 1475-\n 1826 is paired with any ...'
}

match_3 = {
    'type': 'range',
    'page': 397,
    'range': '1475.0 to 1826.0',
    'match': '1475-\n 1826',
    'context': '... any of SEQ ID NOS: 1475-\n 1826 and variable light ...'
}

print("Match 2 classification:", classify_match(match_2))
print("Match 3 classification:", classify_match(match_3))
