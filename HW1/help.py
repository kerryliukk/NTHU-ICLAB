for i in range(256):
    mode = bin(i)[2:].rjust(8, '0')
    minterm = []
    if mode[0] == '1':
        minterm.append('P_in&S_in&D_in')
    if mode[1] == '1':
        minterm.append('P_in&S_in&~D_in')
    if mode[2] == '1':
        minterm.append('P_in&~S_in&D_in')
    if mode[3] == '1':
        minterm.append('P_in&~S_in&~D_in')
    if mode[4] == '1':
        minterm.append('~P_in&S_in&D_in')
    if mode[5] == '1':
        minterm.append('~P_in&S_in&~D_in')
    if mode[6] == '1':
        minterm.append('~P_in&~S_in&D_in')
    if mode[7] == '1':
        minterm.append('~P_in&~S_in&~D_in')

    if minterm:
        ans = ' | '.join(minterm)
    else:
        ans = '0'
    # print(f'mode = {mode} ({i}), ans = {ans}')
    print(f"8'b{mode[:4]}_{mode[4:]}: Result_temp = {ans};")
    