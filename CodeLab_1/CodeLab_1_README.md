# Codelab 1 — Dark Data to Structured Gold 🌟

## Overview
Transformed unstructured PDF documents (froyo product specs, supplier info, quality reports) into queryable BigQuery views using Google Cloud's AI-powered data pipeline.

## Architecture
```
PDF Files (GCS) ──► Dataplex DataScan ──► BigQuery External Table ──► Materialized Views
                         │
                    Gemini AI (Schema Inference)
```

## Key Components

### 1. GCS Bucket Setup
Uploaded raw PDF files containing:
- Product specifications
- Ingredient lists
- Supplier information
- Quality test results
- Manufacturing site data

### 2. Dataplex DataScan
- **Scan ID**: `datascan-froyo-vipasana1`
- **Type**: Data Discovery with Gemini semantic inference
- Automatically inferred schema from unstructured PDFs
- Generated BigQuery external table `froyo_data_vipasana1`

### 3. BigQuery Dataset: `froyo_data`

| Table | Type | Description |
|-------|------|-------------|
| `froyo_data_vipasana1` | EXTERNAL | Raw PDF data via Dataplex |
| `froyo_data_vipasana1_materialized` | TABLE | Materialized version |
| `allergen` | VIEW | Allergen information |
| `consistsof` | VIEW | Product-ingredient relationships |
| `containsallergen` | VIEW | Ingredient-allergen mapping |
| `ingredient` | VIEW | Ingredient details |
| `manufacturingsite` | VIEW | Manufacturing locations |
| `product` | VIEW | Product catalog |
| `qualitytest` | VIEW | Quality test results |
| `supplier` | VIEW | Supplier information |
| `supplied_by` | VIEW | Supplier-ingredient mapping |

## Setup Script
