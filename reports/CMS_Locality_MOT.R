library(stringr)
library(lubridate)
library(pander)
library(dplyr)
library(tidyr)

# source ("reports/CMS_prep.R")

#CMS <- read.csv("data/CMS_8_26.txt")
#FIPS_Codes <- read.csv("/data/FIPS_R.csv")

# # Remove Extraneous columns from CMS table
# CMS <- CMS[,!names(CMS) %in% c("Notes","Received","ErrorType","FilingDate","CorrectionDate")]
# 
# #Remove extra white space from around some values
# CMS$HEAR.RSLT <- str_trim(CMS$HEAR.RSLT)
# CMS$CASE.TYP <- str_trim(CMS$CASE.TYP)
# CMS$MOT <- str_trim(CMS$MOT)
# 
# #Create Month and Year columns
# CMS$HEAR.DATE <- as.Date(CMS$HEAR.DATE, format = '%m/%d/%Y')
# CMS$Year<- year(CMS$HEAR.DATE)
# CMS$Month <- month(CMS$HEAR.DATE)
# 
# #Filter for no errors (keep or no?)
# CMS<- filter(CMS, Error< 1|is.na(Error))
# 
# # Create Fiscal Year Variable
# CMS$FYear<- CMS$Year
# CMS[CMS$Month > 6, ]$FYear <- as.numeric(CMS[CMS$Month > 6, ]$Year) + 1
# 
# #Create Fiscal Quarter Variable
# CMS$FQtr <- CMS$Month
# CMS[CMS$Month == 7|CMS$Month==8| CMS$Month==9, ]$FQtr <- 1
# CMS[CMS$Month == 10|CMS$Month==11| CMS$Month==12, ]$FQtr <- 2
# CMS[CMS$Month == 1|CMS$Month==2| CMS$Month==3, ]$FQtr <- 3
# CMS[CMS$Month == 4|CMS$Month==5| CMS$Month==6, ]$FQtr <- 4
# 
# # Create abbreviated month column, factored in accordance with fiscal calendar
# CMS$FYMonthAbbrev <- factor(substr(month.name[CMS$Month],1,3),levels=substr(c(month.name[7:12],month.name[1:6]),1,3))
# 
# # Create a uniq identifier for the month (may or may not be needed)
# CMS$month_id <- factor(paste(CMS$FYear, str_pad(as.character(CMS$Month), 2, side="left", pad="0"), sep="-"))
# 
# #Create FIPs column
# CMS$FIPS <- substr(CMS$CASE.NUMBER, 1, 4)
# 
# #Include FIPS names
# CMS <- merge(CMS, FIPS_Codes, by = c("FIPS"), all.x = TRUE)
# CMS <- CMS[,!names(CMS) %in% c("SHORT_FIPS","COURT")]
# names(CMS)[names(CMS)=="NAME"] <- "Locality"
# 
# #Use Pay Code to determine if Initial
# CMS$Initial <- ifelse (CMS$PAY.CD == 41 | CMS$PAY.CD == 46, FALSE, TRUE)
# CMS$Initial [is.na(CMS$PAY.CD)] <- TRUE

########### HERE'S THE MEAT #########
# Create table of the counts of 4 Different MOT Types for all localities
CMS_MOT <- filter(CMS, CASE.TYP =="MC", HEAR.RSLT %in% c("MO", "I"))%>%
mutate(MOT_TYPE=ifelse((HEAR.RSLT=="I" & MOT=="Y" & !Initial), "TYPE4", NA)) %>%
mutate(MOT_TYPE=ifelse((HEAR.RSLT=="I" & MOT=="Y" & Initial), "TYPE3", MOT_TYPE)) %>%
mutate(MOT_TYPE=ifelse((HEAR.RSLT=="MO"  & Initial), "TYPE1", MOT_TYPE)) %>%
mutate(MOT_TYPE=ifelse((HEAR.RSLT=="MO"  & !Initial), "TYPE2", MOT_TYPE)) %>%
mutate(MOT_TYPE=factor(MOT_TYPE)) %>%
#   group_by(Locality,HEAR.RSLT, MOT, Initial)%>%
group_by(Locality,MOT_TYPE)%>%
#   filter((HEAR.RSLT == "I" & (MOT == "Y") ) | HEAR.RSLT == "MO" ) %>%
  summarise(count = n()) 

CMS_MOT <- CMS_MOT[complete.cases(CMS_MOT),]

CMS_MOT <- spread(CMS_MOT,MOT_TYPE,count)

CMS_MOT[is.na(CMS_MOT)] <- 0

CMS_MOT$Total <- CMS_MOT$TYPE1 + CMS_MOT$TYPE2 + CMS_MOT$TYPE3 + CMS_MOT$TYPE4

names(CMS_MOT) <- c("Locality", "Direct", "New\nHearing", "Discharge\nInitial", "Discharge\nRecommitment", "Total")
CMS_MOT$Locality <- gsub("/","/\n",CMS_MOT$Locality)
CMS_MOT$Locality <- gsub(" \\(","\n\\(",CMS_MOT$Locality)

# Trying to give MOT type column names
#CMS_MOT <- as.data.frame(CMS_MOT,colnames)
#colnames(CMS_MOT) <- CMS_MOT[49,]

# CMS_MOT <- as.data.frame(CMS_MOT)
# 
# CMS_MOT<- rename(CMS_MOT, Stepdown_Recommitment_Discharge=V1, Stepdown_Initial_Discharge=V2, Stepdown_New_Hearing=V3, Direct=V4)
# CMS_MOT <- CMS_MOT[-50,]


#pander(CMS_MOT, caption= "MOT Types by Locality", keep.line.breaks = TRUE,split.table = Inf))
