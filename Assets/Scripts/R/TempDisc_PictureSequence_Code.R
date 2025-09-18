#-#--#-#-#-##-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
#           Temporal Discrimination Study           #
#    Generating picture sequence for Unity Input    #
#-#--#-#-#-##-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
library(lubridate)

# Sample from truncated exponential distribution
sampletruncexp <- function(n, mean, min = 0, max = Inf) {
  u <- runif(n)
  exp_min <- exp(-min / mean)
  exp_max <- exp(-max / mean)
  samples <- -mean * log(exp_min - u * (exp_min - exp_max))
  return(samples)
}

# Read the input data
current_dir <- "F:/Documents/GitHub/Unity/interval-categorization-humans/Assets/Scripts/R"
file_name <- "TempDisc_PictureSequence_Input.csv"
input_path <- file.path(current_dir, file_name)
full_results <- data.frame(read.csv(input_path, sep = ",", dec = ".", header = TRUE))  # TempDisc_PictureSequence_Input
picture_info <- full_results[, c(1:2)]
colnames(picture_info) <- c("PictureType", "file_name")

# Define the picture types and their respective counts
picture_counts <- list(
  Zebra = 8, Horse = 8, DogAggressive = 12, DogNeutral = 12,
  WolfAggressive = 12, WolfNeutral = 12, NegHigh = 8, NegLow = 8,
  PosLow = 8, PosHigh = 8, NewNeutralTraining = 15, NeutralTest = 8
)

# Define occurrences for each picture type (excluding NewNeutralTraining)
occurrences <- list(
  Zebra = 23, Horse = 23, DogAggressive = 34, DogNeutral = 34,
  WolfAggressive = 34, WolfNeutral = 34, NegHigh = 23, NegLow = 23,
  PosLow = 23, PosHigh = 23, NeutralTest = 23
)

# Define the presentation stimulusDurations
stimulusDurations <- list(
  anchor = c(200, 2200),
  intermediate = c(603, 1797, 931, 1469, 1200)
)

# Define the mean ITI
iti_mu <- 4000

# Pre-stimulus delay settings
preStimDelayMin = 0
preStimDelayMean = 1.2
preStimDelayMax = 6

# Function to generate training sequence
generate_training_sequence <- function(picture_info) {
  
  # Subset training neutral pictures
  training_neutral_pictures <- subset(picture_info, PictureType == "NewNeutralTraining")$file_name
  training_neutral_pictures <- sample(training_neutral_pictures)
  
  # Phase 1: Randomly select pictures and assign to 10 trials (with max 3 repetitions per picture)
  max_reps <- 1
  phase1_pictures <- rep(training_neutral_pictures, each = max_reps)  # Limit to 3 repetitions max
  phase1_pictures <- sample(phase1_pictures, size = 10, replace = FALSE)  # Sample 10 pictures
  
  # Ensure 10 trials in Phase 1
  if (length(phase1_pictures) != 10) {
    phase1_pictures <- rep(training_neutral_pictures, length.out = 10)
    phase1_pictures <- sample(phase1_pictures, size = 10, replace = FALSE)
  }
  
  phase1_preStimulusDelays <- round(sampletruncexp(10, mean = preStimDelayMean, min = preStimDelayMin, max = preStimDelayMax) * 1000)
  phase1_stimulusDurations <- c(rep(200, 5), rep(2200, 5))  # Short and long anchors
  phase1_stimulusDurations <- sample(phase1_stimulusDurations)  # Randomize stimulus durations
  phase1_itis <- c(rep(1800, 5), rep(3800, 5))
  phase1_itis <- sample(phase1_itis)

  # Create Phase 1 dataframe
  phase1 <- data.frame(
    file_name = phase1_pictures,
    preStimulusDelay = phase1_preStimulusDelays,
    stimulusDuration = phase1_stimulusDurations, 
    iti = phase1_itis,
    phase = 1
  )
  
  # Phase 2: Intermediate times, randomized stimulus durations and pictures
  phase2_preStimulusDelays <- round(sampletruncexp(34, mean = preStimDelayMean, min = preStimDelayMin, max = preStimDelayMax) * 1000)
  phase2_stimulusDurations <- c(200, 603, 931, 1469, 1797, 2200)
  phase2_stimulusDurations <- sample(rep(phase2_stimulusDurations, times = c(3, 6, 8, 8, 6, 3)))  # Randomize stimulusDurations
  phase2_itis <- c(iti_mu-200, iti_mu-603, iti_mu-931, iti_mu-1469, iti_mu-1797, iti_mu-2200)
  phase2_itis <- sample(rep(phase2_itis, times = c(3, 6, 8, 8, 6, 3)))  
  
  # Check and adjust stimulus duration sequence
  while (length(phase2_stimulusDurations) != 34) {
    phase2_stimulusDurations <- sample(rep(phase2_stimulusDurations, times = c(3, 6, 8, 8, 6, 3)))
  }
  
  # Now, create a vector that repeats each picture up to 3 times (max reps of 3)
  max_reps <- 3
  phase2_pictures <- rep(training_neutral_pictures, each = max_reps)
  phase2_pictures <- sample(phase2_pictures, size = length(phase2_stimulusDurations), replace = FALSE)
  
  # If the length does not match, adjust (make sure Phase 2 has 34 trials)
  if (length(phase2_pictures) != 34) {
    phase2_pictures <- rep(training_neutral_pictures, length.out = 34)
    phase2_pictures <- sample(phase2_pictures, size = length(phase2_stimulusDurations), replace = FALSE)
  }
  
  phase2 <- data.frame(
    file_name = phase2_pictures,
    preStimulusDelay = phase2_preStimulusDelays,
    stimulusDuration = phase2_stimulusDurations, 
    iti = phase2_itis,
    phase = 2
  )
  
  # Return phase 1 and phase 2 separately
  return(list(phase1 = phase1, phase2 = phase2))
}

# Function to generate test sequence
generate_test_sequence <- function(picture_info, picture_counts, occurrences, stimulusDurations) {
  test_sequence <- data.frame()
  
  for (ptype in names(occurrences)) {
    picture_set <- subset(picture_info, PictureType == ptype)$file_name
    n_pictures <- length(picture_set)
    
    if (ptype %in% c("DogAggressive", "DogNeutral", "WolfAggressive", "WolfNeutral")) {
      
      # For Dog and Wolf pictures
      stimulusDurations_rep <- c(
        rep(c(200, 2200), each = 3),
        rep(c(603, 1797), each = 5),
        rep(c(931, 1469), each = 6), 
        rep(c(1200), each=6)
      )
      itis_rep <- c(
        rep(c(iti_mu-200, iti_mu-2200), each = 3),
        rep(c(iti_mu-603, iti_mu-1797), each = 5),
        rep(c(iti_mu-931, iti_mu-1469), each = 6), 
        rep(c(iti_mu-1200), each=6)
      )
      n_rep <- 34
    } else {
      
      # For other pictures
      stimulusDurations_rep <- c(
        rep(c(200, 2200), each = 3),
        rep(c(603, 1797), each = 3),
        rep(c(931, 1469), each = 4), 
        rep(c(1200), each=3)
      )
      itis_rep <- c(
        rep(c(iti_mu-200, iti_mu-2200), each = 3),
        rep(c(iti_mu-603, iti_mu-1797), each = 3),
        rep(c(iti_mu-931, iti_mu-1469), each = 4), 
        rep(c(iti_mu-1200), each=3)
      )
      n_rep <- 23
    }
    
    # Apply a maximum repetition limit of 3 for each picture
    max_reps <- 3
    pictures_rep <- rep(picture_set, length.out = length(stimulusDurations_rep))
    
    # Ensure no picture is repeated more than 3 times
    picture_counts <- table(pictures_rep)
    over_repeated_pictures <- picture_counts[picture_counts > max_reps]
    
    # If any picture is repeated more than 3 times, adjust the sample to respect the limit
    while (any(picture_counts > max_reps)) {
      pictures_rep <- sample(picture_set, size = length(stimulusDurations_rep), replace = TRUE)
      picture_counts <- table(pictures_rep)
    }
    
    # Combine the pictures and stimulus durations
    preStimulusDelay_rep <- round(sampletruncexp(length(pictures_rep), mean = preStimDelayMean, min = preStimDelayMin, max = preStimDelayMax) * 1000)
    stimulusDurations_rep <- rep(stimulusDurations_rep, length.out = length(pictures_rep))
    itis_rep <- sample(rep(itis_rep, length.out = length(pictures_rep)))

    sequence <- data.frame(
      file_name = pictures_rep, 
      preStimulusDelay = preStimulusDelay_rep,
      stimulusDuration = stimulusDurations_rep, 
      iti = itis_rep, 
      phase = 3)
    
    test_sequence <- rbind(test_sequence, sequence)
  }
  
  test_sequence <- shuffle_with_constraints(test_sequence)
  
  return(test_sequence)
}

# Function to shuffle data with constraints
shuffle_with_constraints <- function(data) {
  data <- data[sample(nrow(data)), ]
  
  # Ensure no picture or stimulusDuration repeats in direct succession
  while (any(rle(data$file_name)$lengths > 1) || any(rle(data$stimulusDuration)$lengths > 2)) {
    data <- data[sample(nrow(data)), ]
  }
  
  return(data)
}

# Function to combine training and test sequences
combine_sequences <- function(phase1, phase2, test_sequence) {
  
  # Shuffle each phase separately
  shuffled_phase1 <- shuffle_with_constraints(phase1)
  shuffled_phase2 <- shuffle_with_constraints(phase2)
  shuffled_test <- shuffle_with_constraints(test_sequence)

  # Combine the shuffled sequences
  final_sequence <- rbind(shuffled_phase1, shuffled_phase2, shuffled_test)
  
  return(final_sequence)
}

num_sequences <- 1000

pb <- txtProgressBar(min = 0, max = num_sequences, style = 3)

for (i in 1:num_sequences) {
  
  # ensure different sequence each time
  set.seed(i)
  
  # Generate sequences
  training_sequences <- generate_training_sequence(picture_info)
  phase1 <- training_sequences$phase1
  phase2 <- training_sequences$phase2
  test_sequence <- generate_test_sequence(picture_info, picture_counts, occurrences, stimulusDurations)
  final_sequence <- combine_sequences(phase1, phase2, test_sequence)
  
  #Save
  timestamp <- format(Sys.time(), "%Y-%m-%d_%H-%M-%S")
  file_name <- paste0("image_sequence_", i, "_", timestamp, ".csv")
  save_dir = "F:/Documents/GitHub/Unity/interval-categorization-humans/Assets/Resources/Image Sequences"
  full_path <- file.path(save_dir, file_name)
  write.csv(final_sequence, file = full_path, row.names = FALSE)
  
  # Update progress bar
  setTxtProgressBar(pb, i)
}

close(pb)

# Print the final sequence
print(final_sequence, row.names=FALSE)

# Plot histogram
hist(final_sequence$preStimulusDelay,
     breaks = 40,       # number of bins
     col = "skyblue",   # fill color
     border = "white",  # border color
     main = "Histogram of x",  # title
     xlab = "Values",          # x-axis label
     ylab = "Frequency")       # y-axis label