# import random as rd
def find_med_tmp(L):
    if L[1] <= L[0] <= L[2] or L[1] >= L[0] >= L[2]:
        return L[0]
    elif L[0] <= L[1] <= L[2] or L[0] >= L[1] >= L[2]:
        return L[1]
    elif L[0] <= L[2] <= L[1] or L[0] >= L[2] >= L[1]:
        return L[2]

def find_med(L):
    L0, L1, L2 = L[0:3], L[3:6], L[6:9]
    tmp0, tmp1, tmp2 = find_med_tmp(L0), find_med_tmp(L1), find_med_tmp(L2)
    ans = find_med_tmp([tmp0, tmp1, tmp2])
    return ans

def find_real_med(L):
    return sorted(L)[4]
# if __name__ == '__main__':
#     err = 0
#     for i in range(10000):
#         L = [rd.randint(0, 255) for i in range(9)]
#         L0, L1, L2 = L[0:3], L[3:6], L[6:9]
#         # print(L0, L1, L2)
#         tmp0, tmp1, tmp2 = find_med(L0), find_med(L1), find_med(L2)
#         ans = find_med([tmp0, tmp1, tmp2])
#         if ans != sorted(L)[4]:
#             print(f'L = {L}, cal = {ans}, golden = {sorted(L)[4]}')
#             err += 1
#         else:
#             print(f'L = {L}, cal = golden = {ans}, CORRECT!')
#     print(f'total err = {err}')
def writefile(L, name):
    fh = open(f'{name}.txt', 'w')
    for line in L:
        temp = [hex(i)[2:].zfill(2) for i in line]
        fh.write('_'.join(temp) + '\n')
    fh.close()

def writefile_long(L, name):
    fh = open(f'{name}.txt', 'w')
    for line in L:
        temp = [hex(i)[2:].zfill(5) for i in line]
        fh.write('_'.join(temp) + '\n')
    fh.close()

def writefile_dec(L, name):
    fh = open(f'{name}_dec.txt', 'w')
    for line in L:
        temp = [str(i).zfill(3) for i in line]
        fh.write('_'.join(temp) + '\n')
    fh.close()
