#-#--#-#-#-##-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
#           Temporal Discrimination Study           #
#    Generating picture sequence for Unity Input    #
#-#--#-#-#-##-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
library(lubridate)

save.image(file="TempDisc_PictureSequence.RData")

# to open
load(file="TempDisc_PictureSequence.RData") 


# Read the input data
full_results <- data.frame(read.csv(file.choose(), sep = ",", dec = ",", header = TRUE))  # TempDisc_PictureSequence_Input
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

# Define the presentation durations
durations <- list(
  anchor = c(200, 2200),
  intermediate = c(603, 1797, 931, 1469)
)

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
  
  phase1_durations <- c(rep(200, 5), rep(2200, 5))  # Short and long anchors
  phase1_durations <- sample(phase1_durations)  # Randomize durations
  
  # Create Phase 1 dataframe
  phase1 <- data.frame(
    file_name = phase1_pictures,
    duration = phase1_durations
  )
  
  # Phase 2: Intermediate times, randomized durations and pictures
  phase2_durations <- c(200, 603, 931, 1469, 1797, 2200)
  phase2_durations <- sample(rep(phase2_durations, times = c(3, 6, 8, 8, 6, 3)))  # Randomize durations
  
  # Check and adjust duration sequence
  while (length(phase2_durations) != 34) {
    phase2_durations <- sample(rep(phase2_durations, times = c(3, 6, 8, 8, 6, 3)))
  }
  
  # Now, create a vector that repeats each picture up to 3 times (max reps of 3)
  max_reps <- 3
  phase2_pictures <- rep(training_neutral_pictures, each = max_reps)
  phase2_pictures <- sample(phase2_pictures, size = length(phase2_durations), replace = FALSE)
  
  # If the length does not match, adjust (make sure Phase 2 has 34 trials)
  if (length(phase2_pictures) != 34) {
    phase2_pictures <- rep(training_neutral_pictures, length.out = 34)
    phase2_pictures <- sample(phase2_pictures, size = length(phase2_durations), replace = FALSE)
  }
  
  phase2 <- data.frame(
    file_name = phase2_pictures,
    duration = phase2_durations
  )
  
  # Return phase 1 and phase 2 separately
  return(list(phase1 = phase1, phase2 = phase2))
}



# Function to generate test sequence
generate_test_sequence <- function(picture_info, picture_counts, occurrences, durations) {
  test_sequence <- data.frame()
  
  for (ptype in names(occurrences)) {
    picture_set <- subset(picture_info, PictureType == ptype)$file_name
    n_pictures <- length(picture_set)
    
    if (ptype %in% c("DogAggressive", "DogNeutral", "WolfAggressive", "WolfNeutral")) {
      # For Dog and Wolf pictures
      durations_rep <- c(
        rep(c(200, 2200), each = 3),
        rep(c(603, 1797), each = 5),
        rep(c(931, 1469), each = 7), 
        rep(c(1200), each=4)
      )
      n_rep <- 34
    } else {
      # For other pictures
      durations_rep <- c(
        rep(c(200, 2200), each = 3),
        rep(c(603, 1797), each = 3),
        rep(c(931, 1469), each = 4), 
        rep(c(1200), each=3)
      )
      n_rep <- 23
    }
    
    # Apply a maximum repetition limit of 3 for each picture
    max_reps <- 3
    picture_reps <- rep(picture_set, length.out = length(durations_rep))
    
    # Ensure no picture is repeated more than 3 times
    picture_counts <- table(picture_reps)
    over_repeated_pictures <- picture_counts[picture_counts > max_reps]
    
    # If any picture is repeated more than 3 times, adjust the sample to respect the limit
    while (any(picture_counts > max_reps)) {
      picture_reps <- sample(picture_set, size = length(durations_rep), replace = TRUE)
      picture_counts <- table(picture_reps)
    }
    
    # Combine the pictures and durations
    durations_rep <- rep(durations_rep, length.out = length(picture_reps))
    
    sequence <- data.frame(file_name = picture_reps, duration = durations_rep)
    test_sequence <- rbind(test_sequence, sequence)
  }
  
  test_sequence <- shuffle_with_constraints(test_sequence)
  
  return(test_sequence)
}

# Function to shuffle data with constraints
shuffle_with_constraints <- function(data) {
  set.seed(123)
  data <- data[sample(nrow(data)), ]
  
  # Ensure no picture or duration repeats in direct succession
  while (any(rle(data$file_name)$lengths > 1) || any(rle(data$duration)$lengths > 2)) {
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

num_sequences <- 100

for (i in 1:num_sequences) {

  # Generate sequences
  training_sequences <- generate_training_sequence(picture_info)
  phase1 <- training_sequences$phase1
  phase2 <- training_sequences$phase2
  test_sequence <- generate_test_sequence(picture_info, picture_counts, occurrences, durations)
  final_sequence <- combine_sequences(phase1, phase2, test_sequence)
  
  # Print the final sequence
  print(final_sequence, row.names=FALSE)
  
  #Save
  timestamp <- format(Sys.time(), "%Y-%m-%d_%H-%M-%S")
  file_name <- paste0("image_sequence_", timestamp, ".csv")
  save_dir = "F:/Documents/Unity/Interval categorization task/Assets/Resources/Image Sequences"
  full_path <- file.path(save_dir, file_name)
  write.csv(final_sequence, file = full_path, row.names = FALSE)
}







#-#-#-##-#-#-#-#-#-#-#-
# TO CHECK 

Seq1 <- read.csv(file.choose(), sep = ",", dec = ",", header = TRUE) 

# Merge the combined data with the image-category mapping
merged_data <- Seq1 %>%
  left_join(full_results, by = "file_name")


# by stimulus
occurrences_S <- merged_data %>%
  group_by(file_name) %>%
  summarize(count = n(), .groups = 'drop')

print(occurrences_S)
boxplot(count~file_name, data=occurrences_S)


# by category and stimulus
occurrences_SC <- merged_data %>%
  group_by(PictureType, duration) %>%
  summarize(count = n(), .groups = 'drop')

print(occurrences_SC)

occurrences_SC$duration<-as.factor(occurrences_SC$duration)

ggplot(occurrences_SC, aes(x = PictureType, y = count, color = duration)) +
  geom_boxplot() +
  theme_minimal()
