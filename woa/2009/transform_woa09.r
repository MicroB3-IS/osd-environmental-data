# Copyright 2015 Ivaylo Kostadinov
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This script takes WOA09 data, transforms it and produces CSV and RData exports.

# WOA09 Documentation ftp://ftp.nodc.noaa.gov/pub/WOA09/DOC/woa09documentation.pdf
# The following is from the header of the individual csv files; codes are from the documentation above
#Column definitions:
#1. Latitude (degrees,negative=south),
#2. Longitude (degrees,negative=west),
#3. Depth (meters),
#4. Objectively analyzed mean (an),
#5. statistical mean (mn),
#6. standard deviation of statistical mean (sd),
#7. standard error of statistical mean (se),
#8. objectively analyzed mean minus statistical mean (oa), #unsure of code assignment
#9. objectively analyzed mean minus objectively analyzed annual mean (ma), #unsure of code assignment
#10. number of grids with statistical means within radius of influence (gp),
#11. number of data used to calculate statistical mean (dd)

#Get command line arguments
args <- commandArgs()

#Extract the input and output directories
input.dir<-args[match('--in',args)[1]+1]
output.dir<-args[match('--out',args)[1]+1]

#Check if input directory exists
if(!file.exists(input.dir)) {
  cat("ERROR: Missing input directory ",input.dir,"\n")
  quit(save="no",status=1,runLast = FALSE)
}
#Check if output directory exists
if(!file.exists(output.dir)){
  cat("ERROR: Missing output directory ",output.dir,"\n")
  quit(save="no",status=1,runLast = FALSE)
}


#Collect WOA parameter directories 
param.dirs<-dir(input.dir,full.names=T)

#Collect paramter names and replace underscore with dot to adhere to R naming convention 
param.names<-unlist(lapply(param.dirs, function(x) {tail(unlist(strsplit(x,"/",fixed=T)),n=1)}))
param.names<-gsub('_','.',param.names,fixed=T)


# For each parameter
for(j in 1:length(param.dirs)) {
  #Create a temporary data frame 
  env.data<-data.frame()
  
  #Collect all files to be processed
  files<-list.files(param.dirs[j],full.names=T)
  
  # TEST
  files<-head(files,n=1)
  
  # For each file
  for (i in 1:length(files)) { 
    file.name<-files[i]
    #Extract the period and standard level (i.e. depth code) from the file name
    period<-unlist(strsplit(tail(unlist(strsplit(file.name,"/",fixed=T)),n=1),"_",fixed=T))[2]
    standard.level<-unlist(strsplit(tail(unlist(strsplit(file.name,"/",fixed=T)),n=1),"_",fixed=T))[3]
    tmp.df<-read.csv(file.name,header=F,comment.char='#')
    tmp.df[,12]<-period
    tmp.df[,13]<-standard.level
    colnames(tmp.df)<-c("lat","lon","depth","an","mn","sd","se","oa","ma","gp","dd","period","depth.level")    
    env.data<-rbind(env.data,tmp.df)
    rm(tmp.df)
  }
  
  assign(paste("woa09",param.names[j],sep='.'),env.data)
  output.csv<-paste(output.dir,"WOA09.",param.names[j],".csv",sep="")
  output.rdata<-paste(output.dir,"WOA09.",param.names[j],".RData",sep="")
  
  write.csv(get(param.names[j]),output.csv,row.names=F,quote=FALSE)
  save(list=c(param.names[j]),file=output.rdata)
  
  #Cleanup objects
  rm(list=c(param.names[j]))
  message(paste(param.names[j],": ",length(files)))
}
