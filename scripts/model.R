library("tidyverse")
library("caret")
library("Rborist")
library("randomForest")
library("Rborist")

# load data from GitHub
temp <- tempfile()
download.file("https://github.com/nealmaker/fia-data-nf/raw/master/rda/nf-fia.rda", 
              temp)
load(temp)

# remove trees that were cut and unwanted variables
nf_fia <- nf_fia %>%
  filter(status_change != "cut") %>%
  mutate(died = as.factor(if_else(status_change == "died", 1, 0))) %>% 
  select(died, spp, dbh_s, cr_s, ba_mid, bal_s, 
         forest_type_s, lat, lon) 

# test set is 20% of full dataset
test_size <- .2

set.seed(10)
index <- createDataPartition(nf_fia$died, times = 1, p = test_size, list = FALSE)

train <- nf_fia[-index,]
test <- nf_fia[index,]


#####################################################################
# Preprocess data
#####################################################################

preproc_mort <- preProcess(train[,-1], method = c("center", "scale", "YeoJohnson"))
train_tran <- predict(preproc_mort, train)
test_tran <- predict(preproc_mort, test)

x <- train_tran[,-1]
y <- train_tran[,1]

# sub-sample for trying different models
train_tran_sub <- train_tran[sample(nrow(train_tran), 500, replace = F),]

x_sub <- train_tran_sub[,-1]
y_sub <- train_tran_sub[,1]

#####################################################################
# Train model
#####################################################################

# Model testing
ranger_mod_test <- train(x_sub, y_sub,
                         method = "ranger",
                         num.trees = 50,
                         tuneGrid = data.frame(mtry = seq(2, 8, by = 2),
                                               splitrule = rep("gini", 4),
                                               min.node.size = rep(10, 4)))

randomForest_mod_test <- train(x_sub, y_sub,
                               method = "rf",
                               importance = T,
                               tuneGrid = data.frame(mtry = seq(2, 8, by = 2)))

Rborist_mod_test <- train(x_sub, y_sub,
                          method = "Rborist",
                          tuneGrid = data.frame(predFixed = seq(2, 8, by = 2),
                                                minNode = rep(2, 4)))


# Final model
set.seed(1)
mort_model_2 <- train(x, y,
                    method = "Rborist",
                    tuneGrid = data.frame(predFixed = seq(2, 8, by = 2),
                                          minNode = rep(2, 4)))

# validation$census can be used to get probabilities
# validation$yPred seems to have changed factor levels
mort_model <- Rborist(x = x, y = y, 
                      predFixed = 7,
                      minNode = 2)

#####################################################################
# Results 
#####################################################################

y_hat_train <- predict(mort_model, newdata = x)
y_hat_train <- if_else(y_hat_train$yPred == 1, 0, 1)
y_hat_train <- as.factor(y_hat_train)

confusionMatrix(data = y_hat_train, reference = y, positive = "1")

caret::F_meas(data = y_hat_train, reference = y, positive = "1")


#####################################################################
# Prediction 
#####################################################################

df <- data.frame(spp = factor(c("hard maple", "paper birch"), 
                              levels = levels(train$spp)),
                 dbh_s = c(10, 19),
                 cr_s = c(60, 10),
                 ba_mid = c(60, 250),
                 bal_s = c(0, 200),
                 forest_type_s = factor(c("Northern hardwood", "Cedar-hardwood"),
                                        levels = levels(train$forest_type_s)),
                 lat = c(44.7, 44.7),
                 lon = c(-73.6, -73.6))

df_trans <- predict(preproc_mort, newdata = df)

# Works well, but predicts "1" for lived & "2" for died
predict(mort_model, newdata = df_trans)

#this will give a probability of death (over next 5ish years)
predict(mort_model, newdata = df_trans)$census[,2]/500


#####################################################################
# Test
#####################################################################

y_hat_test <- predict(mort_model, newdata = test_tran[,-1])$yPred
y_hat_test <- as.factor(if_else(y_hat_test == 1, 0, 1))

confusionMatrix(data = y_hat_test, reference = test$died, positive = "1")


#####################################################################
# Save
#####################################################################

# STOP! Too big to fit on GitHub
# save(mort_model, file = "rda/mort_model.rda")