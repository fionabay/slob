class SVIRaw:
    def __init__(self,a=0,b=0,rho=0,m=0,sigma=0.001):
        self.a = a
        self.b = b
        self.rho = rho
        self.m = m
        self.sigma = sigma
    def calc(self,k):
        '''calculate SVI raw, note hard to find parameters to prevent static arbitrage'''
        variance = self.a + self.b *(self.rho*(k-self.m)+math.sqrt((k-self.m)**2+self.sigma**2))
        return(variance)
    def bound(self):
        '''bounds for scipy.optimize.minimize'''
        bounds = ((-np.inf, np.inf),(0,np.inf),(-1,1),(-np.inf, np.inf),(0.00001,1))
        return(bounds)
