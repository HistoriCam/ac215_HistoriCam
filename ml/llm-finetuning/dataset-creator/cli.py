import os
import argparse
import pandas as pd
import json
import time
import glob
from sklearn.model_selection import train_test_split
from google.cloud import storage

# Gen AI
from google import genai
from google.genai import types
from google.genai.types import Content, Part, GenerationConfig, ToolConfig
from google.genai import errors

# Setup
GCP_PROJECT = os.environ["GCP_PROJECT"]
GCP_LOCATION = "us-central1"
GENERATIVE_MODEL = "gemini-2.0-flash-001"
OUTPUT_FOLDER = "data"
GCS_BUCKET_NAME = os.environ["GCS_BUCKET_NAME"]

#############################################################################
#                       Initialize the LLM Client                           #
llm_client = genai.Client(vertexai=True, project=GCP_PROJECT, location=GCP_LOCATION)
#############################################################################

safety_settings = [
    types.SafetySetting(category="HARM_CATEGORY_HATE_SPEECH", threshold="OFF"),
    types.SafetySetting(category="HARM_CATEGORY_DANGEROUS_CONTENT", threshold="OFF"),
    types.SafetySetting(category="HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold="OFF"),
    types.SafetySetting(category="HARM_CATEGORY_HARASSMENT", threshold="OFF"),
]

# System Prompt
SYSTEM_INSTRUCTION = """Generate a set of 20 question-answer pairs about Harvard Landmarks in English, adopting the tone and perspective of a tour guide. While answering questions, always suggest that these are answers, recommendations, and ideas from the tour guide. Adhere to the following guidelines:

1. Question Independence:
   - Ensure each question-answer pair is completely independent and self-contained
   - Do not reference other questions or answers within the set
   - Each Q&A pair should be understandable without any additional context

2. Technical Information:
   - Incorporate detailed technical information about Harvard Landmarks, their history, architecture, and significance
   - Include specific data such as dates, architectural styles, and notable events associated with each landmark
   - Explain the architectural principles behind Harvard Landmarks
   - Discuss the role of specific historical figures, events, and cultural influences in the development of these landmarks
   - Reference relevant technical terms, architectural styles, and methodologies used in the preservation and study of Harvard Landmarks

3. Expert Perspective and Personalization:
   - Embody the voice of a friendly tour guide with deep knowledge of Harvard Landmarks
   - Address all answers directly from the tour guide, using a friendly yet respectful tone
   - Infuse responses with passion for the history and significance of Harvard Landmarks
   - Reference historical figures, architectural styles, and cultural anecdotes where relevant

4. Content Coverage:
   - Architectural methods, including specific techniques and equipment
   - Harvard landmarks, their characteristics, and cultural significance
   - Harvard landmarks, with emphasis on the history behind them
   - Cultural importance of these landmarks in Harvard and beyond
   - Historical details of Harvard Landmarks, viewed through an expert's lens

5. Tone and Style:
   - Use a passionate, authoritative, yet friendly tone that conveys years of expertise
   - Incorporate humorous terms where appropriate
   - Balance technical knowledge with accessible explanations from the tour guide

6. Complexity and Depth:
   - Provide a mix of basic information and advanced technical insights
   - Include lesser-known facts, expert observations, and scientific data
   - Offer nuanced explanations that reflect deep understanding of Harvard Landmarks
   
7. Question Types:
   - Include a variety of question types (e.g., "what", "how", "why", "can you explain", "what's the difference between")
   - Formulate questions as if someone is passionate about Harvard Landmarks
   - Ensure questions cover a wide range of topics within the Harvard Landmarks domain, including technical aspects

8. Answer Format:
   - Include vivid imagery and scenarios that bring the tour guide's expertise to life
   - Give comprehensive answers that showcase expertise while maintaining a personal touch
   - Include relevant anecdotes, historical context, or scientific explanations where appropriate
   - Ensure answers are informative and engaging, balancing technical detail with accessibility

9. Cultural Context:
   - Highlight the role of Harvard and its landmarks in broader cultural and historical contexts
   - Reference significant historical events and figures associated with Harvard Landmarks

10. Accuracy and Relevance:
    - Ensure all information, especially technical data, is factually correct and up-to-date
    - Focus on widely accepted information about Harvard Landmarks and their historical significance

11. Language:
    - Use English throughout
    - Define technical terms when first introduced

Output Format:
Provide the Q&A pairs in JSON format, with each pair as an object containing 'question' and 'answer' fields, within a JSON array.
Follow these strict guidelines:
1. Use double quotes for JSON keys and string values.
2. For any quotation marks within the text content, use single quotes (') instead of double quotes. Avoid quotation marks.
3. If a single quote (apostrophe) appears in the text, escape it with a backslash (\'). 
4. Ensure there are no unescaped special characters that could break the JSON structure.
5. Avoid any Invalid control characters that JSON decode will not be able to decode.

Here's an example of the expected format:
Sample JSON Output:
```json
[
  {
    "question": "When was Memorial Hall built?",
    "answer": "Memorial Hall at Harvard University was built between 1870 and 1877. It was constructed to honor Harvard men who fought for the Union in the American Civil War. The building is a striking example of High Victorian Gothic architecture and serves as a significant historical landmark on the Harvard campus."
  },
  {
    "question": "Can you tell me a fun fact about Widener Library?",
    "answer": "Here's a fun (and true!) fact about Harvard's Widener Library: It was built because of a tragic Titanic story. The library was donated by Eleanor Elkins Widener in memory of her son, Harry Elkins Widener, a Harvard alum and rare-book collector who died in the Titanic sinking in 1912. As part of the gift, she required that Harry's personal rare-book collection always remain intact—and that no major structural changes be made to the library's exterior."
  },
  "question": "What is so significant about Sever Hall?",
  "answer": "Sever Hall is significant as one of H. H. Richardson's finest Romanesque designs, celebrated for its masterful brickwork, subtle ornamentation, and distinctive acoustic archway."
]
```

Note: The sample JSON provided includes only two Q&A pairs for brevity. The actual output should contain all 20 pairs as requested."""

response_schema = {
    "type": "array",
    "description": "Array of question and answer pairs",
    "items": {
        "type": "object",
        "properties": {
            "question": {"type": "string", "description": "The question being asked"},
            "answer": {
                "type": "string",
                "description": "The detailed answer to the question",
            },
        },
        "required": ["question", "answer"],
    },
}


def generate():
    print("generate()")

    # Make dataset folders
    os.makedirs(OUTPUT_FOLDER, exist_ok=True)

    INPUT_PROMPT = """Generate 20 diverse, informative, and engaging question-answer pairs about Harvard landmarks following these guidelines. Ensure each pair is independent and self-contained, embody the passionate and knowledgeable tone of a tour guide, incorporate relevant technical information, keep all content in English, and address all answers directly."""
    NUM_ITERATIONS = 400  

    # Configuration settings for the content generation
    GENERATION_CONFIG = types.GenerateContentConfig(
        temperature=0.9,
        top_p=0.95,
        max_output_tokens=8192,
        safety_settings=safety_settings,
        system_instruction=SYSTEM_INSTRUCTION,
        response_mime_type="application/json",
        response_schema=response_schema,
    )

    # Loop to generate and save the content
    for i in range(0, NUM_ITERATIONS):
        print(f"Generating batch: {i}")
        try:

            response = llm_client.models.generate_content(
                model=GENERATIVE_MODEL,
                contents=INPUT_PROMPT,
                config=GENERATION_CONFIG,
            )
            generated_text = response.text

            # Create a unique filename for each iteration
            file_name = f"{OUTPUT_FOLDER}/historicam_qa_{i}.txt"
            # Save
            with open(file_name, "w") as file:
                file.write(generated_text)
        except Exception as e:
            print(f"Error occurred while generating content: {e}")


def prepare():
    print("prepare()")

    # Get the generated files
    output_files = glob.glob(os.path.join(OUTPUT_FOLDER, "historicam_qa_*.txt"))
    output_files.sort()

    # Consolidate the data
    output_pairs = []
    errors = []
    for output_file in output_files:
        print("Processing file:", output_file)
        with open(output_file, "r") as read_file:
            text_response = read_file.read()

        text_response = text_response.replace("```json", "").replace("```", "")

        try:
            json_responses = json.loads(text_response)
            output_pairs.extend(json_responses)

        except Exception as e:
            errors.append({"file": output_file, "error": str(e)})

    print("Number of errors:", len(errors))
    print(errors[:5])

    # Save the dataset
    output_pairs_df = pd.DataFrame(output_pairs)
    output_pairs_df.drop_duplicates(subset=["question"], inplace=True)
    output_pairs_df = output_pairs_df.dropna()
    print("Shape:", output_pairs_df.shape)
    print(output_pairs_df.head())
    filename = os.path.join(OUTPUT_FOLDER, "instruct-dataset.csv")
    output_pairs_df.to_csv(filename, index=False)

    # Build training formats
    output_pairs_df["text"] = (
        "human: "
        + output_pairs_df["question"]
        + "\n"
        + "bot: "
        + output_pairs_df["answer"]
    )

    # Gemini Data prep: https://cloud.google.com/vertex-ai/generative-ai/docs/models/gemini-supervised-tuning-prepare
    # {"contents":[{"role":"user","parts":[{"text":"..."}]},{"role":"model","parts":[{"text":"..."}]}]}
    output_pairs_df["contents"] = output_pairs_df.apply(
        lambda row: [
            {"role": "user", "parts": [{"text": row["question"]}]},
            {"role": "model", "parts": [{"text": row["answer"]}]},
        ],
        axis=1,
    )

    # Test train split
    df_train, df_test = train_test_split(
        output_pairs_df, test_size=0.1, random_state=42
    )
    df_train[["text"]].to_csv(os.path.join(OUTPUT_FOLDER, "train.csv"), index=False)
    df_test[["text"]].to_csv(os.path.join(OUTPUT_FOLDER, "test.csv"), index=False)

    # Gemini : Max numbers of examples in validation dataset: 256
    df_test = df_test[:256]

    # JSONL
    with open(os.path.join(OUTPUT_FOLDER, "train.jsonl"), "w") as json_file:
        json_file.write(df_train[["contents"]].to_json(orient="records", lines=True))
    with open(os.path.join(OUTPUT_FOLDER, "test.jsonl"), "w") as json_file:
        json_file.write(df_test[["contents"]].to_json(orient="records", lines=True))


def upload():
    print("upload()")

    storage_client = storage.Client()
    bucket = storage_client.bucket(GCS_BUCKET_NAME)
    timeout = 300

    data_files = glob.glob(os.path.join(OUTPUT_FOLDER, "*.jsonl")) + glob.glob(
        os.path.join(OUTPUT_FOLDER, "*.csv")
    )
    data_files.sort()

    # Upload
    for index, data_file in enumerate(data_files):
        filename = os.path.basename(data_file)
        destination_blob_name = os.path.join("llm-finetune-dataset-small", filename)
        blob = bucket.blob(destination_blob_name)
        print("Uploading file:", data_file, destination_blob_name)
        blob.upload_from_filename(data_file, timeout=timeout)


def main(args=None):
    print("CLI Arguments:", args)

    if args.generate:
        generate()

    if args.prepare:
        prepare()

    if args.upload:
        upload()


if __name__ == "__main__":
    # Generate the inputs arguments parser
    # if you type into the terminal '--help', it will provide the description
    parser = argparse.ArgumentParser(description="CLI")

    parser.add_argument(
        "--generate",
        action="store_true",
        help="Generate data",
    )
    parser.add_argument(
        "--prepare",
        action="store_true",
        help="Prepare data",
    )
    parser.add_argument(
        "--upload",
        action="store_true",
        help="Upload data to bucket",
    )

    args = parser.parse_args()

    main(args)
