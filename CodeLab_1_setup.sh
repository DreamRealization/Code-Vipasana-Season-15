#!/bin/bash
# Codelab 1 — Dark Data to Structured Gold Setup Script
# Sets up GCS bucket, BigQuery dataset, and loads CSV data

set -e

export PROJECT_ID=${PROJECT_ID:-"your-project-id"}
export REGION="us-central1"
export DATASET="froyo_data"
export BUCKET_NAME="froyo-data-${PROJECT_ID}"

echo "🚀 Starting Codelab 1 Setup..."
echo "Project: $PROJECT_ID"

# Enable required APIs
echo "📡 Enabling required APIs..."
gcloud services enable \
  dataplex.googleapis.com \
  bigquery.googleapis.com \
  storage.googleapis.com \
  aiplatform.googleapis.com \
  --project=$PROJECT_ID

# Create GCS bucket
echo "🪣 Creating GCS bucket..."
gsutil mb -p $PROJECT_ID -l $REGION gs://${BUCKET_NAME}/ 2>/dev/null || echo "Bucket already exists"

# Create BigQuery dataset
echo "📊 Creating BigQuery dataset..."
bq mk --location=$REGION --dataset ${PROJECT_ID}:${DATASET} 2>/dev/null || echo "Dataset already exists"

# Download and load CSV files
echo "📥 Downloading CSV files..."
GITHUB_RAW="https://raw.githubusercontent.com/AbiramiSukumaran/raw-data-to-gold/refs/heads/main/data"

declare -A TABLES=(
  ["allergen"]="allergen_name:STRING"
  ["consistsof"]="product_id:STRING,ingredient_id:STRING"
  ["containsallergen"]="ingredient_id:STRING,allergen_name:STRING"
  ["ingredient"]="ingredient_id:STRING,ingredient_name:STRING,purity:STRING,moisture_content:STRING,ph_range:STRING,specific_gravity_range:STRING"
  ["product"]="product_id:STRING,product_name:STRING,category:STRING,stability:STRING"
  ["suppliedby"]="ingredient_id:STRING,supplier_id:STRING"
  ["supplier"]="supplier_id:STRING,supplier_name:STRING,production_site_id:STRING,facility_grade:STRING"
  ["froyo_data_materialized"]="allergen:STRING,containsallergen:STRING,ingredient:STRING,product:STRING,suppliedby:STRING,supplier:STRING,ref:STRING,md5_hash:STRING"
)

for table in "${!TABLES[@]}"; do
  echo "Loading $table..."
  wget -q "${GITHUB_RAW}/froyo_data.${table}.csv" -O "/tmp/froyo_data.${table}.csv"
  bq load \
    --autodetect \
    --source_format=CSV \
    --skip_leading_rows=1 \
    --allow_quoted_newlines \
    --quote="" \
    ${DATASET}.${table} \
    "/tmp/froyo_data.${table}.csv" \
    "${TABLES[$table]}" 2>/dev/null || echo "Table $table already exists"
  echo "✅ $table loaded"
done

# Verify
echo ""
echo "📋 Verifying tables:"
bq ls --project_id=$PROJECT_ID $DATASET

echo ""
echo "✅ Codelab 1 Setup Complete!"
echo "BigQuery Dataset: ${PROJECT_ID}:${DATASET}"
echo "Tables loaded: ${#TABLES[@]}"
