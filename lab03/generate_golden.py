def FU(a,b,instruction):
    if instruction==0:
        return a
    elif instruction==1:
        return a+1
    elif instruction==2:
        return a+(~b)
    elif instruction==3:
        return a+(~b)+1
    elif instruction==4:
        return a+b
    elif instruction==5:
        return a+b+1
    elif instruction==6:
        return b
    elif instruction==7:
        return a-1
    elif instruction==8:
        return a&b
    elif instruction==9:
        return a|b
    elif instruction==10:
        return a^b
    elif instruction==11:
        return ~a
    elif instruction==16:
        return (b>>1)&32767
    elif instruction==17:
        return b<<1
    elif instruction==18:
        return ((b>>1)&32767)+((b&1)<<15)
    elif instruction==19:
        return (b<<1)+((((b&(2**15)))>>15)&1)



import random
random.seed(5)
fout=open("./golden2.dat","w")

test_pattern=20

for test_num in range(0,test_pattern):
    input_a=random.randint(0,65535)
    input_b=random.randint(0,65535)

    for i in range(0,12):
        out=FU(input_a,input_b,i)&0xffffffff
        out=out&65535
        fout.write("%04x_%04x_%02x_%04x \n" % (input_a,(input_b&0xffffffff)&65535,i,out))
    


    for i in range(16,20):
        out=FU(input_a,input_b,i)&0xffffffff
        out=out&65535
        fout.write("%04x_%04x_%02x_%04x \n" % (input_a,(input_b&0xffffffff)&65535,i,out))
fout.close()