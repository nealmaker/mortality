# mortality
Tree mortality model for the Northern Forest

This model is poorly developed now, and has not been tested against independent data yet.

## To Do:

* More exploritory analysis, especially examination of possible interactive effects.
* Better lit review
* Exploration of other model types
  * Are non-parametric models best?
  * Would disagregation models be useful & possible? (see Zhang et al. 2011)
  * Look into splitting criteria for tree-based models (am I optimizing the right thing?).
* Construct ROC curves and calculate Areas Under Curve (AUC) so results are comperable w/ Wiskittel and others.
* Is AUC really better than an F-value? Why (F-value seems more intuitive to me)?
* Do other studies treat survival as the "possitive" outcome? Does it matter?

## Possiblities For Dealing With Censoring:

* Use a Cox model, which is semi-parametric, and definately has implementations that work with interval-censored data.
* Find a non-parametric model that can handle interval-censored data
  * Random survival forests for R look like a dead end: have looked, but haven't found any that can handle interval censoring
  * Bagged trees for survival?
  * Support vector machines?
  * Survival neural networks? (These definitley exist for Python. Not sure about R. Are they even applicable?)
* Avoid censoring altogether by using a binary outcome (lived or died) and using the remeasurement period as a predictor. Then you could just put in the period you want when doing predictions (as long as it's in the range of the training data). 
