# BBNJ Conference Speech Data
## Natural Language Processing with spacyr

This project models ocean health within a country's marine jurisdiction (as measured by the Ocean Health Index) using the country's speeches at meetings of the UN Biodiversity Beyond National Jurisdictions conference.

I scraped the speech pdf data from the BBNJ website and read in the contents of each pdf. I used spacy to process the text in the scraped and tidied dataset, including lemmatization (finding the root word) and part of speech tagging (only included nouns and verbs). The cleaned dataset is quite small - it comprises 100 speeches in English given by only 40 distinct countries.

I set up and trained 3 model types (random forest, generalized linear, k-nearest neighbors). The random forest model performed best - albeit with an R-squared of less than 0.25. This model was fitted to the reserved test data to generate predictions (on only 30 speeches, 30% of the dataset).

I mapped error (RMSE) and found that the model is worse at predicting ocean health scores for smaller island countries. Error is higher for Sri Lanka and parts of Polynesia. Important phrases (lemmas) included: "conservation", "instrument", "capacity building", and "transfer technology".
