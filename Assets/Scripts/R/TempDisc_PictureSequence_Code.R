#-#--#-#-#-##-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
#           Temporal Discrimination Study           #
#    Generating picture sequence for Unity Input    #
#-#--#-#-#-##-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
library(lubridate)

# Read the input data
current_dir <- "F:/Documents/GitHub/Unity/interval-categorization-humans/Assets/Scripts/R"
file_name <- "TempDisc_PictureSequence_Input.csv"
input_path <- file.path(current_dir, file_name)
full_results <- data.frame(read.csv(input_path, sep = ";", dec = ",", header = TRUE))  # TempDisc_PictureSequence_Input
picture_info <- full_results[, c(1:2)]
colnames(picture_info) <- c("PictureType", "file_name")

# Define the picture types and their respective counts
picture_counts <- list(
  Zebra = 7, Horse = 7, DogAggressive = 12, DogNeutral = 12,
  WolfAggressive = 12, WolfNeutral = 12, NegHigh = 7, NegLow = 7,
  PosLow = 7, PosHigh = 7, NewNeutralTraining = 16, NeutralTest = 7
)

# Define occurrences for each picture type (excluding NewNeutralTraining)
occurrences <- list(
  Zebra = 20, Horse = 20, DogAggressive = 34, DogNeutral = 34,
  WolfAggressive = 34, WolfNeutral = 34, NegHigh = 20, NegLow = 20,
  PosLow = 20, PosHigh = 20, NeutralTest = 20
)

# Define the stimulus durations
durations <- list(
  anchor = c(200, 2200),
  intermediate = c(603, 1797, 931, 1469)
)

# Define the ITI durations
iti_mu <- 4000
itis <- list(
  anchor = c(iti_mu-200, iti_mu-2200),
  intermediate = c(iti_mu-603, iti_mu-1797, iti_mu-931, iti_mu-1469)
)

# Function to generate training sequence
generate_training_sequence <- function(picture_info) {
  
  # Subset training neutral pictures
  training_neutral_pictures <- subset(picture_info, PictureType == "NewNeutralTraining")$file_name
  training_neutral_pictures <- sample(training_neutral_pictures)
  
  # Phase 1: Short (200 ms) and Long (2200 ms) anchors, randomized sequence with constraints
  phase1_durations <- c(rep(200, 5), rep(2200, 5))
  phase1_durations <- sample(phase1_durations)  # Randomize durations
  phase1_itis <- c(rep(1800, 5), rep(3800, 5))
  phase1_itis <- sample(phase1_itis)
  
  # Check and adjust duration sequence
  while (any(diff(phase1_durations) == 0)) {
    phase1_durations <- sample(phase1_durations)
  }
  
  phase1 <- data.frame(
    file_name = rep(training_neutral_pictures[1:2], each = 5),
    duration = phase1_durations,
    iti = phase1_itis,
    phase = 1
  )
  
  # Phase 2: Intermediate times, randomized durations and pictures
  phase2_durations <- c(200, 603, 931, 1469, 1797, 2200)
  phase2_durations <- sample(rep(phase2_durations, times = c(3, 6, 8, 8, 6, 3)))  # Randomize durations
  phase2_itis <- c(iti_mu-200, iti_mu-603, iti_mu-931, iti_mu-1469, iti_mu-1797, iti_mu-2200)
  phase2_itis <- sample(rep(phase2_itis, times = c(3, 6, 8, 8, 6, 3)))  
  
  # Check and adjust duration sequence
  while (any(diff(phase2_durations) == 0)) {
    phase2_durations <- sample(phase2_durations)
  }
  
  # Randomly select pictures for phase 2
  phase2_pictures <- sample(training_neutral_pictures, size = length(phase2_durations), replace = TRUE)
  
  phase2 <- data.frame(
    file_name = phase2_pictures,
    duration = phase2_durations,
    iti = phase2_itis,
    phase = 2
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
        rep(c(603, 1797), each = 6),
        rep(c(931, 1469), each = 8)
      )
      itis_rep <- c(
        rep(c(iti_mu-200, iti_mu-2200), each = 3),
        rep(c(iti_mu-603, iti_mu-1797), each = 6),
        rep(c(iti_mu-931, iti_mu-1469), each = 8)
      )
      n_rep <- 34
    } else {
      
      # For other pictures
      durations_rep <- c(
        rep(c(200, 2200), each = 3),
        rep(c(603, 1797), each = 3),
        rep(c(931, 1469), each = 4)
      )
      itis_rep <- c(
        rep(c(iti_mu-200, iti_mu-2200), each = 3),
        rep(c(iti_mu-603, iti_mu-1797), each = 3),
        rep(c(iti_mu-931, iti_mu-1469), each = 4)
      )
      n_rep <- 20
    }
    
    pictures_rep <- sample(rep(picture_set, length.out = length(durations_rep)))
    durations_rep <- rep(durations_rep, length.out = length(pictures_rep))
    itis_rep <- sample(rep(itis_rep, length.out = length(pictures_rep)))
    
    sequence <- data.frame(
      file_name = pictures_rep,
      duration = durations_rep,
      iti = itis_rep,
      phase = 3
    )
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

num_sequences <- 1000

pb <- txtProgressBar(min = 0, max = num_sequences, style = 3)

for (i in 1:num_sequences) {
  
  # Generate sequences
  training_sequences <- generate_training_sequence(picture_info)
  phase1 <- training_sequences$phase1
  phase2 <- training_sequences$phase2
  test_sequence <- generate_test_sequence(picture_info, picture_counts, occurrences, durations)
  final_sequence <- combine_sequences(phase1, phase2, test_sequence)
  
  # Save
  timestamp <- format(Sys.time(), "%Y-%m-%d_%H-%M-%S")
  file_name <- paste0("image_sequence_", timestamp, ".csv")
  save_dir = "F:/Documents/GitHub/Unity/interval-categorization-humans/Assets/Resources/Image Sequences"
  full_path <- file.path(save_dir, file_name)
  write.csv(final_sequence, file = full_path, row.names = FALSE)
  
  # Update progress bar
  setTxtProgressBar(pb, i)
}

close(pb)

# Print the final sequence
print(final_sequence, row.names=FALSE)
