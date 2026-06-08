#!/bin/bash
# Codelab 2 — AlloyDB + BigQuery Federation Setup Script

set -e

export PROJECT_ID=${PROJECT_ID:-"your-project-id"}
export REGION="us-central1"
export CLUSTER_ID="froyo-cluster"
export INSTANCE_ID="froyo-instance"
export ALLOYDB_PASSWORD=${ALLOYDB_PASSWORD:-"FroyoPass123!"}
export VPC_NAME="alloydb-vpc"
export SUBNET_NAME="alloydb-subnet"

echo "🚀 Starting AlloyDB Setup..."
echo "Project: $PROJECT_ID | Region: $REGION"

# Get project number
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
echo "Project Number: $PROJECT_NUMBER"

# Enable APIs
echo "📡 Enabling APIs..."
gcloud services enable \
  alloydb.googleapis.com \
  servicenetworking.googleapis.com \
  secretmanager.googleapis.com \
  --project=$PROJECT_ID

# Create VPC
echo "🌐 Creating VPC..."
gcloud compute networks create $VPC_NAME \
  --project=$PROJECT_ID \
  --subnet-mode=custom 2>/dev/null || echo "VPC already exists"

gcloud compute networks subnets create $SUBNET_NAME \
  --project=$PROJECT_ID \
  --network=$VPC_NAME \
  --region=$REGION \
  --range=10.0.0.0/24 2>/dev/null || echo "Subnet already exists"

# Setup private service access
echo "🔒 Setting up private service access..."
gcloud compute addresses create google-managed-services-alloydb \
  --project=$PROJECT_ID \
  --global \
  --purpose=VPC_PEERING \
  --prefix-length=16 \
  --network=$VPC_NAME 2>/dev/null || echo "Address already exists"

gcloud services vpc-peerings connect \
  --project=$PROJECT_ID \
  --service=servicenetworking.googleapis.com \
  --ranges=google-managed-services-alloydb \
  --network=$VPC_NAME 2>/dev/null || echo "Peering already exists"

# Create AlloyDB cluster
echo "🗄️ Creating AlloyDB cluster..."
gcloud alloydb clusters create $CLUSTER_ID \
  --project=$PROJECT_ID \
  --region=$REGION \
  --network=projects/${PROJECT_NUMBER}/global/networks/${VPC_NAME} \
  --database-version=POSTGRES_15 \
  --password=$ALLOYDB_PASSWORD

# Create primary instance
echo "⚡ Creating AlloyDB instance (this takes ~10 minutes)..."
gcloud alloydb instances create $INSTANCE_ID \
  --project=$PROJECT_ID \
  --cluster=$CLUSTER_ID \
  --region=$REGION \
  --instance-type=PRIMARY \
  --cpu-count=2

# Enable bigquery_fdw flag
echo "🔧 Enabling bigquery_fdw flag..."
gcloud alloydb instances update $INSTANCE_ID \
  --cluster=$CLUSTER_ID \
  --region=$REGION \
  --project=$PROJECT_ID \
  --database-flags=bigquery_fdw.enabled=on

# Grant IAM permissions
echo "🔑 Granting IAM permissions..."
ALLOYDB_SA="service-${PROJECT_NUMBER}@gcp-sa-alloydb.iam.gserviceaccount.com"
COMPUTE_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

for SA in "$ALLOYDB_SA" "$COMPUTE_SA"; do
  for ROLE in roles/bigquery.dataViewer roles/bigquery.user roles/bigquery.readSessionUser roles/bigquery.jobUser; do
    gcloud projects add-iam-policy-binding $PROJECT_ID \
      --member="serviceAccount:${SA}" \
      --role="$ROLE" 2>/dev/null
  done
done

# Get instance IP
INSTANCE_IP=$(gcloud alloydb instances describe $INSTANCE_ID \
  --cluster=$CLUSTER_ID \
  --region=$REGION \
  --project=$PROJECT_ID \
  --format="value(ipAddress)")

echo ""
echo "✅ AlloyDB Setup Complete!"
echo "Cluster: $CLUSTER_ID"
echo "Instance: $INSTANCE_ID"
echo "Private IP: $INSTANCE_IP"
echo ""
echo "Next: Connect via AlloyDB Studio and run federation.sql"
