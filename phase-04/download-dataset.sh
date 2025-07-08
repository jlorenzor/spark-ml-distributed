!/bin/bash

# Download dataset script for Spark ML Distributed
# Usage: ./download-dataset.sh
set -e
# Download dataset
echo "Descargando dataset..."
wget -q https://raw.githubusercontent.com/jlorenzor/spark-ml-distributed/main/phase-04/cultivos_piura.csv -O cultivos_piura.csv

# Check if the download was successful
if [ $? -eq 0 ]; then
    echo "Dataset descargado exitosamente: cultivos_piura.csv"
else
    echo "Error al descargar el dataset."
    exit 1
fi