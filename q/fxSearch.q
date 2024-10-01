/ recursive search function for FX pairs in market quote table

fxSearch:{[histSymbol;quoteCache]
 /0N!histSymbol;
 fromSymbol: `$ last string histSymbol;
 targetSymbol: `$ first string histSymbol;
 searchedSymbol: `$ 1_ string histSymbol;

 nextSymbol: exec (histSymbol ,/: fxto) from quoteCache where fxfrom = fromSymbol,not fxto in searchedSymbol;

 / to avoid loop, next symbol should not appear in symbols already searched
 /if found target symbol, return histSymbol, otherwise keep searching
 $[fromSymbol=targetSymbol; histSymbol;
 $[ count[nextSymbol]=0; ::; nextSymbol .z.s \: quoteCache]]}

/ exhaustive search function use each left iterator
possibleFX:{ [sym;eventTime]
 initialSymbol: `$ -3_string sym;
 targetSymbol: `$ 3_string sym;
 /put target symbol to the first of hist string
 reversedSymbol: targetSymbol,initialSymbol;

 / combine both direct and indirect FX pairs
 quotefrom: select time, fxfrom:  `$ -3_'string sym, fxto:  `$ 3_'string sym,sym,spot:bid, qty:bsize from quote where time within (`date$ eventTime +`time $ 0,eventTime);
 quoteto:select time, fxfrom:`$ 3_'string sym, fxto:  `$ -3_'string sym,sym,spot:reciprocal ask, qty:asize from quote where time within (`date$ eventTime +`time $ 0, eventTime);
 quoteCache:quotefrom,quoteto;

 start: exec (reversedSymbol ,/: fxto) from quoteCache where fxfrom = initialSymbol;
 res:start fxSearch \: quoteCache;
 raze res
 }

/test example to list all possible conversion from IDR to USD
res: possibleFX [`IDRUSD; 2024.02.01D12:11]
res


/with conversion qty constraint
/ recursive search function for FX from start to target,start is in the last 3 character of histSymbol
fxTrade:{[histTrade;quoteCache]

 histSymbol: histTrade[`sym];
 histQty: histTrade[`execQty];
 histSpot: histTrade[`execSpot];

 fromSymbol: `$ last string histSymbol;
 targetSymbol: `$ first string histSymbol;
 searchedSymbol: `$ 1_ string histSymbol;

 / to avoid loop, next symbol should not appear in symbols already searched
 / search criteria the available qty should be greated than the wanted quantity
 nextTrade: select sym: (histSymbol ,/: fxto), execQty: (histQty */: spot),execSpot: (histSpot */:spot) from quoteCache where fxfrom = fromSymbol,not fxto in searchedSymbol,qty>=histQty;

 /if found target symbol, return histSymbol, otherwise keep searching
 $[fromSymbol=targetSymbol; histSpot; $[ count[nextTrade]=0; -1; nextTrade .z.s \: quoteCache]]}


marketPrice:{ [sym;eventTime;side;execQty]

 initialSymbol: `$ -3_string sym;
 targetSymbol: `$ 3_string sym;

 / make target currency the first symbol
 $[side=`buy; reversedSymbol: targetSymbol,initialSymbol; reversedSymbol: initialSymbol,targetSymbol];
 $[side=`buy; initialSymbol: initialSymbol; initialSymbol: targetSymbol];

 quotefrom: select time, fxfrom:  `$ -3_'string sym, fxto:  `$ 3_'string sym,sym,spot:bid, qty:bsize from quote where time within (`date$ eventTime +`time $ 0,eventTime),bsize>= execQty;
 quoteto:select time, fxfrom:`$ 3_'string sym, fxto:  `$ -3_'string sym,sym,spot:reciprocal ask, qty:asize from quote where time within (`date$ eventTime +`time $ 0, eventTime),asize>=execQty;
 quoteCache:quotefrom,quoteto;

 start: select sym:(reversedSymbol ,/: fxto), execQty: (execQty */: spot), execSpot: spot from quoteCache where fxfrom = initialSymbol,qty>=execQty;
 res:start fxTrade \: quoteCache;
 res: raze res;
 $[side=`buy; last max res; last max reciprocal res ]
}

tradeMetric: {[side;exec_price;market_price]

 $[side=`buy;$[0N!exec_price>market_price;"outperforming";"underperforming"];
             $[0N!exec_price<market_price;"outperforming";"underperforming"]]
  }

/resTrade: marketPrice [`IDRUSD; 2024.02.01D12:11:02.665;`buy;1000];
tradereport: update  market_price:  marketPrice'[sym;  time;  side; exec_qty]  from tradereport;
tradereport: update  performance:   tradeMetric'[side;exec_price;market_price] from tradereport ;
select from tradereport