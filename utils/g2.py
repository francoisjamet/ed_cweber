#!/bin/env python
import h5py
import numpy as np
import sys

nomb = int(sys.argv[1])
beta = float(sys.argv[2])
chiloc = np.loadtxt('G2_uudd_1_2222')
nomv = int(np.sqrt(chiloc.shape[0]))



g = np.loadtxt('g1.inp').T
g = g[0::2] +1j * g[1::2]

g = g[:,:int(nomv/2)]

norb = int(g.shape[0]**0.5)

gg = np.zeros((norb**2, nomv),dtype = complex)
gg[:,int(nomv/2):]  = g[:]
gg[:,:int(nomv/2)] = np.conjugate(g[:,::-1])
gg = gg.reshape(norb,norb,nomv)
bubble = np.zeros((nomv,nomv),dtype = complex)

g2_uu = np.zeros((nomv, nomv, norb,norb,norb,norb, nomb),dtype = complex)
g2_ud = np.zeros((nomv, nomv, norb,norb,norb,norb ,nomb),dtype = complex)


from itertools import product
print(nomb,norb,beta)
for iom,i1,i2,i3,i4 in product(range(nomb),range(norb),range(norb),range(norb),range(norb)) :
    g2_1 = np.loadtxt('G2_uuuu_{}_{}{}{}{}'.format(iom+1,i1+1,i2+1,i3+1,i4+1)).T
    g2_2 = np.loadtxt('G2_uudd_{}_{}{}{}{}'.format(iom+1,i1+1,i2+1,i3+1,i4+1)).T
    g2_1 = g2_1[0] +1j* g2_1[1]
    g2_2 = g2_2[0] +1j* g2_2[1]
    k = 0

    for i in range(nomv) :
        for j in range(nomv) :
            g2_uu[i,j,i2,i1,i4,i3,iom] = g2_1[k]/beta
            g2_ud[i,j,i2,i1,i4,i3,iom] = g2_2[k]/beta
            k+=1

f = h5py.File('G2.h5', 'w')
f.create_dataset('g2_uuuu',data=g2_uu)
f.create_dataset('g2_uudd',data=g2_ud)
f.create_dataset('beta',data=[beta])
# f = h5py.File('chiS.h5', 'w')
# f.create_dataset('chis',data=g2_uu-g2_ud)
# f.create_dataset('chic',data=g2_uu+g2_ud)
# f.create_dataset('beta',data=[beta])
f.close()
