import math
import numpy as np

class SVINatural:
    def __init__(self,delta=0,omega=0,epsilon=0.0001,rho=0, miu=0):
        self.delta = delta
        self.omega = omega
        self.epsilon = epsilon
        self.rho = rho
        self.miu = miu
    def calc(self,k):
        variance = self.delta+0.5*self.omega*(1+self.epsilon*self.rho*(k-self.miu)+math.sqrt((self.epsilon*(k-self.miu)+self.rho)**2+(1-self.rho)**2))
        return variance
    def bound(self):
        bounds = ((-np.inf, np.inf),(0,np.inf),(0.00001,np.inf),(-1,1),(-np.inf,np.inf))
        return bounds
